import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatefulWidget {
  final String username;
  ChatPage({required this.username});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WindowListener {
  bool _isDarkMode = false;
  String? _userAvatarPath;
  String? _userFolderPath;
  bool _isEmojiVisible = false;
  String? _selectedUser;
  final TextEditingController _messageController = TextEditingController();
  final List<String> _chatUsers = ["Alice", "Bob", "Charlie", "David"];
  final Map<String, List<Message>> _userMessages = {};

  @override
  void initState() {
    super.initState();
    _initializeUserFolder();
    _resizeWindow();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initializeUserFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    _userFolderPath = '${directory.path}/${widget.username}';
    final userFolder = Directory(_userFolderPath!);

    if (!userFolder.existsSync()) {
      userFolder.createSync();
      const defaultAvatarPath = 'assets/images/default_user.jpg';
      final avatarFile = File('$_userFolderPath/user.jpg');
      if (File(defaultAvatarPath).existsSync()) {
        avatarFile.writeAsBytesSync(File(defaultAvatarPath).readAsBytesSync());
      }
    }

    setState(() {
      _userAvatarPath = '$_userFolderPath/user.jpg';
    });
  }

  Future<void> _resizeWindow() async {
    await windowManager.setSize(const Size(800, 600));
    await windowManager.center();
  }

  void _sendMessage({String? imagePath}) {
    if ((_messageController.text.isNotEmpty || imagePath != null) && _selectedUser != null) {
      setState(() {
        _userMessages[_selectedUser!] ??= [];
        _userMessages[_selectedUser!]!.add(
          Message(
            sender: 'me',
            content: _messageController.text.isNotEmpty ? _messageController.text : imagePath!,
            timestamp: DateTime.now(),
            type: imagePath != null ? MessageType.image : MessageType.text,
          ),
        );
        _messageController.clear();
        _isEmojiVisible = false;
      });
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }

  Future<void> _handleFileUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImage = await file.copy('$_userFolderPath/$fileName.png');
      _sendMessage(imagePath: savedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${widget.username}'),
          actions: <Widget>[
            IconButton(
              icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(
                backgroundImage: _userAvatarPath != null
                    ? FileImage(File(_userAvatarPath!))
                    : AssetImage('assets/images/default_user.jpg')
                        as ImageProvider,
              ),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isEmojiVisible) {
              setState(() {
                _isEmojiVisible = false;
              });
            }
          },
          child: Row(
            children: <Widget>[
              // 封装聊天用户列表
              ChatUserList(
                chatUsers: _chatUsers,
                selectedUser: _selectedUser,
                onUserSelected: (user) {
                  setState(() {
                    _selectedUser = user;
                  });
                },
              ),
              VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // 封装聊天窗口和消息显示
                    Expanded(
                      child: ChatWindow(
                        selectedUser: _selectedUser,
                        userMessages: _userMessages,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                    // 封装输入栏
                    ChatInputBar(
                      messageController: _messageController,
                      isEmojiVisible: _isEmojiVisible,
                      onEmojiToggle: () {
                        setState(() {
                          _isEmojiVisible = !_isEmojiVisible;
                        });
                      },
                      onFileUpload: _handleFileUpload,
                      onMessageSend: _sendMessage,
                    ),
                    if (_isEmojiVisible)
                      SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            _onEmojiSelected(emoji);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 聊天用户列表组件
class ChatUserList extends StatelessWidget {
  final List<String> chatUsers;
  final String? selectedUser;
  final Function(String) onUserSelected;

  ChatUserList({
    required this.chatUsers,
    required this.selectedUser,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: ListView.builder(
        itemCount: chatUsers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(chatUsers[index]),
            selected: selectedUser == chatUsers[index],
            onTap: () => onUserSelected(chatUsers[index]),
          );
        },
      ),
    );
  }
}

// 聊天窗口和消息显示组件
class ChatWindow extends StatelessWidget {
  final String? selectedUser;
  final Map<String, List<Message>> userMessages;
  final bool isDarkMode;

  ChatWindow({
    required this.selectedUser,
    required this.userMessages,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: selectedUser == null
              ? Center(child: Text('请选择一个聊天对象'))
              : ListView.builder(
                  itemCount: userMessages[selectedUser]?.length ?? 0,
                  itemBuilder: (context, index) {
                    var message = userMessages[selectedUser!]![index];
                    var isMyMessage = message.sender == 'me';

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMyMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMyMessage)
                            Text(
                              message.sender,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            margin: EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? isDarkMode
                                      ? const Color.fromARGB(255, 32, 22, 169)
                                      : const Color.fromARGB(255, 95, 144, 197)
                                  : isDarkMode
                                      ? const Color.fromARGB(255, 59, 154, 15)
                                      : const Color.fromARGB(96, 104, 234, 113),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: message.type == MessageType.text
                                ? Text(message.content)
                                : Image.file(
                                    File(message.content),
                                    width: 200,
                                  ),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// 聊天输入栏组件
class ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final bool isEmojiVisible;
  final VoidCallback onEmojiToggle;
  final VoidCallback onFileUpload;
  final Function({String? imagePath}) onMessageSend;

  ChatInputBar({
    required this.messageController,
    required this.isEmojiVisible,
    required this.onEmojiToggle,
    required this.onFileUpload,
    required this.onMessageSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          IgnorePointer(
            ignoring: isEmojiVisible,
            child: IconButton(
              icon: Icon(Icons.emoji_emotions),
              onPressed: onEmojiToggle,
            ),
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Enter your message',
              ),
              onSubmitted: (value) => onMessageSend(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: onFileUpload,
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => onMessageSend(),
          ),
        ],
      ),
    );
  }
}

enum MessageType { text, image }

class Message {
  final String sender;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}
