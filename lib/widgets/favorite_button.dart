import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteButton extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const FavoriteButton({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(postId)
          .snapshots(),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data?.exists ?? false;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: Colors.red,
          ),
          onPressed: () async {
            final favRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('favorites')
                .doc(postId);

            if (isFavorite) {
              await favRef.delete();
            } else {
              await favRef.set({
                ...postData,
                'postId': postId,
                'postOwnerId': postData['userId'],
                'createdAt': DateTime.now().toIso8601String(),
              });
            }
          },
        );
      },
    );
  }
}
