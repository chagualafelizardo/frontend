import 'package:flutter/material.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/RoleService.dart';
import 'AddNewRoleForm.dart';
import 'EditRoleForm.dart';

class AddRolePage extends StatefulWidget {
  const AddRolePage({super.key});

  @override
  _AddRolePageState createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRolePage> {
  final RoleService roleService =
      RoleService('http://localhost:5000'); // Replace with your URL
  List<Role> _roles = []; // List to store roles
  int _rowsPerPage = 10; // Number of rows per page
  int _currentPage = 0; // Current page index

  @override
  void initState() {
    super.initState();
    _fetchRoles(); // Load roles on initialization
  }

  Future<void> _fetchRoles() async {
    List<Role>? roles = await roleService.getRoles();
    setState(() {
      _roles = roles ?? [];
    });
  }

  void _openAddRoleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: AddNewRoleForm(
            roleService: roleService,
            onRoleAdded: _fetchRoles,
          ),
        );
      },
    );
  }

  void _openEditRoleDialog(Role role) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: EditRoleForm(
            roleService: roleService,
            role: role,
            onRoleUpdated: _fetchRoles,
          ),
        );
      },
    );
  }

  Future<void> _deleteRole(Role role) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              Text('Are you sure you want to delete the role "${role.name}"?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Returns true if confirmed
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Returns false if canceled
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      bool success = await roleService.deleteRole(role.id!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role "${role.name}" deleted successfully!')),
        );
        // Ensure the list is updated after deletion
        setState(() {
          _roles.removeWhere((r) => r.id == role.id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete role. Please try again.')),
        );
      }
    }
  }

  void _viewRole(Role role) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Role Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to the left
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${role.id}'),
              Text('Name: ${role.name}'),
              Text('Created At: ${role.createdAt.toString()}'),
              Text('Updated At: ${role.updatedAt.toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _changeRowsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _rowsPerPage = value;
        _currentPage = 0; // Reset to the first page
      });
    }
  }

  List<Role> get _paginatedRoles {
    int start = _currentPage * _rowsPerPage;
    int end = start + _rowsPerPage;
    return _roles.sublist(start, end > _roles.length ? _roles.length : end);
  }

  void _nextPage() {
    if ((_currentPage + 1) * _rowsPerPage < _roles.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roles'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: _rowsPerPage,
                  items: [10, 20, 30, 50, 100].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value rows'),
                    );
                  }).toList(),
                  onChanged: _changeRowsPerPage,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousPage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Created At')),
                    DataColumn(label: Text('Updated At')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _paginatedRoles
                      .asMap()
                      .map((index, role) {
                        Color rowColor =
                            index.isEven ? const Color.fromARGB(255, 10, 10, 10) : Colors.white;

                        return MapEntry(
                          index,
                          DataRow(
                            color: WidgetStateProperty.all(
                                rowColor), // Row color
                            cells: [
                              DataCell(Text(role.id.toString())),
                              DataCell(Text(role.name)),
                              DataCell(Text(role.createdAt.toString())),
                              DataCell(Text(role.updatedAt.toString())),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _viewRole(role),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _openEditRoleDialog(role),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteRole(role),
                                  ),
                                ],
                              )),
                            ],
                          ),
                        );
                      })
                      .values
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddRoleDialog,
        tooltip: 'Add New Role',
        child: const Icon(Icons.add),
      ),
    );
  }
}
