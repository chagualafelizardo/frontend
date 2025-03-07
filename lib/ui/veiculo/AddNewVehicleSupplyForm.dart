import 'package:flutter/material.dart';
import 'package:app/models/VehicleSupply.dart';
import 'package:app/services/VehicleSupplyService.dart';

class AddNewVehicleSupplyForm extends StatefulWidget {
  final VehicleSupplyService vehicleSupplyService;
  final VoidCallback onSupplyAdded;

  const AddNewVehicleSupplyForm({
    Key? key,
    required this.vehicleSupplyService,
    required this.onSupplyAdded,
  }) : super(key: key);

  @override
  _AddNewVehicleSupplyFormState createState() => _AddNewVehicleSupplyFormState();
}

class _AddNewVehicleSupplyFormState extends State<AddNewVehicleSupplyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addSupply() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final VehicleSupply newSupply = VehicleSupply(
        id: 0, // ID será gerado no backend
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        stock: int.parse(_quantityController.text.trim()),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await widget.vehicleSupplyService.createVehicleSupply(newSupply);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle supply added successfully!')),
        );
        widget.onSupplyAdded();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add supply: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Vehicle Supply'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the supply name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addSupply,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
