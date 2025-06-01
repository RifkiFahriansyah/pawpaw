import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/main.dart';
import 'package:fasum/screens/Auth/sign_in_screen.dart';
import 'package:fasum/screens/map_picker_screen.dart';
import 'package:fasum/screens/theme/theme_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  LatLng? _selectedLocation;
  String? _locationName;
  String? _district;
  String? _city;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.loose,
        children: [ 
          Positioned.fill(
            child: Image.asset( Theme.of(context).brightness == Brightness.dark
        ? 'assets/sign_up_dark.png'
        : 'assets/sign_up_light.png', fit: BoxFit.cover),
          ),
          Positioned(top: 25, right: 5,
            child: Consumer<ThemeProvider>(
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
          ),
          Center(
          child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 190, 16.0, 16.0),
            child: SingleChildScrollView(
              child: Form(key: _formKey,
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(onTap: _showImageSourceDialog,
                      child: Container(decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Theme.of(context).primaryColorLight,
                  border: Border.all(color: Theme.of(context).canvasColor,
                  width: 2.0,          
                  ),
                ),
                        child: CircleAvatar(radius: 40, backgroundColor: Theme.of(context).primaryColorLight,
                          child:
                              _profileImage != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(60),
                                    child: Image.file(_profileImage!, height: 250,
                                      width: double.infinity, fit: BoxFit.cover,
                                    ),
                                  )  : Center(
                                    child: Icon(Icons.add_a_photo, size: 30,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),  
                        ),
                      child: TextFormField(
                        controller: _storeNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color:Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Store Name', 
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),
                            prefixIcon: Icon(Icons.store),
                          ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your store name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),  
                        ),
                      child: TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color:Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Phone Number', 
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),  
                        ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color:Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Email', 
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),
                            prefixIcon: Icon(Icons.email),
                          ),
                        validator: (value) {
                          if (value == null || value.isEmpty || !_isValidEmail(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),  
                        ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color:Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Password', 
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ), 
                            prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),  
                        ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color:Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Confirm Password', 
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),
                            prefixIcon: Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          ), obscureText: !_isConfirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(style: ElevatedButton.styleFrom(
                             backgroundColor: Theme.of(context).primaryColorDark
                            ),
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.gps_fixed, color: Colors.white,),
                            label: const Text("Lokasi Saat Ini", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColorDark
                            ),
                            onPressed: _pickLocationFromMap, icon: const Icon(Icons.map, color: Colors.white,),
                            label: const Text("Pilih dari Peta", style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ),
                      ],
                    ),
                    if (_locationName != null)
                      Container(decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorDark,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(padding: const EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white,),
                              Text(
                                '$_locationName', style: const TextStyle(color: Colors.white,)
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10.0),
                    _isLoading ? const CircularProgressIndicator() : ElevatedButton(style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorDark,
                      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                      onPressed: _signUp, child: const Text('SIGN UP', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    const SizedBox(height: 16.0),
                    RichText(text: TextSpan(style: const TextStyle(fontSize: 16.0, color: Color.fromRGBO(153, 131, 131, 1),
                        ),
                          children: [ const TextSpan(text: "Sudah Punya Akun? "),
                            TextSpan(text: "Masuk", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                    ..onTap = () { Navigator.push( context, MaterialPageRoute(
                                          builder: (context) => const SignInScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      _showErrorMessage("Silakan pilih lokasi terlebih dahulu.");
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            if (_base64Image != null) 'profileImage': _base64Image,
            'storeName': _storeNameController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'email': email,
            'createdAt': Timestamp.now(),
            'location': _selectedLocation != null ? {
                      'lat': _selectedLocation!.latitude,
                      'lng': _selectedLocation!.longitude,
                    } : null,
            'locationName': _locationName,
            'district': _district,
            'city': _city,
          });
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainScreen()), (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showErrorMessage(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showErrorMessage('An error occurred: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of( context, ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    String emailRegex = r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zAZ0-9-]+)*$";
    return RegExp(emailRegex).hasMatch(email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    final placeDetails = await _getPlaceDetailsFromLatLng(latLng);
    setState(() {
      _selectedLocation = latLng;
      _district = placeDetails['district'];
      _city = placeDetails['city'];
      _locationName = "${_district ?? ''}, ${_city ?? ''}";
    });
  }

  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push( context, MaterialPageRoute(builder:
            (context) => MapPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null && result is LatLng) {
      final name = await _getPlaceDetailsFromLatLng(result);
      setState(() {
        _selectedLocation = result;
        _locationName = "${name['district']}, ${name['city']}";
        _district = name['district'];
        _city = name['city'];
      });
    }
  }

  Future<Map<String, String>> _getPlaceDetailsFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude, latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return {
          'district': place.subAdministrativeArea ?? '', 
          'city': place.locality ?? '', 
        };
      }
    } catch (e) {
      print("Placemark error: $e");
    }
    return {'district': '', 'city': ''};
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
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
    if (_profileImage == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _profileImage!.path,
        quality: 50,
      );

      if (compressedImage == null) return;

      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context, ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
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
}
