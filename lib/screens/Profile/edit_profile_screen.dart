import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../map_picker_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  LatLng? _location;
  String? _locationName;
  String? _district;
  String? _city;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final data =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final user = data.data();

    if (user != null && mounted) {
      _nameController.text = user['storeName'] ?? '';
      _phoneController.text = user['phoneNumber'] ?? '';
      if (user['location'] != null) {
        _location = LatLng(user['location']['lat'], user['location']['lng']);
        _locationName = user['locationName'];
        _district = user['district'];
        _city = user['city'];
      }
      if (user['profileImage'] != null) {
        _base64Image = user['profileImage'];
      }
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _compressAndEncodeImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_profileImage == null || !mounted) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _profileImage!.path,
        quality: 50,
      );

      if (compressedImage == null) return;
      if (!mounted) return;

      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final newStoreName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newLocation =
        _location != null
            ? {'lat': _location!.latitude, 'lng': _location!.longitude}
            : null;
    final newLocationName = _locationName;

    await userRef.update({
      if (_base64Image != null) 'profileImage': _base64Image,
      'storeName': newStoreName,
      'phoneNumber': newPhone,
      'location': newLocation,
      'locationName': newLocationName,
      'district': _district,
      'city': _city,
    });

    final postQuery =
        await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: uid)
            .get();

    for (final doc in postQuery.docs) {
      await doc.reference.update({'storeName': newStoreName});
    }

    final favQuery =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();

    for (final fav in favQuery.docs) {
      await fav.reference.update({'storeName': newStoreName});
    }


    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<Map<String, String>> _getPlaceDetailsFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return {
          'district': place.subAdministrativeArea ?? '', // Kecamatan
          'city': place.locality ?? '', // Kota/Kabupaten
        };
      }
    } catch (e) {
      // Error fallback
      print("Placemark error: $e");
    }

    return {'district': '', 'city': ''};
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    final placeDetails = await _getPlaceDetailsFromLatLng(latLng);

    if (!mounted) return;

    setState(() {
      _location = LatLng(position.latitude, position.longitude);
      _district = placeDetails['district'];
      _city = placeDetails['city'];
      _locationName = "${_district ?? ''}, ${_city ?? ''}";
    });
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: _location),
      ),
    );

    if (!mounted) return;
    
    if (result != null && result is LatLng) {
      final name = await _getPlaceDetailsFromLatLng(result);
      if (!mounted) return;
      setState(() {
        _location = result;
        _city = name['city'];
        _district = name['district'];
        _locationName = "${name['district']}, ${name['city']}";
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset( Theme.of(context).brightness == Brightness.dark
        ? 'assets/profile_dark.png'
        : 'assets/profile_light.png', fit: BoxFit.cover),
          ), 
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          radius: 60,
                          backgroundImage:
                              _base64Image != null
                                  ? MemoryImage(base64Decode(_base64Image!))
                                  : const AssetImage(
                                        'assets/placeholder_image.png',
                                      )
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColorDark,
                            child: IconButton(
                              icon: const Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                              ),
                              onPressed: _showImageSourceDialog,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextFields(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColorDark
                            ),
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.gps_fixed, color: Colors.white,),
                            label: const Text("Lokasi saat ini", style: TextStyle(color: Colors.white),),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColorDark
                            ),
                            onPressed: _pickFromMap,
                            icon: const Icon(Icons.map, color: Colors.white,),
                            label: const Text("Pilih dari Peta", style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                      onPressed: _saveChanges,
                      child: const Text('SAVE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        Card(
          color: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(Icons.person, ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          color: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(Icons.phone,),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          color: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_locationName != null)
                            Text(
                              '$_locationName', style: TextStyle(
                                fontSize: 15),
                              ),     
                        ],
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
