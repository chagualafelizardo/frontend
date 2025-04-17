import 'package:app/models/Atendimento.dart';
import 'package:app/ui/charts/AtendimentoBarChart.dart';
import 'package:app/ui/charts/AtendimentoLineChart.dart';
import 'package:app/ui/charts/AtendimentoPieChart.dart' show AtendimentoPieChart;
import 'package:flutter/material.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AtendimentoChartPage extends StatefulWidget {
  @override
  _AtendimentoChartPageState createState() => _AtendimentoChartPageState();
}

class _AtendimentoChartPageState extends State<AtendimentoChartPage> {
  final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  List<Atendimento> atendimentos = [];
  Map<DateTime, int> atendimentosPorData = {};
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
        atendimentosPorData = atendimentoService.agruparAtendimentosPorData(atendimentos);
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
                    child: AtendimentoBarChart(atendimentosPorData: atendimentosPorData),
                  ),
                  SizedBox(
                    height: 300,
                    child: AtendimentoLineChart(atendimentosPorData: atendimentosPorData),
                  ),
                  SizedBox(
                    height: 300,
                    child: AtendimentoPieChart(atendimentosPorData: atendimentosPorData),
                  ),
                ],
              ),
            ),
    );
  }
}