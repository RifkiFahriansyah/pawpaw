import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/Auth/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data();
  }

  bool _isBase64Image(String? data) {
    return data != null &&
        (data.startsWith('/9j/') || data.startsWith('iVBOR'));
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false,
    );
  }

  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          fit: StackFit.loose,
           children: [
            Positioned.fill(
              child: Image.asset( Theme.of(context).brightness == Brightness.dark
          ? 'assets/profile_dark.png'
          : 'assets/profile_light.png', fit: BoxFit.cover),
            ),       
            SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).canvasColor,
                    child: IconButton(
                      iconSize: 24,
                      icon: const Icon(Icons.logout,),
                      onPressed: signOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return Container(
                padding: const EdgeInsets.only(top: 24, left: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 80),           
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _isBase64Image(data['profileImage'])
                                ? MemoryImage(base64Decode(data['profileImage']))
                                : const AssetImage('assets/placeholder_image.png')
                                    as ImageProvider,
                      ),
                    
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child:
                        Column(
                          children: [
                        _profileTile(Icons.person, 'Name', data['storeName']),
                        _profileTile(Icons.phone, 'Phone', data['phoneNumber']),
                        _profileTile(Icons.email, 'Email', data['email']),
                        _profileTile(Icons.location_on, 'Location', data['locationName'] ?? 'Belum dipilih',),
                  ],),
                    ),
                    
              
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),      
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/edit_profile');
                          setState(() {
                            _userDataFuture = _getUserData();
                          });
                        },
                        child: const Text('EDIT', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
           ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String value) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold,)),
        subtitle: Text(value,
      ),
      ),
    );
  }
}
