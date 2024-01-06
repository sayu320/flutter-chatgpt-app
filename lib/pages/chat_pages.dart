import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatgpt_app/consts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
    token: openaiApiKey,
    baseOption: HttpSetup(receiveTimeout: Duration(seconds: 5)),
    enableLog: true,
  );
  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'Sayooj', lastName: 'Krishna');

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');

  List<ChatMessage> _messages = <ChatMessage>[];

  List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 166, 126, 1),
        title: const Text(
          'GPT Chat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          messageOptions: const MessageOptions(
              currentUserContainerColor: Colors.black,
              containerColor: Color.fromRGBO(0, 166, 126, 1),
              textColor: Colors.white),
          onSend: (ChatMessage m) {
            getChatResponse(m);
          },
          messages: _messages),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    try {
      setState(() {
        _messages.insert(0, m);
        _typingUsers.add(_gptChatUser);
      });
      List<Messages> _messagesHistory = _messages.reversed.map((m) {
        if (m.user == _currentUser) {
          return Messages(role: Role.user, content: m.text);
        } else {
          return Messages(role: Role.assistant, content: m.text);
        }
      }).toList();
      print("_messageHistory: $_messagesHistory");

      final request = ChatCompleteText(
          model: Gpt432kChatModel(),
          messages: _messagesHistory,
          maxToken: 200);

      print("ChatGPT Request: ${request.toJson()}");

      final response = await _openAI.onChatCompletion(request: request);

      print("ChatGPT Response: ${response?.toJson()}");

      for (var element in response!.choices) {
        if (element.message != null) {
          setState(() {
            _messages.insert(
                0,
                ChatMessage(
                    user: _gptChatUser,
                    createdAt: DateTime.now(),
                    text: element.message!.content));
          });
        }
      }
      setState(() {
        _typingUsers.remove(_gptChatUser);
      });
    } catch (e) {
      print("Error in getChatResponse: $e");
    }
  }
}
