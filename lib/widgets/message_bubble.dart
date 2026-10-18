import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'user_avatar.dart';

/// Chat bubble aligned to the trailing edge when [isMe], leading otherwise.
/// Sent messages use neon cyan, received ones a dark shade. Messages whose
/// text starts with 'https://' are rendered as images.
class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String timestamp;
  final Color bubbleColor;
  final String? avatarUrl;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.timestamp,
    required this.bubbleColor,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = _buildBubble(context);
    if (isMe) return bubble;

    // Received messages show the sender's avatar to the left of the bubble.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: UserAvatar(avatarUrl: avatarUrl, radius: 16),
        ),
        Flexible(child: bubble),
      ],
    );
  }

  Widget _buildBubble(BuildContext context) {
    final isImage = text.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isImage ? Colors.transparent : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: isImage
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: isMe
                              ? const Color(0xFF00D9FF).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.4),
                          blurRadius: isMe ? 8 : 4,
                          offset: const Offset(0, 2),
                          spreadRadius: isMe ? 1 : 0,
                        ),
                      ],
              ),
              padding: isImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: isImage ? _buildImage(context) : _buildText(),
            ),
          ),
          if (isImage && timestamp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                timestamp,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageWidth = MediaQuery.of(context).size.width * 0.6;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isMe
            ? const Radius.circular(16)
            : const Radius.circular(4),
        bottomRight: isMe
            ? const Radius.circular(4)
            : const Radius.circular(16),
      ),
      child: CachedNetworkImage(
        imageUrl: text,
        width: imageWidth,
        height: 250,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: imageWidth,
          height: 250,
          color: const Color(0xFF2D3748),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00D9FF)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: imageWidth,
          height: 250,
          color: Colors.red.shade900,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black87 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (timestamp.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              timestamp,
              style: TextStyle(
                fontSize: 11,
                color: isMe
                    ? Colors.black54
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}
