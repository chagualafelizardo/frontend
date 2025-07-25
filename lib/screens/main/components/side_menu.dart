import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Function(String) onMenuSelected;

  const SideMenu({Key? key, required this.onMenuSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 34, 33, 33), // Cor de fundo do DrawerHeader
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Imagem circular
            ClipOval(
                  child: Image.asset(
                    'assets/images/car_rental.jpg', // Caminho da imagem no diretório de assets
                    width: 80, // Largura da imagem
                    height: 80, // Altura da imagem
                    fit: BoxFit.cover, // Ajusta a imagem para cobrir o espaço circular
                  ),
                ),
                SizedBox(height: 10), // Espaçamento entre a imagem e o texto
                // Texto
                Text(
                  "LN Car Rental",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Dashboard
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text("Dashboard"),
            onTap: () => onMenuSelected('/dashboard'),
          ),
          Divider(), // Separador entre os itens
          
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text("Manage vehicle in service"),
            onTap: () => onMenuSelected('/geolocation'),
          ),
         Divider(), //
 
           // Vehicle (Raiz com submenus)
          ExpansionTile(
            leading: Icon(Icons.directions_car),
            title: Text("Vehicle"),
            childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
            children: [
              ListTile(
                leading: Icon(Icons.add_circle),
                title: Text("Register New Vehicle"),
                onTap: () => onMenuSelected('/vehicles'),
              ),
              Divider(), // Separador entre os itens

              ListTile(
                leading: Icon(Icons.local_gas_station),
                title: Text("Fuel Stations"),
                onTap: () => onMenuSelected('/fuelStations'),
              ),
              ListTile(
                leading: Icon(Icons.build),
                title: Text("Workshops"),
                onTap: () => onMenuSelected('/workshops'),
              ),
              ListTile(
                leading: Icon(Icons.local_shipping),
                title: Text("Vehicle Supply"),
                onTap: () => onMenuSelected('/vehicleSupply'),
              ),
              Divider(), // Separador entre os itens
              
              ListTile(
                leading: Icon(Icons.car_repair),
                title: Text("Item of Car"),
                onTap: () => onMenuSelected('/carItem'),
              ),
              ListTile(
                leading: Icon(Icons.description),
                title: Text("Documents at Delivery"),
                onTap: () => onMenuSelected('/documentsatdelivery'),
              ),

              Divider(), // Separador entre os itens
              ListTile(
                leading: Icon(Icons.car_crash),
                title: Text("Vehicle for Maintenance"),
                onTap: () => onMenuSelected('/vehicleMaintenance'),
              ),
            ],
          ),

          // Finance
          ExpansionTile(
            leading: Icon(Icons.attach_money),
            title: Text("Finance"),
            childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
            children: [
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Employees Financial Details"),
                onTap: () => onMenuSelected('/finance'),
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Payment Criteria"),
                onTap: () => onMenuSelected('/paymentCriteria'),
              ),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.attach_money),
            title: Text("Fines"),
            childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
            children: [
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Type of Fines"),
                onTap: () => onMenuSelected('/finestype'),
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Fines registered"),
                onTap: () => onMenuSelected('/finesregistered'),
              ),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.attach_money),
            title: Text("Payment"),
            childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
            children: [
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Reservation Payment"),
                onTap: () => onMenuSelected('/pagamentoreserva'),
              ),
              Divider(), // Separador entre os itens

              ListTile(
                leading: Icon(Icons.list),
                title: Text("Create Payment"),
                onTap: () => onMenuSelected('/createPayment'),
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text("Confirm Payment"),
                onTap: () => onMenuSelected('/confirmPayment'),
              ),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.analytics),
            title: Text("Business analysis"),
            childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
            children: [
              ListTile(
                leading: Icon(Icons.analytics),
                title: Text("Reserves Evolution"),
                onTap: () => onMenuSelected('/'),
              ),
              ListTile(
                leading: Icon(Icons.analytics),
                title: Text("Services Evolution"),
                onTap: () => onMenuSelected('/atendimentoChart'),
              ),
              ListTile(
                leading: Icon(Icons.analytics),
                title: Text("Reservations and Services"),
                onTap: () => onMenuSelected('/reservationsAndService'),
              ),
            ],
          ),

          // GeoLocation
          // ExpansionTile(
          //   leading: Icon(Icons.location_on),
          //   title: Text("Geo Location"),
          //   childrenPadding: EdgeInsets.only(left: 20), // Ajuste de espaçamento para os subitens
          //   children: [
          //     ListTile(
          //       leading: Icon(Icons.person),
          //       title: Text("View maps"),
          //       onTap: () => onMenuSelected('/geolocation'),
          //     ),
          //   ],
          // ),
         Divider(), //

          // Users
          ListTile(
            leading: Icon(Icons.people),
            title: Text("Users"),
            onTap: () => onMenuSelected('/users'),
          ),

          Divider(), // Separador entre os itens

          // Settings
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () => onMenuSelected('/settings'),
          ),
        ],
      ),
    );
  }
}