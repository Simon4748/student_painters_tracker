import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_store.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<Uint8List> _imageBytesList = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPostImages() async {
    final files = await _imagePicker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    final bytesList = <Uint8List>[];
    for (final file in files) {
      bytesList.add(await file.readAsBytes());
    }

    if (!mounted) return;

    setState(() {
      _imageBytesList.addAll(bytesList);
    });
  }

  void _removeImageAt(int index) {
    setState(() {
      _imageBytesList.removeAt(index);
    });
  }

  void _submitPost() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) return;

    final item = FeedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: FeedItemType.post,
      authorId: 'manager_1',
      authorName: 'Simon',
      authorRole: 'Branch Manager',
      branchId: 'brattleboro_branch',
      branchName: 'Brattleboro Branch',
      divisionName: 'New England',
      createdAt: DateTime.now(),
      title: title,
      description: description,
      imageBytesList: List<Uint8List>.from(_imageBytesList),
    );

    FeedStore.items.insert(0, item);

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Photos (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _pickPostImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Add Photos'),
              ),
            ),
            const SizedBox(height: 12),
            if (_imageBytesList.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageBytesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytesList[index],
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => _removeImageAt(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPost,
                child: const Text('Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}