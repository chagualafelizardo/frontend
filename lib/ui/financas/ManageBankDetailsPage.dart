import 'package:app/models/BankDetails.dart';
import 'package:app/services/BankDetailsService.dart';
import 'package:app/ui/financas/BankDetailsForm.dart';
import 'package:flutter/material.dart';

class ManageBankDetailsPage extends StatefulWidget {
  final BankDetailsService service;
  final int userID;
  final String username;

  const ManageBankDetailsPage({
    required this.service,
    required this.userID,
    required this.username,
    Key? key,
  }) : super(key: key);

  @override
  _ManageBankDetailsPageState createState() => _ManageBankDetailsPageState();
}

class _ManageBankDetailsPageState extends State<ManageBankDetailsPage> {
  late Future<List<BankDetails>> _bankDetailsFuture;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  void _loadBankDetails() {
    setState(() {
      _bankDetailsFuture = widget.service.getBankDetailsByUser(widget.userID);
    });
  }

  void _showForm({BankDetails? bankDetails}) async {
  final result = await showDialog<BankDetails>(
    context: context,
    builder: (context) => BankDetailsForm(
      bankDetails: bankDetails,
      userID: widget.userID,
      firstName: widget.username.split(" ").first, // Se necessário ajustar
      lastName: widget.username.split(" ").length > 1
          ? widget.username.split(" ").sublist(1).join(" ")
          : '',
    ),
  );

  if (result != null) {
    if (bankDetails == null) {
      await widget.service.createBankDetails(result);
    } else {
      await widget.service.updateBankDetails(result);
    }
    _loadBankDetails();
    setState(() {});
  }
}


  void _deleteBankDetails(int id) async {
    await widget.service.deleteBankDetails(id);
    _loadBankDetails();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bank Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção fixa para mostrar os detalhes do usuário
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User id: ${widget.userID}',
                        style: TextStyle(fontSize: 16)),
                    Text('User name: ${widget.username}',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),

          // Lista de detalhes bancários
          Expanded(
            child: FutureBuilder<List<BankDetails>>(
              future: _bankDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bank details available.'));
                }

                final bankDetails = snapshot.data!;
                return ListView.builder(
                  itemCount: bankDetails.length,
                  itemBuilder: (context, index) {
                    final details = bankDetails[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          details.bankName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Number: ${details.accountNumber}',
                                style: TextStyle(fontSize: 14)),
                            Text(
                                'M-Pesa Account: ${details.mpesaAccountNumber ?? 'N/A'}',
                                style: TextStyle(fontSize: 14)),
                            Text(
                                'e-Mola Account: ${details.eMolaAccountNumber ?? 'N/A'}',
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(bankDetails: details),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteBankDetails(details.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        tooltip: 'Add Bank Details',
        child: const Icon(Icons.add),
      ),
    );
  }
}
