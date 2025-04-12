import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hw4/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late final String userId;
  DateTime _registrationDate = DateTime.now();
  String _role = 'User';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _firstNameController.text = data['firstName'];
        _lastNameController.text = data['lastName'];
        _role = data['role'];
        _registrationDate = data['registeredAt'].toDate();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await Future.wait([
        FirebaseFirestore.instance.collection('Users').doc(userId).update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'role': _role,
        }),
        updateUserMessages(
            '${_firstNameController.text} ${_lastNameController.text}'),
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Future<void> updateUserMessages(String newName) async {
    final messagesRef = FirebaseFirestore.instance.collection('Messages');
    final userMessages =
        await messagesRef.where('userId', isEqualTo: userId).get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in userMessages.docs) {
      batch.update(doc.reference, {'username': newName});
    }

    await batch.commit();
  }

  String? _nameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageBoardAppBar(isLoggedIn: true),
      drawer: const MessageBoardAppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: _nameValidator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: _nameValidator,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['User', 'Moderator', 'Admin']
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (newRole) =>
                    setState(() => _role = newRole ?? _role),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
              const SizedBox(height: 8),
              Text(
                'Registered on: ${_registrationDate.toIso8601String().split('T')[0]}',
              )
            ],
          ),
        ),
      ),
    );
  }
}
