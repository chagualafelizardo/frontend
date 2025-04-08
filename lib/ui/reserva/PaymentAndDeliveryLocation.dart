import 'package:app/models/DriveDeliver.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/services/DriveDeliverService.dart';
import 'package:app/services/UserService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class PaymentAndDeliveryLocation extends StatefulWidget {
  final int reservaId;
  final int userId;

  const PaymentAndDeliveryLocation({
    Key? key,
    required this.reservaId,
    required this.userId,
  }) : super(key: key);

  @override
  _PaymentAndDeliveryLocationState createState() => _PaymentAndDeliveryLocationState();
}

class _PaymentAndDeliveryLocationState extends State<PaymentAndDeliveryLocation> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PagamentoReservaService();
  final _driveDeliverService = DriveDeliverService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  LatLng? _pickupLocation;
  LatLng? _returnLocation;
  GoogleMapController? _pickupMapController;
  GoogleMapController? _returnMapController;
  final Set<Marker> _pickupMarkers = {};
  final Set<Marker> _returnMarkers = {};

  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _returnSearchController = TextEditingController();

  String? _userName;

  // Adicionar tipos de mapa
  String _pickupMapType = 'normal';
  String _returnMapType = 'normal';

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _pickupSearchController.dispose();
    _returnSearchController.dispose();
    super.dispose();
  }

  void _onPickupMapCreated(GoogleMapController controller) {
    _pickupMapController = controller;
  }

  void _onReturnMapCreated(GoogleMapController controller) {
    _returnMapController = controller;
  }

  void _onPickupMapTap(LatLng location) {
    setState(() {
      _pickupLocation = location;
      _pickupMarkers.clear();
      _pickupMarkers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    });
  }

  void _onReturnMapTap(LatLng location) {
    setState(() {
      _returnLocation = location;
      _returnMarkers.clear();
      _returnMarkers.add(
        Marker(
          markerId: const MarkerId('return_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Return Location'),
        ),
      );
    });
  }

  Future<void> _searchAndMovePickupLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        setState(() {
          _pickupLocation = latLng;
          _pickupMarkers.clear();
          _pickupMarkers.add(Marker(
            markerId: const MarkerId('pickup_location'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ));
        });

        _pickupMapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup location not found: $e')),
      );
    }
  }

  Future<void> _searchAndMoveReturnLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        setState(() {
          _returnLocation = latLng;
          _returnMarkers.clear();
          _returnMarkers.add(Marker(
            markerId: const MarkerId('return_location'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Return Location'),
          ));
        });

        _returnMapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return location not found: $e')),
      );
    }
  }

  Future<void> _submitPayment() async {
  if (!_formKey.currentState!.validate()) return;
  if (_pickupLocation == null || _returnLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select both pickup and return locations')),
    );
    return;
  }

  try {
    // Verifica se o campo de observações está vazio e trata adequadamente
    final String? notes = _notesController.text.isNotEmpty 
        ? _notesController.text 
        : null;

    final payment = PagamentoReserva(
      valorTotal: double.parse(_amountController.text),
      data: DateTime.parse(_dateController.text),
      obs: notes, // Usando a variável tratada
      userId: widget.userId,
      reservaId: widget.reservaId,
    );

    // Debug: Verifique os dados antes de enviar
    debugPrint('Dados do pagamento: ${payment.toJson()}');

    // Salvar pagamento no serviço
    await _paymentService.createPagamentoReserva(payment);

    // Salvar coordenadas de entrega
    final driveDeliver = DriveDeliver(
      date: DateTime.now(), // Data atual ou a data desejada
      deliver: 'Yes', // Você pode definir o estado conforme a lógica do seu app
      pickupLatitude: _pickupLocation?.latitude,
      pickupLongitude: _pickupLocation?.longitude,
      dropoffLatitude: _returnLocation?.latitude,
      dropoffLongitude: _returnLocation?.longitude,
      locationDescription: notes,
      reservaID: widget.reservaId, // Adicionando o campo reservaID
    );

    // Salvar as coordenadas de entrega no serviço
    await _driveDeliverService.createDriveDeliver(driveDeliver);

    // Mostrar mensagem de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment and delivery coordinates registered successfully!')),
    );

    // Fechar a tela após o sucesso
    Navigator.pop(context, true);
  } catch (e) {
    // Mostrar mensagem de erro caso ocorra
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error registering payment and delivery coordinates: $e')),
    );
    debugPrint('Erro completo: $e');
  }
}

@override
Widget build(BuildContext context) {
  final isWideScreen = MediaQuery.of(context).size.width > 700;

  return Scaffold(
    appBar: AppBar(
      title: Text('Payment & Location (Res#${widget.reservaId}, User#${widget.userId})'),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: 'MZN ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Select pickup and return locations:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            Flex(
              direction: isWideScreen ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pickupSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search pickup location',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _searchAndMovePickupLocation,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 350,
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: _onPickupMapCreated,
                              onTap: _onPickupMapTap,
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(-25.9689, 32.5699),
                                zoom: 12.0,
                              ),
                              markers: _pickupMarkers,
                              mapType: _pickupMapType == 'normal' ? MapType.normal : MapType.hybrid,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.map,
                                        color: _pickupMapType == 'normal' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _pickupMapType = 'normal';
                                        });
                                      },
                                      tooltip: 'Normal map',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.satellite,
                                        color: _pickupMapType == 'hybrid' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _pickupMapType = 'hybrid';
                                        });
                                      },
                                      tooltip: 'Hybrid map',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickupLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Lat: ${_pickupLocation!.latitude.toStringAsFixed(4)}, '
                            'Lng: ${_pickupLocation!.longitude.toStringAsFixed(4)}',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16, height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Return Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _returnSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search return location',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _searchAndMoveReturnLocation,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 350,
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: _onReturnMapCreated,
                              onTap: _onReturnMapTap,
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(-25.9689, 32.5699),
                                zoom: 12.0,
                              ),
                              markers: _returnMarkers,
                              mapType: _returnMapType == 'normal' ? MapType.normal : MapType.hybrid,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.map,
                                        color: _returnMapType == 'normal' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _returnMapType = 'normal';
                                        });
                                      },
                                      tooltip: 'Normal map',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.satellite,
                                        color: _returnMapType == 'hybrid' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _returnMapType = 'hybrid';
                                        });
                                      },
                                      tooltip: 'Hybrid map',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_returnLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Lat: ${_returnLocation!.latitude.toStringAsFixed(4)}, '
                            'Lng: ${_returnLocation!.longitude.toStringAsFixed(4)}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
                          const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitPayment,
                child: const Text('Submit Payment'),
              ),
          ],
        ),
      ),
    ),
  );
  }
}