// Adicionei o pacote para visualização de documentos
import 'dart:convert';

import 'package:app/models/AtendimentoDocument.dart';
import 'package:app/models/AtendimentoItem.dart';
import 'package:app/models/ItensEntrega.dart';
import 'package:app/services/AtendimentoDocumentService.dart';
import 'package:app/services/AtendimentoItemService.dart';
import 'package:app/services/ItensEntregaService.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/services/ItemService.dart';
import 'package:app/models/Item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para manipular bytes

class AtendimentoForm extends StatefulWidget {
  final Atendimento atendimento;
  final Reserva reserva;
  final Function(DateTime dataSaida, DateTime dataChegada, String destino,
      double kmInicial) onProcessStart;

  const AtendimentoForm({
    super.key,
    required this.atendimento,
    required this.onProcessStart,
    required this.reserva,
  });

  @override
  _AtendimentoFormState createState() => _AtendimentoFormState();
}

class _AtendimentoFormState extends State<AtendimentoForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dataSaida;
  DateTime? _dataChegada;
  String? _destino;
  double? _kmInicial;
  double? _kmFinal;
  final AtendimentoService _atendimentoService =
      AtendimentoService(dotenv.env['BASE_URL']!);
  final ItemService _itemService = ItemService(dotenv.env['BASE_URL']!);

  List<Item> _items = [];
  Map<String, bool> _itemChecklist = {};
  bool _isLoading = true;
  late TabController _tabController;
  final ItensEntregaService _itensEntregaService = ItensEntregaService(dotenv.env['BASE_URL']!);
  List<ItensEntrega> _itensEntrega = [];
  ItensEntrega? _selectedItem;

  // Lista para armazenar documentos selecionados
  final List<Map<String, dynamic>> _selectedDocuments = [];

  @override
  void initState() {
    super.initState();
    _destino = widget.reserva.destination;
    _tabController = TabController(length: 3, vsync: this);
    _fetchItems();
     _fetchItensEntrega();
  }

  void _fetchItems() async {
    try {
      List<Item> fetchedItems = await _itemService.fetchItems(1, 100);
      setState(() {
        _items = fetchedItems;
        _itemChecklist = {for (var item in _items) item.item ?? '': false};
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching items: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _fetchItensEntrega() async {
    try {
      List<ItensEntrega> itens = await _itensEntregaService.getAllItensEntrega();
      setState(() {
        _itensEntrega = itens;
      });
    } catch (e) {
      print('Erro ao buscar os itens de entrega: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao buscar os itens de entrega.')),
      );
    }
  }

  Future<void> addAtendimentoItems(
      List<String> checkedItems, int atendimentoID) async {
    AtendimentoItemService atendimentoItemService = AtendimentoItemService(
        dotenv.env['BASE_URL']!); // Substitua pela URL correta

    for (String itemDescription in checkedItems) {
      final atendimentoItem = AtendimentoItem(
        atendimentoID: atendimentoID,
        itemDescription: itemDescription,
      );

      try {
        print('Enviando: ${atendimentoItem.toJson()}');
        await atendimentoItemService.addAtendimentoItem(atendimentoItem);
        print('Item adicionado com sucesso: $itemDescription');
      } catch (e) {
        print('Erro ao adicionar item: $e');
      }
    }
  }

  Future<void> addAtendimentoDocuments(
      List<Map<String, dynamic>> documents, int atendimentoID) async {
    AtendimentoDocumentService atendimentoDocumentService =
        AtendimentoDocumentService(
            dotenv.env['BASE_URL']!); // Substitua pela URL correta

    for (var doc in documents) {
      final atendimentoDocument = AtendimentoDocument(
        atendimentoID: atendimentoID,
        itemDescription: doc['itemDescription'],
        image: doc['image'] as Uint8List?, // Imagem no formato Uint8List
      );

      try {
        print('Enviando documento: ${atendimentoDocument.toJson()}');
        await atendimentoDocumentService
            .addAtendimentoDocument(atendimentoDocument);
        print('Documento adicionado com sucesso: ${doc['itemDescription']}');
      } catch (e) {
        print('Erro ao adicionar documento: $e');
      }
    }
  }

   @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Atendimento Form'),  // Título da barra
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Item Checklist'), // 1ª Aba: Item Checklist
                  Tab(text: 'Document Upload'), // 2ª Aba: Document Upload
                  Tab(
                      text:
                          'Service Registration'), // 3ª Aba: Service Registration
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildItemChecklist(), // 1ª Aba: Item Checklist
                    _buildDocumentUploadForm(), // 2ª Aba: Document Upload
                    _buildAtendimentoForm(), // 3ª Aba: Service Registration
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtendimentoForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Start vehicle rental process',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Reserva: ${widget.reserva.id}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Numbers of days: ${widget.reserva.numberOfDays}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Destination: ${widget.reserva.destination}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildKmField('Initial Kilometers',
              (value) => _kmInicial = double.tryParse(value!)),
          // _buildKmField(
          //     'Final Kilometers', (value) => _kmFinal = int.tryParse(value!)),
          _buildDateField('Departure Date', _dataSaida,
              (pickedDate) => _dataSaida = pickedDate),
          _buildDateField('Arrival Date', _dataChegada,
              (pickedDate) => _dataChegada = pickedDate),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                // Preparar a lista de documents / imagens para Adicionar
                List<Map<String, dynamic>> selectedDocuments =
                    _selectedDocuments
                        .where((doc) =>
                            doc['type'] != null && doc['bytes'] != null)
                        .map((doc) => {
                              'itemDescription':
                                  doc['type'], // Campo da descrição
                              'image': doc['bytes'], // Bytes da imagem
                            })
                        .toList();

                // Preparar a lista de Itens selecionados para Adicionar
                List<String> selectedItems = _itemChecklist.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();

                // Adicionar na tabela principal Atendimento
                _atendimentoService
                    .addCompleteAtendimento(
                  DateTime
                      .now(), // Se necessário, substitua por um valor apropriado
                  dataSaida: _dataSaida!,
                  dataChegada: _dataChegada!,
                  destino: _destino!,
                  kmInicial: _kmInicial!,
                  reserveID: widget.reserva.id,
                  checkedItems: selectedItems,
                  documents: selectedDocuments, // Adiciona os documentos
                )
                    .then((_) async {
                  widget.onProcessStart(
                    _dataSaida!,
                    _dataChegada!,
                    _destino!,
                    _kmInicial!,
                  );

                  // Exibindo uma mensagem de sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'The service for this vehicle has already started.')),
                  );

                  Navigator.of(context).pop();
                }).catchError((error) {
                  debugPrint('Error adding service: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to start process: $error')),
                  );
                });
                /**/
              }
            },
            child: const Text('Start Process'),
          ),
        ],
      ),
    );
  }

  Widget _buildKmField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onSaved: onSaved,
      validator: (value) => value!.isEmpty ? 'Please enter the $label' : null,
    );
  }

  Widget _buildDateField(
      String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      readOnly: true,
      controller: TextEditingController(
        text: selectedDate == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(selectedDate),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        setState(() {
          onDateSelected(pickedDate!);
        });
            },
      validator: (value) => value!.isEmpty ? 'Please select the $label' : null,
    );
  }

  Widget _buildItemChecklist() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        bool isEvenIndex = index.isEven;

        return Container(
          color: isEvenIndex ? const Color.fromARGB(255, 97, 95, 95) : const Color.fromARGB(255, 12, 12, 12),
          child: CheckboxListTile(
            title: Text(item.item ?? ''),
            value: _itemChecklist[item.item ?? ''],
            controlAffinity:
                ListTileControlAffinity.leading, // Checkbox à esquerda
            onChanged: (value) {
              setState(() {
                _itemChecklist[item.item ?? ''] = value!;
              });
            },
          ),
        );
      },
    );
  }

