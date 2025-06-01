import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/Home/detail_screen.dart';
import 'package:fasum/screens/Home/search_screen.dart';
import 'package:fasum/screens/theme/theme_provider.dart';
import 'package:fasum/widgets/favorite_button.dart';
import 'package:fasum/widgets/welcome_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;

   final List<Map<String, dynamic>> categories = [
    {'label': 'Cat', 'logo': '🐱', 'iconBg': Colors.pink[200]},
    {'label': 'Dog', 'logo': '🐶',  'iconBg': Colors.blue[200]},
    {'label': 'Bird', 'logo': '🦜', 'iconBg': Colors.yellow},
    {'label': 'Hamster', 'logo': '🐹', 'iconBg': Colors.orange[200]},
    {'label': 'Turtle', 'logo': '🐢', 'iconBg': Colors.green[200]},
    {'label': 'Rabbit', 'logo': '🐰', 'iconBg': Colors.purple[200]},
    {'label': 'Others', 'logo': '🐾',  'iconBg': Colors.brown[200]},
  ];

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else if (diff.inHours < 48) {
      return '1 day ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 45,
        backgroundColor: Colors.transparent,
        title: const WelcomeWidget(),
        actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                  final isDark = themeProvider.isDarkMode;
                    return IconButton(
                        icon: Icon(
                          isDark ? Icons.dark_mode : Icons.wb_sunny_outlined,
                          color: isDark ? const Color.fromRGBO(122, 68, 76, 1) : Colors.amber,
                        ),  
                        onPressed: () {
                        themeProvider.toggleTheme();
                        },
                    );  
              },
            ),
],
      ),
      body: SingleChildScrollView(
        child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: SizedBox(height: 48, width: double.infinity,
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular((10)),
                        child: Container(
                          height: double.infinity, alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).searchBarTheme.backgroundColor?.resolve({}),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Text("Search", style: TextStyle( fontSize: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12,
                          ),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColorDark,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset( Theme.of(context).brightness == Brightness.dark
        ? 'assets/iklan_dark.jpeg'
        : 'assets/iklan_light.jpeg', 
        fit: BoxFit.cover,
        ),

              ),
            ),
            Padding(padding: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
              child: Row(
                children: [
                  Text('Pet Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category['label'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 12,backgroundColor: category['iconBg'],
                            child: Text(category['logo'])
                          ),
                          const SizedBox(width: 6),
                          Text(category['label'],style: TextStyle(color: isSelected ?
                           Colors.white : Colors.black87,fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = selected ? category['label'] : null;
                        });
                      },
                      backgroundColor: Colors.white,selectedColor: Theme.of(context).primaryColorDark, shape: StadiumBorder(),
                      elevation: 0, pressElevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Adopt Pets', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: Text('See All', style: TextStyle( fontSize: 12, 
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: () async { setState(() {}); },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final category = data['animalCategory'] ?? 'Others';
                        return (selectedCategory == null || selectedCategory == category);
                      }).toList();

                  if (posts.isEmpty) {
                    return const Center(child: Text("No posts found for this filter."),
                    );
                  }

                  return SizedBox(height: 260,
                    child: GridView.builder(
                      padding: const EdgeInsets.only( left: 10, right: 10, bottom: 10, ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1, crossAxisSpacing: 12, mainAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                      scrollDirection: Axis.horizontal,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final doc = posts[index];
                        final data = posts[index].data();
                        final image = data['image'];
                        final name = data['name'] ?? 'Unknown';
                        final gender = data['gender'] ?? 'unknown';
                        final storeName = data['storeName'] ?? 'Unknown';
                        final createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users').where('storeName', isEqualTo: storeName)
                              .limit(1).get().then((snapshot) {
                                if (snapshot.docs.isNotEmpty) {
                                  return snapshot.docs.first;
                                } else {
                                  return FirebaseFirestore.instance.doc('users/unknown').get();
                                }
                              }),

                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(),
                              );
                            }

                            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                            final updatedLat = userData?['location']?['lat'] ?? data['lat'] ?? 0.0;
                            final updatedLng = userData?['location']?['lng'] ?? data['lng'] ?? 0.0;
                            final updatedLocation = userData?['locationName'] ?? data['locationName'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                    builder:
                                        (_) => DetailScreen(
                                          userId: data['userId'] ?? '',
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
                                          price: double.tryParse( data['price']?.toString() ?? '', ) ?? 0.0,
                                          weight: double.tryParse( data['weight']?.toString() ?? '', ) ?? 0.0,
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
                                  borderRadius: BorderRadius.circular(16), color: Theme.of(context).primaryColorLight,
                                  boxShadow: [
                                    BoxShadow(color: Colors.grey, blurRadius: 1, offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: image != null ? Image.memory(base64Decode(image),
                                                    width: double.infinity, height: 150, fit: BoxFit.cover,
                                                  ) : Container(width: double.infinity, height: 150,  color: Colors.grey[300],
                                                    child: const Icon(Icons.pets,),
                                                  ),
                                        ),
                                        Positioned(top: 10, right: 10,
                                          child: Container( height: 35, width: 35,
                                            decoration: BoxDecoration(
                                              borderRadius:  const BorderRadius.all(Radius.circular(5), ),
                                              color: Colors.white,
                                            ),
                                            child: FavoriteButton(postId: doc.id, postData : data,
                                            ),     
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(padding: const EdgeInsets.all(8.0),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text( name, style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 18,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              CircleAvatar(radius: 16, backgroundColor:const Color.fromRGBO(232, 239, 250, 1,),
                                                child: Icon(
                                                  gender.toLowerCase() == 'male' ? Icons.male : gender.toLowerCase() == 'female' ? Icons.female : Icons.help_outline,
                                                  color: gender.toLowerCase() == 'male'  ? Colors.blue : Colors.pink,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text('$updatedLocation',
                                                  style: TextStyle(fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.store, size: 16,),
                                              const SizedBox(width: 4),
                                              Text(storeName, style: TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
