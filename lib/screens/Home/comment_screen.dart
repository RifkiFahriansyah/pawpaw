import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? currentUserData;
  String? replyToCommentId;
  String? replyingToName;
  String? replyingToText;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      setState(() {
        currentUserData = snapshot.data();
      });
    }
  }

  void _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || currentUserData == null) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'uid': uid,
          'storeName': currentUserData!['storeName'] ?? '',
          'profileImage': currentUserData!['profileImage'] ?? '',
          'text': text,
          'createdAt': Timestamp.now(),
          'parentId': replyToCommentId,
          'likes': <String>[],
        });

    _controller.clear();
    setState(() {
      replyToCommentId = null;
    });
  }

  bool _isBase64Image(String? data) {
    return data != null &&
        (data.startsWith('/9j/') || data.startsWith('iVBOR'));
  }

  void _toggleLike(String commentId, List likes) async {
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    if (likes.contains(uid)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  void _deleteComment(String commentId) async {
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    await ref.delete();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container( 
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        color:Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!.docs;
        
                  List<DocumentSnapshot> topLevelComments =
                      comments.where((doc) => doc['parentId'] == null).toList();
                  Map<String, List<DocumentSnapshot>> replies = {};
        
                  for (var comment in comments) {
                    final parentId = comment['parentId'];
                    if (parentId != null) {
                      replies[parentId] = [...(replies[parentId] ?? []), comment];
                    }
                  }
        
                  Widget buildComment(DocumentSnapshot doc, {int indent = 1, double  profile = 1.0}) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['storeName'] ?? 'Unknown';
                    final text = data['text'] ?? '';
                    final profileImage = data['profileImage'] ?? '';
                    final isMine = data['uid'] == uid;
                    final commentId = doc.id;
                    final likeList = List<String>.from(data['likes'] ?? []);
        
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10.0 * indent,
                            right: 10,
                            bottom: 8,
                          ),
        
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20 * profile,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    _isBase64Image(profileImage)
                                        ? MemoryImage(base64Decode(profileImage))
                                        : const AssetImage(
                                              'assets/placeholder_image.png',
                                            )
                                            as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(text),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            likeList.contains(uid)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.pink,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _toggleLike(
                                                commentId,
                                                likeList,
                                              ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text('${likeList.length}'),
                                        if (isMine)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => _deleteComment(commentId),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.reply, size: 20, color: Theme.of(context).primaryColorDark,),
                                          onPressed: () {
                                            setState(() {
                                              replyToCommentId = commentId;
                                              replyingToName = name;
                                              replyingToText = text;
                                            });
                                          },
                                        
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ),
                        if (replies.containsKey(commentId))
                          ...replies[commentId]!
                              .map(
                                (replyDoc) =>
                                    buildComment(replyDoc, indent: indent + 4, profile: 0.8),
                              )    
                      ],
                    );
                  }
        
                  return ListView(
                    controller: widget.scrollController,
                    children:
                        topLevelComments.map((doc) => buildComment(doc)).toList(),
                  );
                },
              ),
            ),
            if (replyToCommentId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).primaryColorDark),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to $replyingToName',
                              style: const TextStyle(
                                color: Colors.white,        
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              replyingToText ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.white,),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.white,),
                        onPressed: () {
                          setState(() {
                            replyToCommentId = null;
                            replyingToName = null;
                            replyingToText = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText:
                              replyToCommentId != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).primaryColorDark, width: 3),
                            ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).primaryColorDark),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
