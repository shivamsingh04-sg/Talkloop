import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  Map<String, String> _userProfilePics = {};

  @override
  void initState() {
    super.initState();
    _fetchGroupUserProfilePics();
  }

  Future<void> _fetchGroupUserProfilePics() async {
    final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);

    for (final uid in memberIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profileUrl = userDoc.data()?['profilePic'] ?? '';
      setState(() {
        _userProfilePics[uid] = profileUrl;
      });
    }
  }

  void _sendMessage({String? imageUrl}) async {
    final message = _messageController.text.trim();
    if (message.isEmpty && imageUrl == null) return;

    _messageController.clear();

    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final name = userData['name'] ?? 'User';

    final messageData = {
      'senderId': currentUser!.uid,
      'senderName': name,
      'message': imageUrl != null ? '[Image]' : message,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': imageUrl != null ? 'image' : 'text',
    };

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.collection('messages').add(messageData);

    await groupRef.update({
      'lastMessage': messageData['message'],
      'lastSenderId': currentUser!.uid,
      'lastTime': FieldValue.serverTimestamp(),
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      try {
        final cloudinaryUrl = Uri.parse('https://api.cloudinary.com/v1_1/shivamsingh04/image/upload');
        final uploadPreset = 'flutter_demo';

        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await request.send();
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);

        if (response.statusCode != 200) {
          throw Exception(data['error']['message'] ?? 'Upload failed');
        }

        final imageUrl = data['secure_url'];
        _sendMessage(imageUrl: imageUrl);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;
                    final profileUrl = _userProfilePics[data['senderId']] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                              radius: 16,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.teal : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      data['senderName'] ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (data['type'] == 'image' && data['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                                      child: GestureDetector(
                                        onTap: () => _showFullImage(data['imageUrl']),
                                        child: Image.network(
                                          data['imageUrl'],
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (data['message'] != null && data['message'] != '[Image]')
                                    Text(
                                      data['message'],
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(data['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo, color: Colors.teal),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
