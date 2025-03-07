import 'package:app/models/VehicleSupply.dart';
import 'package:app/services/VehicleSupplyService.dart';
import 'package:flutter/material.dart';

class EditVehicleSupplyForm extends StatefulWidget {
  final String veiculoId;  // ID do veículo para edição

  const EditVehicleSupplyForm({super.key, required this.veiculoId, required VehicleSupplyService vehicleSupplyService, required VehicleSupply supply, required Future<void> Function() onSupplyUpdated});

  @override
  _EditVehicleSupplyFormState createState() => _EditVehicleSupplyFormState();
}

class _EditVehicleSupplyFormState extends State<EditVehicleSupplyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplyAmountController = TextEditingController();
  final TextEditingController _supplyDateController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  String _selectedFuelType = 'Gasolina'; // Valor inicial

  // Simulação de opções de combustível
  List<String> fuelTypes = ['Gasolina', 'Diesel', 'Gásóleo'];

  @override
  void initState() {
    super.initState();
    // Você pode carregar os dados atuais do veículo aqui, se necessário
    // Exemplo: Carregar informações do abastecimento e popular os campos
  }

  @override
  void dispose() {
    _supplyAmountController.dispose();
    _supplyDateController.dispose();
    _fuelTypeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Processar os dados do formulário
      // Aqui você pode fazer a requisição para atualizar as informações de abastecimento
      print("Formulário enviado com sucesso!");
      // Exemplo de como você pode capturar os valores:
      print('ID Veículo: ${widget.veiculoId}');
      print('Quantidade: ${_supplyAmountController.text}');
      print('Data de Abastecimento: ${_supplyDateController.text}');
      print('Tipo de Combustível: $_selectedFuelType');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Abastecimento do Veículo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quantidade de Combustível (litros)',
                  style: TextStyle(fontSize: 16),
                ),
                TextFormField(
                  controller: _supplyAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Digite a quantidade',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo não pode ser vazio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Data do Abastecimento',
                  style: TextStyle(fontSize: 16),
                ),
                TextFormField(
                  controller: _supplyDateController,
                  decoration: const InputDecoration(
                    labelText: 'Selecione a data',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo não pode ser vazio';
                    }
                    return null;
                  },
                  onTap: () async {
                    // Mostrar um seletor de data
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    _supplyDateController.text =
                        "${selectedDate?.toLocal()}".split(' ')[0]; // Formatando a data
                                    },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Tipo de Combustível',
                  style: TextStyle(fontSize: 16),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  items: fuelTypes.map((fuelType) {
                    return DropdownMenuItem<String>(
                      value: fuelType,
                      child: Text(fuelType),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFuelType = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Selecione o tipo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text('Salvar Alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
