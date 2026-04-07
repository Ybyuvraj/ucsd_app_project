import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();

  // Initialize the chat history with a system prompt.
  final List<Map<String, String>> _chatHistory = [
    {
      "role": "system",
      "content":"""
          Your name is TritonAI you are a helpful and knowledgeable assistant for UC San Diego (UCSD) students. 
          Your role is to provide accurate, up-to-date, and relevant responses about student resources, academics, events, campus life, career opportunities, and job preparation. Prioritize clarity and empathy in your tone. 
          When answering questions, use a UCSD-specific context, referencing official departments, campus services, and student experiences. If a question is outside your knowledge or scope, suggest where the student might find help 
          (e.g., “You can check with the UCSD Career Center” or “Try contacting the Registrar’s Office”)."""
    }
  ];

  bool _isLoading = false;

  // Replace with your OpenAI API key.
  final String _openaiApiKey = dotenv.env['OPENAI_API_KEY']!;

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // Append the user's message to the conversation history.
    setState(() {
      _chatHistory.add({"role": "user", "content": message});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_openaiApiKey",
        },
        body: json.encode({
          "model": "gpt-3.5-turbo",
          "messages": _chatHistory,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botReply = data['choices'][0]['message']['content'];
        setState(() {
          _chatHistory.add({"role": "assistant", "content": botReply});
          _isLoading = false;
        });
      } else {
        setState(() {
          _chatHistory.add({
            "role": "assistant",
            "content": "Sorry, there was an error: ${response.statusCode}"
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({"role": "assistant", "content": "Error: $e"});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "TritonAI",
          style: TextStyle(
              decoration: TextDecoration.none, 
            ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[_chatHistory.length - 1 - index];
                final isUser = message["role"] == "user";
                if (message["role"] == "system") return const SizedBox.shrink();
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser
                            ? const Radius.circular(12)
                            : const Radius.circular(0),
                        bottomRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(12),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Text(
                      message["content"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask something about UCSD...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
