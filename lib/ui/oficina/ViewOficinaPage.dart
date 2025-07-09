import 'package:flutter/material.dart';
import 'package:app/models/Oficina.dart';

class ViewOficinaPage extends StatelessWidget {
  final Oficina oficina;

  const ViewOficinaPage({super.key, required this.oficina});

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80, // Largura reduzida para os labels
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 14), // Fonte um pouco menor
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('ID:', oficina.id.toString()),
        _buildDetailRow('Name:', oficina.nomeOficina),
        _buildDetailRow('Address:', oficina.endereco),
        _buildDetailRow('Phone:', oficina.telefone.toString()),
        _buildDetailRow('Notes:', oficina.obs ?? 'N/A'),
      ],
    );
  }
}