import 'package:app/models/DriveDeliver.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/services/DriveDeliverService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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

  String _pickupMapType = 'normal';
  String _returnMapType = 'normal';
  bool _isPickupSearching = false;
  bool _isReturnSearching = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initializeMap();
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

  void _onPickupMapTap(LatLng location) {
    setState(() {
      _pickupLocation = location;
      _pickupMarkers.clear();
      _pickupMarkers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _returnLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and return locations')),
      );
      return;
    }

    try {
      final String? notes = _notesController.text.isNotEmpty 
          ? _notesController.text 
          : null;

      final payment = PagamentoReserva(
        valorTotal: double.parse(_amountController.text),
        data: DateTime.parse(_dateController.text),
        obs: notes,
        userId: widget.userId,
        reservaId: widget.reservaId,
      );
      
      await _paymentService.createPagamentoReserva(payment);

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
      
      await _driveDeliverService.createDriveDeliver(driveDeliver);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment and locations registered successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      debugPrint('Full error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment and Locations (Reservation#${widget.reservaId})'),
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
                  if (value == null || value.isEmpty) return 'Enter the amount';
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