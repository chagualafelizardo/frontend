import 'package:app/models/Reserva.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddDeliveryLocation extends StatefulWidget {
  final int reservaId; // Adicionando o parâmetro reservaId

  const AddDeliveryLocation({Key? key, required this.reservaId}) : super(key: key);

  @override
  _AddReservationScreenState createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddDeliveryLocation> {
  bool _isGridView = true;
  List<Veiculo> _veiculos = []; // Suponha que esta lista já esteja populada

  LatLng? _selectedLocation; // Armazena a localização selecionada
  GoogleMapController? _mapController; // Controlador do Google Maps
  final Set<Marker> _markers = {}; // Marcadores no mapa

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear(); // Remove marcadores anteriores
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: '${location.latitude}, ${location.longitude}',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add delivery Location (ID: ${widget.reservaId})'), // Exibir o ID da reserva
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Selected Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  // Mapa do Google Maps
                  Expanded(
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      onTap: _onMapTap,
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ?? LatLng(-25.9689, 32.5699), // Posição inicial do mapa (ex: Maputo)
                        zoom: 12.0,
                      ),
                      markers: _markers,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeiculoCard(Veiculo veiculo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${veiculo.marca} ${veiculo.modelo}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Placa: ${veiculo.matricula}'),
          ],
        ),
      ),
    );
  }
}