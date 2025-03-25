import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app/models/Veiculo.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VeiculoGrid extends StatefulWidget {
  const VeiculoGrid({Key? key}) : super(key: key);

  @override
  _VeiculoGridState createState() => _VeiculoGridState();
}

class _VeiculoGridState extends State<VeiculoGrid> {
  late VeiculoService _veiculoService;
  List<Veiculo> _veiculos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _veiculoService = VeiculoService(dotenv.env['BASE_URL']!);
    _fetchVeiculos();
  }

  Future<void> _fetchVeiculos() async {
    try {
      final veiculos = await _veiculoService.getVeiculos();
      setState(() {
        _veiculos = veiculos;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch vehicles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 colunas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Proporção do card
            ),
            itemCount: _veiculos.length,
            itemBuilder: (context, index) {
              final veiculo = _veiculos[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Ação ao clicar no veículo
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem do veículo
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                          child: veiculo.imagemBase64.isNotEmpty
                              ? Image.memory(
                                  base64Decode(veiculo.imagemBase64),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : const Center(
                                  child: Icon(Icons.car_repair, size: 50, color: Colors.grey),
                                ),
                        ),
                      ),
                      // Informações do veículo
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              veiculo.matricula,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${veiculo.marca} ${veiculo.modelo}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ano: ${veiculo.ano}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}