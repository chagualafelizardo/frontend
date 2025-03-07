// import 'package:app/models/VehicleSupply.dart';
// import 'package:app/ui/veiculo/EditVehicleSupplyForm.dart';
// import 'package:flutter/material.dart';

// class ViewVehicleSupplyPage extends StatelessWidget {
//   final String veiculoId;  // ID do veículo que será visualizado

//   ViewVehicleSupplyPage({required this.veiculoId, required VehicleSupply supply});

//   @override
//   Widget build(BuildContext context) {
//     // Simulação de dados de abastecimento (isso seria normalmente buscado de uma API)
//     final List<Map<String, String>> supplyData = [
//       {
//         'data': '2025-01-15',
//         'quantidade': '40',
//         'combustivel': 'Gasolina',
//       },
//       {
//         'data': '2025-01-10',
//         'quantidade': '50',
//         'combustivel': 'Diesel',
//       },
//       {
//         'data': '2025-01-05',
//         'quantidade': '30',
//         'combustivel': 'Gásóleo',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Visualizar Abastecimento do Veículo"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Histórico de Abastecimento',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: supplyData.length,
//                 itemBuilder: (context, index) {
//                   var data = supplyData[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 8.0),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Data: ${data['data']}',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             'Quantidade: ${data['quantidade']} litros',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             'Tipo de Combustível: ${data['combustivel']}',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 // Ação para editar as informações de abastecimento
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => EditVehicleSupplyForm(
//                       veiculoId: veiculoId,
//                     ),
//                   ),
//                 );
//               },
//               child: Text('Editar Abastecimento'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: Size(double.infinity, 50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
