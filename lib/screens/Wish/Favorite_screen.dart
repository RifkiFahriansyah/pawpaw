import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/Home/detail_screen.dart';
import 'package:fasum/widgets/your_favorite_card_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> _fetchPostWithUserLocation(
      String postId, String storeName) async {
    try {
      final postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!postSnap.exists) return null;

      final postData = postSnap.data()!;
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('storeName', isEqualTo: storeName)
          .limit(1)
          .get();

      final userData = userSnap.docs.isNotEmpty ? userSnap.docs.first.data() : null;

      return {
        ...postData,
        'locationName': userData?['locationName'] ?? '',
        'location': userData?['location'] ?? {'lat': 0.0, 'lng': 0.0},
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.loose,
        children: [
          Positioned.fill(
              child: Image.asset( Theme.of(context).brightness == Brightness.dark
          ? 'assets/add_edit_post_screen_dark.png'
          : 'assets/add_edit_post_screen_light.png', fit: BoxFit.cover),
            ),
            Column(
              children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(15, 25, 0, 5),
                child: Row(
          children: [
            Text('Your Favorite Pet ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            Icon(Icons.favorite, color: Colors.red, size: 24),
          ],
        ),
              ),
           StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('favorites')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
        
            final favDocs = snapshot.data!.docs;
        
            if (favDocs.isEmpty) {
              return const Center(child: Text("No favorites yet."));
            }
        
            return Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                itemCount: favDocs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final favDoc = favDocs[index];
                  final postId = favDoc['postId'];
                  final storeName = favDoc['storeName'];
                  final createdAt = DateTime.tryParse(favDoc['createdAt'] ?? '') ?? DateTime.now();
                      
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchPostWithUserLocation(postId, storeName),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final postData = snapshot.data;
                      if (postData == null) {
                        return const SizedBox(); // Post has been deleted
                      }
                      
                      return YourFavoriteCardWidget(
                        postData: postData,
                        postId: postId,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                userId: postData['userId'],
                                postId: postId,
                                imageBase64: postData['image'],
                                description: postData['description'] ?? '',
                                createdAt: createdAt,
                                storeName: storeName,
                                latitude: postData['location']?['lat'] ?? 0.0,
                                longitude: postData['location']?['lng'] ?? 0.0,
                                category: postData['animalCategory'] ?? '',
                                heroTag: 'fasum-image-$postId',
                                name: postData['name'] ?? '',
                                price: double.tryParse(postData['price']?.toString() ?? '') ?? 0.0,
                                weight: double.tryParse(postData['weight']?.toString() ?? '') ?? 0.0,
                                breed: postData['breed'] ?? '',
                                colors: postData['colors'] ?? '',
                                gender: postData['gender'] ?? '',
                                location: postData['locationName'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
              ]
            ), 
        ],
      ),
    );
  }
}
