import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fasum/widgets/favorite_button.dart';

class YourFavoriteCardWidget extends StatelessWidget {
  final Map<String, dynamic> postData;
  final String postId;
  final VoidCallback? onTap;

  const YourFavoriteCardWidget
({
    super.key,
    required this.postData,
    required this.postId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = postData['image'];
    final name = postData['name'] ?? 'Unknown';
    final gender = postData['gender'] ?? 'Unknown';
    final location = postData['locationName'] ?? 'Unknown';
    final storeName = postData['storeName'] ?? 'Unknown';

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).primaryColorLight,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular((16)),
                  child: image != null
                      ? Image.memory(
                          base64Decode(image),
                          width: double.infinity,
                          height: 130,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 130,
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 50),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: FavoriteButton(
                      postId: postId,
                      postData: {
                        ...postData,
                        'postId': postId,
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color.fromRGBO(232, 239, 250, 1),
                        child: Icon(
                          gender.toLowerCase() == 'male'
                              ? Icons.male
                              : gender.toLowerCase() == 'female'
                                  ? Icons.female
                                  : Icons.help_outline,
                          color: gender.toLowerCase() == 'male'
                              ? Colors.blue
                              : gender.toLowerCase() == 'female'
                                  ? Colors.pink
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16,),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 12,),
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
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(fontSize: 12,),
                          overflow: TextOverflow.ellipsis,
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
  }
}
