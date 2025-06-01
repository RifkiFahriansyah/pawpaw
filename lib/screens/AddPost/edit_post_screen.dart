import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorsController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _image;
  String? _base64Image;
  bool _isUploading = false;
  String? _selectedGender;
  String? _animalCategory;

  List<String> animalCategories = ['Cat', 'Dog', 'Bird', 'Hamster', 'Turtle', 'Rabbit', 'Others'];

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _breedController.text = data['breed'] ?? '';
        _colorsController.text = data['colors'] ?? '';
        _weightController.text = data['weight']?? '';
        _priceController.text = data['price']?? '';
        _selectedGender = data['gender'];
        _animalCategory = data['animalCategory'];
        _base64Image = data['image'];
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load post: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        await _compressAndEncodeImage();
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 50,
    );
    if (compressedImage != null) {
      _base64Image = base64Encode(compressedImage);
    }
  }

  Future<void> _updatePost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add an image and description.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'image': _base64Image,
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'animalCategory': _animalCategory,
        'breed': _breedController.text.trim(),
        'colors': _colorsController.text.trim(),
        'weight': _weightController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MainScreen()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post updated successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a picture'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _colorsController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _image != null
        ? Image.file(_image!, fit: BoxFit.cover)
        : (_base64Image != null
            ? Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover)
            : Icon(Icons.add_a_photo, size: 50, color: Colors.grey));

    return Scaffold(
      body: Stack(
        fit: StackFit.loose,
        children:[ 
          Positioned.fill(
            child: Image.asset( Theme.of(context).brightness == Brightness.dark
        ? 'assets/add_edit_post_screen_dark.png'
        : 'assets/add_edit_post_screen_light.png', fit: BoxFit.cover),
          ),  
          SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                child: const Text("Edit Your Pet 🐾", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), ),
              ),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    border: Border.all(
                    color: Theme.of(context).canvasColor,
                    width: 2.0,          
                  ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Your Pet\'s Name',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                           
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).primaryColorLight,
                value: _selectedGender != null && ['Male', 'Female'].contains(_selectedGender) ? _selectedGender : null,
                items: ['Male', 'Female'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Gender',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                          
                          ),
                            ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).primaryColorLight,
                value: _animalCategory != null && animalCategories.contains(_animalCategory) ? _animalCategory : null,
                items: animalCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _animalCategory = value),
                decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Animal Category',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                          
                          ),
                            ),
              ), 
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _breedController,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Animal Breed',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                          
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _colorsController,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Animal Colors',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                        
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Weight (kg)',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                          
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Price (Rp. )',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                         
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            labelText: 'Description',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).canvasColor,),
                            ),                         
                          ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _updatePost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Theme.of(context).primaryColorDark,
                  ),
                  child: _isUploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        ]
      ),
    );
  }
}
