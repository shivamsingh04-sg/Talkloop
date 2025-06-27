import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final Set<String> _selectedMembers = {};
  final _currentUser = FirebaseAuth.instance.currentUser;

  File? _groupImage;
  bool _isLoading = false;

  bool get _canCreateGroup =>
      _groupNameController.text.trim().isNotEmpty && _selectedMembers.isNotEmpty;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_canCreateGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a group name and select members")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_groupImage != null) {
        final ref = FirebaseStorage.instance
            .ref('group_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await ref.putFile(_groupImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final groupRef = FirebaseFirestore.instance.collection('groups').doc();
      final memberIds = [_currentUser!.uid, ..._selectedMembers];

      await groupRef.set({
        'groupName': _groupNameController.text.trim(),
        'groupDescription': _groupDescriptionController.text.trim(),
        'groupImage': imageUrl,
        'members': memberIds,
        'adminId': _currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created',
        'lastSenderId': _currentUser!.uid,
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      await groupRef.collection('messages').add({
        'senderId': _currentUser!.uid,
        'senderName': _currentUser!.displayName ?? 'User',
        'message': '${_currentUser!.displayName ?? 'User'} created this group',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group created successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickGroupImage,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.teal.shade100,
              backgroundImage: _groupImage != null ? FileImage(_groupImage!) : null,
              child: _groupImage == null
                  ? Icon(Icons.camera_alt, size: 30, color: Colors.teal.shade700)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    hintText: "Group name",
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _groupDescriptionController,
                  decoration: const InputDecoration(
                    hintText: "Description (optional)",
                    border: UnderlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMembers() {
    if (_selectedMembers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _selectedMembers.map((id) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(id).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data!.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            data['photoUrl'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMembers.remove(id)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        data['name'] ?? 'User',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            final uid = user.id;
            final data = user.data() as Map<String, dynamic>;
            final isSelected = _selectedMembers.contains(uid);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  data['photoUrl'] ?? 'https://via.placeholder.com/150',
                ),
              ),
              title: Text(data['name'] ?? 'User'),
              subtitle: Text(data['email'] ?? ''),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (_) {
                  setState(() {
                    isSelected ? _selectedMembers.remove(uid) : _selectedMembers.add(uid);
                  });
                },
                activeColor: Colors.teal,
              ),
              onTap: () {
                setState(() {
                  isSelected ? _selectedMembers.remove(uid) : _selectedMembers.add(uid);
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: _canCreateGroup ? _createGroup : null,
            child: Text(
              "CREATE",
              style: TextStyle(
                color: _canCreateGroup ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildGroupInfo(),
          _buildSelectedMembers(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "Add members",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  "${_selectedMembers.length} selected",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }
}
