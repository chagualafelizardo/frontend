import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Veiculo.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ViewVeiculoPage extends StatefulWidget {
  final Veiculo veiculo;

  const ViewVeiculoPage({super.key, required this.veiculo});

  @override
  _ViewVeiculoPageState createState() => _ViewVeiculoPageState();
}

class _ViewVeiculoPageState extends State<ViewVeiculoPage> {
  List<String> _additionalImageUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdditionalImages();
  }

  Future<void> _loadAdditionalImages() async {
    final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
    try {
      final images = await veiculoImgService.fetchImagesByVehicleId(widget.veiculo.id);
      setState(() {
        _additionalImageUrls = images.map((img) => img.imageBase64).toList();
        _isLoading = false;
      });
    } catch (error) {
      print('Failed to load additional images: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800, // Largura ajustada
        height: 600, // Altura ajustada
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com imagem e informações básicas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem do veículo
                    Container(
                      width: 250, // Largura da imagem ajustada
                      height: 250, // Altura da imagem ajustada
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.veiculo.imagemBase64.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_addPadding(_removeDataPrefix(widget.veiculo.imagemBase64))),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.car_repair, size: 40, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre a imagem e os detalhes
                    // Detalhes do veículo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.veiculo.marca} ${widget.veiculo.modelo}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.confirmation_number, 'Matrícula', widget.veiculo.matricula),
                          _buildDetailRow(Icons.directions_car, 'Marca', widget.veiculo.marca),
                          _buildDetailRow(Icons.model_training, 'Modelo', widget.veiculo.modelo),
                          _buildDetailRow(Icons.calendar_today, 'Ano', widget.veiculo.ano.toString()),
                          _buildDetailRow(Icons.color_lens, 'Cor', widget.veiculo.cor),
                          _buildDetailRow(Icons.confirmation_number, 'Nº Chassi', widget.veiculo.numChassi),
                          _buildDetailRow(Icons.people, 'Nº Lugares', widget.veiculo.numLugares.toString()),
                          _buildDetailRow(Icons.engineering, 'Nº Motor', widget.veiculo.numMotor),
                          _buildDetailRow(Icons.door_back_door, 'Nº Portas', widget.veiculo.numPortas.toString()),
                          _buildDetailRow(Icons.local_gas_station, 'Combustível', widget.veiculo.tipoCombustivel),
                          _buildDetailRow(Icons.flag, 'Estado', widget.veiculo.state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Colors.grey),
              // Título para as Additional Images
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Additional Images',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Lista de Additional Images
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _additionalImageUrls.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Nenhuma imagem adicional disponível.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _additionalImageUrls.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewPage(
                                        images: _additionalImageUrls
                                            .map((base64) => base64Decode(base64))
                                            .toList(),
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(_additionalImageUrls[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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