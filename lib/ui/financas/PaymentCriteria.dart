import 'package:app/models/PaymentCriteria.dart';
import 'package:flutter/material.dart';

class PaymentCriteriaForm extends StatefulWidget {
  final PaymentCriteria? paymentCriteria;

  const PaymentCriteriaForm({this.paymentCriteria, Key? key}) : super(key: key);

  @override
  _PaymentCriteriaFormState createState() => _PaymentCriteriaFormState();
}

class _PaymentCriteriaFormState extends State<PaymentCriteriaForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _activityController;
  String? _paymentType;
  String? _paymentMethod;
  String? _paymentPeriod;
  late TextEditingController _amountController;

  final List<String> _paymentTypes = ['Alojamento', 'PERDIEM','Motorista'];
  final List<String> _paymentMethods = ['cash', 'transfer', 'mobile_money'];
  final List<String> _paymentPeriods = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(
        text: widget.paymentCriteria?.activity ?? '');
    _paymentType = widget.paymentCriteria?.paymentType;
    _paymentMethod = widget.paymentCriteria?.paymentMethod;
    _paymentPeriod = widget.paymentCriteria?.paymentPeriod;
    _amountController = TextEditingController(
        text: widget.paymentCriteria?.amount.toString() ?? '');
  }

  @override
  void dispose() {
    _activityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final paymentCriteria = PaymentCriteria(
        id: widget.paymentCriteria?.id,
        activity: _activityController.text,
        paymentType: _paymentType!,
        paymentMethod: _paymentMethod!,
        paymentPeriod: _paymentPeriod!,
        amount: double.parse(_amountController.text),
      );

      Navigator.of(context).pop(paymentCriteria);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.paymentCriteria == null
          ? 'Add Payment Criteria'
          : 'Edit Payment Criteria'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(labelText: 'Activity'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the activity';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Payment Type'),
                items: _paymentTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _paymentType = value),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payment type';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: _paymentMethods
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _paymentMethod = value),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payment method';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentPeriod,
                decoration: const InputDecoration(labelText: 'Payment Period'),
                items: _paymentPeriods
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _paymentPeriod = value),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payment period';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount';
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
          onPressed: _submitForm,
          child: Text(widget.paymentCriteria == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
