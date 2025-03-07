import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/models/BankDetails.dart';

class BankDetailsForm extends StatefulWidget {
    final BankDetails? bankDetails;
    final int userID;
    final String firstName;
    final String lastName;

    const BankDetailsForm({
      this.bankDetails,
      required this.userID,
      required this.firstName,
      required this.lastName,
      Key? key,
    }) : super(key: key);

    @override
    _BankDetailsFormState createState() => _BankDetailsFormState();
  }

class _BankDetailsFormState extends State<BankDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _mpesaAccountNumberController;
  late TextEditingController _eMolaAccountNumberController;
  AccountType? _accountType;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(
        text: widget.bankDetails?.bankName ?? '');
    _accountNumberController = TextEditingController(
        text: widget.bankDetails?.accountNumber ?? '');
    _mpesaAccountNumberController = TextEditingController(
        text: widget.bankDetails?.mpesaAccountNumber ?? '');
    _eMolaAccountNumberController = TextEditingController(
        text: widget.bankDetails?.eMolaAccountNumber ?? '');
    _accountType = widget.bankDetails?.accountType ?? AccountType.savings;
  }

@override
Widget build(BuildContext context) {
  return AlertDialog(
    title: Text(widget.bankDetails == null ? 'Add Bank Details' : 'Edit Bank Details'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('User id: ${widget.userID}', style: TextStyle(fontSize: 16)),
            Text('First Name: ${widget.firstName}', style: TextStyle(fontSize: 16)),
            Text('Last Name: ${widget.lastName}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: 'Account Number'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            DropdownButtonFormField<AccountType>(
              value: _accountType,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(describeEnum(type)),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _accountType = value!;
              }),
              validator: (value) => value == null ? 'Please select an account type' : null,
            ),
            TextFormField(
              controller: _mpesaAccountNumberController,
              decoration: const InputDecoration(labelText: 'M-PESA Account Number'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _eMolaAccountNumberController,
              decoration: const InputDecoration(labelText: 'E-MOLA Account Number'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final newDetails = BankDetails(
              id: widget.bankDetails?.id,
              userId: widget.userID, // Pegando userId do widget ou de um estado global
              bankName: _bankNameController.text,
              accountNumber: _accountNumberController.text,
              accountType: _accountType!,
              mpesaAccountNumber: _mpesaAccountNumberController.text,
              eMolaAccountNumber: _eMolaAccountNumberController.text,
            );
            Navigator.of(context).pop(newDetails);
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

}
