import 'dart:convert';
import 'dart:math';

import 'package:app/models/DriveDeliver.dart';
import 'package:app/services/DriveDeliverService.dart';
import 'package:app/ui/reserva/PaymentAndDeliveryLocation.dart';
import 'package:app/ui/user/UserDetailsPage.dart';
import 'package:app/ui/veiculo/ViewVeiculoPage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:app/models/Reserva.dart' as user_model;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/models/Veiculo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class ManageReservationPaymentPage extends StatefulWidget {
  const ManageReservationPaymentPage({super.key});

  @override
  _ManageReservationPaymentPageState createState() => _ManageReservationPaymentPageState();
}

class _ManageReservationPaymentPageState extends State<ManageReservationPaymentPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PagamentoReservaService _pagamentoReservaService = PagamentoReservaService();
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Reservation Payments'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Confirmed Reservations'),
              Tab(text: 'Reservation Payments'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ReservationsTab(
              reservaService: _reservaService,
              pagamentoService: _pagamentoReservaService,
            ),
            PagamentosReservaTab(),
          ],
        ),
      ),
    );
  }
}

class ReservationsTab extends StatefulWidget {
  final ReservaService reservaService;
  final PagamentoReservaService pagamentoService;
  
  const ReservationsTab({
    super.key, 
    required this.reservaService,
    required this.pagamentoService,
  });

  @override
  _ReservationsTabState createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  int? _expandedReservationId;
  String _pickupMapType = 'normal';
  String _returnMapType = 'normal';
  bool _isPickupSearching = false;
  bool _isReturnSearching = false;
  LatLng? _pickupLocation;
  LatLng? _returnLocation;
  GoogleMapController? _pickupMapController;
  GoogleMapController? _returnMapController;
  Set<Marker> _pickupMarkers = {};
  Set<Marker> _returnMarkers = {};

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
    
  Widget _buildPaymentForm(Reserva reservation) {
  final _driveDeliverService = DriveDeliverService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _notesController = TextEditingController();
  final _pickupSearchController = TextEditingController();
  final _returnSearchController = TextEditingController();
  
  bool _isPickupSearching = false;
  bool _isReturnSearching = false;
  final isWideScreen = MediaQuery.of(context).size.width > 700;
  
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: Colors.grey[850], // Cor escura uniforme
      borderRadius: BorderRadius.circular(8),
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Texto branco para contraste
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white), // Texto branco
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: 'MZN ',
                prefixStyle: const TextStyle(color: Colors.white),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter the amount';
                if (double.tryParse(value) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dateController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Payment Date',
                labelStyle: const TextStyle(color: Colors.white70),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
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
            const SizedBox(height: 16),
            
            // Section Title
            const Text(
              'Select Delivery and Return Locations:',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Maps Row - Delivery and Return side by side
            Flex(
              direction: isWideScreen ? Axis.horizontal : Axis.vertical,
              children: [
                // Delivery Map Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Location:', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pickupSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search delivery point (e.g., Hotel, Address)',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                          suffixIcon: _isPickupSearching 
                              ? const CircularProgressIndicator()
                              : null,
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        onSubmitted: (query) async {
                          if (query.isEmpty) return;
                          setState(() => _isPickupSearching = true);
                          try {
                            await _searchAndMovePickupLocation(query);
                            if (_pickupLocation != null) {
                              setState(() {
                                _returnLocation = _pickupLocation;
                                _returnMarkers = {
                                  Marker(
                                    markerId: const MarkerId('return'),
                                    position: _pickupLocation!,
                                    infoWindow: const InfoWindow(title: 'Return Location (same as delivery)'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                  ),
                                };
                              });
                            }
                          } finally {
                            setState(() => _isPickupSearching = false);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 350,
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: _onPickupMapCreated,
                              onTap: (LatLng position) {
                                setState(() {
                                  _pickupLocation = position;
                                  _pickupMarkers = {
                                    Marker(
                                      markerId: const MarkerId('delivery'),
                                      position: position,
                                      infoWindow: const InfoWindow(title: 'Delivery Point'),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                    ),
                                  };
                                  if (_returnMarkers.isEmpty || _returnLocation == _pickupLocation) {
                                    _returnLocation = position;
                                    _returnMarkers = {
                                      Marker(
                                        markerId: const MarkerId('return'),
                                        position: position,
                                        infoWindow: const InfoWindow(title: 'Return Location (same as delivery)'),
                                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                      ),
                                    };
                                  }
                                });
                              },
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
                                    heroTag: 'delivery_normal',
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
                                    heroTag: 'delivery_hybrid',
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
                            'Delivery Point: Lat ${_pickupLocation!.latitude.toStringAsFixed(4)}, '
                            'Lng ${_pickupLocation!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(color: Colors.green[300]), // Verde mais claro
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: isWideScreen ? 16 : 0, height: isWideScreen ? 0 : 16),
                
                // Return Map Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Return Location:', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _returnSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search return point (e.g., Airport, Office)',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                          suffixIcon: _isReturnSearching 
                              ? const CircularProgressIndicator()
                              : null,
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
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
                              onTap: (LatLng position) {
                                setState(() {
                                  _returnLocation = position;
                                  _returnMarkers = {
                                    Marker(
                                      markerId: const MarkerId('return'),
                                      position: position,
                                      infoWindow: const InfoWindow(title: 'Return Point'),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                    ),
                                  };
                                });
                              },
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
                            'Return Point: Lat ${_returnLocation!.latitude.toStringAsFixed(4)}, '
                            'Lng ${_returnLocation!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(color: Colors.red[300]), // Vermelho mais claro
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedReservationId = null;
                    });
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_pickupLocation == null || _returnLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select both delivery and return locations'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        final payment = PagamentoReserva(
                          valorTotal: double.parse(_amountController.text),
                          data: DateTime.parse(_dateController.text),
                          obs: _notesController.text.isNotEmpty ? _notesController.text : null,
                          userId: reservation.userId,
                          reservaId: reservation.id,
                        );

                       /* Processo de Pagamento Confirmacao  */
                        await widget.pagamentoService.createPagamentoReserva(payment);
                        await widget.reservaService.updateIsPaid(
                          reservaId: reservation.id,
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
                            locationDescription: _notesController.text,
                            reservaId: reservation.id,
                          );

                          debugPrint('Sending driveDeliver: ${driveDeliver.toJson()}');

                          await _driveDeliverService.createDriveDeliver(driveDeliver);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment and locations registered successfully!')),
                          );

                          // Navigator.pop(context, true);

                        } catch (e) {
                          debugPrint('=== ERRO CAPTURADO ===');
                          debugPrint('Tipo do erro: ${e.runtimeType}');
                          debugPrint('Mensagem: ${e.toString()}');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                        /**************************************************/

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment and locations registered successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        setState(() {
                          _expandedReservationId = null;
                        });
                      } 
                  },
                  child: const Text('Register Payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reserva>>(
      future: widget.reservaService.getNotpaidReservas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No confirmed reservations found.'));
        }

