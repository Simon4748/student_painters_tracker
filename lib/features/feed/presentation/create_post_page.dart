import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      imagePaths: const [],
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
      body: Padding(
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