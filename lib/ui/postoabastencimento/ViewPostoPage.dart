import 'package:flutter/material.dart';
import 'package:app/models/posto.dart';

class ViewPostoPage extends StatelessWidget {
  final Posto posto;

  const ViewPostoPage({super.key, required this.posto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Station Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID:', posto.id.toString()),
            _buildDetailRow('Name:', posto.nomePosto),
            _buildDetailRow('Address:', posto.endereco),
            _buildDetailRow('Phone:', posto.telefone.toString()),
            _buildDetailRow('Notes:', posto.obs ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}