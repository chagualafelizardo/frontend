import 'package:flutter/material.dart';
import 'package:app/models/Item.dart';
import 'package:app/services/ItemService.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class AddNewItemForm extends StatefulWidget {
  final ItemService itemService;
  final Function onItemAdded;

  const AddNewItemForm({
    super.key, 
    required this.itemService, 
    required this.onItemAdded
  });

  @override
  _AddNewItemFormState createState() => _AddNewItemFormState();
}

class _AddNewItemFormState extends State<AddNewItemForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newItem = Item(
        item: _nameController.text,
        obs: _notesController.text.isNotEmpty ? _notesController.text : null,
        selected: false,
      );

      await widget.itemService.addItem(newItem);

      // Send email after saving new item
      await _sendEmailNotification(newItem.item!);
      
      if (!mounted) return;
      
      widget.onItemAdded();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${newItem.item}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendEmailNotification(String itemName) async {
    try {
      final smtpServer = gmail('felizardo.chaguala@gmail.com', 'Imediatamente');
      
      final message = Message()
        ..from = Address('fchaguala@yahoo.com.br', 'Felizardo Chaguala')
        ..recipients.add('fchaguala@yahoo.com.br')
        ..subject = 'New Item Added'
        ..html = '''
          <h3>New Item Added Successfully</h3>
          <p><strong>Item Name:</strong> $itemName</p>
          <p><strong>Notes:</strong> ${_notesController.text.isNotEmpty ? _notesController.text : 'None'}</p>
          <p><em>This is an automatic notification.</em></p>
        ''';

      await send(message, smtpServer);
      setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added but email failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minWidth: 300,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name*',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SAVE ITEM'),
                ),
                if (_emailSent)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Notification email sent',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
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