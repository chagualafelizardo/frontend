import 'package:app/ui/veiculo/AddNewVeiculoForm.dart' as add_form;
import 'package:app/ui/veiculo/EditVeiculoForm.dart' as edit_form;
import 'package:flutter/material.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/models/Veiculo.dart';
import 'package:app/models/VeiculoAdd.dart';
import 'package:app/ui/veiculo/ViewVeiculoPage.dart';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageVeiculosPage extends StatefulWidget {
  const ManageVeiculosPage({super.key});

  @override
  _ManageVeiculosPageState createState() => _ManageVeiculosPageState();
}

class _ManageVeiculosPageState extends State<ManageVeiculosPage> {
  final VeiculoService veiculoService = VeiculoService(dotenv.env['BASE_URL']!);
  final VeiculoServiceAdd veiculoServiceAdd =
      VeiculoServiceAdd(dotenv.env['BASE_URL']!);

  List<Veiculo> _veiculos = [];
  List<Veiculo> _filteredVeiculos = []; // Lista filtrada de veículos

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = ''; // Variável para armazenar a consulta de pesquisa
  bool _isGridView = true;

  
  @override
  void initState() {
    super.initState();
    _fetchVeiculos();
  }

  Future<void> _fetchVeiculos() async {
  try {
    List<Veiculo> veiculos = await veiculoService.fetchVeiculos(_currentPage, _itemsPerPage);
    print('Veiculos fetched successfully: $veiculos');
    setState(() {
      _veiculos = veiculos;
      // Sempre que os veículos são atualizados, atualizamos também a lista filtrada
      _filteredVeiculos = List.from(veiculos); // Garante que a lista filtrada comece com todos os veículos
    });
  } catch (e) {
    print('Error fetching vehicles: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch vehicles: $e')),
    );
  }
}


  // Função para filtrar os veículos pela matrícula
  void _filterVehicles(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        // Se a pesquisa estiver vazia, mostrar todos os veículos
        _filteredVeiculos = List.from(_veiculos); // Garante que todos os veículos sejam exibidos
      } else {
        // Se houver uma consulta, filtra os veículos pela matrícula
        _filteredVeiculos = _veiculos.where((veiculo) {
          return veiculo.matricula.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

    void _openAddVeiculoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return add_form.AddNewVeiculoForm(
          veiculoServiceAdd: veiculoServiceAdd,
          onVeiculoAdded: _fetchVeiculos,
        );
      },
    );
  }

  void _openEditVeiculoDialog(Veiculo veiculo) {
    VeiculoAdd veiculoAdd = VeiculoAdd(
      id: veiculo.id,
      matricula: veiculo.matricula,
      marca: veiculo.marca,
      modelo: veiculo.modelo,
      ano: veiculo.ano,
      cor: veiculo.cor,
      numChassi: veiculo.numChassi,
      numLugares: veiculo.numLugares,
      numMotor: veiculo.numMotor,
      numPortas: veiculo.numPortas,
      tipoCombustivel: veiculo.tipoCombustivel,
      state: veiculo.state,
      imagemBase64: veiculo.imagemBase64,
      rentalIncludesDriver: true, // Ajuste aqui se necessário
      createdAt: veiculo.createdAt,
      updatedAt: veiculo.updatedAt,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: edit_form.EditVeiculoForm(
            veiculoServiceAdd: VeiculoServiceAdd(
                dotenv.env['BASE_URL']!), // Substitua pelo seu serviço real
            veiculo: veiculoAdd,
            onVeiculoUpdated: () {
              // Atualize a lista de veículos após a edição
              setState(() {});
            },
          ),
        );
      },
    );
  }

  void _confirmDeleteVeiculo(Veiculo veiculo) {
    // Lógica para confirmar a exclusão
  }

  void _viewVeiculoDetails(Veiculo veiculo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vehicle Details'),
          content: ViewVeiculoPage(veiculo: veiculo),
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


  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchVeiculos();
    }
  }

  void _goToNextPage() {
    setState(() {
      _currentPage++;
    });
    _fetchVeiculos();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Vehicles'),
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
            onChanged: _filterVehicles,
            decoration: const InputDecoration(
              labelText: 'Search by Vehicle Info',
              hintText: 'Enter vehicle info',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),

          // Exibição de veículos no formato ListView ou GridView
          Expanded(
            child: _isGridView
                ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // Ajuste para 3 colunas
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredVeiculos.length,
                    itemBuilder: (context, index) {
                      Veiculo veiculo = _filteredVeiculos[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: _buildImage(veiculo.imagemBase64),
                              ),
                              Text(veiculo.matricula),
                              Text(veiculo.marca),
                              Text(veiculo.modelo),
                              Text(veiculo.ano.toString()),
                              // Adicione os outros detalhes do veículo aqui
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye),
                                    onPressed: () => _viewVeiculoDetails(veiculo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _openEditVeiculoDialog(veiculo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _confirmDeleteVeiculo(veiculo),
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
                          DataColumn(label: Text('Image')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Matricula')),
                          DataColumn(label: Text('Marca')),
                          DataColumn(label: Text('Modelo')),
                          DataColumn(label: Text('Ano')),
                          DataColumn(label: Text('Cor')),
                          DataColumn(label: Text('Num Chassi')),
                          DataColumn(label: Text('Num Lugares')),
                          DataColumn(label: Text('Num Motor')),
                          DataColumn(label: Text('Num Portas')),
                          DataColumn(label: Text('Tipo Combustível')),
                          DataColumn(label: Text('Rental Includes Driver')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _filteredVeiculos.asMap().entries.map((entry) {
                          int index = entry.key;
                          Veiculo veiculo = entry.value;

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
                                  child: _buildImage(veiculo.imagemBase64),
                                ),
                              ),
                              DataCell(Text(veiculo.id.toString())),
                              DataCell(Text(veiculo.matricula)),
                              DataCell(Text(veiculo.marca)),
                              DataCell(Text(veiculo.modelo)),
                              DataCell(Text(veiculo.ano.toString())),
                              DataCell(Text(veiculo.cor)),
                              DataCell(Text(veiculo.numChassi)),
                              DataCell(Text(veiculo.numLugares.toString())),
                              DataCell(Text(veiculo.numMotor)),
                              DataCell(Text(veiculo.numPortas.toString())),
                              DataCell(Text(veiculo.tipoCombustivel)),
                              DataCell(Text(veiculo.rentalIncludesDriver.toString())),
                              DataCell(Text(veiculo.state)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      onPressed: () => _viewVeiculoDetails(veiculo),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openEditVeiculoDialog(veiculo),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _confirmDeleteVeiculo(veiculo),
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
        onPressed: _openAddVeiculoDialog,
        child: const Icon(Icons.add),
      ),
  );
}
}
