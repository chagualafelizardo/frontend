import 'package:app/ui/charts/ReservaBarChart.dart';
import 'package:app/ui/charts/ReservaLineChart.dart';
import 'package:app/ui/charts/ReservaPieChart.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReservaChartPage extends StatefulWidget {
  @override
  _ReservaChartPageState createState() => _ReservaChartPageState();
}

class _ReservaChartPageState extends State<ReservaChartPage> {
  final ReservaService reservaService = ReservaService(dotenv.env['BASE_URL']!);
  List<Reserva> reservas = [];
  Map<DateTime, int> reservasPorData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservas();
  }

  Future<void> _fetchReservas() async {
    try {
      final fetchedReservas = await reservaService.getReservas();
      setState(() {
        reservas = fetchedReservas;
        reservasPorData = reservaService.agruparReservasPorData(reservas);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load reservas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas por Data'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Gráfico de Reservas por Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    // child: ReservaBarChart(reservasPorData: reservasPorData),
                    child: ReservaPieChart(reservasPorData: reservasPorData),
                  ),
                ],
              ),
            ),
    );
  }
}