import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:talkloop/pages/login_page.dart';
import 'package:talkloop/screens/chat_room_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  Stream<QuerySnapshot> getChatRooms() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUser!.uid)
        .orderBy('lastTime', descending: true)
        .snapshots();
  }

  Future<void> _handleLogout() async {
    final googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google Sign-Out Error: $e");
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) return '${dateTime.day}/${dateTime.month}';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No chats yet", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Start a conversation with your friends", style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onStartChat(),
            icon: const Icon(Icons.add),
            label: const Text("Start New Chat"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _onStartChat() async {
    final result = await showSearch(
      context: context,
      delegate: ChatSearchDelegate(currentUser!.uid),
    );
    if (result != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _onStartChat),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Logout')]),
              )
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chatDoc = chats[index];
                final chatRoomId = chatDoc.id;
                final users = List<String>.from(chatDoc['users']);
                final receiverId = users.firstWhere((u) => u != currentUser!.uid);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
                  builder: (ctx, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 72);
                    }
                    if (!userSnap.hasData || !userSnap.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final userData = userSnap.data!.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Stack(
                          children: [
                            CircleAvatar(radius: 28, backgroundImage: NetworkImage(userData['photoUrl'] ?? 'https://via.placeholder.com/150')),
                            if (userData['isOnline'] == true)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: CircleAvatar(radius: 6, backgroundColor: Colors.green)),
                              ),
                          ],
                        ),
                        title: Text(userData['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(chatDoc['lastMessage'] ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chatDoc['lastTime'] != null)
                              Text(_formatTime((chatDoc['lastTime'] as Timestamp).toDate()), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            const SizedBox(height: 4),
                            if ((chatDoc['unreadCount'] ?? 0) > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.all(Radius.circular(10))),
                                child: Text('${chatDoc['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(chatRoomId: chatRoomId, receiverId: receiverId, receiverEmail: userData['email'] ?? '')));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _onStartChat, backgroundColor: Colors.teal, child: const Icon(Icons.chat, color: Colors.white)),
    );
  }
}


class ChatSearchDelegate extends SearchDelegate<Widget?> {
  final String currentUserId;

  ChatSearchDelegate(this.currentUserId);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for friends to start chatting',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final name = doc['name']?.toLowerCase() ?? '';
          final email = doc['email']?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();

        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user['photoUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(user['name'] ?? 'User'),
                subtitle: Text(user['email'] ?? ''),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  final userId = user.id;
                  close(
                    context,
                    ChatRoomPage(
                      chatRoomId: 'TEMP_$userId',
                      receiverId: userId,
                      receiverEmail: user['email'] ?? '',
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}