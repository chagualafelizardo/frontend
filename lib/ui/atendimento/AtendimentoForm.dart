import 'package:intl/intl.dart';
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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app/models/DriveDeliver.dart';
import 'package:app/services/DriveDeliverService.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

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

class _AtendimentoFormState extends State<AtendimentoForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dataSaida;
  DateTime? _dataChegada;
  String? _destino;
  double? _kmInicial;
  double? _kmFinal;

  final AtendimentoService _atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  final ItemService _itemService = ItemService(dotenv.env['BASE_URL']!);

  List<Item> _items = [];
  Map<String, bool> _itemChecklist = {};
  bool _isLoading = true;
  late TabController _tabController;
  final ItensEntregaService _itensEntregaService = ItensEntregaService(dotenv.env['BASE_URL']!);
  List<ItensEntrega> _itensEntrega = [];
  ItensEntrega? _selectedItem;

  late DriveDeliverService _driveDeliverService;
  DriveDeliver? _driveDeliver;
  bool _isLoadingDriveDeliver = true;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  MapType _pickupMapType = MapType.normal;
  MapType _dropoffMapType = MapType.normal;

  // Lista para armazenar documentos selecionados
  final List<Map<String, dynamic>> _selectedDocuments = [];

  @override
  void initState() {
    super.initState();
    _destino = widget.reserva.destination;
    _tabController = TabController(length: 3, vsync: this);
    _driveDeliverService = DriveDeliverService();
    _fetchItems();
    _fetchItensEntrega();
    _fetchDriveDeliver();
  }


  // Metodo para enviar email
  void sendEmail() async {
  final smtpServer = gmail('felizardo.chaguala@gmail.com', 'Imediatamente'); // Seu e-mail e senha

  final message = Message()
    ..from = Address('fchaguala@yahoo.com.br', 'Felizardo Chaguala') // Remetente
    ..recipients.add('fchaguala@yahoo.com.br') // Destinatário
    ..subject = 'Confirmação do pagamento da Reserva' // Assunto
    ..text = 'Confirmação do pagamento da Reserva e entrega da viatura ao cliente!'; // Corpo do e-mail

  try {
    final sendReport = await send(message, smtpServer);
    print('E-mail enviado: ' + sendReport.toString());
  } catch (e) {
    print('Erro ao enviar: $e');
  }
}

  Future<DateTime?> _selectDateTime(
      BuildContext context, DateTime? initialDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate == null) return null;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
    );

    if (pickedTime == null) return pickedDate;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
  // Adicione este método para buscar os dados de DriveDeliver
  Future<void> _fetchDriveDeliver() async {
    try {
      List<DriveDeliver> driveDelivers = await _driveDeliverService.getAllDriveDelivers();
      DriveDeliver? deliverForReserva = driveDelivers.firstWhere(
        (deliver) => deliver.reservaId == widget.reserva.id,
      );

      setState(() {
        _driveDeliver = deliverForReserva;
        if (deliverForReserva.pickupLatitude != null && deliverForReserva.pickupLongitude != null) {
          _pickupLocation = LatLng(
            deliverForReserva.pickupLatitude!,
            deliverForReserva.pickupLongitude!,
          );
        }
        if (deliverForReserva.dropoffLatitude != null && deliverForReserva.dropoffLongitude != null) {
          _dropoffLocation = LatLng(
            deliverForReserva.dropoffLatitude!,
            deliverForReserva.dropoffLongitude!,
          );
        }
        _isLoadingDriveDeliver = false;
      });
        } catch (error) {
      debugPrint('Error fetching drive deliver: $error');
      setState(() {
        _isLoadingDriveDeliver = false;
      });
    }
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
                  Tab(text: 'Service Registration'), // 1ª Aba: Item Checklist
                  Tab(text: 'Item Checklist'), // 2ª Aba: Document Upload
                  Tab(
                      text:
                          'Document Upload'), // 3ª Aba: Service Registration
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildAtendimentoForm(), // 1ª Aba: Service Registration
                      _buildItemChecklist(), // 2ª Aba: Item Checklist
                    _buildDocumentUploadForm(), // 3ª Aba: Document Upload
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
  return SingleChildScrollView(
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Start vehicle rental process',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Informações da reserva
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Reserva: ${widget.reserva.id}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Numbers of days: ${widget.reserva.numberOfDays}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Destination: ${widget.reserva.destination}',
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          
          // Mapas de localização
          Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Delivery Locations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 8),
          _isLoadingDriveDeliver
              ? const CircularProgressIndicator()
              : _buildLocationMaps(),
          const SizedBox(height: 16),
          
          // Campos do formulário
          _buildKmField('Initial Kilometers',
              (value) => _kmInicial = double.tryParse(value!)),
          const SizedBox(height: 16),
          _buildDateField('Departure Date & Time', _dataSaida,
              (pickedDateTime) => _dataSaida = pickedDateTime),
          const SizedBox(height: 16),
          _buildDateField('Arrival Date & Time', _dataChegada,
              (pickedDateTime) => _dataChegada = pickedDateTime),
          const SizedBox(height: 16),
          
          // Botão de submissão
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                List<Map<String, dynamic>> selectedDocuments = _selectedDocuments
                    .where((doc) => doc['type'] != null && doc['bytes'] != null)
                    .map((doc) => {
                          'itemDescription': doc['type'],
                          'image': doc['bytes'],
                        })
                    .toList();

                List<String> selectedItems = _itemChecklist.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();

                _atendimentoService
                    .addCompleteAtendimento(
                  DateTime.now(),
                  dataSaida: _dataSaida!,
                  dataChegada: _dataChegada!,
                  destino: _destino!,
                  kmInicial: _kmInicial!,
                  reserveID: widget.reserva.id,
                  checkedItems: selectedItems,
                  documents: selectedDocuments,
                )
                    .then((_) async {
                  widget.onProcessStart(
                    _dataSaida!,
                    _dataChegada!,
                    _destino!,
                    _kmInicial!,
                  );

                // Chamar o metodo para enviar os e-mail
                sendEmail();

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
              }
            },
            child: const Text('Start Process'),
          ),
        ],
      ),
    ),
  );
}

