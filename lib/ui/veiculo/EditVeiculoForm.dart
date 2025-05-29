import 'dart:typed_data';
import 'dart:convert';
import 'package:app/models/VeiculoDetails.dart';
import 'package:app/services/VehicleHistoryRentService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/ui/veiculo/ManageVehiclePriceRentHistoryPage.dart';
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
  final VehicleHistoryRentService historyRentService = VehicleHistoryRentService(dotenv.env['BASE_URL']!);
  final TextEditingController _smsLockCommandController = TextEditingController();
  final TextEditingController _smsUnLockCommandController = TextEditingController();

  String _selectedState = 'Free';
  String _selectedCombustivel = 'GASOLINA';
  Uint8List? _imageBytes;
  bool _rentalIncludesDriver = false;
  bool _isAvailable = false;

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
    _smsLockCommandController.text = widget.veiculo.smsLockCommand;
    _smsUnLockCommandController.text = widget.veiculo.smsUnLockCommand;

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
        isAvailable: _isAvailable, 
        smsLockCommand: _smsLockCommandController.text, 
        smsUnLockCommand: _smsUnLockCommandController.text, 
      );

      try {
        await widget.veiculoServiceAdd.updateVeiculo(veiculo);

        if (_newAdditionalImages.isNotEmpty) {
          await _uploadAdditionalImages(veiculo.id);
        }

        // if (_existingImageUrls.isNotEmpty) {
        //   await _deleteRemovedImages(veiculo.id);
        // }

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
                                  const SizedBox(height: 16),
                                  // Campo SMS Lock Command
                                  TextFormField(
                                    controller: _smsLockCommandController,
                                    decoration: const InputDecoration(
                                      labelText: 'Comando SMS para Bloqueio',
                                      hintText: 'Ex: BLOQUEAR123'
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o comando de bloqueio';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Campo SMS Unlock Command
                                  TextFormField(
                                    controller: _smsUnLockCommandController,
                                    decoration: const InputDecoration(
                                      labelText: 'Comando SMS para Desbloqueio',
                                      hintText: 'Ex: DESBLOQUEAR123'
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira o comando de desbloqueio';
                                      }
                                      return null;
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
                            color: Color.fromRGBO(245, 243, 243, 0.986),
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
        Tooltip(
          message: 'Cancel edit and close',
          child: TextButton.icon(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text(
              'Cancel',
              style: TextStyle(color: Colors.redAccent),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        Tooltip(
          message: 'Manage price and rental history for this vehicle',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Rent Price History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            onPressed: () {
              _showHistoryPopup(context);
            },
          ),
        ),
        Tooltip(
          message: 'Add new vehicle detail',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Detail'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            onPressed: () {
              _showAddDetailDialog();
            },
          ),
        ),
        Tooltip(
          message: 'Save all changes made to the vehicle',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: _saveVeiculo,
          ),
        ),
      ],

    );
  }

  void _showAddDetailDialog() {
    final descriptionController = TextEditingController();
    final obsController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4, // 40% da largura
              maxHeight: MediaQuery.of(context).size.height * 0.7, // 70% da altura
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Add Vehicle Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selectedDate != null) {
                                    setState(() {
                                      startDate = selectedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    '${startDate.day}/${startDate.month}/${startDate.year}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selectedDate != null) {
                                    setState(() {
                                      endDate = selectedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    '${endDate.day}/${endDate.month}/${endDate.year}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: obsController,
                          decoration: const InputDecoration(
                            labelText: 'Observations',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final newDetail = VeiculoDetails(
                                  id: 0,
                                  veiculoId: widget.veiculo.id,
                                  description: descriptionController.text,
                                  startDate: startDate,
                                  endDate: endDate,
                                  obs: obsController.text,
                                );
                                
                                await widget.veiculoServiceAdd.addVeiculoDetail(newDetail);

                                setState(() {
                                  _veiculoDetails.add(newDetail);
                                });
                                
                                Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistoryPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,  // 90% da largura da tela
              maxHeight: MediaQuery.of(context).size.height * 0.7, // 70% da altura da tela
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rental Price History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ManageVehicleHistoryPage(
                      service: historyRentService,
                      veiculoId: widget.veiculo.id,
                    ),
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