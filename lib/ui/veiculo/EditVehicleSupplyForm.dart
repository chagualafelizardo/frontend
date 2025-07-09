import 'dart:core';
import 'package:flutter/material.dart';
import 'package:app/models/VehicleSupply.dart';
import 'package:app/services/VehicleSupplyService.dart';

class EditVehicleSupplyForm extends StatefulWidget {
  final VehicleSupplyService vehicleSupplyService;
  final VehicleSupply supply;
  final VoidCallback onSupplyUpdated;
  final String veiculoId;

  const EditVehicleSupplyForm({
    Key? key,
    required this.vehicleSupplyService,
    required this.supply,
    required this.onSupplyUpdated,
    required this.veiculoId,
  }) : super(key: key);

  @override
  _EditVehicleSupplyFormState createState() => _EditVehicleSupplyFormState();
}

class _EditVehicleSupplyFormState extends State<EditVehicleSupplyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _dateController;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supply.name);
    _descriptionController = TextEditingController(text: widget.supply.description);
    _quantityController = TextEditingController(text: widget.supply.stock.toString());
    _dateController = TextEditingController();
  }

  Future<void> _updateSupply() async {
    print('[DEBUG] Iniciando processo de atualização do supply...');
    
    if (_formKey.currentState?.validate() ?? false) {
      print('[DEBUG] Formulário validado com sucesso');
      setState(() => _isLoading = true);

      // Garantir que os campos obrigatórios não sejam nulos
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        print('[ERROR] Nome do supply não pode ser vazio');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O nome do supply é obrigatório')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final stockValue = int.tryParse(_quantityController.text.trim()) ?? 0;
      if (stockValue <= 0) {
        print('[ERROR] Estoque inválido');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O estoque deve ser um número positivo')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final updatedSupply = VehicleSupply(
        id: widget.supply.id,
        name: name,
        description: _descriptionController.text.trim(),
        stock: stockValue,
        createdAt: widget.supply.createdAt,
        updatedAt: DateTime.now(),
        selected: widget.supply.selected,
      );

      print('[DEBUG] Dados do supply a ser atualizado:');
      print(' - ID: ${updatedSupply.id}');
      print(' - Nome: ${updatedSupply.name}');
      print(' - Descrição: ${updatedSupply.description ?? "null"}');
      print(' - Estoque: ${updatedSupply.stock}');
      print(' - Criado em: ${updatedSupply.createdAt ?? "null"}');
      print(' - Atualizado em: ${updatedSupply.updatedAt}');
      print(' - Selecionado: ${updatedSupply.selected}');

      try {
        print('[DEBUG] Chamando serviço para atualizar supply...');
        final response = await widget.vehicleSupplyService.updateVehicleSupply(updatedSupply);
        print('[DEBUG] Resposta do servidor: $response');
        
        if (!mounted) {
          print('[WARNING] Widget não está montado, abortando operação');
          return;
        }
        
        print('[DEBUG] Supply atualizado com sucesso no servidor');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supply updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('[DEBUG] Chamando callback para atualizar lista');
        widget.onSupplyUpdated();
        
        print('[DEBUG] Fechando diálogo de edição');
        Navigator.of(context).pop();
        
      } catch (e) {
        print('[ERROR] Erro ao atualizar supply: $e');
        if (!mounted) {
          print('[WARNING] Widget não está montado, não é possível mostrar erro');
          return;
        }
        
        String errorMessage = 'Erro ao atualizar supply';
        if (e.toString().contains('Null')) {
          errorMessage = 'Dados inválidos: algum campo obrigatório está vazio';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          print('[DEBUG] Finalizando estado de loading');
          setState(() => _isLoading = false);
        } else {
          print('[WARNING] Widget não está montado, não é possível atualizar estado');
        }
      }
    } else {
      print('[DEBUG] Validação do formulário falhou');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supply Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter supply name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the supply name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Enter quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the quantity';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateSupply,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Supply',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}