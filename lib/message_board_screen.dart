import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hw4/main.dart';

class MessageBoardScreen extends StatefulWidget {
  const MessageBoardScreen({super.key, required this.boardId});

  final String boardId;

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  Stream<QuerySnapshot> getMessages() {
    return FirebaseFirestore.instance
        .collection('Messages')
        .where('boardId', isEqualTo: widget.boardId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageBoardAppBar(),
      drawer: const MessageBoardAppDrawer(),
      body: const Center(child: Text('No messages here.')),
    );
  }
}
