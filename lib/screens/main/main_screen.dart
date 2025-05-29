import 'package:app/controllers/menu_app_controller.dart';
import 'package:app/responsive.dart';
import 'package:app/screens/dashboard/dashboard_screen.dart';
import 'package:app/ui/charts/AtendimentoChartPage.dart';
import 'package:app/ui/charts/ReservationsAndServiceChartPage.dart';
import 'package:app/ui/financas/ManagePaymentCriteriaPage.dart';
import 'package:app/ui/financas/ManageUsersEmployeeFinancialDetailsPage.dart';
import 'package:app/ui/item/ManageItemsPage.dart';
import 'package:app/ui/itensentrega/ManageItensEntregaPage.dart';
import 'package:app/ui/login/login_page.dart';
import 'package:app/ui/manutencao/ManageManutencoesPage.dart';
import 'package:app/ui/multa/ManageMultaPage.dart';
import 'package:app/ui/multa/ManageTipoMultaPage.dart';
import 'package:app/ui/oficina/ManageOficinasPage.dart';
import 'package:app/ui/pagamento/ManageConfirmPaymentPage.dart';
import 'package:app/ui/pagamento/ManagePaymentPage.dart';
import 'package:app/ui/pagamento/ManageReservationPaymentPage.dart';
import 'package:app/ui/postoabastencimento/ManagePostosPage.dart';
import 'package:app/ui/reserva/ManageReservasPage.dart';
import 'package:app/ui/reserva/ManageDashboardService.dart';
import 'package:app/ui/user/ManageUsersPage.dart';
import 'package:app/ui/veiculo/ManageVehicleSupplyPage.dart';
import 'package:app/ui/veiculo/ManageVeiculosPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({Key? key, required this.userName}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedPage = '/dashboard';

  void _navigateTo(String route) {
    setState(() {
      _selectedPage = route;
    });
  }

  Widget _getPage() {
    switch (_selectedPage) {
      case '/dashboard':
        return DashboardScreen(userName: widget.userName);
      case '/users':
        return ManageUsersPage();
      case '/vehicles':
        return ManageVeiculosPage();
      case '/fuelStations':
        return ManagePostosPage();
      case '/workshops':
        return ManageOficinasPage();
      case '/vehicleSupply':
        return ManageVehicleSupplyPage();
      case '/userdetails':
            return LoginPage();
      case '/documentsatdelivery':
        return ManageItensEntregaPage();
      case '/carItem':
        return ManageItemsPage();
      case '/vehicleMaintenance':
        return ManageManutencoesPage();
      case '/request':
        return ManageReservasPage();
      case '/finance':
        return ManageUsersEmployeeFinancialDetailsPage();
      case '/finestype':
        return ManageTipoMultaPage();
      case '/finesrecorded':
        return ManageMultaPage();
      case '/paymentCriteria':
        return ManagePaymentCriteriaPage();
      case '/createPayment':
        return ManagePaymentPage();
      case '/confirmPayment':
        return ManageConfirmPaymentPage();
      case '/atendimentoChart':
        return AtendimentoChartPage();
      case '/reservationsAndService':
        return ReservationsAndServiceChartPage();
      case '/pagamentoreserva':
        return ManageReservationPaymentPage();
      case '/geolocation':
      return ManageDashboardService(); 
      case '/settings':
        return LoginPage();
      default:
        return DashboardScreen(userName: widget.userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: SideMenu(onMenuSelected: _navigateTo),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                child: SideMenu(onMenuSelected: _navigateTo),
              ),
            Expanded(
              flex: 5,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(16),
                child: _getPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
