import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AtendimentoPieChart extends StatelessWidget {
  final Map<DateTime, int> atendimentosPorData;

  const AtendimentoPieChart({required this.atendimentosPorData});

  @override
  Widget build(BuildContext context) {
    // Converte o mapa de reservas por data em uma lista ordenada por data
    final sortedEntries = atendimentosPorData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Calcula o total de reservas
    final totalReservas = sortedEntries.fold(0, (sum, entry) => sum + entry.value);

    // Cria as seções do gráfico circular
    final sections = sortedEntries.map((entry) {
      final date = entry.key;
      final reservas = entry.value;
      final percentage = (reservas / totalReservas) * 100;

      return PieChartSectionData(
        color: _getColorForDate(date), // Cor da seção
        value: reservas.toDouble(), // Valor da seção
        title: '${percentage.toStringAsFixed(1)}%', // Exibe a porcentagem
        radius: 40, // Raio das seções
        titleStyle: TextStyle(
          fontSize: 14, // Tamanho da fonte
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 400, // Altura do gráfico
      width: 400, // Largura do gráfico
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections, // Seções do gráfico
              borderData: FlBorderData(show: false), // Remove a borda ao redor do gráfico
              centerSpaceRadius: 80, // Espaço central
              sectionsSpace: 2, // Espaço entre as seções
            ),
          ),
          // Texto no centro do gráfico
          Text(
            'T[R]: $totalReservas',
            style: TextStyle(
              fontSize: 20, // Tamanho da fonte
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Método para gerar cores dinamicamente com base na data
  Color _getColorForDate(DateTime date) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    return colors[date.day % colors.length]; // Usa o dia para escolher uma cor
  }
}