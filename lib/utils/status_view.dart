import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatusViewerScreen extends StatefulWidget {
  final String userId;

  const StatusViewerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _startStatusTimer();
    _markAsViewed();
  }

  void _startStatusTimer() {
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context);
      }
    });
  }

  void _markAsViewed() async {
    if (widget.userId != currentUser!.uid) {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.userId)
          .update({
        'viewedBy': FieldValue.arrayUnion([currentUser!.uid]),
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Status not available",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final statusData = snapshot.data!.data() as Map<String, dynamic>;

          return GestureDetector(
            onTapDown: (_) => _progressController.stop(),
            onTapUp: (_) => _progressController.forward(),
            onTapCancel: () => _progressController.forward(),
            onLongPressStart: (_) => _progressController.stop(),
            onLongPressEnd: (_) => _progressController.forward(),
            child: Stack(
              children: [
                // Background Image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(statusData['photoUrl'] ?? ''),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Progress Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  ),
                ),

                // Header: User Info + Close
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          statusData['userPhotoUrl'] ?? 'https://via.placeholder.com/150',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusData['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatStatusTime(statusData['timestamp'] as Timestamp?),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Caption
                if (statusData['caption'] != null && statusData['caption'].toString().isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusData['caption'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                // Action buttons (for own status)
                if (widget.userId == currentUser!.uid)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility,
                          label: "Views",
                          onTap: () => _showViewsList(statusData['viewedBy'] ?? []),
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: "Delete",
                          onTap: _deleteStatus,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStatus() async {
    try {
      await FirebaseFirestore.instance.collection('stories').doc(currentUser!.uid).delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status deleted")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete status: $e")),
      );
    }
  }

  void _showViewsList(List viewedBy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Viewed By",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: viewedBy.length,
                  itemBuilder: (context, index) {
                    final viewerId = viewedBy[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(viewerId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final user = snapshot.data!.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              user['photoUrl'] ?? 'https://via.placeholder.com/150',
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'User',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            user['email'] ?? '',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatStatusTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