Widget _buildDocumentUploadForm() {
  return Column(
    children: [
      const Text(
        'Upload Document',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<ItensEntrega>(
              value: _selectedItem,
              decoration: const InputDecoration(labelText: 'Select Document Type'),
              items: _itensEntrega.map((item) {
                return DropdownMenuItem<ItensEntrega>(
                  value: item,
                  child: Text(item.item!),
                );
              }).toList(),
              onChanged: (ItensEntrega? newValue) {
                setState(() {
                  _selectedItem = newValue;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _selectedItem == null
                ? null
                : () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();

                    if (result != null && result.files.isNotEmpty) {
                      Uint8List? bytes = result.files.single.bytes;
                      String fileName = result.files.single.name;

                      String documentType = _selectedItem?.item ?? 'Unknown Type';

                      setState(() {
                        _selectedDocuments.add({
                          'type': documentType,
                          'name': fileName,
                          'bytes': bytes,
                        });

                        // Opcional: reseta o tipo selecionado após o upload
                        _selectedItem = null;
                      });
                    }
                  },
            child: const Text('Select Document'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          itemCount: _selectedDocuments.length,
          itemBuilder: (context, index) {
            final doc = _selectedDocuments[index];
            return Card(
              child: ListTile(
                title: Text(doc['name'] ?? 'Unknown Document'),
                subtitle: Text('Type: ${doc['type']} | Bytes length: ${doc['bytes'].length}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () {
                        setState(() {
                          _selectedDocuments.removeAt(index);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.preview),
                      onPressed: () {
                        _showDocumentPreview(doc['bytes']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}


  void _showDocumentPreview(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Preview'),
        content: Image.memory(bytes),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