        final confirmedReservations = snapshot.data!.where((reserva) => 
            reserva.state.toLowerCase() == 'confirmed').toList();
        
        if (confirmedReservations.isEmpty) {
          return const Center(child: Text('No confirmed reservations found.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatsHeader(confirmedReservations),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: confirmedReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = confirmedReservations[index];
                    final isExpanded = _expandedReservationId == reservation.id;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reservation #${reservation.id}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Chip(
                                  label: const Text(
                                    'CONFIRMED',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.person,
                                    'Customer:',
                                    ' ${reservation.userId} - ${reservation.user.firstName} ${reservation.user.lastName}',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                                  tooltip: 'View User Details',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailsPage(
                                          user: UserBase64.fromUser(reservation.user),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.directions_car,
                                    'Vehicle:',
                                    reservation.veiculo.matricula ?? 'N/A',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                                  tooltip: 'View Vehicle Details',
                                  onPressed: () {
                                    // Navigator.push...
                                  },
                                ),
                              ],
                            ),

                            _buildDetailRow(
                              Icons.calendar_today,
                              'Date:',
                              DateFormat('dd/MM/yyyy').format(reservation.date),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.payment,
                                    color: isExpanded ? Colors.grey : Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _expandedReservationId = isExpanded ? null : reservation.id;
                                    });
                                  },
                                  tooltip: 'Add Payment',
                                ),
                              ],
                            ),

                            if (isExpanded) _buildPaymentForm(reservation),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(List<Reserva> reservations) {
    final todayCount = reservations.where((r) => 
        DateUtils.isSameDay(r.date, DateTime.now())).length;
    final lastReservation = reservations.isNotEmpty 
        ? DateFormat('dd/MM/yyyy').format(reservations.last.date)
        : 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.list, 'Total Confirmed', reservations.length.toString()),
            _buildStatItem(Icons.calendar_today, 'Last Added', lastReservation),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class PagamentosReservaTab extends StatelessWidget {
  final PagamentoReservaService _pagamentoService = PagamentoReservaService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PagamentoReserva>>(
      future: _pagamentoService.fetchAllPagamentosReservas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reservation payments found.'));
        }

        final pagamentos = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header with statistics
                _buildStatsHeader(pagamentos),
                const SizedBox(height: 20),
                // Payments list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagamentos.length,
                  itemBuilder: (context, index) {
                    return _buildPagamentoCard(pagamentos[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(List<PagamentoReserva> pagamentos) {
    final total = pagamentos.fold(0.0, (sum, item) => sum + item.valorTotal);
    final lastPayment = pagamentos.isNotEmpty 
        ? DateFormat('dd/MM/yyyy').format(pagamentos.last.data)
        : 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.payments, 'Total Received', '${total.toStringAsFixed(2)} €'),
            _buildStatItem(Icons.list, 'Total Payments', pagamentos.length.toString()),
            _buildStatItem(Icons.calendar_today, 'Last Payment', lastPayment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPagamentoCard(PagamentoReserva pagamento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment #${pagamento.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Chip(
                  label: Text(
                    '${pagamento.valorTotal.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Linha do cliente com botão de detalhes
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    Icons.person, 
                    'Customer:', 
                    ' ${pagamento.userId}'
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () {
                    // Implemente a navegação para os detalhes do usuário
                    // Você precisará obter o objeto User completo primeiro
                    // Navigator.of(path.context as BuildContext).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => UserDetailsPage(
                    //       user: User(id: pagamento.userId, 
                    //       username: '', 
                    //       firstName: '', 
                    //       lastName: '', 
                    //       gender: '', 
                    //       birthdate: null, 
                    //       address: '', 
                    //       neighborhood: '', 
                    //       email: '', 
                    //       phone1: '', 
                    //       phone2: '', 
                    //       password: '', 
                    //       state: ''), // Adapte conforme sua implementação
                    //     ),
                    //   ),
                    // );
                  },
                  tooltip: 'View Customer Details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            // Linha da reserva com botão de detalhes
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    Icons.confirmation_number, 
                    'Reservation:', 
                    ' ${pagamento.reservaId}'
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () {
                    // Implemente a navegação para os detalhes da reserva
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => ReservationDetailsPage(
                    //       reservationId: pagamento.reservaId, // Adapte conforme sua implementação
                    //     ),
                    //   ),
                    // );
                  },
                  tooltip: 'View Reservation Details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            _buildDetailRow(
              Icons.calendar_today, 
              'Date:', 
              DateFormat('dd/MM/yyyy - HH:mm').format(pagamento.data)
            ),
            
            if (pagamento.obs != null && pagamento.obs!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notes:', pagamento.obs!),
              
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.blue),
                  onPressed: () => _showPagamentoDetails(path.context as BuildContext, pagamento),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {}, // Implement edit
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {}, // Implement delete
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showPagamentoDetails(BuildContext context, PagamentoReserva pagamento) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _pagamentoService.fetchPagamentoDetails(pagamento.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Payment Details #${pagamento.id}'),
                content: const Center(child: CircularProgressIndicator()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Payment Details #${pagamento.id}'),
                content: Text('Error loading details: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final details = snapshot.data!;
            final user = user_model.User.fromJson(details['user']);
            final reserva = Reserva.fromJson(details['reserva']);

            return AlertDialog(
              title: Text('Payment Details #${pagamento.id}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.person, 'Customer:', '${user.firstName} ${user.lastName}'),
                    _buildDetailRow(Icons.email, 'Email:', user.email ?? 'N/A'),
                    _buildDetailRow(Icons.phone, 'Phone:', user.phone1 ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.confirmation_number, 'Reservation ID:', reserva.id.toString()),
                    _buildDetailRow(Icons.date_range, 'Reservation Date:', 
                        DateFormat('dd/MM/yyyy').format(reserva.date)),
                    _buildDetailRow(Icons.directions_car, 'Vehicle:', reserva.veiculo.matricula ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.payments, 'Amount:', '${pagamento.valorTotal.toStringAsFixed(2)} €'),
                    _buildDetailRow(Icons.calendar_today, 'Payment Date:', 
                        DateFormat('dd/MM/yyyy - HH:mm').format(pagamento.data)),
                    if (pagamento.obs != null && pagamento.obs!.isNotEmpty)
                      _buildDetailRow(Icons.note, 'Notes:', pagamento.obs!),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
