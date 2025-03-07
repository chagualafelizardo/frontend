import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AtendimentoLineChart extends StatelessWidget {
  final Map<DateTime, int> atendimentosPorData;

  const AtendimentoLineChart({required this.atendimentosPorData});

  @override
  Widget build(BuildContext context) {
    // Converte o mapa de reservas por data em uma lista ordenada por data
    final sortedEntries = atendimentosPorData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Cria os pontos (spots) para o gráfico de linhas
    final spots = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      return FlSpot(index.toDouble(), dataEntry.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots, // Pontos no gráfico
            isCurved: true, // Define se a linha é curva ou reta
            color: Colors.blue, // Cor da linha
            barWidth: 3, // Espessura da linha
            belowBarData: BarAreaData(
              show: true, // Mostra a área abaixo da linha
              color: Colors.blue.withOpacity(0.2), // Cor da área
            ),
            dotData: FlDotData(
              show: true, // Mostra os pontos nos dados
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4, // Raio dos pontos
                  color: Colors.blue, // Cor dos pontos
                );
              },
            ),
          ),
        ],
        titlesData: FlTitlesData(
          // Títulos no eixo X (inferior)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30, // Espaço reservado para os títulos
              getTitlesWidget: (value, meta) {
                // Exibe a data no eixo X
                final date = sortedEntries[value.toInt()].key;
                return Text('${date.day}/${date.month}');
              },
            ),
          ),
          // Títulos no eixo Y (esquerdo)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // Espaço reservado para os títulos
              getTitlesWidget: (value, meta) {
                // Exibe a quantidade no eixo Y
                return Text(value.toInt().toString());
              },
            ),
          ),
          // Desativa os títulos no eixo Y (direito)
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // Desativa os títulos no eixo X (superior)
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        // Configura as grades (grids) visíveis
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true, // Mostra as linhas verticais
          drawHorizontalLine: true, // Mostra as linhas horizontais
        ),
        // Configura a borda ao redor do gráfico
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1),
        ),
      ),
    );
  }
}