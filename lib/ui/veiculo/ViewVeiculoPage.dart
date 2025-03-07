import 'package:flutter/material.dart';
import 'package:app/models/Veiculo.dart';
import 'dart:convert';

class ViewVeiculoPage extends StatelessWidget {
  final Veiculo veiculo;

  const ViewVeiculoPage({super.key, required this.veiculo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800, // Largura ajustada
        height: 600, // Altura ajustada
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem à esquerda
              Container(
                width: 250, // Largura da imagem ajustada
                height: 250, // Altura da imagem ajustada
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: veiculo.imagemBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(_addPadding(
                            _removeDataPrefix(veiculo.imagemBase64))),
                        fit: BoxFit.cover,
                      )
                    : const Center(child: Text('No Image Available')),
              ),
              const SizedBox(width: 16), // Espaçamento entre a imagem e os detalhes
              // Detalhes do veículo à direita
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${veiculo.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Matricula: ${veiculo.matricula}'),
                      Text('Marca: ${veiculo.marca}'),
                      Text('Modelo: ${veiculo.modelo}'),
                      Text('Ano: ${veiculo.ano}'),
                      Text('Cor: ${veiculo.cor}'),
                      Text('Num Chassi: ${veiculo.numChassi}'),
                      Text('Num Lugares: ${veiculo.numLugares}'),
                      Text('Num Motor: ${veiculo.numMotor}'),
                      Text('Num Portas: ${veiculo.numPortas}'),
                      Text('Tipo Combustível: ${veiculo.tipoCombustivel}'),
                      Text('State: ${veiculo.state}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _removeDataPrefix(String base64String) {
    const prefix = 'data:image/jpeg;base64,';
    if (base64String.startsWith(prefix)) {
      return base64String.substring(prefix.length);
    }
    return base64String;
  }

  String _addPadding(String base64String) {
    final remainder = base64String.length % 4;
    if (remainder == 0) return base64String;
    return base64String.padRight(base64String.length + (4 - remainder), '=');
  }
}
