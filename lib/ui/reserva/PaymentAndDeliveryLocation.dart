import 'package:app/models/PagamentoReserva.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/services/UserService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

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
  final _userService = UserService(dotenv.env['BASE_URL']!);
  
  // Form field controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Location data
  LatLng? _pickupLocation;
  LatLng? _returnLocation;
  GoogleMapController? _pickupMapController;
  GoogleMapController? _returnMapController;
  final Set<Marker> _pickupMarkers = {};
  final Set<Marker> _returnMarkers = {};
  
  // User data
  String? _userName;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getUserById(widget.userId);
      setState(() {
        _userName = '${user.firstName} ${user.lastName}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
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

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _returnLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and return locations')),
      );
      return;
    }

    try {
      final payment = PagamentoReserva(
        valorTotal: double.parse(_amountController.text),
        data: DateTime.parse(_dateController.text),
        obs: _notesController.text.isNotEmpty ? _notesController.text : null,
        userId: widget.userId,
        reservaId: widget.reservaId,
      );

      await _paymentService.createPagamentoReserva(payment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment registered successfully!')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment and Location To (Reservation #${widget.reservaId}) and (Client #${widget.userId})'),
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
              // User information
              if (_userName != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client: $_userName',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User ID: ${widget.userId}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reservation ID: ${widget.reservaId}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Payment form
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
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a date';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Select locations:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Pickup Location Map
              const Text(
                'Pickup Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_pickupLocation != null)
                Text(
                  'Lat: ${_pickupLocation!.latitude.toStringAsFixed(4)}, '
                  'Lng: ${_pickupLocation!.longitude.toStringAsFixed(4)}',
                ),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: _onPickupMapCreated,
                  onTap: _onPickupMapTap,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-25.9689, 32.5699), // Maputo
                    zoom: 12.0,
                  ),
                  markers: _pickupMarkers,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Return Location Map
              const Text(
                'Return Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_returnLocation != null)
                Text(
                  'Lat: ${_returnLocation!.latitude.toStringAsFixed(4)}, '
                  'Lng: ${_returnLocation!.longitude.toStringAsFixed(4)}',
                ),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: _onReturnMapCreated,
                  onTap: _onReturnMapTap,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-25.9689, 32.5699), // Maputo
                    zoom: 12.0,
                  ),
                  markers: _returnMarkers,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes field (moved before submit button)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Additional payment information',
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              ElevatedButton(
                onPressed: _submitPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Register Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}