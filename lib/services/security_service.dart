import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

/// Top-level so it can be passed to `compute()`. Owns its own cipher
/// instances because nothing from [SecurityService] can cross isolates.
Future<String> _decryptInWorker(Map<String, dynamic> args) async {
  final packet = args['packet'] as Uint8List;
  final password = args['password'] as String;

  if (packet.length < SecurityService.headerLength) {
    throw FormatException('Packet too short: ${packet.length} bytes');
  }

  int offset = 0;
  final salt = packet.sublist(offset, offset + SecurityService.saltLength);
  offset += SecurityService.saltLength;
  final nonce = packet.sublist(offset, offset + SecurityService.nonceLength);
  offset += SecurityService.nonceLength;
  final macBytes = packet.sublist(offset, offset + SecurityService.macLength);
  offset += SecurityService.macLength;

  // Take all remaining bytes; trimming trailing zeroes can corrupt valid
  // ciphertext and break MAC verification on some platforms.
  final ciphertext = packet.sublist(offset);

  if (ciphertext.isEmpty) throw FormatException('Empty ciphertext');

  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 50000,
    bits: 256,
  );
  final aes = AesGcm.with256bits();

  final masterKey = await pbkdf2.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );

  try {
    final clearTextBytes = await aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes)),
      secretKey: masterKey,
    );
    return utf8.decode(clearTextBytes);
  } catch (e) {
    throw FormatException('Auth Failed: Wrong Key or Corrupted Data ($e)');
  }
}

class SecurityService {
  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int macLength = 16;
  static const int headerLength = saltLength + nonceLength + macLength; // 44 bytes

  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 50000,
    bits: 256,
  );

  // AES-GCM with 256-bit keys; default MAC length (16 bytes) matches macLength.
  final _aes = AesGcm.with256bits();
  final _rng = Random.secure();

  Future<Uint8List> encryptMessage(String message, String password) async {
    final messageBytes = utf8.encode(message);
    final salt = _randomBytes(saltLength);
    final nonce = _randomBytes(nonceLength);

    final masterKey = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final secretBox = await _aes.encrypt(
      messageBytes,
      secretKey: masterKey,
      nonce: nonce,
    );

    final macBytes = secretBox.mac.bytes;
    // Sanity check during development; can be removed later.
    assert(macBytes.length == macLength,
        'Unexpected MAC length: ${macBytes.length} (expected $macLength)');

    final cipherLen = secretBox.cipherText.length;
    final totalLen = headerLength + cipherLen;
    final packet = Uint8List(totalLen);
    
    int offset = 0;
    packet.setRange(offset, offset + saltLength, salt);
    offset += saltLength;
    packet.setRange(offset, offset + nonceLength, nonce);
    offset += nonceLength;
    packet.setRange(offset, offset + macLength, macBytes);
    offset += macLength;
    packet.setRange(offset, offset + cipherLen, secretBox.cipherText);

    return packet;
  }

  /// Decrypts off the UI thread. On Flutter Web, `compute()` has no real
  /// isolates and runs the callback on the main thread instead.
  ///
  /// Derivations are queued so only a few run at once   (each PBKDF2
    /// derivation is CPU-heavy). The timeout covers execution only, not time spent waiting.
  Future<String> decryptMessage(Uint8List packet, String password) async {
    await _acquireSlot();
    try {
      return await compute(_decryptInWorker, {
        'packet': packet,
        'password': password,
      }).timeout(
        _decryptTimeout,
        onTimeout: () => throw TimeoutException('Decryption timed out'),
      );
    } finally {
      _releaseSlot();
    }
  }

  static const Duration _decryptTimeout = Duration(seconds: 15);
  // Web runs everything on one thread, so parallel derivations only hurt.
  static final int _maxConcurrent = kIsWeb ? 1 : 2;
  static int _running = 0;
  static final Queue<Completer<void>> _waiting = Queue<Completer<void>>();

  static Future<void> _acquireSlot() {
    if (_running < _maxConcurrent) {
      _running++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waiting.add(waiter);
    return waiter.future;
  }

  static void _releaseSlot() {
    if (_waiting.isNotEmpty) {
      // Hand the slot straight to the next waiter; _running is unchanged.
      _waiting.removeFirst().complete();
    } else {
      _running--;
    }
  }

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    return bytes;
  }
}