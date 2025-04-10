import 'package:app/ui/user/EditUserForm.dart';
import 'package:flutter/material.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/services/UserService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'AddNewUserForm.dart';
import 'dart:typed_data';
import 'dart:convert';


class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final UserService userService = UserService(dotenv.env['BASE_URL']!);
  List<UserBase64> _users = [];
  List<UserBase64> _filteredUsers = [];
  String _searchQuery = ''; // Variável para armazenar a consulta de pesquisa
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

// Função para filtrar os usuários
  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredUsers = List.from(_users); // Se a pesquisa estiver vazia, mostrar todos os usuários
      } else {
        _filteredUsers = _users.where((user) {
          return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (user.firstName.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                 (user.lastName.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList(); // Filtra pelos campos username, firstName ou lastName
      }
    });
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
        _filteredUsers = List.from(_users); // Inicialmente, a lista filtrada é igual à lista completa
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

  void _openAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNewUserForm(
          userService: userService,
          onUserAdded: _fetchUsers,
        );
      },
    );
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
          height: 30,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Volta para a tela anterior
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de pesquisa
            TextField(
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                labelText: 'Search by Name or Username',
                hintText: 'Enter name or username',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            
            // Exibição de usuários no formato ListView ou GridView
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // Reduz o número de colunas para 3
                        crossAxisSpacing: 8, // Reduz o espaçamento horizontal
                        mainAxisSpacing: 8, // Reduz o espaçamento vertical
                      ),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        UserBase64 user = _filteredUsers[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 40, // Reduz o tamanho da imagem
                                  height: 40, // Reduz o tamanho da imagem
                                  child: _buildImage(user.imgBase64),
                                ),
                                Text(user.username, style: TextStyle(fontSize: 12)),
                                Text(user.firstName ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(user.lastName ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(user.gender ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(DateFormat('yyyy-MM-dd').format(user.birthdate).toString(), style: TextStyle(fontSize: 12)),
                                Text(user.email, style: TextStyle(fontSize: 12)),
                                Text(user.address ?? 'No address provided', style: TextStyle(fontSize: 12)),
                                Text(user.neighborhood ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(user.phone1 ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(user.phone2 ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Text(user.password ?? 'No password', style: TextStyle(fontSize: 12)),
                                Text(user.state ?? 'N/A', style: TextStyle(fontSize: 12)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        final selectedUser = user;
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return EditUserForm(
                                              userService: userService,
                                              user: selectedUser,
                                              onUserUpdated: _fetchUsers,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _confirmDeleteUser(user);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () {
                                        _viewUser(user);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                            DataColumn(label: Text('Password')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredUsers.asMap().entries.map((entry) {
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
                                DataCell(Text(user.password ?? 'No password')),
                                DataCell(Text(user.state ?? 'N/A')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final selectedUser = user;
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return EditUserForm(
                                                userService: userService,
                                                user: selectedUser,
                                                onUserUpdated: _fetchUsers,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _confirmDeleteUser(user);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          _viewUser(user); // Certifique-se que 'user' está disponível neste contexto
                                        },
                                        tooltip: 'View user details', // Adicione um tooltip para melhor UX
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
