import 'package:app/models/Atendimento.dart';
import 'package:app/ui/charts/AtendimentoBarChart.dart';
import 'package:app/ui/charts/AtendimentoLineChart.dart';
import 'package:app/ui/charts/AtendimentoPieChart.dart' show AtendimentoPieChart;
import 'package:app/ui/charts/ReservaBarChart.dart';
import 'package:app/ui/charts/ReservaLineChart.dart';
import 'package:app/ui/charts/ReservaPieChart.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/AtendimentoService.dart';

class ReservationsAndServiceChartPage extends StatefulWidget {
  @override
  _AtendimentoChartPageState createState() => _AtendimentoChartPageState();
}

class _AtendimentoChartPageState extends State<ReservationsAndServiceChartPage> {
  final AtendimentoService atendimentoService = AtendimentoService('http://localhost:5000');
  List<Atendimento> atendimentos = [];
  Map<DateTime, int> reservationsAndServicePorData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservas();
  }

  Future<void> _fetchReservas() async {
    try {
      final fetchAtendimentos = await atendimentoService.fetchAtendimentos();
      setState(() {
        atendimentos = fetchAtendimentos;
        reservationsAndServicePorData = atendimentoService.agruparAtendimentosPorData(atendimentos);
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
        title: const Text('Service by date'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Service by date graphics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: AtendimentoBarChart(atendimentosPorData: reservationsAndServicePorData),
                  ),
                  SizedBox(
                    height: 300,
                    child: AtendimentoLineChart(atendimentosPorData: reservationsAndServicePorData),
                  ),
                  SizedBox(
                    height: 300,
                    child: AtendimentoPieChart(atendimentosPorData: reservationsAndServicePorData),
                  ),
                ],
              ),
            ),
    );
  }
}