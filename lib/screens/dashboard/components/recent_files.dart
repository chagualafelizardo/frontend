import 'package:app/models/atendimento.dart'; // Importe o modelo Atendimento
import 'package:app/services/AtendimentoService.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:app/ui/charts/ReservaBarChart.dart'; // Importe o gráfico de barras
import 'package:app/ui/charts/ReservaLineChart.dart'; // Importe o gráfico de linhas
import 'package:app/ui/charts/ReservaPieChart.dart'; // Importe o gráfico circular
import 'package:app/models/Reserva.dart'; // Importe o modelo Reserva
import 'package:app/services/ReservaService.dart'; // Importe o serviço de Reserva

class RecentFiles extends StatefulWidget {
  const RecentFiles({Key? key}) : super(key: key);

  @override
  _RecentFilesState createState() => _RecentFilesState();
}

class _RecentFilesState extends State<RecentFiles> {
  final ReservaService _reservaService = ReservaService('http://localhost:5000');
  Map<DateTime, int> reservasPorData = {};
  bool _isLoading = true;
  DateTime? _startDate; // Data inicial selecionada
  DateTime? _endDate; // Data final selecionada
  List<DateTime> _availableDates = []; // Lista de datas disponíveis

  // Controladores para os campos de texto de data
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReservas();
  }

  Future<void> _fetchReservas() async {
    setState(() {
      _isLoading = true; // Inicia o estado de carregamento
    });

    try {
      // Busca as reservas do serviço
      final List<Reserva> reservas = await _reservaService.getReservas();

      // Agrupa as reservas por data
      final Map<DateTime, int> reservasAgrupadas = {};
      for (var reserva in reservas) {
        final date = DateTime(reserva.date.year, reserva.date.month, reserva.date.day);
        if (reservasAgrupadas.containsKey(date)) {
          reservasAgrupadas[date] = reservasAgrupadas[date]! + 1;
        } else {
          reservasAgrupadas[date] = 1;
        }
      }

      // Atualiza a lista de datas disponíveis
      final List<DateTime> availableDates = reservasAgrupadas.keys.toList();
      availableDates.sort((a, b) => a.compareTo(b));

      setState(() {
        reservasPorData = reservasAgrupadas; // Atualiza os dados das reservas
        _availableDates = availableDates; // Atualiza as datas disponíveis
        _isLoading = false; // Finaliza o estado de carregamento
      });
    } catch (e) {
      print('Error fetching reservas: $e');
      setState(() {
        _isLoading = false; // Finaliza o estado de carregamento em caso de erro
      });
    }
  }

  // Filtra os dados das reservas entre as datas selecionadas
  Map<DateTime, int> _filterReservasByDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return reservasPorData;

    return Map.fromEntries(
      reservasPorData.entries.where(
        (entry) => entry.key.isAfter(startDate.subtract(Duration(days: 1))) && entry.key.isBefore(endDate.add(Duration(days: 1))),
      ),
    );
  }

  // Função para abrir o calendário e selecionar uma data
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = "${picked.day}/${picked.month}/${picked.year}";
        } else {
          _endDate = picked;
          _endDateController.text = "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtra os dados das reservas com base no intervalo de datas selecionado
    final filteredReservas = _filterReservasByDateRange(_startDate, _endDate);

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Request Service Charts",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Spacer(), // Adiciona espaço entre o texto e os campos de data
              // Campo de texto para selecionar a data inicial
              SizedBox(
                width: 150, // Largura do campo de texto
                child: TextField(
                  controller: _startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              SizedBox(width: 10),
              // Campo de texto para selecionar a data final
              SizedBox(
                width: 150, // Largura do campo de texto
                child: TextField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          SizedBox(height: defaultPadding),
          // Exibe um indicador de carregamento enquanto os dados são buscados
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                // Gráfico de Barras
                Container(
                  height: 300,
                  child: ReservaBarChart(reservasPorData: filteredReservas),
                ),
                SizedBox(height: defaultPadding),
                // Gráfico de Linhas
                Container(
                  height: 400,
                  child: ReservaLineChart(reservasPorData: filteredReservas),
                ),
                Container(
                  height: 400,
                  child: ReservaPieChart(reservasPorData: filteredReservas),
                ),
              ],
            ),
        ],
      ),
    );
  }
}