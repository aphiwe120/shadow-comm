import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'security_service.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  final _security = SecurityService();

  /// Encrypts message and sends it to Supabase (as base64)
  Future<void> sendSecureMessage({
    required String text,
    required String password,
    required String senderId,
    required String receiverId,
  }) async {
    print('\n📤 [ChatService.sendSecureMessage]');
    print('   From: $senderId');
    print('   To: $receiverId');
    print('   Message: "$text"');
    
    try {
      print('   1️⃣  Encrypting message...');
      final packet = await _security.encryptMessage(text, password);
      print('   ✅ Encrypted (${packet.length} bytes)');
      
      print('   2️⃣  Encoding to base64...');
      final packetBase64 = base64Encode(packet);
      print('   ✅ Base64 encoded (${packetBase64.length} chars)');
      
      print('   3️⃣  Inserting into Supabase...');
      print('   Table: "messages"');
      
      final response = await _supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'packet': packetBase64,
      });
      
      print('   ✅ Supabase insert successful. Response: $response');
      print('✅ Message sent securely (stored as base64)\n');
    } catch (e, stackTrace) {
      print('   ❌ Error at step (unknown): $e');
      print('   Stack trace:');
      print(stackTrace);
      print('❌ Send failed: $e\n');
      rethrow;
    }
  }

  /// Listens for recent messages with pagination (latest 20 only)
  /// Optimized: Uses .order('created_at', descending) and .limit(20)
  /// Reduces decryption load from 1000+ messages to 20 at a time
  /// Returns messages ordered DESC (newest first in stream)
  Stream<List<Map<String, dynamic>>> listenForMessages(String userId) {
    print('📡 [ChatService.listenForMessages] Setting up paginated stream for userId: $userId');
    print('   💡 Strategy: Fetch only 20 most recent messages to minimize decryption');
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)  // Newest first
        .limit(20)  // Only decrypt 20 messages, not 1000+
        .map((event) {
          // Filter client-side: sender OR receiver matches userId
          final filtered = event
              .where((msg) => 
                  msg['sender_id'] == userId || msg['receiver_id'] == userId)
              .toList()
              .cast<Map<String, dynamic>>();
          
          print('📥 Paginated stream update: ${filtered.length} messages (from last 20)');
          return filtered;
        });
  }

  /// Uploads image bytes to Supabase Storage bucket 'snaps'
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String senderId,
  }) async {
    print('\n📸 [ChatService.uploadImage]');
    print('   Size: ${imageBytes.length} bytes');

    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${senderId}_$timestamp.jpg';
      final filePath = 'snaps/$fileName';

      print('   1️⃣  Uploading to Storage...');
      print('   Path: $filePath');

      // Upload to Supabase Storage
      await _supabase.storage
          .from('snaps')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('   ✅ Upload successful');

      // Get public URL
      print('   2️⃣  Generating public URL...');
      final publicUrl = _supabase.storage
          .from('snaps')
          .getPublicUrl(fileName);

      print('   ✅ Public URL: $publicUrl');
      print('📸 Image uploaded successfully\n');

      return publicUrl;
    } catch (e, stackTrace) {
      print('   ❌ Upload error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Uploads an image and sends its URL as an encrypted message (as a "snap")
  Future<void> sendSecureSnap({
    required Uint8List imageBytes,
    required String password,
    required String senderId,
    required String receiverId,
  }) async {
    print('\n🔐 [ChatService.sendSecureSnap]');

    try {
      // Step 1: Upload image and get URL
      print('   1️⃣  Uploading image...');
      final imageUrl = await uploadImage(
        imageBytes: imageBytes,
        senderId: senderId,
      );

      // Step 2: Send URL as encrypted message
      print('   2️⃣  Sending image URL as encrypted message...');
      await sendSecureMessage(
        text: imageUrl,
        password: password,
        senderId: senderId,
        receiverId: receiverId,
      );

      print('✅ Secure snap sent successfully\n');
    } catch (e, stackTrace) {
      print('   ❌ Send snap error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}