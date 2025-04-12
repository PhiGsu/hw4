import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hw4/main.dart';
import 'package:hw4/message_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, IconData> boardIcons = {
    'Business': Icons.business,
    'Games': Icons.videogame_asset,
    'Health': Icons.health_and_safety,
    'Study': Icons.school,
  };

  final Map<String, Color> boardColors = {
    'Business': Colors.greenAccent,
    'Games': Colors.blueAccent,
    'Health': Colors.redAccent,
    'Study': Colors.purpleAccent,
  };

  Stream<QuerySnapshot> getBoards() {
    return FirebaseFirestore.instance
        .collection('Boards')
        .orderBy('name')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageBoardAppBar(isLoggedIn: true),
      drawer: const MessageBoardAppDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: getBoards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No boards available.'));
          }

          final boards = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              double minTileHeight = constraints.maxHeight / boards.length;

              return ListView.builder(
                itemCount: boards.length,
                padding: EdgeInsets.only(bottom: 8),
                itemBuilder: (context, index) {
                  final board = boards[index];
                  return ListTile(
                    title: Text(board['name']),
                    tileColor: boardColors[board['name']],
                    leading: Icon(
                      boardIcons[board['name']] ?? Icons.question_mark,
                      size: minTileHeight * 0.4,
                    ),
                    minTileHeight: minTileHeight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MessageBoardScreen(boardId: board.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
