import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:talkloop/utils/status_upload.dart';
import 'package:talkloop/utils/status_view.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> getStatuses() {
    return FirebaseFirestore.instance
        .collection('stories')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Add status settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // My Status Section
          _buildMyStatusSection(),

          // Divider
          Container(
            height: 8,
            color: Colors.grey[100],
          ),

          // Recent Updates Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "Recent updates",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Friends' Status List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getStatuses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allStatuses = snapshot.data!.docs;
                final friendsStatuses = allStatuses
                    .where((doc) => doc.id != currentUser!.uid)
                    .toList();

                if (friendsStatuses.isEmpty) {
                  return _buildEmptyFriendsStatus();
                }

                return ListView.builder(
                  itemCount: friendsStatuses.length,
                  itemBuilder: (context, index) {
                    final statusDoc = friendsStatuses[index];
                    final statusData = statusDoc.data() as Map<String, dynamic>;

                    return _buildStatusItem(
                      userId: statusDoc.id,
                      userName: statusData['name'] ?? 'Unknown',
                      userPhoto: statusData['photoUrl'] ?? 'https://via.placeholder.com/150',
                      timestamp: statusData['timestamp'] as Timestamp?,
                      isViewed: false, // TODO: Implement view tracking
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatusUploadScreen()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildMyStatusSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final hasStatus = snapshot.hasData && snapshot.data!.exists;
        final statusData = hasStatus
            ? snapshot.data!.data() as Map<String, dynamic>
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (hasStatus) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewerScreen(userId: currentUser!.uid),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatusUploadScreen()),
                    );
                  }
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: hasStatus && statusData!['photoUrl'] != null
                          ? NetworkImage(statusData['photoUrl'])
                          : NetworkImage(currentUser!.photoURL ?? 'https://via.placeholder.com/150'),
                    ),
                    if (!hasStatus)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStatus ? "My status" : "My status",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasStatus
                          ? _formatStatusTime(statusData!['timestamp'] as Timestamp?)
                          : "Tap to add status update",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatusUploadScreen()),
                  );
                },
                icon: Icon(
                  hasStatus ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem({
    required String userId,
    required String userName,
    required String userPhoto,
    required Timestamp? timestamp,
    required bool isViewed,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isViewed ? Colors.grey[400]! : Colors.teal,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage(userPhoto),
        ),
      ),
      title: Text(
        userName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatStatusTime(timestamp),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusViewerScreen(userId: userId),
          ),
        );
      },
    );
  }

  Widget _buildEmptyFriendsStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No recent updates",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When your friends share status updates,\nthey'll appear here",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final statusTime = timestamp.toDate();
    final difference = now.difference(statusTime);

    if (difference.inDays > 0) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}