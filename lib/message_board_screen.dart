import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hw4/main.dart';

class MessageBoardScreen extends StatefulWidget {
  const MessageBoardScreen({super.key, required this.boardId});

  final String boardId;

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  late final TextEditingController _messageController;
  String boardName = '';
  String userDisplayName = 'Anonymous';
  late String userId;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _fetchBoardName();
    _fetchUserDisplayName();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBoardName() async {
    var board = await FirebaseFirestore.instance
        .collection('Boards')
        .doc(widget.boardId)
        .get();
    if (board.exists) {
      setState(() {
        boardName = board['name'];
      });
    }
  }

  Future<void> _fetchUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final firstName = userDoc['firstName'];
        final lastName = userDoc['lastName'];
        userDisplayName = '$firstName $lastName';
      }
    }
  }

  Stream<QuerySnapshot> getMessages() {
    return FirebaseFirestore.instance
        .collection('Messages')
        .where('boardId', isEqualTo: widget.boardId)
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_messageController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('Messages').add({
        'message': _messageController.text,
        'boardId': widget.boardId,
        'userId': user.uid,
        'username': userDisplayName,
        'timestamp': Timestamp.now(),
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MessageBoardAppBar(isLoggedIn: true, title: boardName),
      drawer: const MessageBoardAppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message['message']),
                      subtitle: Text(message['username']),
                      trailing: Text(
                        message['timestamp']
                            .toDate()
                            .toLocal()
                            .toString()
                            .split('.')[0],
                      ),
                      tileColor: message['userId'] == userId
                          ? Colors.blue[100]
                          : Colors.grey[200],
                    );
                  },
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
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
