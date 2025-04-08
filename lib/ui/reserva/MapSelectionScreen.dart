import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MapSelectionScreen> createState() => _MapPageState();
}

class _MapPageState extends State<MapSelectionScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-25.9655, 32.5832); // Maputo

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Vehicles in Service on Google Maps'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
      ),
    );
  }
}
