import 'package:app/ui/charts/ReservaPieChart.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'chart.dart';
import 'storage_info_card.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/models/Reserva.dart';

class StorageDetails extends StatefulWidget {
  const StorageDetails({Key? key}) : super(key: key);

  @override
  _StorageDetailsState createState() => _StorageDetailsState();
}

class _StorageDetailsState extends State<StorageDetails> {
  final ReservaService _reservaService = ReservaService('http://localhost:5000');
  Map<DateTime, int> reservasPorData = {};
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _fetchReservas();
  }

  Future<void> _fetchReservas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Reserva> reservas = await _reservaService.getReservas();
      final Map<DateTime, int> reservasAgrupadas = {};

      for (var reserva in reservas) {
        final date = DateTime(reserva.date.year, reserva.date.month, reserva.date.day);
        reservasAgrupadas[date] = (reservasAgrupadas[date] ?? 0) + 1;
      }

      final List<DateTime> availableDates = reservasAgrupadas.keys.toList()..sort();

      setState(() {
        reservasPorData = reservasAgrupadas;
        _availableDates = availableDates;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reservas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Request, confirm and allocate services here",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: defaultPadding),
          _buildStorageCard(context, svgSrc: "assets/icons/Documents.svg", title: "Request", route: "/request"),
          _buildStorageCard(context, svgSrc: "assets/icons/Documents.svg", title: "Confirmed Request", route: "/confirmedRequest"),
          _buildStorageCard(context, svgSrc: "assets/icons/Documents.svg", title: "Allocations", route: "/allocations"),
          SizedBox(height: defaultPadding),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ReservaPieChart(reservasPorData: reservasPorData),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, {
    required String svgSrc,
    required String title,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: StorageInfoCard(
        svgSrc: svgSrc,
        title: title,
        amountOfFiles: "1.3GB",
        numOfFiles: 1328,
      ),
    );
  }
}
