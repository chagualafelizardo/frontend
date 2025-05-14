import 'package:app/models/DriveDeliver.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/services/DriveDeliverService.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/services/VehicleHistoryRentService.dart';
import 'package:app/ui/veiculo/ManageVehiclePriceRentHistoryPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/models/Veiculo.dart' as model_veiculo;


class PaymentAndDeliveryLocation extends StatefulWidget {
  final int reservaId;
  final int userId;
  final int veiculoId;

  const PaymentAndDeliveryLocation({
    Key? key,
    required this.reservaId,
    required this.userId,
    required this.veiculoId,
  }) : super(key: key);

  @override
  _PaymentAndDeliveryLocationState createState() => _PaymentAndDeliveryLocationState();
}

class _PaymentAndDeliveryLocationState extends State<PaymentAndDeliveryLocation> {
  final VehicleHistoryRentService _rentHistoryService = VehicleHistoryRentService(dotenv.env['BASE_URL']!);
  final ReservaService _reservaService =  ReservaService(dotenv.env['BASE_URL']!);
  final VeiculoService _veiculoService =  VeiculoService(dotenv.env['BASE_URL']!);

  bool _isLoadingRentValue = false;
  
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
  Set<Marker> _pickupMarkers = {};
  Set<Marker> _returnMarkers = {};

  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _returnSearchController = TextEditingController();

