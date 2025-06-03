import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/AddPost/edit_post_screen.dart';
import 'package:fasum/screens/Home/comment_screen.dart';
import 'package:fasum/screens/Home/full_image_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final String imageBase64;
  final String description;
  final DateTime createdAt;
  final String storeName;
  final double latitude;
  final double longitude;
  final String category;
  final String heroTag;
  final String name;
  final double price;
  final double weight;
  final String breed;
  final String colors;
  final String gender;
  final String location;
  final String postId;
  final String userId;

  const DetailScreen({
    super.key,
    required this.imageBase64,
    required this.description,
    required this.createdAt,
    required this.storeName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
    required this.name,
    required this.price,
    required this.weight,
    required this.breed,
    required this.colors,
    required this.gender,
    required this.location,
    required this.postId,
    required this.userId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? profileImageBase64;
  String? phoneNumber;
  bool isFavorite = false;
  bool isLoading = true;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late String name;
  late String description;
  late double price;
  late String imageBase64;
  late String category;
  late String location;
  late double latitude;
  late double longitude;
  late String gender;
  late String colors;
  late String breed;
  late double weight;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    description = widget.description;
    price = widget.price;
    imageBase64 = widget.imageBase64;
    category = widget.category;
    location = widget.location;
    latitude = widget.latitude;
    longitude = widget.longitude;
    gender = widget.gender;
    colors = widget.colors;
    breed = widget.breed;
    weight = widget.weight;
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchOwnerProfileImage(),
      checkFavoriteStatus(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> checkFavoriteStatus() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites').doc(widget.postId).get();
    setState(() {
      isFavorite = doc.exists;
    });
  }

  Future<void> _loadPostData() async {
    final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        name = data['name'];
        description = data['description'];
        price = data['price']?.toDouble() ?? 0;
        imageBase64 = data['imageBase64'];
        category = data['category'];
        location = data['location'];
        latitude = data['latitude']?.toDouble() ?? 0;
        longitude = data['longitude']?.toDouble() ?? 0;
        gender = data['gender'];
        colors = data['colors'];
        breed = data['breed'];
        weight = data['weight']?.toDouble() ?? 0;
      });
    }
  }

  Future<void> toggleFavorite() async {
    final favRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites').doc(widget.postId);
    if (isFavorite) {
      await favRef.delete();
      setState(() => isFavorite = false);
    } else {
      await favRef.set({
        'postId': widget.postId,
        'storeName': widget.storeName,
        'createdAt': DateTime.now().toIso8601String(),
      });
      setState(() => isFavorite = true);
    }
  }

  Future<void> fetchOwnerProfileImage() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('storeName', isEqualTo: widget.storeName).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          profileImageBase64 = userData['profileImage'];
          phoneNumber = userData['phoneNumber'];
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile image or phone number: $e');
    }
  }

  Future<void> openMap(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  void _openCommentScreen(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.8,maxChildSize: 0.95,minChildSize: 0.4,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: CommentScreen(
                  postId: widget.postId,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}


  bool _isBase64Image(String? data) {
    return data != null && (data.startsWith('/9j/') || data.startsWith('iVBOR'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: widget.heroTag,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageScreen(imageBase64: imageBase64),
                            ),
                          ),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            width: double.infinity,
                            height: 320,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, )),
                                Text('Rp ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                 Icon(Icons.pets, size: 16),
                                const SizedBox(width: 10),
                                Text(category,),
                              ],
                            ),
                            InkWell(
                              onTap: () => openMap(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16,),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(location, overflow: TextOverflow.ellipsis, maxLines: 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _infoCard(gender, 'Sex'),
                                _infoCard(colors, 'Color'),
                                _infoCard(breed, 'Breed'),
                                _infoCard('${weight.toString()} kg', 'Weight'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: profileImageBase64 != null && _isBase64Image(profileImageBase64)
                                      ? MemoryImage(base64Decode(profileImageBase64!))
                                      : const AssetImage('assets/placeholder_image.png') as ImageProvider,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Owner by:',),
                                    Text(widget.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(phoneNumber ?? 'No phone number available', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(description, ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12, left: 12, right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleButtonArrowBack(Icons.arrow_back, () => Navigator.pop(context)),
                      Row(
                        children: [
                          if (widget.userId == uid)
                          _circleButtonEdit(Icons.edit, widget.postId, context, _loadPostData),
                          _circleButtonComment(Icons.comment, () {_openCommentScreen(context);}),
                          _circleButtonFav(isFavorite ? Icons.favorite : Icons.favorite_border, toggleFavorite),
                          if (widget.userId == uid)
                          _circleButtonDel(Icons.delete, () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Post'),
      content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel',  )),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ),
  );

  if (confirm == true) {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        await doc.reference.collection('favorites').doc(widget.postId).delete().catchError((_) {});
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }
})


                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
  decoration:  BoxDecoration(
    color: Theme.of(context).shadowColor,
    boxShadow: [
      BoxShadow(      
        color: Theme.of(context).shadowColor, blurRadius: 70, spreadRadius: 70, blurStyle: BlurStyle.normal, offset: Offset(0, 20),
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColorDark,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: const Text(
      'ADOPT ME',
      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
    ),
  ),
),

    );
  }

  Widget _infoCard(String value, String label) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 0),
        color: Color.fromRGBO(254, 247, 244, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(value, style:  TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark), textAlign: TextAlign.center,),  
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _circleButtonFav(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.red),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _circleButtonEdit(IconData icon, String postId, BuildContext context, VoidCallback onUpdated) {
    return IconButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditPostScreen(postId: postId),
          ),
        );
        if (result == 'updated') {
          onUpdated();
        }
      },
      icon: Icon(icon, color: const Color.fromRGBO(249, 177, 166, 1)),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _circleButtonArrowBack(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _circleButtonComment(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color.fromRGBO(130, 115, 151, 1)),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _circleButtonDel(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.orange),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
