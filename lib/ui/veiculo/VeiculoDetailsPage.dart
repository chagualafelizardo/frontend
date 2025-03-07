import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app/models/Veiculo.dart';

class VeiculoDetailsPage extends StatelessWidget {
  final Veiculo veiculo;

  const VeiculoDetailsPage({super.key, required this.veiculo, required int veiculoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${veiculo.marca} ${veiculo.modelo} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            veiculo.imagemBase64 != null
                ? Image.memory(
                    base64Decode(veiculo.imagemBase64),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 16.0),
            Text('Marca: ${veiculo.marca}'),
            Text('Modelo: ${veiculo.modelo}'),
            // Adicione mais campos conforme necessário
          ],
        ),
      ),
    );
  }
}
