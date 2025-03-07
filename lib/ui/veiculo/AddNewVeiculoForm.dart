import 'dart:typed_data';
import 'dart:convert';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/VeiculoAdd.dart';

class AddNewVeiculoForm extends StatefulWidget {
  final VeiculoServiceAdd veiculoServiceAdd;
  final Function onVeiculoAdded;

  const AddNewVeiculoForm({
    Key? key,
    required this.veiculoServiceAdd,
    required this.onVeiculoAdded,
  }) : super(key: key);

  @override
  _AddNewVeiculoFormState createState() => _AddNewVeiculoFormState();
}

class _AddNewVeiculoFormState extends State<AddNewVeiculoForm> with SingleTickerProviderStateMixin {
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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        _additionalImages.add(Uint8List.fromList(bytes));
      });
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

void _saveVeiculo() async {
  print('Saving vehicle...');

  if (_formKey.currentState?.validate() ?? false) {
    final veiculo = VeiculoAdd(
      id: 0,
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('Vehicle data prepared: ${veiculo.toJson()}');

    if (_imageBytes != null) {
      print("Image bytes size: ${_imageBytes!.length} bytes");
    }

    try {
      // Criação do veículo
      await widget.veiculoServiceAdd.createVeiculo(veiculo);
      print('Vehicle saved successfully.');

      // Obter o veículo salvo
      final veiculoSalvo = await widget.veiculoServiceAdd.getVeiculoByMatricula(_matriculaController.text);

      if (veiculoSalvo == null) {
        print('Failed to retrieve the saved vehicle: No vehicle found.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve the saved vehicle')),
        );
        return;
      }

      print('Retrieved vehicle ID: ${veiculoSalvo.id}');
      
      // Fazer upload das imagens adicionais
      if (_additionalImages.isNotEmpty) {
        await _uploadAdditionalImages(veiculoSalvo.id); // Envia imagens adicionais
      }
      
      // Finalizar e voltar
      widget.onVeiculoAdded();
      Navigator.of(context).pop();

    } catch (error) {
      print('Error during vehicle saving process: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add vehicle: $error')),
      );
    }
  } else {
    print('Form validation failed.');
  }
}

Future<void> _uploadAdditionalImages(int veiculoId) async {
  final VeiculoImgService veiculoImgService = VeiculoImgService('http://localhost:5000');
  print('Uploading additional images for vehicle ID: $veiculoId');

  if (_additionalImages.isEmpty) {
    print('No additional images to upload.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No images to upload')),
    );
    return;
  }

  for (var image in _additionalImages) {
    print("Preparing to upload image, size: ${image.length} bytes");
    try {
      await veiculoImgService.addImageToVehicle(veiculoId, image);
      print('Image uploaded successfully for vehicle ID: $veiculoId');
    } catch (error) {
      print('Failed to upload additional image for vehicle ID $veiculoId: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload an image: $error')),
      );
    }
  }

  print('Image upload process completed.');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Image upload process completed')),
  );
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Vehicle'),
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
                                    decoration: const InputDecoration(labelText: 'Matricula'),
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter matricula' : null,
                                  ),
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration: const InputDecoration(labelText: 'Marca'),
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter marca' : null,
                                  ),
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration: const InputDecoration(labelText: 'Modelo'),
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter modelo' : null,
                                  ),
                                  TextFormField(
                                    controller: _anoController,
                                    decoration: const InputDecoration(labelText: 'Ano'),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter ano' : null,
                                  ),
                                  TextFormField(
                                    controller: _corController,
                                    decoration: const InputDecoration(labelText: 'Cor'),
                                  ),
                                  TextFormField(
                                    controller: _numChassiController,
                                    decoration: const InputDecoration(labelText: 'Num Chassi'),
                                  ),
                                  TextFormField(
                                    controller: _numLugaresController,
                                    decoration: const InputDecoration(labelText: 'Num Lugares'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  TextFormField(
                                    controller: _numMotorController,
                                    decoration: const InputDecoration(labelText: 'Num Motor'),
                                  ),
                                  TextFormField(
                                    controller: _numPortasController,
                                    decoration: const InputDecoration(labelText: 'Num Portas'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCombustivel,
                                    decoration: const InputDecoration(labelText: 'Tipo Combustível'),
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
                                    validator: (value) => value == null || value.isEmpty ? 'Please select a tipo combustivel' : null,
                                  ),
                                  DropdownButtonFormField<String>(
                                    value: _selectedState,
                                    decoration: const InputDecoration(labelText: 'State'),
                                    items: <String>['Free', 'Occupied'].map((String value) {
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
                                    validator: (value) => value == null || value.isEmpty ? 'Please select a state' : null,
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _additionalImages.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImagePreviewPage(
                                      images: _additionalImages,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Image.memory(_additionalImages[index]),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _removeAdditionalImage(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
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
