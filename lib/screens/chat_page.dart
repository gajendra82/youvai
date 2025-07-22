import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Dr. Leah Zane",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            "You are currently in a chat session\nwith your doctor!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8F5FE8),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Today",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Patient (right, purple)
                Align(
                  alignment: Alignment.centerRight,
                  child: _ChatBubble(
                    message:
                        "Hi doctor. I have some skin issues I'd like to discuss with you.",
                    time: "02:00 PM",
                    isMe: true,
                  ),
                ),
                const SizedBox(height: 10),
                // Doctor (left, grey)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _ChatBubble(
                    message:
                        "Hello! Of course, I'm here to help. Could you please explain the skin problem you're experiencing?",
                    time: "02:01 PM",
                    isMe: false,
                  ),
                ),
                const SizedBox(height: 10),
                // Patient (right, purple)
                Align(
                  alignment: Alignment.centerRight,
                  child: _ChatBubble(
                    message:
                        "Yes, recently I've been dealing with quite severe acne on my face. I've tried some over-the-counter products but it seems like there's been no change.",
                    time: "02:05 PM",
                    isMe: true,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Message",
                          hintStyle: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    margin: const EdgeInsets.only(bottom: 150),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F5FE8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(16);
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF8F5FE8)
                : const Color(0xFFEAEBED),
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: isMe ? radius : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : radius,
            ),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              "• Seen",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        )
      ],
    );
  }
}