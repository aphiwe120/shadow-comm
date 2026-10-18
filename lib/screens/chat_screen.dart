import 'dart:convert';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/room_key_dialog.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String myUserId;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatarUrl;

  const ChatScreen({
    super.key,
    required this.myUserId,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SecurityService _securityService = SecurityService();
  late Stream<List<Map<String, dynamic>>> _messageStream;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;

  String _chatKey = '';

  /// Cache decrypted messages to avoid re-decrypting on every frame
  /// Key: message ID, Value: decrypted text
  final Map<String, String> _messageCache = {};
  final Map<String, Future<String>> _decryptionCache = {};

  /// Track number of messages to detect new arrivals
  int _previousMessageCount = 0;

  /// Set of message IDs we've notified for (avoid duplicate notifications)
  final Set<String> _notifiedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.listenForMessages(widget.receiverId);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      print('⚠️  ScrollController: no clients yet');
      return;
    }

    try {
      // With reverse: true, latest message is at position 0
      // So we scroll to minScrollExtent (0.0) to show the newest message
      final minScroll = _scrollController.position.minScrollExtent;
      final currentScroll = _scrollController.offset;

      print(
        '📱 ScrollController (reversed): min=$minScroll, current=$currentScroll',
      );

      _scrollController
          .animateTo(
            minScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            print('✅ Scrolled to latest message (reversed ListView)');
          })
          .catchError((e) {
            print('❌ Scroll error: $e');
          });
    } catch (e) {
      print('❌ ScrollToBottom error: $e');
    }
  }

  /// Prompts for the room password and resets decrypted state if it changed.
  Future<void> _showPasswordOverlay() async {
    final key = await showRoomKeyDialog(context, initialKey: _chatKey);
    if (key == null || !mounted) return;

    setState(() {
      if (key != _chatKey) {
        _messageCache.clear();
        _decryptionCache.clear();
      }
      _chatKey = key;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Password set'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _sendMessage() async {
    print('Attempting to send...');

    final text = _inputController.text.trim();
    print('Message text: "$text" (length: ${text.length})');

    if (text.isEmpty) {
      print('Message is empty, aborting send');
      return;
    }

    if (_chatKey.isEmpty) {
      print('Chat key is empty, aborting send');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the Room Key before sending.')),
        );
      }
      return;
    }

    try {
      print(
        'Sending to: receiverId=${widget.receiverId}, senderId=${widget.myUserId}',
      );

      await _chatService.sendSecureMessage(
        text: text,
        password: _chatKey,
        senderId: widget.myUserId,
        receiverId: widget.receiverId,
      );

      print('✅ Message sent successfully');
      _inputController.clear();
      _scrollToBottom();
    } catch (e, stackTrace) {
      print('❌ Send Error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  /// Picks an image from gallery and sends it as an encrypted "snap"
  Future<void> _pickAndSendImage() async {
    print('\n📸 [_pickAndSendImage]');

    if (_chatKey.isEmpty) {
      print('⚠️  Chat key is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the Room Key before sending a snap.'),
        ),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      print('   1️⃣  Opening image picker...');
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        print('   ⚠️  User cancelled image selection');
        return;
      }

      print('   ✅ Image selected: ${image.path}');

      final Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await image.readAsBytes();
        print(
          '   📊 Image size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB',
        );
      } else {
        final originalSize = await image.length();
        print(
          '   📊 Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
        );

        print('   2️⃣  Compressing image (70% quality, 1024px max width)...');
        final compressedImage = await FlutterImageCompress.compressAndGetFile(
          image.path,
          '${image.path}.compressed.jpg',
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
          format: CompressFormat.jpeg,
        );

        if (compressedImage == null) {
          print('❌ Image compression failed');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to compress image')),
            );
          }
          return;
        }

        imageBytes = await compressedImage.readAsBytes();
        final reduction = ((1 - (imageBytes.length / originalSize)) * 100)
            .toStringAsFixed(1);
        print(
          '   ✅ Compressed size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB ($reduction% reduction)',
        );
      }

      print('   3️⃣  Sending encrypted snap...');
      await _chatService.sendSecureSnap(
        imageBytes: imageBytes,
        password: _chatKey,
        senderId: widget.myUserId,
        receiverId: widget.receiverId,
      );

      print('✅ Snap sent successfully\n');

      _scrollToBottom();
    } catch (e, stackTrace) {
      print('❌ Send snap error: $e');
      print(stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send snap: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(avatarUrl: widget.receiverAvatarUrl, radius: 16),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.receiverName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text("No packets found."));
                }

                print('📨 Stream update: ${messages.length} messages received');

                // 🔔 Notification Logic: Detect new messages and show notifications
                if (messages.length > _previousMessageCount) {
                  print(
                    '📬 New message(s) detected! ($_previousMessageCount -> ${messages.length})',
                  );

                  // Process new messages from the other user
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (
                      int i = _previousMessageCount;
                      i < messages.length;
                      i++
                    ) {
                      final msg = messages[i];
                      final messageId = msg['id']?.toString() ?? '';
                      final senderId = msg['sender_id']?.toString();

                      // Only notify if message is FROM the other user (not our own message)
                      if (senderId == widget.receiverId &&
                          !_notifiedMessageIds.contains(messageId)) {
                        print(
                          '🔔 Showing notification for message $messageId from ${widget.receiverName}',
                        );

                        // Get decrypted preview from cache
                        String preview = '🔒 New encrypted message';
                        if (messageId.isNotEmpty &&
                            _messageCache.containsKey(messageId)) {
                          preview = _messageCache[messageId]!;
                          // Truncate preview to 50 chars
                          if (preview.length > 50) {
                            preview = '${preview.substring(0, 50)}...';
                          }
                        } else if (preview.startsWith('https://')) {
                          preview = '📸 Image received';
                        }

                        if (!kIsWeb) {
                          NotificationService().showMessageNotification(
                            senderName: widget.receiverName,
                            messagePreview: preview,
                            payload: widget.receiverId,
                          );
                        }

                        _notifiedMessageIds.add(messageId);
                      }
                    }
                  });

                  _previousMessageCount = messages.length;

                  // Scroll when new messages arrive without triggering a rebuild.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    print('📌 Triggering auto-scroll to newest message...');
                    _scrollToBottom();
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  reverse:
                      true, // ✨ Reversed UI: newest at bottom, oldest at top
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    // Filter: Only show messages between current user and selected receiver
                    final senderId = msg['sender_id']?.toString();
                    final receiverId = msg['receiver_id']?.toString();
                    final messageId = msg['id']?.toString();
                    final isRelevant =
                        (senderId == widget.myUserId &&
                            receiverId == widget.receiverId) ||
                        (senderId == widget.receiverId &&
                            receiverId == widget.myUserId);
                    if (!isRelevant) {
                      return const SizedBox.shrink();
                    }

                    final bool isMe = senderId == widget.myUserId;

                    // Determine colors based on sender
                    final bubbleColor = isMe
                        ? const Color(
                            0xFF00D9FF,
                          ) // Neon cyan for current user (vibrant)
                        : const Color(0xFF2D3748); // Dark shadow for others

                    // Parse timestamp
                    String timeLabel = "";
                    final createdAt = msg['created_at'];
                    if (createdAt is String) {
                      try {
                        final dt = DateTime.parse(createdAt).toLocal();
                        timeLabel =
                            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                      } catch (_) {}
                    }

                    // Decode packet from Supabase
                    final dynamic rawPacket = msg['packet'];
                    Uint8List encryptedPacket;

                    try {
                      if (rawPacket is String) {
                        // Base64 encoded packet
                        encryptedPacket = base64Decode(rawPacket);
                      } else if (rawPacket is List) {
                        // List<dynamic> from Supabase
                        encryptedPacket = Uint8List.fromList(
                          List<int>.from(rawPacket),
                        );
                      } else {
                        throw Exception(
                          "Unknown packet format: ${rawPacket.runtimeType}",
                        );
                      }
                    } catch (e) {
                      // Packet decode error
                      return MessageBubble(
                        isMe: isMe,
                        text: "❌ Packet Error: $e",
                        timestamp: timeLabel,
                        bubbleColor: Colors.red.shade900,
                        avatarUrl: widget.receiverAvatarUrl,
                      );
                    }

                    // Gate: Require room key before decryption
                    if (_chatKey.isEmpty) {
                      return MessageBubble(
                        isMe: false,
                        text:
                            "🔒 Room locked. Enter the Room Key above to decrypt.",
                        timestamp: timeLabel,
                        bubbleColor: const Color(
                          0xFF2D3748,
                        ), // Dark shadow color
                        avatarUrl: widget.receiverAvatarUrl,
                      );
                    }

                    // ✨ THE DECRYPT ONCE RULE ✨
                    // Check cache first: if message ID is cached, show immediately
                    if (messageId != null &&
                        _messageCache.containsKey(messageId)) {
                      final cachedText = _messageCache[messageId]!;
                      print('💾 Cache HIT for message $messageId');
                      return MessageBubble(
                        isMe: isMe,
                        text: cachedText,
                        timestamp: timeLabel,
                        bubbleColor: bubbleColor,
                        avatarUrl: widget.receiverAvatarUrl,
                      );
                    }

                    // Cache miss: decrypt and save to cache
                    print('🔐 Cache MISS for message $messageId - decrypting...');
                    final decryptionCacheKey =
                        messageId ?? base64Encode(encryptedPacket);
                    if (!_decryptionCache.containsKey(decryptionCacheKey)) {
                      _decryptionCache[decryptionCacheKey] = _securityService
                          .decryptMessage(encryptedPacket, _chatKey)
                          .then((decrypted) {
                            if (messageId != null) {
                              _messageCache[messageId] = decrypted;
                              print(
                                '💾 Cached message $messageId (${decrypted.length} chars)',
                              );
                            }
                            return decrypted;
                          });
                    }
                    return FutureBuilder<String>(
                      future: _decryptionCache[decryptionCacheKey]!,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'Decryption Failed 🔒',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        if (snapshot.hasData) {
                          return MessageBubble(
                            isMe: isMe,
                            text: snapshot.data!,
                            timestamp: timeLabel,
                            bubbleColor: bubbleColor,
                            avatarUrl: widget.receiverAvatarUrl,
                          );
                        }

                        // Loading state
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          MessageInputBar(
            controller: _inputController,
            focusNode: _focusNode,
            receiverName: widget.receiverName,
            hasRoomKey: _chatKey.isNotEmpty,
            showEmojiPicker: _showEmojiPicker,
            onEmojiTap: _toggleEmojiPicker,
            onKeyTap: _showPasswordOverlay,
            onImageTap: _pickAndSendImage,
            onSend: _sendMessage,
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _inputController,
                config: const Config(height: 250),
              ),
            ),
        ],
      ),
    );
  }
}
