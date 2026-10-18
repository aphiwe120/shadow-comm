import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final rng = Random.secure();
  
  // 1. Create your "Shipping Container" first!
  var buffer = Uint8List(1024);
  var rawMessage = utf8.encode("Hello, Shadow Comm!");

  // 2. KEY GENERATION (The Gym)
  var salt = Uint8List(16);
  for (int i = 0; i < salt.length; i++) {
    salt[i] = rng.nextInt(256);
  }
  
  final algorithm = Argon2id(
    memory: 64000,
    iterations: 3,
    parallelism: 4,
    hashLength: 32,
  );

  final masterKey = await algorithm.deriveKeyFromPassword(
    password: "my_secure_password",
    nonce: salt,
  );

  // 3. ENCRYPTION (The Scramble)
  final cipher = AesGcm.with256bits();
  final nonce = Uint8List(12);
  for (var i = 0; i < nonce.length; i++) {
    nonce[i] = rng.nextInt(256);
  }

  final secretBox = await cipher.encrypt(
    rawMessage, 
    secretKey: masterKey,
    nonce: nonce,
  );

  // 4. THE STITCH (The Packet)
  buffer.fillRange(0, buffer.length, 0); // Clear it
  buffer.setRange(0, nonce.length, nonce); // Put Nonce at 0-11
  buffer.setRange(
    nonce.length, 
    nonce.length + secretBox.cipherText.length, 
    secretBox.cipherText
  ); // Put Ciphertext starting at 12

  print("--- PHASE 1 COMPLETE ---");
  print("Full Encrypted Packet: $buffer");

  // 5. THE "REVERSE" (Decryption Simulation)
  // Step A: Extract Nonce (First 12 bytes)
  var extractedNonce = buffer.sublist(0, 12);
  
  // Step B: Extract Ciphertext (From index 12 to 12 + length)
  var extractedCiphertext = buffer.sublist(12, 12 + secretBox.cipherText.length);

  // Step C: Decrypt
  final decryptedBox = SecretBox(
    extractedCiphertext,
    nonce: extractedNonce,
    mac: secretBox.mac, // We'll talk about this 'mac' seal next time!
  );

  final clearText = await cipher.decrypt(
    decryptedBox,
    secretKey: masterKey,
  );

  print("Final Decrypted Result: ${utf8.decode(clearText)}");
}