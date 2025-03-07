import 'package:app/services/BankDetailsService.dart';
import 'package:app/ui/financas/ManageBankDetailsPage.dart';
import 'package:flutter/material.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/services/UserService.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';

class ManageUsersEmployeeFinancialDetailsPage extends StatefulWidget {
  const ManageUsersEmployeeFinancialDetailsPage({super.key});

  @override
  _ManageUsersEmployeeFinancialDetailsPageState createState() => _ManageUsersEmployeeFinancialDetailsPageState();
}

class _ManageUsersEmployeeFinancialDetailsPageState extends State<ManageUsersEmployeeFinancialDetailsPage> {
  final UserService userService = UserService('http://localhost:5000');
  List<UserBase64> _users = [];
  String _searchQuery = '';
  bool _isGridView = true;
  
  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final List<dynamic> userJsonList = await userService.getUsers();

      setState(() {
        _users = userJsonList.map((userJson) {
          if (userJson is Map<String, dynamic>) {
            return UserBase64.fromJson(userJson);
          } else {
            print('Unexpected type for userJson: ${userJson.runtimeType}');
            throw TypeError();
          }
        }).toList();
      });
    } catch (e, stackTrace) {
      print('Error fetching users: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch users.')),
      );
    }
  }

  Uint8List? _decodeImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return null;
    }

    try {
      final cleanBase64 = base64Image.replaceFirst(
          RegExp(r'^data:image\/[a-zA-Z]+;base64,'), '');
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }


  void _viewUser(UserBase64 user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Uint8List? imageBytes = _decodeImage(user.imgBase64);
        return AlertDialog(
          title: const Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${user.id}'),
                Text('Username: ${user.username}'),
                Text('First Name: ${user.firstName}'),
                Text('Last Name: ${user.lastName}'),
                Text('Gender: ${user.gender}'),
                Text('Birthdate: ${user.birthdate}'),
                Text('Email: ${user.email}'),
                Text('Address: ${user.address ?? 'No address provided'}'),
                Text('Neighborhood: ${user.neighborhood ?? 'N/A'}'),
                Text('Phone 1: ${user.phone1 ?? 'N/A'}'),
                Text('Phone 2: ${user.phone2 ?? 'N/A'}'),
                Text('Password: ${user.password}'),
                Text('State: ${user.state}'),
                const SizedBox(height: 16),
                imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : const Text('No Image'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(UserBase64 user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              Text('Are you sure you want to delete User "${user.username}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await userService.deleteUser(user.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User "${user.username}" deleted successfully!')),
        );
        _fetchUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete user. Please try again.')),
        );
      }
    }
  }

  Widget _buildImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return const Center(
        child: Text('No Image', style: TextStyle(fontSize: 12)),
      );
    }

    try {
      final cleanBase64 = base64Image.replaceFirst(
          RegExp(r'^data:image\/[a-zA-Z]+;base64,'), '');
      final decodedImage = base64Decode(cleanBase64);
      return ClipOval(
        child: Image.memory(
          decodedImage,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return const Center(
        child: Text('Error Image', style: TextStyle(fontSize: 12)),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Users'),
      actions: [
        // Botões para alternar entre ListView e GridView na barra de título
        ToggleButtons(
          isSelected: [!_isGridView, _isGridView],
          onPressed: (int index) {
            setState(() {
              _isGridView = index == 1;
            });
          },
          children: const [
            Icon(Icons.list),
            Icon(Icons.grid_on),
          ],
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: _isGridView
                ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // Número de colunas no Grid
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImage(user.imgBase64),
                            Text(user.username),
                            Text(user.firstName ?? 'N/A'),
                            Text(user.lastName ?? 'N/A'),
                            Text(user.gender ?? 'N/A'),
                            Text(DateFormat('yyyy-MM-dd').format(user.birthdate).toString()),
                            Text(user.email),
                            Text(user.address ?? 'No address provided'),
                            Text(user.neighborhood ?? 'N/A'),
                            Text(user.phone1 ?? 'N/A'),
                            Text(user.phone2 ?? 'N/A'),
                            Text(user.state ?? 'N/A'),
                            // Botão de operação
                            Tooltip(
                              message: 'Add Bank Details',
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: SizedBox(
                                          width: 600,
                                          height: 400,
                                          child: ManageBankDetailsPage(
                                            service: BankDetailsService(
                                              baseUrl: 'http://localhost:5000',
                                              userID: user.id!, 
                                              username: '${user.firstName} ${user.lastName}',
                                            ), 
                                            userID: user.id!,
                                            username: '${user.firstName} ${user.lastName}',
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
                      );
                    },
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12.0,
                        columns: const [
                          DataColumn(label: Text('User image')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('First Name')),
                          DataColumn(label: Text('Last Name')),
                          DataColumn(label: Text('Gender')),
                          DataColumn(label: Text('Birthdate')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Neighborhood')),
                          DataColumn(label: Text('Phone 1')),
                          DataColumn(label: Text('Phone 2')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _users.asMap().entries.map((entry) {
                          int index = entry.key;
                          UserBase64 user = entry.value;

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                                return index % 2 == 0
                                    ? const Color.fromARGB(255, 15, 15, 15)
                                    : const Color.fromARGB(255, 33, 34, 34);
                              },
                            ),
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _buildImage(user.imgBase64),
                                ),
                              ),
                              DataCell(Text(user.id.toString())),
                              DataCell(Text(user.username)),
                              DataCell(Text(user.firstName ?? 'N/A')),
                              DataCell(Text(user.lastName ?? 'N/A')),
                              DataCell(Text(user.gender ?? 'N/A')),
                              DataCell(Text(DateFormat('yyyy-MM-dd').format(user.birthdate).toString())),
                              DataCell(Text(user.email)),
                              DataCell(Text(user.address ?? 'No address provided')),
                              DataCell(Text(user.neighborhood ?? 'N/A')),
                              DataCell(Text(user.phone1 ?? 'N/A')),
                              DataCell(Text(user.phone2 ?? 'N/A')),
                              DataCell(Text(user.state ?? 'N/A')),
                              DataCell(
                                Row(
                                  children: [
                                    Tooltip(
                                      message: 'Add Bank Details',
                                      child: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                ),
                                                child: SizedBox(
                                                  width: 600,
                                                  height: 400,
                                                  child: ManageBankDetailsPage(
                                                    service: BankDetailsService(
                                                      baseUrl: 'http://localhost:5000',
                                                      userID: user.id!, 
                                                      username: '${user.firstName} ${user.lastName}',
                                                    ), 
                                                    userID: user.id!,
                                                    username: '${user.firstName} ${user.lastName}',
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
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

}
