import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chat> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatsJsonString = prefs.getString('chats');
    if (chatsJsonString != null) {
      List<dynamic> chatsJson = jsonDecode(chatsJsonString);
      setState(() {
        _chats = chatsJson.map((json) => Chat.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatsJsonString = jsonEncode(_chats.map((chat) => chat.toJson()).toList());
    prefs.setString('chats', chatsJsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
      ),
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_chats[index].contactName),
            subtitle: Text(_chats[index].lastMessageWithTime),
            leading: CircleAvatar(
              backgroundColor: _chats[index].avatarColor,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chat: _chats[index]),
                ),
              );
              _loadChats(); // Перезагружаем чаты при возвращении из ChatScreen
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createChat(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createChat(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatCreatorScreen()),
    );

    if (result != null && result is Chat) {
      setState(() {
        _chats.add(result);
        _saveChats();
      });
    }
  }
}

class ChatCreatorScreen extends StatefulWidget {
  const ChatCreatorScreen({Key? key}) : super(key: key);

  @override
  State<ChatCreatorScreen> createState() => _ChatCreatorScreenState();
}

class _ChatCreatorScreenState extends State<ChatCreatorScreen> {
  Color _avatarColor = Colors.blue;
  String _contactName = '';

  void _createChat() {
    if (_contactName.isNotEmpty) {
      final newChat = Chat(
        contactName: _contactName,
        avatarColor: _avatarColor,
      );
      Navigator.pop(context, newChat);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter contact name.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Chat'),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _avatarColor,
            ),
            title: TextField(
              decoration: const InputDecoration(
                labelText: 'Contact Name',
              ),
              onChanged: (value) {
                setState(() {
                  _contactName = value;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: _createChat,
            child: const Text('Create Chat'),
          ),
          const SizedBox(height: 16.0),
          Text('Choose Avatar Color:'),
          Wrap(
            spacing: 8.0,
            children: <Widget>[
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.yellow),
              _buildColorButton(Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _avatarColor = color;
        });
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 16.0,
      ),
    );
  }
}

class Chat {
  final String contactName;
  final Color avatarColor;
  List<String> messages;
  List<String> times;

  Chat({required this.contactName, required this.avatarColor, this.messages = const [], this.times = const []});

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      contactName: json['contactName'],
      avatarColor: Color(json['avatarColor']),
      messages: List<String>.from(json['messages']),
      times: List<String>.from(json['times']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactName': contactName,
      'avatarColor': avatarColor.value,
      'messages': messages,
      'times': times,
    };
  }

  String get lastMessage => messages.isNotEmpty ? messages.last : '';

  String get lastMessageWithTime {
    if (messages.isNotEmpty && times.isNotEmpty) {
      final lastMessageTime = DateTime.parse(times.last);
      final formattedTime = '${lastMessageTime.hour}:${lastMessageTime.minute}';
      return '$lastMessage - $formattedTime';
    } else {
      return '';
    }
  }
}

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.contactName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chat.messages[index],
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            _formatTime(widget.chat.times[index]),
                            style: TextStyle(fontSize: 12.0, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _sendMessage();
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        widget.chat.messages.add(message);
        widget.chat.times.add(DateTime.now().toString());
        _saveChats(); // Сохраняем обновленные данные о чате
        _messageController.clear();
      });
    }
  }

  String _formatTime(String timeString) {
    DateTime dateTime = DateTime.parse(timeString);
    String hour = '${dateTime.hour}'.padLeft(2, '0');
    String minute = '${dateTime.minute}'.padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatsJsonString = jsonEncode(widget.chat.toJson());
    prefs.setString('chats', chatsJsonString);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
