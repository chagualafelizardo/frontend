import 'dart:typed_data';
import 'dart:convert'; // Adicionado para codificação base64
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/VeiculoAdd.dart';

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

class _EditVeiculoFormState extends State<EditVeiculoForm> {
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

  String _selectedState = 'Free'; // Estado selecionado
  String _selectedCombustivel = 'GASOLINA'; // Tipo de combustível selecionado
  Uint8List? _imageBytes; // Armazena a imagem selecionada como bytes
  bool _rentalIncludesDriver =
      false; // Valor inicial para "Rental Includes Driver"

  @override
  @override
  void initState() {
    super.initState();

    // Inicialize os controladores com os valores atuais do veículo
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

    // Converta a imagem base64 para bytes
    if (widget.veiculo.imagemBase64.isNotEmpty) {
      _imageBytes = base64Decode(widget.veiculo.imagemBase64);
    }

    // Inicialize o campo rentalIncludesDriver com o valor do veículo
    _rentalIncludesDriver = widget.veiculo.rentalIncludesDriver;
    print(
        "Rental Includes Driver: $_rentalIncludesDriver"); // Verifique o valor
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = Uint8List.fromList(bytes);
      });
    }
  }

  void _saveVeiculo() {
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
        imagemBase64: _imageBytes != null
            ? base64Encode(_imageBytes!)
            : widget.veiculo.imagemBase64,
        rentalIncludesDriver:
            _rentalIncludesDriver, // Inclui o valor de "Rental Includes Driver"
        createdAt: widget.veiculo.createdAt,
        updatedAt: DateTime.now(),
      );

      // Certifique-se de passar o ID do veículo e o objeto VeiculoAdd
      widget.veiculoServiceAdd
          .updateVeiculo(widget.veiculo.id as String, veiculo)
          .then((_) {
        widget.onVeiculoUpdated();
        Navigator.of(context).pop();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Vehicle'),
      content: SizedBox(
        width: 800, // Largura ajustada
        height: 600, // Altura ajustada
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 500, // Largura ajustada
                    height: 520, // Altura ajustada
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _matriculaController,
                        decoration:
                            const InputDecoration(labelText: 'Matricula'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter matricula';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _marcaController,
                        decoration: const InputDecoration(labelText: 'Marca'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter marca';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _modeloController,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter modelo';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _anoController,
                        decoration: const InputDecoration(labelText: 'Ano'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ano';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _corController,
                        decoration: const InputDecoration(labelText: 'Cor'),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a tipo combustivel';
                          }
                          return null;
                        },
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
                      ),
                      SwitchListTile(
                        title: const Text('Rental Includes Driver'),
                        value: _rentalIncludesDriver,
                        onChanged: (bool value) {
                          setState(() {
                            _rentalIncludesDriver = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveVeiculo,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
