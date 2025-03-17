import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/constants.dart';
import 'package:app/controllers/menu_app_controller.dart';
import 'package:app/ui/charts/AtendimentoChartPage.dart';
import 'package:app/ui/charts/ReservationsAndServiceChartPage.dart';
import 'package:app/ui/financas/ManagePaymentCriteriaPage.dart';
import 'package:app/ui/login/login_page.dart';
import 'package:app/ui/manutencao/ManageManutencoesPage.dart';
import 'package:app/ui/pagamento/ManageConfirmPaymentPage.dart';
import 'package:app/ui/pagamento/ManagePaymentPage.dart';
import 'package:app/ui/reserva/MapSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app/ui/alocacao/ManageAlocarMotoristaPage.dart';
import 'package:app/ui/financas/ManageUsersEmployeeFinancialDetailsPage.dart';
import 'package:app/ui/itensentrega/ManageItensEntregaPage.dart';
import 'package:app/ui/veiculo/ManageVehicleSupplyPage.dart';
import 'package:app/ui/oficina/ManageOficinasPage.dart';
import 'package:app/ui/postoabastencimento/ManagePostosPage.dart';
import 'package:app/ui/reserva/ManageReservasPage.dart';
import 'package:app/ui/reserva/ManageConfirmedReservePage.dart';
import 'package:app/ui/user/ManageUsersPage.dart';
import 'package:app/ui/veiculo/ManageVeiculosPage.dart';
import 'package:app/ui/item/ManageItemsPage.dart';
import 'package:app/screens/main/main_screen.dart';

Future<void> main() async {
  await dotenv.load(); // Carregar o .env antes de rodar o app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MenuAppController(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FCC Software Development, EI',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/dashboard': (context) => MainScreen(userName: 'Guest'),
          '/carItem': (context) => ManageItemsPage(),
          '/documentsatdelivery': (context) => ManageItensEntregaPage(),
          '/users': (context) => ManageUsersPage(),
          '/vehicles': (context) => ManageVeiculosPage(),
          '/fuelStations': (context) => ManagePostosPage(),
          '/workshops': (context) => ManageOficinasPage(),
          '/vehicleSupply': (context) => ManageVehicleSupplyPage(),
          '/vehicleMaintenance'
          : (context) => ManageManutencoesPage(),
          '/userdetails': (context) => LoginPage(),
          '/logout': (context) => LoginPage(),
          '/request': (context) => ManageReservasPage(), // 🚀 Ajustado para Requests
          '/confirmedRequest': (context) => ManageConfirmedReservasPage(),
          '/allocations': (context) => ManageAlocarMotoristaPage(),
          '/finance': (context) => ManageUsersEmployeeFinancialDetailsPage(),
          '/paymentCriteria': (context) => ManagePaymentCriteriaPage(),
          '/createPayment': (context) => ManagePaymentPage(),
          '/confirmPayment': (context) => ManageConfirmPaymentPage(),
          '/atendimentoChart': (context) => AtendimentoChartPage(),
          '/reservationsAndService': (context) => ReservationsAndServiceChartPage(),
          '/geolocation': (context) => MapSelectionScreen(),
          '/settings': (context) => LoginPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/dashboard') {
            final args = settings.arguments as Map<String, dynamic>?;
            final userName = args?['userName'] ?? 'Guest';

            return MaterialPageRoute(
              builder: (context) => MainScreen(userName: userName),
            );
          }
          return null;
        },
      ),
    );
  }
}
