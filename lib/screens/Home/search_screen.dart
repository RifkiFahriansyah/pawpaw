import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:fasum/screens/Home/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = '';

  final List<String> categoryOrder = ['Cat', 'Dog', 'Bird', 'Hamster', 'Turtle', 'Rabbit', 'Others', ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Search by Location',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium!.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5F5B5B)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular((10),),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).searchBarTheme.backgroundColor?.resolve({}),
                        hintText: "Search",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allPosts = snapshot.data!.docs;

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userDocs = userSnapshot.data!.docs;
                    final userMap = {
                      for (var doc in userDocs)
                        (doc.data() as Map<String, dynamic>)['storeName']: doc,
                    };

                    final filteredPosts =
                        allPosts.where((post) {
                          final data = post.data() as Map<String, dynamic>;
                          final storeName = data['storeName'];
                          final userData =
                              userMap[storeName]?.data()
                                  as Map<String, dynamic>?;

                          if (userData == null) return false;

                          final locationName =
                              (userData['locationName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                          return searchQuery.isEmpty ||
                              locationName.contains(searchQuery);
                        }).toList();

                    if (filteredPosts.isEmpty) {
                      return const Center(
                        child: Text("No matching posts found."),
                      );
                    }

                    Map<String, List<QueryDocumentSnapshot>> categorized = {
                      for (var cat in categoryOrder) cat: [],
                    };

                    for (var post in filteredPosts) {
                      final data = post.data() as Map<String, dynamic>;
                      final cat =
                          (data['animalCategory'] ?? 'Others').toString();
                      final categoryKey =
                          categoryOrder.contains(cat) ? cat : 'Others';
                      categorized[categoryKey]!.add(post);
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children:
                          categoryOrder.expand((category) {
                            final posts = categorized[category]!;
                            if (posts.isEmpty) return <Widget>[];
                            return <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 5, bottom: 5),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColorDark,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.pets,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6,),
                                          Text(
                                            category,
                                            style: const TextStyle( fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),                                     
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 230,
                                child: GridView.builder(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    bottom: 13,
                                  ),
                                  itemCount: posts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1,
                                        childAspectRatio: 1.6,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final doc =
                                        posts[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final image = data['image'];
                                    final name = data['name'] ?? 'Unknown';
                                    final gender = data['gender'] ?? 'unknown';
                                    final storeName =
                                        data['storeName'] ?? 'Unknown';
                                    final createdAt =
                                        DateTime.tryParse(
                                          data['createdAt'] ?? '',
                                        ) ??
                                        DateTime.now();

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users').where('storeName',  isEqualTo: storeName,
                                          ).limit(1).get().then(
                                            (snapshot) =>
                                                snapshot.docs.isNotEmpty ? snapshot.docs.first.reference
                                                .get() : FirebaseFirestore.instance.doc('users/default')
                                                .get(),
                                          ),

                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                                        final updatedLat = userData?['location']?['lat'] ?? data['lat'] ?? .0;
                                        final updatedLng = userData?['location']?['lng'] ??  data['lng'] ?? 0.0;
                                        final updatedLocation = userData?['locationName'] ?? data['locationName'] ?? '';

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => DetailScreen(
                                                      userId: data['userId'],
                                                      postId: doc.id,
                                                      imageBase64: image,
                                                      description: data['description'] ?? '',
                                                      createdAt: createdAt,
                                                      storeName: storeName,
                                                      latitude: updatedLat,
                                                      longitude: updatedLng,
                                                      category: data['animalCategory'] ?? '',
                                                      heroTag: 'fasum-image-${createdAt.millisecondsSinceEpoch}',
                                                      name: data['name'] ?? 'Unknown',
                                                      price: double.tryParse( data['price'] ?.toString() ?? '',) ?? 0.0,
                                                      weight: double.tryParse( data['weight']?.toString() ??'', ) ?? 0.0,
                                                      breed: data['breed'] ?? 'Unknown',
                                                      colors: data['colors'] ?? 'Unknown',
                                                      gender: gender,
                                                      location: updatedLocation,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              color: Theme.of(context).primaryColorLight,
                                              boxShadow: [
                                                BoxShadow( color: Colors.grey, blurRadius: 1, offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Column(crossAxisAlignment:CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular((16),
                                                          ),
                                                      child:
                                                          image != null
                                                              ? Image.memory(base64Decode(image,
                                                                ),
                                                                width: double.infinity,
                                                                height: 130,  fit: BoxFit.cover,
                                                              )
                                                              : Container(
                                                                width: double .infinity, height: 130,
                                                                color: Colors.grey[300],
                                                                child: const Icon(Icons.pets,
                                                                    ),
                                                              ),
                                                    ),
                                                    Positioned(top: 10, right: 10,
                                                      child: Container(height: 35, width: 35,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.all(
                                                                Radius.circular(5),
                                                              ),
                                                          color: Colors.white,
                                                        ),
                                                        child: FavoriteButton(
                                              postId: doc.id,
                                              postData : data,
                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding( padding: const EdgeInsets.all( 8.0,
                                                  ),
                                                  child: Column(crossAxisAlignment: CrossAxisAlignment .start,
                                                    children: [
                                                      Row( mainAxisAlignment: MainAxisAlignment .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(name,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight .bold,
                                                                fontSize: 18,
                                                              ),
                                                              overflow: TextOverflow .ellipsis,
                                                            ),
                                                          ),
                                                          CircleAvatar(
                                                            radius: 16, backgroundColor:Color.fromRGBO(232, 239, 250, 1,),
                                                            child: Icon(
                                                              gender.toLowerCase() == 'male'
                                                                  ? Icons.male : gender.toLowerCase() == 'female'
                                                                  ? Icons.female : Icons.help_outline,
                                                              color:
                                                                  gender.toLowerCase() == 'male'
                                                                      ? Colors .blue
                                                                      : Colors.pink,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon( Icons.location_on, size: 16,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(updatedLocation,
                                                              style: const TextStyle( fontSize: 12,
                                                                  ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.store, size: 16,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded( child: Text(
                                                              storeName,
                                                              style: const TextStyle( fontSize: 12,
                                                                  ), overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ];
                          }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
