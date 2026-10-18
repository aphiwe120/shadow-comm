import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String timestamp;
  final Color backgroundColor;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) const SizedBox(width: 32),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: const TextStyle(fontSize: 14)),
                if (timestamp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timestamp,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isMe) const SizedBox(width: 32),
      ],
    );
  }
}
