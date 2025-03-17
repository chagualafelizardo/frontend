import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageAtendimentosPage extends StatefulWidget {
  const ManageAtendimentosPage({super.key});

  @override
  _ManageAtendimentosPageState createState() => _ManageAtendimentosPageState();
}

class _ManageAtendimentosPageState extends State<ManageAtendimentosPage> {
  final AtendimentoService _atendimentoService =
      AtendimentoService(dotenv.env['BASE_URL']!);

  List<Atendimento> _atendimentos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAtendimentos();
  }

  Future<void> _fetchAtendimentos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Atendimento> atendimentos =
          await _atendimentoService.fetchAtendimentos();
      setState(() {
        _atendimentos = atendimentos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching atendimentos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editAtendimento(int atendimentoId) async {
    Atendimento? atendimento = _atendimentos
        .firstWhere((atendimento) => atendimento.id == atendimentoId);
    // Lógica para editar o atendimento
  }

  Future<void> _viewDetails(int atendimentoId) async {
    print("View Details for Atendimento ID: $atendimentoId");
  }

  Future<void> _deleteAtendimento(int atendimentoId) async {
    // try {
    //   await _atendimentoService.deleteAtendimento(atendimentoId);
    //   setState(() {
    //     _atendimentos.removeWhere((atendimento) => atendimento.id == atendimentoId);
    //   });
    // } catch (e) {
    //   print('Error deleting atendimento: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Atendimentos'),
      ),
      body: _atendimentos.isEmpty && !_isLoading
          ? const Center(child: Text('No atendimentos found'))
          : ListView.builder(
              itemCount: _atendimentos.length,
              itemBuilder: (context, index) {
                var atendimento = _atendimentos[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Atendimento ID: ${atendimento.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Destination: ${atendimento.destino}'),
                        Text('Data de Saída: ${atendimento.dataSaida}'),
                        Text('Data de Chegada: ${atendimento.dataChegada}'),
                        Text('Km Inicial: ${atendimento.kmInicial}'),
                        Text('Km Final: ${atendimento.kmFinal}'),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _editAtendimento(atendimento.id!),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _viewDetails(atendimento.id!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _deleteAtendimento(atendimento.id!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
