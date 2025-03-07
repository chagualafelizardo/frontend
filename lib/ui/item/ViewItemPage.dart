import 'package:flutter/material.dart';
import 'package:app/models/Item.dart';

class ViewItemPage extends StatelessWidget {
  final Item item;

  const ViewItemPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Item Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item.id}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Name: ${item.item ?? 'No name'}',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Notes: ${item.obs ?? 'No notes'}',
                style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
