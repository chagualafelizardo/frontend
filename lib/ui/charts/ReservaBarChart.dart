import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReservaBarChart extends StatelessWidget {
  final Map<DateTime, int> reservasPorData;

  const ReservaBarChart({required this.reservasPorData});

  @override
  Widget build(BuildContext context) {
    // Converte o mapa de reservas por data em uma lista ordenada por data
    final sortedEntries = reservasPorData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final dataEntry = entry.value;
          return BarChartGroupData(
            x: index, // Índice no eixo X
            barRods: [
              BarChartRodData(
                toY: dataEntry.value.toDouble(), // Quantidade de reservas no eixo Y
                color: Colors.blue,
                width: 30, // Aumente este valor para tornar as barras mais largas
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          // Mantém os títulos no eixo X (inferior)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Exibe a data no eixo X
                final date = sortedEntries[value.toInt()].key;
                return Text('${date.day}/${date.month}');
              },
            ),
          ),
          // Mantém os títulos no eixo Y (esquerdo)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Exibe a quantidade no eixo Y
                return Text(value.toInt().toString());
              },
            ),
          ),
          // Desativa os títulos no eixo Y (direito)
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Desativa os títulos
          ),
          // Desativa os títulos no eixo X (superior)
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Desativa os títulos
          ),
        ),
        // Mantém as grades (grids) visíveis
        gridData: FlGridData(show: true),
        // Mantém a borda ao redor do gráfico
        borderData: FlBorderData(show: true),
      ),
    );
  }
}