  String _pickupMapType = 'normal';
  String _returnMapType = 'normal';
  bool _isPickupSearching = false;
  bool _isReturnSearching = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initializeMap();
    _loadLatestRentValue();
  }

  Future<void> _loadLatestRentValue() async {
    setState(() => _isLoadingRentValue = true);

    try {
      final rentValue = await _rentHistoryService.getLatestRentValue(widget.veiculoId);
      
      if (rentValue != null && mounted) {
        setState(() {
          // Assume que rentValue é o double diretamente
          _amountController.text = rentValue.toStringAsFixed(2);
        });
      } else if (mounted) {
        setState(() {
          _amountController.text = '';
        });
      }
    } catch (e) {
      print('Error loading latest rent value: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load latest rent value: ${e.toString()}')),
        );
        _amountController.text = '';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRentValue = false);
      }
    }
  }


     Future<int?> _getVeiculoIdFromReserva(int reservaId) async {
        try {
          final response = await http.get(
            Uri.parse('${dotenv.env['BASE_URL']}/reservas/$reservaId'),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return data['veiculoID'];
          }
          return null;
        } catch (e) {
          print('Error fetching reserva details: $e');
          return null;
        }
      }
    
  Future<void> _initializeMap() async {
    await dotenv.load();
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

void _onPickupMapTap(LatLng position) {
  setState(() {
    // Atualiza o local de recolha
    _pickupLocation = position;
    _pickupMarkers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: position,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    };

    // Também atualiza o local de devolução com as mesmas coordenadas
    _returnLocation = position;
    _returnMarkers = {
      Marker(
        markerId: const MarkerId('return'),
        position: position,
        infoWindow: const InfoWindow(title: 'Return Location (same as pickup)'),
      ),
    };
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _searchAndMovePickupLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isPickupSearching = true);
    
    try {
      // First try with geocoding API
      try {
        List<Location> locations = await locationFromAddress(query);

        if (locations.isNotEmpty) {
          _updatePickupLocation(
            LatLng(locations.first.latitude, locations.first.longitude),
            query,
          );
          return;
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
      }

      // If not found, try with Places API
      await _searchWithPlacesAPI(query, isPickup: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isPickupSearching = false);
    }
  }

  void _openVeiculoPriceHistoryDialog(Veiculo veiculo) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: ManageVehicleHistoryPage(
              service: VehicleHistoryRentService(dotenv.env['BASE_URL']!),
              veiculoId: veiculo.id, // Passe o ID do veículo
            ),
          ),
        );
      },
    );
  }


  Future<void> _searchWithPlacesAPI(String query, {required bool isPickup}) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null) {
      debugPrint('Error: API key not found');
      throw Exception('Google Maps API key not configured');
    }
    
    try {
      final url = Uri.parse('${dotenv.env['BASE_URL_GOOGLE_MAPS_PLACES']}/pagamentoreserva/buscarlocalizacao?query=$query&key=$apiKey&language=pt&region=mz');

      debugPrint('Search URL: $url');
    
      final response = await http.get(url);
      final data = jsonDecode(response.body);
    
      debugPrint('API response: $data');
    
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final lat = result['geometry']['location']['lat'];
        final lng = result['geometry']['location']['lng'];
        final address = result['formatted_address'] ?? query;
      
        final latLng = LatLng(lat, lng);
        if (isPickup) {
          _updatePickupLocation(latLng, address);
        } else {
          _updateReturnLocation(latLng, address);
        }
      } else {
        debugPrint('API status: ${data['status']}');
        throw Exception(data['error_message'] ?? 'No results found');
      }
    } catch (e) {
      debugPrint('API call error: $e');
      rethrow;
    }
  }

  void _updatePickupLocation(LatLng latLng, String address) {
    debugPrint('Updating pickup location to: $latLng');
    debugPrint('Address: $address');
  
    setState(() {
      _pickupLocation = latLng;
      _pickupMarkers.clear();
      _pickupMarkers.add(Marker(
        markerId: const MarkerId('pickup_location'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    });
  
    _pickupMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );
  
    debugPrint('Marker added and camera moved');
  }

  Future<void> _searchAndMoveReturnLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isReturnSearching = true);
    
    try {
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        _updateReturnLocation(
          LatLng(locations.first.latitude, locations.first.longitude),
          query,
        );
        return;
      }

      await _searchWithPlacesAPI(query, isPickup: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found. Try another search.')),
      );
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isReturnSearching = false);
    }
  }

  void _updateReturnLocation(LatLng latLng, String address) {
    setState(() {
      _returnLocation = latLng;
      _returnMarkers.clear();
      _returnMarkers.add(Marker(
        markerId: const MarkerId('return_location'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Return Location',
          snippet: address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });
    
    _returnMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );
  }

  Future<void> _submitPayment() async {
  debugPrint('=== INICIANDO _submitPayment ===');
  
  if (!_formKey.currentState!.validate()) {
    debugPrint('Validação do formulário falhou');
    return;
  }

  if (_pickupLocation == null || _returnLocation == null) {
    debugPrint('Locais de pickup/return não selecionados');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select pickup and return locations')),
    );
    return;
  }

  try {
    final String? notes = _notesController.text.isNotEmpty 
        ? _notesController.text 
        : null;
    debugPrint('Notas: ${notes ?? "null"}');

    // Log dos valores antes de criar o pagamento
    debugPrint('Valores do pagamento:');
    debugPrint('valorTotal: ${_amountController.text}');
    debugPrint('data: ${_dateController.text}');
    debugPrint('userId: ${widget.userId}');
    debugPrint('reservaId: ${widget.reservaId}');

  /* Registar o pagamento da reserva */
    final payment = PagamentoReserva(
      valorTotal: double.parse(_amountController.text),
      data: DateTime.parse(_dateController.text),
      obs: notes,
      userId: widget.userId,
      reservaId: widget.reservaId,
    );

    debugPrint('=== ANTES DE CHAMAR createPagamentoReserva ===');
    debugPrint('Pagamento.toJson(): ${payment.toJson()}');
    
    await _paymentService.createPagamentoReserva(payment);
    debugPrint('Pagamento criado com sucesso');

    /* Processo de Pagamento Confirmacao  */
      await _reservaService.updateIsPaid(
          reservaId: widget.reservaId,
          isPaid: 'Paid',
    );

    /* Iniciar o registo dos locais de entrega e recolha do veiculo */
      final driveDeliver = DriveDeliver(
        date: DateTime.now(),
        deliver: 'Yes',
        pickupLatitude: _pickupLocation?.latitude,
        pickupLongitude: _pickupLocation?.longitude,
        dropoffLatitude: _returnLocation?.latitude,
        dropoffLongitude: _returnLocation?.longitude,
        locationDescription: notes,
        reservaId: widget.reservaId,
      );

      debugPrint('Sending driveDeliver: ${driveDeliver.toJson()}');

      await _driveDeliverService.createDriveDeliver(driveDeliver);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment and locations registered successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('=== ERRO CAPTURADO ===');
      debugPrint('Tipo do erro: ${e.runtimeType}');
      debugPrint('Mensagem: ${e.toString()}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment and Locations (Reservation #${widget.reservaId}, for user #${widget.userId}, and vehicle #${widget.veiculoId},)'),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        prefixText: 'MZN ',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingRentValue
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter the amount';
                        final parsed = double.tryParse(value.replaceAll(',', '.'));
                        if (parsed == null) return 'Invalid amount';
                        return null;
                      },
                      onSaved: (value) {
                        _amountController.text = value!.replaceAll(',', '.');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'View vehicle price rent history',
                    child: Material(
                      color: Colors.orangeAccent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        // onTap: () => _openVeiculoPriceHistoryDialog(model_veiculo.Veiculo as Veiculo),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.list_alt, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
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
                          decoration: InputDecoration(
                            hintText: 'Search (e.g. Hotel, Restaurant, etc.)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isPickupSearching 
                                ? const CircularProgressIndicator()
                                : null,
                            border: const OutlineInputBorder(),
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
                                child: Column(
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: 'pickup_normal',
                                      onPressed: () => setState(() => _pickupMapType = 'normal'),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.map,
                                        color: _pickupMapType == 'normal' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Normal map',
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      heroTag: 'pickup_hybrid',
                                      onPressed: () => setState(() => _pickupMapType = 'hybrid'),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.satellite,
                                        color: _pickupMapType == 'hybrid' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Hybrid map',
                                    ),
                                  ],
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
                          decoration: InputDecoration(
                            hintText: 'Search (e.g. Mall, Airport, etc.)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isReturnSearching 
                                ? const CircularProgressIndicator()
                                : null,
                            border: const OutlineInputBorder(),
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
                                child: Column(
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: 'return_normal',
                                      onPressed: () => setState(() => _returnMapType = 'normal'),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.map,
                                        color: _returnMapType == 'normal' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Normal map',
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      heroTag: 'return_hybrid',
                                      onPressed: () => setState(() => _returnMapType = 'hybrid'),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.satellite,
                                        color: _returnMapType == 'hybrid' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Hybrid map',
                                    ),
                                  ],
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
                child: const Text('Register Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
