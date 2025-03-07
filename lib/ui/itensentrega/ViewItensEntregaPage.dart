import 'package:flutter/material.dart';
import 'package:app/models/ItensEntrega.dart';

class ViewItensEntregaPage extends StatelessWidget {
  final ItensEntrega item;

  const ViewItensEntregaPage({super.key, required this.item});

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
            const Text(
              'Item Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('ID: ${item.id ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Name: ${item.item ?? 'No Name'}'),
            const SizedBox(height: 8),
            Text('Notes: ${item.obs ?? 'No Notes'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
