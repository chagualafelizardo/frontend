import 'package:app/models/Role.dart';
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
  bool _isLoading = false;
  bool _hasError = false;
  
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
    // 1. Ativa estado de loading
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final List<dynamic> userJsonList = await userService.getUsers();
      final List<UserBase64> usersWithRoles = [];

      // 2. Processa cada usuário com tratamento individual de erros
      for (var userJson in userJsonList) {
        try {
          if (userJson is! Map<String, dynamic>) {
            debugPrint('Invalid user format: ${userJson.runtimeType}');
            continue;
          }

          final user = UserBase64.fromJson(userJson);
          List<Role> roles = [];

          // 3. Tenta obter roles com fallback
          try {
            roles = await userService.getUserRoles(user.id);
          } catch (e) {
            debugPrint('Error fetching roles for user ${user.id}: $e');
            if (userJson['roles'] != null && userJson['roles'] is List) {
              roles = (userJson['roles'] as List)
                  .whereType<Map<String, dynamic>>() // Filtra apenas Maps válidos
                  .map((r) => Role.fromJson(r))
                  .toList();
            }
          }

          usersWithRoles.add(
            UserBase64(
              id: user.id,
              username: user.username,
              firstName: user.firstName,
              lastName: user.lastName,
              gender: user.gender,
              birthdate: user.birthdate,
              email: user.email,
              address: user.address,
              neighborhood: user.neighborhood,
              phone1: user.phone1,
              phone2: user.phone2,
              password: user.password,
              state: user.state,
              imgBase64: user.imgBase64,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              roles: roles.isNotEmpty ? roles : null,
            )
          );
        } catch (e) {
          debugPrint('Error processing user: $e');
          // Continua para o próximo usuário mesmo se este falhar
        }
      }

      // 4. Atualiza estado apenas se o widget ainda estiver montado
      if (mounted) {
        setState(() {
          _users = usersWithRoles;
          _filteredUsers = List.from(_users);
        });
      }

    } catch (e, stackTrace) {
      debugPrint('Error fetching users: $e\n$stackTrace');
      
      // 5. Mostra feedback de erro se o widget ainda estiver montado
      if (mounted) {
        setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load users'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchUsers,
          ),
        ),
      );
    }
  } finally {
    // 6. Desativa loading sempre
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        content: Text('Are you sure you want to delete User "${user.username}"?'),
        actions: [
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
    setState(() => _isLoading = true); // Ativa o loading
    
    try {
      await userService.deleteUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "${user.username}" deleted successfully!')),
      );
      await _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Desativa o loading
      }
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
          Navigator.of(context).pop();
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
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: _filterUsers,
                decoration: const InputDecoration(
                  labelText: 'Search by Name or Username',
                  hintText: 'Enter name or username',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: _isLoading && _users.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredUsers.isEmpty
                          ? const Center(child: Text('No users found'))
                          : _isGridView
                              ? GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
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
                                              width: 40,
                                              height: 40,
                                              child: _buildImage(user.imgBase64),
                                            ),
                                            Text(user.username, style: const TextStyle(fontSize: 12)),
                                            Text(user.firstName ?? 'N/A', style: const TextStyle(fontSize: 12)),
                                            Text(user.lastName ?? 'N/A', style: const TextStyle(fontSize: 12)),
                                            Text(user.gender ?? 'N/A', style: const TextStyle(fontSize: 12)),
                                            Text(DateFormat('yyyy-MM-dd').format(user.birthdate).toString(), style: const TextStyle(fontSize: 12)),
                                            Text(user.email, style: const TextStyle(fontSize: 12)),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Tooltip(
                                                  message: 'View user details',
                                                  child: Material(
                                                    color: Colors.blueAccent,
                                                    shape: const CircleBorder(),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(50),
                                                      onTap: () => _viewUser(user),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Icon(Icons.visibility, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Tooltip(
                                                  message: 'Edit user',
                                                  child: Material(
                                                    color: Colors.orangeAccent,
                                                    shape: const CircleBorder(),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(50),
                                                      onTap: () {
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
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Icon(Icons.edit, color: Colors.white),  // ← CORRIGIDO
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Tooltip(
                                                  message: 'Delete user',
                                                  child: Material(
                                                    color: Colors.redAccent,
                                                    shape: const CircleBorder(),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(50),
                                                      onTap: () => _confirmDeleteUser(user),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Icon(Icons.delete, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
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
                                        DataColumn(label: Text('Image')),
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Username')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Birthdate')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: _filteredUsers.map((user) {
                                        return DataRow(
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
                                            DataCell(Text('${user.firstName} ${user.lastName}')),
                                            DataCell(Text(user.email)),
                                            DataCell(Text(DateFormat('yyyy-MM-dd').format(user.birthdate))),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility, size: 20),
                                                    onPressed: () => _viewUser(user),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 20),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => EditUserForm(
                                                          userService: userService,
                                                          user: user,
                                                          onUserUpdated: _fetchUsers,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                                    onPressed: () => _confirmDeleteUser(user),
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
              ),
            ],
          ),
        ),
        if (_isLoading && _users.isNotEmpty)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _openAddUserDialog,
      child: const Icon(Icons.add),
    ),
  );
}
}