@override
Widget _buildLocationMaps() {
  return Column(
    children: [
      const SizedBox(height: 8),
      Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 73, 72, 72),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _driveDeliver?.locationDescription ?? 'No location description',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 300,
        child: Row(
          children: [
            // Mapa de Pickup
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _pickupMapType == MapType.normal
                                ? Icons.satellite
                                : Icons.map,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _pickupMapType = _pickupMapType == MapType.normal
                                  ? MapType.hybrid
                                  : MapType.normal;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _pickupLocation == null
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('No pickup location data'),
                              ),
                            )
                          : GoogleMap(
                              mapType: _pickupMapType,
                              initialCameraPosition: CameraPosition(
                                target: _pickupLocation!,
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: _pickupLocation!,
                                  infoWindow: InfoWindow(
                                    title: 'Pickup Location',
                                    snippet: _driveDeliver?.deliver ?? '',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue,
                                  ),
                                ),
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Mapa de Dropoff
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dropoff Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _dropoffMapType == MapType.normal
                                ? Icons.satellite
                                : Icons.map,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _dropoffMapType = _dropoffMapType == MapType.normal
                                  ? MapType.hybrid
                                  : MapType.normal;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _dropoffLocation == null
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('No dropoff location data'),
                              ),
                            )
                          : GoogleMap(
                              mapType: _dropoffMapType,
                              initialCameraPosition: CameraPosition(
                                target: _dropoffLocation!,
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('dropoff'),
                                  position: _dropoffLocation!,
                                  infoWindow: InfoWindow(
                                    title: 'Dropoff Location',
                                    snippet: _driveDeliver?.deliver ?? '',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
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

  Widget _buildDateField(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: selectedDate == null
            ? ''
            : DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
      ),
      onTap: () async {
        DateTime? pickedDateTime = await _selectDateTime(context, selectedDate);
        if (pickedDateTime != null) {
          setState(() {
            onDateSelected(pickedDateTime);
          });
        }
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
