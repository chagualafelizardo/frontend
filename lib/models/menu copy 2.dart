// import 'package:app/models/Reserva.dart';
// import 'package:flutter/material.dart';
// import 'package:charts_flutter/flutter.dart' as charts;
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// class Menus {
//   final String? svgSrc, title, route;
//   final int? numOfFiles, percentage;
//   final Color? color;

//   Menus({
//     this.svgSrc,
//     required this.title,
//     this.numOfFiles,
//     this.percentage,
//     this.color,
//     this.route, // Rota associada ao menu
//   });
// }

// // Função para buscar reservas do backend
// Future<List<Reserva>> fetchReservas() async {
//   final response = await http.get(Uri.parse('http://localhost:5000/reserva'));
//   if (response.statusCode == 200) {
//     final List<dynamic> data = jsonDecode(response.body);
//     return data.map((json) => Reserva.fromJson(json)).toList();
//   } else {
//     throw Exception('Failed to load reservas');
//   }
// }

// // Classe para representar os dados do gráfico
// class ReservationData {
//   final DateTime date;
//   final int count;

//   ReservationData(this.date, this.count);

//   String get formattedDate => DateFormat('yyyy-MM-dd').format(date);
// }

// class MenusPage extends StatefulWidget {
//   const MenusPage({super.key});

//   @override
//   _MenusPageState createState() => _MenusPageState();
// }

// class _MenusPageState extends State<MenusPage> {
//   List<Reserva> _reservas = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchReservasAndGenerateChart();
//   }

//   Future<void> _fetchReservasAndGenerateChart() async {
//     try {
//       final reservas = await fetchReservas();
//       setState(() {
//         _reservas = reservas;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching reservas: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to fetch reservation data')),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // Função para agrupar reservas por dia
//   Map<DateTime, int> groupReservasByDay(List<Reserva> reservas) {
//     final groupedData = <DateTime, int>{};
//     for (var reserva in reservas) {
//       final day = DateTime(reserva.date.year, reserva.date.month, reserva.date.day);
//       groupedData[day] = (groupedData[day] ?? 0) + 1;
//     }
//     return groupedData;
//   }

//   // Widget para exibir o gráfico de barras
//   Widget _buildBarChart(Map<DateTime, int> groupedData) {
//     final chartData = groupedData.entries
//         .map((entry) => ReservationData(entry.key, entry.value))
//         .toList();

//     final series = [
//       charts.Series<ReservationData, String>(
//         id: 'Reservations',
//         domainFn: (ReservationData data, _) => data.formattedDate,
//         measureFn: (ReservationData data, _) => data.count,
//         data: chartData,
//         fillColorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
//       )
//     ];

//     return charts.BarChart(
//       series,
//       animate: true,
//       vertical: false,
//       barRendererDecorator: charts.BarLabelDecorator<String>(),
//       domainAxis: const charts.OrdinalAxisSpec(
//         renderSpec: charts.NoneRenderSpec(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reservation Analytics'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Text(
//                     'Number of Reservations by Day',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildBarChart(groupReservasByDay(_reservas)),
//                 ),
//               ],
//             ),
//     );
//   }
// }