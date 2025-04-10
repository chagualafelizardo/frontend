import 'dart:convert';
import 'package:app/ui/veiculo/ViewVeiculoPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/models/Reserva.dart' as reserva_model;
import 'package:app/models/Veiculo.dart' as veiculo_model;
import 'package:app/services/DriveDeliverService.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  String _mapType = 'normal';
  final LatLng _center = const LatLng(-25.9655, 32.5832);
  late TabController _tabController;

  // Serviços
  final DriveDeliverService _driveDeliverService = DriveDeliverService();
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);
  final VeiculoService _veiculoService = VeiculoService(dotenv.env['BASE_URL']!);

  // Dados do mapa
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Certifique-se que é 4
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 3) { // Verifique se é o índice correto para o mapa
        _loadDriveDeliverData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    
    // Recarrega os dados do mapa apenas quando a aba do mapa estiver ativa
    if (_tabController.index == 2) {
      _loadDriveDeliverData();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    setState(() {
      _mapController = controller;
      _isMapLoading = false;
    });
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == 'normal' ? 'hybrid' : 'normal';
    });
  }

  // Método para buscar veículos free's
  Future<List<veiculo_model.Veiculo>> _fetchAvailableVehicles() async {
    return await _veiculoService.fetchVehiclesByState('Free');
  }

  // Método para buscar veículos ocupados
  Future<List<veiculo_model.Veiculo>> _fetchOccupiedVehicles() async {
    return await _veiculoService.fetchVehiclesByState('Occupied');
  }

  Future<List<reserva_model.Reserva>> _fetchReservas() async {
    return await _reservaService.getReservas();
  }

  Future<void> _loadDriveDeliverData() async {
    if (!mounted) return;

    setState(() => _isMapLoading = true);
    
    try {
      final deliveries = await _driveDeliverService.getAllDriveDelivers();
      
      if (!mounted) return;
      
      setState(() {
        _markers.clear();
        _polylines.clear();
        
        for (final delivery in deliveries) {
          // Marcador de pickup (verde)
          if (delivery.pickupLatitude != null && delivery.pickupLongitude != null) {
            final pickupLatLng = LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!);
            
            _markers.add(
              Marker(
                markerId: MarkerId('pickup_${delivery.id}'),
                position: pickupLatLng,
                infoWindow: InfoWindow(
                  title: 'Pickup Point - Reserva ${delivery.reservaId}',
                  snippet: 'Data: ${delivery.date?.toLocal().toString().split(' ')[0] ?? 'N/A'}\n'
                          'Local: ${delivery.locationDescription ?? 'Sem descrição'}',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
            );
          }
          
          // Marcador de dropoff (vermelho)
          if (delivery.dropoffLatitude != null && delivery.dropoffLongitude != null) {
            final dropoffLatLng = LatLng(delivery.dropoffLatitude!, delivery.dropoffLongitude!);
            
            _markers.add(
              Marker(
                markerId: MarkerId('dropoff_${delivery.id}'),
                position: dropoffLatLng,
                infoWindow: InfoWindow(
                  title: 'Dropoff Point - Reserva ${delivery.reservaId}',
                  snippet: 'Entregador: ${delivery.deliver ?? 'N/A'}\n'
                          'Coordenadas: ${delivery.dropoffLatitude!.toStringAsFixed(4)}, ${delivery.dropoffLongitude!.toStringAsFixed(4)}',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          }
          
          // Linha entre pickup e dropoff (azul)
          if (delivery.pickupLatitude != null && 
              delivery.pickupLongitude != null &&
              delivery.dropoffLatitude != null && 
              delivery.dropoffLongitude != null) {
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_${delivery.id}'),
                color: Colors.blue,
                width: 3,
                points: [
                  LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!),
                  LatLng(delivery.dropoffLatitude!, delivery.dropoffLongitude!),
                ],
              ),
            );
          }
        }
        _isMapLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar entregas: ${e.toString()}')),
      );
      setState(() => _isMapLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Map & Services'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Vehicles'),
            Tab(text: 'Vehicles In Service'),
            Tab(text: 'Occupied Vehicles'), // Nova aba
            Tab(text: 'Delivery Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Desabilita o swipe entre tabs
        children: [
          _buildAvailableVehiclesTab(),
          _buildVehiclesInServiceTab(),
          _buildOccupiedVehiclesTab(), // Nova aba
          _buildDeliveryMapTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableVehiclesTab() {
    return FutureBuilder<List<veiculo_model.Veiculo>>(
      future: _fetchAvailableVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No available vehicles'));
        }

        final vehicles = snapshot.data!;
        bool isGridView = false;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  child: IconButton(
                    icon: Icon(isGridView ? Icons.list : Icons.grid_view),
                    tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    onPressed: () => setInnerState(() => isGridView = !isGridView),
                  ),
                ),
                Expanded(
                  child: isGridView
                      ? GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(8),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
                        )
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) => _buildVehicleListItem(vehicles[index]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Nova aba para veículos ocupados (similar à primeira aba)
  Widget _buildOccupiedVehiclesTab() {
    return FutureBuilder<List<veiculo_model.Veiculo>>(
      future: _fetchOccupiedVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No occupied vehicles'));
        }

        final vehicles = snapshot.data!;
        bool isGridView = false;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  child: IconButton(
                    icon: Icon(isGridView ? Icons.list : Icons.grid_view),
                    tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    onPressed: () => setInnerState(() => isGridView = !isGridView),
                  ),
                ),
                Expanded(
                  child: isGridView
                      ? GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(8),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
                        )
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) => _buildVehicleListItem(vehicles[index]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleCard(veiculo_model.Veiculo vehicle) {
    return Card(
      child: InkWell(
        onTap: () => _showVehicleDetails(vehicle),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: vehicle.imagemBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(vehicle.imagemBase64),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : const Icon(Icons.directions_car, size: 60),
              ),
              const SizedBox(height: 4),
              Text('${vehicle.id} : ${vehicle.marca} ${vehicle.modelo}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Matrícula: ${vehicle.matricula}'),
              Text('Ano: ${vehicle.ano}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleListItem(veiculo_model.Veiculo vehicle) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: vehicle.imagemBase64.isNotEmpty
            ? Image.memory(
                base64Decode(vehicle.imagemBase64),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.directions_car, size: 40),
        title: Text('${vehicle.id} : ${vehicle.marca} ${vehicle.modelo}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Matrícula: ${vehicle.matricula}'),
            Text('Ano: ${vehicle.ano}'),
            Text('Lugares: ${vehicle.numLugares}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showVehicleDetails(vehicle),
      ),
    );
  }

  void _showVehicleDetails(veiculo_model.Veiculo vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 800,
          height: 800,
          child: ViewVeiculoPage(veiculo: vehicle),
        ),
      ),
    );
  }

  Widget _buildVehiclesInServiceTab() {
    return FutureBuilder<List<reserva_model.Reserva>>(
      future: _fetchReservas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No vehicles in service'));
        }

        final reservasEmServico = snapshot.data!
            .where((reserva) => reserva.inService == 'Yes')
            .toList();

        if (reservasEmServico.isEmpty) {
          return const Center(child: Text('No vehicles currently in service'));
        }

        bool isGridView = false;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  child: IconButton(
                    icon: Icon(isGridView ? Icons.list : Icons.grid_view),
                    tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    onPressed: () => setInnerState(() => isGridView = !isGridView),
                  ),
                ),
                Expanded(
                  child: isGridView
                      ? GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(8),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: reservasEmServico.map((reserva) => _buildReservationCard(reserva)).toList(),
                        )
                      : ListView.builder(
                          itemCount: reservasEmServico.length,
                          itemBuilder: (context, index) => _buildReservationListItem(reservasEmServico[index]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReservationCard(reserva_model.Reserva reserva) {
    return Card(
      child: InkWell(
        onTap: () => _showReservationDetails(reserva),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reserva: ${reserva.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'User: ${reserva.user.firstName ?? 'Unknown'} ${reserva.user.lastName ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.car_repair, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Veiculo: ${reserva.veiculo.matricula}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Destino: ${reserva.destination}'),
              Text('Data: ${reserva.date.toLocal().toString().split(' ')[0]}'),
              Text('Dias: ${reserva.numberOfDays}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationListItem(reserva_model.Reserva reserva) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: reserva.veiculo?.imagemBase64 != null && reserva.veiculo!.imagemBase64!.isNotEmpty
            ? Image.memory(
                base64Decode(reserva.veiculo!.imagemBase64!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.car_repair, size: 40),
        title: Text('Reserva: ${reserva.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'User: ${reserva.user.firstName ?? 'Unknown'} ${reserva.user.lastName ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.car_repair, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Veiculo: ${reserva.veiculo.matricula}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Destino: ${reserva.destination}'),
            Text('Data: ${reserva.date.toLocal().toString().split(' ')[0]}'),
            Text('Dias: ${reserva.numberOfDays}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showReservationDetails(reserva),
      ),
    );
  }

  void _showReservationDetails(reserva_model.Reserva reserva) {
    if (reserva.veiculo != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 800,
            height: 800,
            // child: ViewVeiculoPage(veiculo: reserva.veiculo!),
          ),
        ),
      );
    }
  }

  Widget _buildDeliveryMapTab() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 12,
          ),
          mapType: _mapType == 'normal' ? MapType.normal : MapType.hybrid,
          markers: _markers,
          polylines: _polylines,
        ),
        if (_isMapLoading)
          const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: _toggleMapType,
                child: Icon(
                  _mapType == 'normal' ? Icons.satellite : Icons.map,
                  color: Colors.white,
                ),
                backgroundColor: Colors.blue,
                tooltip: _mapType == 'normal' ? 'Satellite View' : 'Map View',
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                onPressed: _loadDriveDeliverData,
                child: const Icon(Icons.refresh, color: Colors.white),
                backgroundColor: Colors.blue,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Pickup Point'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Dropoff Point'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 12, height: 3, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Delivery Route'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}