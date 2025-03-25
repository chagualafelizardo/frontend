import 'dart:typed_data';
import 'dart:convert';
import 'package:app/models/VeiculoDetails.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/VeiculoAdd.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditVeiculoForm extends StatefulWidget {
  final VeiculoServiceAdd veiculoServiceAdd = VeiculoServiceAdd(dotenv.env['BASE_URL']!);
  final VeiculoAdd veiculo;
  final VoidCallback onVeiculoUpdated;

  EditVeiculoForm({
    Key? key,
    required this.veiculo,
    required this.onVeiculoUpdated, required VeiculoServiceAdd veiculoServiceAdd,
  }) : super(key: key);

  @override
  _EditVeiculoFormState createState() => _EditVeiculoFormState();
}

class _EditVeiculoFormState extends State<EditVeiculoForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _anoController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _numChassiController = TextEditingController();
  final TextEditingController _numLugaresController = TextEditingController();
  final TextEditingController _numMotorController = TextEditingController();
  final TextEditingController _numPortasController = TextEditingController();

  String _selectedState = 'Free';
  String _selectedCombustivel = 'GASOLINA';
  Uint8List? _imageBytes;
  bool _rentalIncludesDriver = false;

  final List<Uint8List> _additionalImages = [];
  List<String> _existingImageUrls = [];
  final List<Uint8List> _newAdditionalImages = [];
  List<VeiculoDetails> _veiculoDetails = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Preenche os campos com os dados do veículo
    _matriculaController.text = widget.veiculo.matricula;
    _marcaController.text = widget.veiculo.marca;
    _modeloController.text = widget.veiculo.modelo;
    _anoController.text = widget.veiculo.ano.toString();
    _corController.text = widget.veiculo.cor;
    _numChassiController.text = widget.veiculo.numChassi;
    _numLugaresController.text = widget.veiculo.numLugares.toString();
    _numMotorController.text = widget.veiculo.numMotor;
    _numPortasController.text = widget.veiculo.numPortas.toString();
    _selectedCombustivel = widget.veiculo.tipoCombustivel;
    _selectedState = widget.veiculo.state;
    _rentalIncludesDriver = widget.veiculo.rentalIncludesDriver;

    // Carrega a imagem principal em segundo plano
    if (widget.veiculo.imagemBase64.isNotEmpty) {
      _loadImageBytes(widget.veiculo.imagemBase64);
    }

    // Carrega as imagens adicionais e detalhes em segundo plano
    _loadExistingImages();
    _loadVeiculoDetails();
  }

  Future<void> _loadImageBytes(String base64) async {
    try {
      final bytes = base64Decode(base64);
      setState(() {
        _imageBytes = bytes;
      });
    } catch (error) {
      print('Failed to decode image: $error');
    }
  }

  Future<void> _loadVeiculoDetails() async {
    try {
      final details = await widget.veiculoServiceAdd.fetchDetailsByVehicleId(widget.veiculo.id);
      setState(() {
        _veiculoDetails = details;
      });
    } catch (error) {
      print('Failed to load vehicle details: $error');
    }
  }

  Future<void> _loadExistingImages() async {
    final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
    try {
      final images = await veiculoImgService.fetchImagesByVehicleId(widget.veiculo.id);
      setState(() {
        _existingImageUrls = images.map((img) => img.imageBase64).toList();
      });
    } catch (error) {
      print('Failed to load existing images: $error');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = Uint8List.fromList(bytes);
      });
    }
  }

  Future<void> _pickAdditionalImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newAdditionalImages.add(Uint8List.fromList(bytes));
      });
    }
  }

  void _removeAdditionalImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _newAdditionalImages.removeAt(index);
      }
    });
  }

  void _saveVeiculo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final veiculo = VeiculoAdd(
        id: widget.veiculo.id,
        matricula: _matriculaController.text,
        marca: _marcaController.text,
        modelo: _modeloController.text,
        ano: int.parse(_anoController.text),
        cor: _corController.text,
        numChassi: _numChassiController.text,
        numLugares: int.parse(_numLugaresController.text),
        numMotor: _numMotorController.text,
        numPortas: int.parse(_numPortasController.text),
        tipoCombustivel: _selectedCombustivel,
        state: _selectedState,
        imagemBase64: _imageBytes != null ? base64Encode(_imageBytes!) : '',
        rentalIncludesDriver: _rentalIncludesDriver,
        createdAt: widget.veiculo.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        await widget.veiculoServiceAdd.updateVeiculo(veiculo);

        if (_newAdditionalImages.isNotEmpty) {
          await _uploadAdditionalImages(veiculo.id);
        }

        if (_existingImageUrls.isNotEmpty) {
          await _deleteRemovedImages(veiculo.id);
        }

        widget.onVeiculoUpdated();
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $error')),
        );
      }
    }
  }

  Future<void> _uploadAdditionalImages(int veiculoId) async {
    final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
    for (var image in _newAdditionalImages) {
      try {
        await veiculoImgService.addImageToVehicle(veiculoId, image);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload an image: $error')),
        );
      }
    }
  }

  Future<void> _deleteRemovedImages(int veiculoId) async {
    final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
    for (var imageUrl in _existingImageUrls) {
      try {
        await veiculoImgService.deleteImageById(veiculoId);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete an image: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // Descarta o TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Vehicle'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Vehicle Info'),
                Tab(text: 'Other Vehicle Images'),
                Tab(text: 'Vehicle Details'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Primeira aba: Vehicle Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 500,
                            height: 600,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _imageBytes != null
                                ? Image.memory(_imageBytes!)
                                : widget.veiculo.imagemBase64.isNotEmpty
                                    ? Image.memory(base64Decode(widget.veiculo.imagemBase64))
                                    : const Center(child: Text('No Image')),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Campo Matrícula
                                  TextFormField(
                                    controller: _matriculaController,
                                    decoration: const InputDecoration(labelText: 'Matrícula'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira a matrícula';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Marca
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration: const InputDecoration(labelText: 'Marca'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira a marca';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Modelo
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration: const InputDecoration(labelText: 'Modelo'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o modelo';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Ano
                                  TextFormField(
                                    controller: _anoController,
                                    decoration: const InputDecoration(labelText: 'Ano'),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o ano';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Cor
                                  TextFormField(
                                    controller: _corController,
                                    decoration: const InputDecoration(labelText: 'Cor'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira a cor';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Número do Chassi
                                  TextFormField(
                                    controller: _numChassiController,
                                    decoration: const InputDecoration(labelText: 'Número do Chassi'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o número do chassi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Número de Lugares
                                  TextFormField(
                                    controller: _numLugaresController,
                                    decoration: const InputDecoration(labelText: 'Número de Lugares'),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o número de lugares';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Número do Motor
                                  TextFormField(
                                    controller: _numMotorController,
                                    decoration: const InputDecoration(labelText: 'Número do Motor'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o número do motor';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo Número de Portas
                                  TextFormField(
                                    controller: _numPortasController,
                                    decoration: const InputDecoration(labelText: 'Número de Portas'),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o número de portas';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Dropdown para Tipo de Combustível
                                  DropdownButtonFormField<String>(
                                    value: _selectedCombustivel,
                                    decoration: const InputDecoration(labelText: 'Tipo de Combustível'),
                                    items: ['GASOLINA', 'DIESEL', 'ELÉTRICO', 'HÍBRIDO']
                                        .map((combustivel) => DropdownMenuItem(
                                              value: combustivel,
                                              child: Text(combustivel),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCombustivel = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Dropdown para Estado
                                  DropdownButtonFormField<String>(
                                    value: _selectedState,
                                    decoration: const InputDecoration(labelText: 'Estado'),
                                    items: ['Free', 'Occupied', 'Maintenance']
                                        .map((state) => DropdownMenuItem(
                                              value: state,
                                              child: Text(state),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedState = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Checkbox para Incluir Motorista
                                  CheckboxListTile(
                                    title: const Text('Incluir Motorista'),
                                    value: _rentalIncludesDriver,
                                    onChanged: (value) {
                                      setState(() {
                                        _rentalIncludesDriver = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Segunda aba: Other Vehicle Images
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _existingImageUrls.length + _newAdditionalImages.length,
                          itemBuilder: (context, index) {
                            if (index < _existingImageUrls.length) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewPage(
                                        images: _existingImageUrls
                                            .map((base64) => base64Decode(base64))
                                            .toList(),
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      base64Decode(_existingImageUrls[index]),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _removeAdditionalImage(index, true),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final newIndex = index - _existingImageUrls.length;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewPage(
                                        images: _newAdditionalImages,
                                        initialIndex: newIndex,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      _newAdditionalImages[newIndex],
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _removeAdditionalImage(newIndex, false),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: FloatingActionButton(
                            onPressed: _pickAdditionalImage,
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Terceira aba: Vehicle Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _veiculoDetails.length,
                            itemBuilder: (context, index) {
                              final detail = _veiculoDetails[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              detail.description,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              detail.startDate.toString().split(' ')[0],
                                              style: const TextStyle(color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              detail.endDate.toString().split(' ')[0],
                                              style: const TextStyle(color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              detail.obs ?? 'N/A',
                                              style: const TextStyle(color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _veiculoDetails.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveVeiculo,
          child: const Text('Save'),
        ),
      ],
    );
  }
}