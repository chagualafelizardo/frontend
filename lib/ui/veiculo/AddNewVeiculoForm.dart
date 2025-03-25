import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/VeiculoDetails.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/VeiculoAdd.dart';

class AddNewVeiculoForm extends StatefulWidget {
  final VeiculoServiceAdd veiculoServiceAdd = VeiculoServiceAdd(dotenv.env['BASE_URL']!); // Inicialização direta
  final Function onVeiculoAdded;

  AddNewVeiculoForm({
    Key? key,
    required this.onVeiculoAdded, required VeiculoServiceAdd veiculoServiceAdd, // Remova o parâmetro veiculoServiceAdd
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

  // Para detalhes do veiculo
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  String _selectedState = 'Free';
  String _selectedCombustivel = 'GASOLINA';
  Uint8List? _imageBytes;
  bool _rentalIncludesDriver = false;

  final List<Uint8List> _additionalImages = [];
  late TabController _tabController;
  final List<VeiculoDetails> _veiculoDetails = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      try {
        // Salvar o veículo
        await widget.veiculoServiceAdd.createVeiculo(veiculo);
        final veiculoSalvo = await widget.veiculoServiceAdd.getVeiculoByMatricula(_matriculaController.text);

        if (veiculoSalvo == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to retrieve the saved vehicle')),
          );
          return;
        }

        // Salvar as imagens adicionais
        if (_additionalImages.isNotEmpty) {
          await _uploadAdditionalImages(veiculoSalvo.id);
        }
        // Salvar os detalhes do veículo
        if (_veiculoDetails.isNotEmpty) {
          for (var detail in _veiculoDetails) {
            await widget.veiculoServiceAdd.addVeiculoDetail(
              VeiculoDetails(
                description: detail.description,
                startDate: detail.startDate,
                endDate: detail.endDate,
                obs: detail.obs,
                veiculoId: veiculoSalvo.id,
              ),
            );
          }
        }

        widget.onVeiculoAdded();
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add vehicle: $error')),
        );
      }
    }
  }

  Future<void> _uploadAdditionalImages(int veiculoId) async {
    final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);

    for (var image in _additionalImages) {
      try {
        await veiculoImgService.addImageToVehicle(veiculoId, image);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload an image: $error')),
        );
      }
    }
  }

  void _addDetail() {
    final description = _descriptionController.text;
    final startDate = DateTime.parse(_startDateController.text);
    final endDate = DateTime.parse(_endDateController.text);
    final obs = _obsController.text;

    if (description.isNotEmpty && startDate.isBefore(endDate)) {
      setState(() {
        _veiculoDetails.add(
          VeiculoDetails(
            description: description,
            startDate: startDate,
            endDate: endDate,
            obs: obs.isNotEmpty ? obs : null,
            veiculoId: 0, // Será atualizado após salvar o veículo
          ),
        );
      });

      // Limpar os campos do formulário
      _descriptionController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _obsController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
    }
  }

  void _removeDetail(VeiculoDetails detail) {
    setState(() {
      _veiculoDetails.remove(detail);
    });
  }

 Widget _buildDetailsForm() {
  return Row(
    children: [
      // Campo Description
      Expanded(
        flex: 2, // Proporção de espaço ocupado
        child: TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 10), // Espaçamento entre os campos
      // Campo Start Date (com calendário)
      Expanded(
        flex: 1,
        child: TextFormField(
          controller: _startDateController,
          decoration: const InputDecoration(
            labelText: 'Start Date',
            border: OutlineInputBorder(),
          ),
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _startDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
              });
            }
          },
        ),
      ),
      const SizedBox(width: 10),
      // Campo End Date (com calendário)
      Expanded(
        flex: 1,
        child: TextFormField(
          controller: _endDateController,
          decoration: const InputDecoration(
            labelText: 'End Date',
            border: OutlineInputBorder(),
          ),
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _endDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
              });
            }
          },
        ),
      ),
      const SizedBox(width: 10),
      // Campo Observations
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: _obsController,
          decoration: const InputDecoration(
            labelText: 'Observations',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 10),
      // Botão para adicionar detalhe
      ElevatedButton(
        onPressed: _addDetail,
        child: const Text('Add Detail'),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Vehicle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Vehicle Info'),
                Tab(text: 'Other Vehicle Images'),
                Tab(text: 'General Information'),
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
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                  )
                                : const Center(child: Icon(Icons.camera_alt, size: 40, color: Colors.grey)),
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
                                  _buildStyledTextField(
                                    controller: _matriculaController,
                                    labelText: 'Matricula',
                                    icon: Icons.confirmation_number,
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter matricula' : null,
                                  ),
                                  _buildStyledTextField(
                                    controller: _marcaController,
                                    labelText: 'Marca',
                                    icon: Icons.directions_car,
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter marca' : null,
                                  ),
                                  _buildStyledTextField(
                                    controller: _modeloController,
                                    labelText: 'Modelo',
                                    icon: Icons.model_training,
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter modelo' : null,
                                  ),
                                  _buildStyledTextField(
                                    controller: _anoController,
                                    labelText: 'Ano',
                                    icon: Icons.calendar_today,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value == null || value.isEmpty ? 'Please enter ano' : null,
                                  ),
                                  _buildStyledTextField(
                                    controller: _corController,
                                    labelText: 'Cor',
                                    icon: Icons.color_lens,
                                  ),
                                  _buildStyledTextField(
                                    controller: _numChassiController,
                                    labelText: 'Num Chassi',
                                    icon: Icons.confirmation_number,
                                  ),
                                  _buildStyledTextField(
                                    controller: _numLugaresController,
                                    labelText: 'Num Lugares',
                                    icon: Icons.people,
                                    keyboardType: TextInputType.number,
                                  ),
                                  _buildStyledTextField(
                                    controller: _numMotorController,
                                    labelText: 'Num Motor',
                                    icon: Icons.engineering,
                                  ),
                                  _buildStyledTextField(
                                    controller: _numPortasController,
                                    labelText: 'Num Portas',
                                    icon: Icons.door_back_door,
                                    keyboardType: TextInputType.number,
                                  ),
                                  _buildStyledDropdown(
                                    value: _selectedCombustivel,
                                    labelText: 'Tipo Combustível',
                                    icon: Icons.local_gas_station,
                                    items: ['GASOLINA', 'DIESEL', 'GASOLEO'],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCombustivel = value!;
                                      });
                                    },
                                  ),
                                  _buildStyledDropdown(
                                    value: _selectedState,
                                    labelText: 'State',
                                    icon: Icons.flag,
                                    items: ['Free', 'Occupied'],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedState = value!;
                                      });
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Rental Includes Driver', style: TextStyle(color: Colors.black87, fontSize: 16)),
                                    value: _rentalIncludesDriver,
                                    onChanged: (bool value) {
                                      setState(() {
                                        _rentalIncludesDriver = value;
                                      });
                                    },
                                    secondary: const Icon(Icons.directions_car, color: Colors.black54),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(_additionalImages[index], fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
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
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Formulário para adicionar novos detalhes
                        _buildDetailsForm(),
                        const SizedBox(height: 20),
                        // Tabela para exibir os detalhes adicionados
                        Container(
                          height: 300, // Altura fixa ou use MediaQuery para altura dinâmica
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Start Date')),
                                DataColumn(label: Text('End Date')),
                                DataColumn(label: Text('Observations')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _veiculoDetails.map((detail) {
                                return DataRow(cells: [
                                  DataCell(Text(detail.description)),
                                  // Célula para Start Date (abre calendário ao clicar)
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: detail.startDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            detail.startDate = pickedDate;
                                          });
                                        }
                                      },
                                      child: Text(
                                        detail.startDate.toString().split(' ')[0],
                                      ),
                                    ),
                                  ),
                                  // Célula para End Date (abre calendário ao clicar)
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: detail.endDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            detail.endDate = pickedDate;
                                          });
                                        }
                                      },
                                      child: Text(
                                        detail.endDate.toString().split(' ')[0],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(detail.obs ?? 'N/A')),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeDetail(detail),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
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
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: _saveVeiculo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 5,
          ),
          child: const Text('Save', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.black87, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required String labelText,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.black87, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}