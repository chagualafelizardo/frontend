import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/VeiculoAdd.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditVeiculoForm extends StatefulWidget {
  final VeiculoServiceAdd veiculoServiceAdd;
  final VeiculoAdd veiculo;
  final VoidCallback onVeiculoUpdated;

  const EditVeiculoForm({
    Key? key,
    required this.veiculoServiceAdd,
    required this.veiculo,
    required this.onVeiculoUpdated,
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
  List<String> _existingImageUrls = []; // URLs das imagens existentes
  final List<Uint8List> _newAdditionalImages = []; // Novas imagens adicionais

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

    // Converte a imagem base64 para bytes
    if (widget.veiculo.imagemBase64.isNotEmpty) {
      _imageBytes = base64Decode(widget.veiculo.imagemBase64);
    }

    // Carrega as imagens adicionais existentes (se houver)
    _loadExistingImages();
  }

  // Método para carregar as imagens adicionais existentes
  Future<void> _loadExistingImages() async {
    final VeiculoImgService veiculoImgService =
        VeiculoImgService(dotenv.env['BASE_URL']!);
    try {
      final images = await veiculoImgService.fetchImagesByVehicleId(widget.veiculo.id);
      setState(() {
        _existingImageUrls = images.cast<String>();
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
        // Atualiza o veículo
        await widget.veiculoServiceAdd.updateVeiculo(veiculo);

        // Faz upload das novas imagens adicionais (se houver)
        if (_newAdditionalImages.isNotEmpty) {
          await _uploadAdditionalImages(veiculo.id);
        }

        // Remove as imagens existentes que foram deletadas
        if (_existingImageUrls.isNotEmpty) {
          await _deleteRemovedImages(veiculo.id);
        }

        // Notifica que o veículo foi atualizado
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
    final VeiculoImgService veiculoImgService =
        VeiculoImgService(dotenv.env['BASE_URL']!);

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
    final VeiculoImgService veiculoImgService =
        VeiculoImgService(dotenv.env['BASE_URL']!);

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
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                                    ? Image.memory(
                                        base64Decode(widget.veiculo.imagemBase64))
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
                                  TextFormField(
                                    controller: _matriculaController,
                                    decoration:
                                        const InputDecoration(labelText: 'Matricula'),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter matricula'
                                            : null,
                                  ),
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration:
                                        const InputDecoration(labelText: 'Marca'),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter marca'
                                            : null,
                                  ),
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration:
                                        const InputDecoration(labelText: 'Modelo'),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter modelo'
                                            : null,
                                  ),
                                  TextFormField(
                                    controller: _anoController,
                                    decoration:
                                        const InputDecoration(labelText: 'Ano'),
                                    keyboardType: TextInputType.number,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter ano'
                                            : null,
                                  ),
                                  TextFormField(
                                    controller: _corController,
                                    decoration:
                                        const InputDecoration(labelText: 'Cor'),
                                  ),
                                  TextFormField(
                                    controller: _numChassiController,
                                    decoration:
                                        const InputDecoration(labelText: 'Num Chassi'),
                                  ),
                                  TextFormField(
                                    controller: _numLugaresController,
                                    decoration:
                                        const InputDecoration(labelText: 'Num Lugares'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  TextFormField(
                                    controller: _numMotorController,
                                    decoration:
                                        const InputDecoration(labelText: 'Num Motor'),
                                  ),
                                  TextFormField(
                                    controller: _numPortasController,
                                    decoration:
                                        const InputDecoration(labelText: 'Num Portas'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCombustivel,
                                    decoration: const InputDecoration(
                                        labelText: 'Tipo Combustível'),
                                    items: <String>['GASOLINA', 'DIESEL', 'GASOLEO']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCombustivel = newValue!;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please select a tipo combustivel'
                                            : null,
                                  ),
                                  DropdownButtonFormField<String>(
                                    value: _selectedState,
                                    decoration:
                                        const InputDecoration(labelText: 'State'),
                                    items: <String>['Free', 'Occupied']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedState = newValue!;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please select a state'
                                            : null,
                                  ),
                                  SwitchListTile(
                                    title: const Text('Rental Includes Driver'),
                                    value: _rentalIncludesDriver,
                                    onChanged: (bool value) {
                                      setState(() {
                                        _rentalIncludesDriver = value;
                                      });
                                    },
                                    secondary: const Icon(Icons.directions_car),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _existingImageUrls.length + _newAdditionalImages.length,
                          itemBuilder: (context, index) {
                            if (index < _existingImageUrls.length) {
                              // Imagens existentes
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewPage(
                                        images: _existingImageUrls
                                            .map((url) => base64Decode(url))
                                            .toList(),
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Image.memory(base64Decode(_existingImageUrls[index])),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            _removeAdditionalImage(index, true),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Novas imagens adicionais
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
                                    Image.memory(_newAdditionalImages[newIndex]),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            _removeAdditionalImage(newIndex, false),
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