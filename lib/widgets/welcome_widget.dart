import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({super.key});

  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'User';

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['storeName'] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Welcome...');
        }

        final name = snapshot.data ?? 'User';
        return Row(
          children: [
            Text('Welcome, $name 🦴'),
          ],
        );
      },
    );
  }
}
