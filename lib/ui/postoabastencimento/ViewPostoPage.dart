import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';

class ViewPostoPage extends StatelessWidget {
  final Posto posto;

  const ViewPostoPage({super.key, required this.posto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posto Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('ID: ${posto.id}'),
          const SizedBox(height: 5),
          Text('Name: ${posto.nomePosto}'),
          const SizedBox(height: 5),
          Text('Address: ${posto.endereco}'),
          const SizedBox(height: 5),
          Text('Phone: ${posto.telefone}'),
          const SizedBox(height: 5),
          Text('Notes: ${posto.obs}'),
        ],
      ),
    );
  }
}
