import 'package:flutter/material.dart';

/// Bottom bar of the chat screen: room key button, image picker and the
/// message field with its send button.
class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String receiverName;
  final bool hasRoomKey;
  final bool showEmojiPicker;
  final VoidCallback onEmojiTap;
  final VoidCallback onKeyTap;
  final VoidCallback onImageTap;
  final VoidCallback onSend;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.receiverName,
    required this.hasRoomKey,
    required this.showEmojiPicker,
    required this.onEmojiTap,
    required this.onKeyTap,
    required this.onImageTap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Row(
          children: [
            // Password Key Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onKeyTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: hasRoomKey
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                        : const Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasRoomKey
                          ? const Color(0xFF7C3AED)
                          : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    hasRoomKey ? Icons.lock_open : Icons.lock,
                    color: hasRoomKey
                        ? const Color(0xFF7C3AED)
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Image Picker Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onImageTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.image, color: Colors.grey[600], size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                color: Colors.grey[600],
              ),
              onPressed: onEmojiTap,
            ),
            // Message Input Field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message $receiverName...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2D3748),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSend,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
