import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Function(String) onMenuSelected;

  const SideMenu({Key? key, required this.onMenuSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.blue, // Fundo azul para todo o Drawer
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue, // Cor de fundo do DrawerHeader
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagem
                  Image.asset(
                    'assets/images/car_rental.jpg', // Caminho da imagem no diretório de assets
                    width: 80, // Largura da imagem
                    height: 80, // Altura da imagem
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
            HoverableListTile(
              leading: Icon(Icons.dashboard, color: Colors.white),
              title: "Dashboard",
              onTap: () => onMenuSelected('/dashboard'),
            ),
            Divider(color: Colors.white54), // Separador entre os itens

            // Users
            HoverableListTile(
              leading: Icon(Icons.people, color: Colors.white),
              title: "Users",
              onTap: () => onMenuSelected('/users'),
            ),

            // Vehicle (Raiz com submenus)
            HoverableExpansionTile(
              leading: Icon(Icons.directions_car, color: Colors.white),
              title: "Vehicle",
              children: [
                HoverableListTile(
                  leading: Icon(Icons.add_circle, color: Colors.white),
                  title: "Register New Vehicle",
                  onTap: () => onMenuSelected('/vehicles'),
                ),
                Divider(color: Colors.white54), // Separador entre os itens

                HoverableListTile(
                  leading: Icon(Icons.local_gas_station, color: Colors.white),
                  title: "Fuel Stations",
                  onTap: () => onMenuSelected('/fuelStations'),
                ),
                HoverableListTile(
                  leading: Icon(Icons.build, color: Colors.white),
                  title: "Workshops",
                  onTap: () => onMenuSelected('/workshops'),
                ),
                HoverableListTile(
                  leading: Icon(Icons.local_shipping, color: Colors.white),
                  title: "Vehicle Supply",
                  onTap: () => onMenuSelected('/vehicleSupply'),
                ),
                Divider(color: Colors.white54), // Separador entre os itens

                HoverableListTile(
                  leading: Icon(Icons.car_repair, color: Colors.white),
                  title: "Item of Car",
                  onTap: () => onMenuSelected('/carItem'),
                ),
                HoverableListTile(
                  leading: Icon(Icons.description, color: Colors.white),
                  title: "Documents at Delivery",
                  onTap: () => onMenuSelected('/documentsatdelivery'),
                ),

                Divider(color: Colors.white54), // Separador entre os itens
                HoverableListTile(
                  leading: Icon(Icons.car_crash, color: Colors.white),
                  title: "Vehicle for Maintenance",
                  onTap: () => onMenuSelected('/vehicleMaintenance'),
                ),
              ],
            ),

            // Finance
            HoverableExpansionTile(
              leading: Icon(Icons.attach_money, color: Colors.white),
              title: "Finance",
              children: [
                HoverableListTile(
                  leading: Icon(Icons.list, color: Colors.white),
                  title: "Employee Financial Details",
                  onTap: () => onMenuSelected('/finance'),
                ),
                HoverableListTile(
                  leading: Icon(Icons.list, color: Colors.white),
                  title: "Payment Criteria",
                  onTap: () => onMenuSelected('/paymentCriteria'),
                ),
              ],
            ),

            HoverableExpansionTile(
              leading: Icon(Icons.attach_money, color: Colors.white),
              title: "Payment",
              children: [
                HoverableListTile(
                  leading: Icon(Icons.list, color: Colors.white),
                  title: "Create Payment",
                  onTap: () => onMenuSelected('/createPayment'),
                ),
                HoverableListTile(
                  leading: Icon(Icons.list, color: Colors.white),
                  title: "Confirm Payment",
                  onTap: () => onMenuSelected('/confirmPayment'),
                ),
              ],
            ),

            HoverableExpansionTile(
              leading: Icon(Icons.analytics, color: Colors.white),
              title: "Business analysis",
              children: [
                HoverableListTile(
                  leading: Icon(Icons.analytics, color: Colors.white),
                  title: "Evolution of reserves",
                  onTap: () => onMenuSelected('/'),
                ),
              ],
            ),

            // GeoLocation
            HoverableExpansionTile(
              leading: Icon(Icons.location_on, color: Colors.white),
              title: "GeoLocation",
              children: [
                HoverableListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: "View maps",
                  onTap: () => onMenuSelected('/geolocation'),
                ),
              ],
            ),

            Divider(color: Colors.white54), // Separador entre os itens

            // Settings
            HoverableListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: "Settings",
              onTap: () => onMenuSelected('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget personalizado para ListTile com efeito de hover
class HoverableListTile extends StatefulWidget {
  final Widget leading;
  final String title;
  final VoidCallback onTap;

  const HoverableListTile({
    Key? key,
    required this.leading,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  _HoverableListTileState createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<HoverableListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? Colors.blue.shade700 : Colors.transparent, // Cor de destaque ao passar o mouse
        child: ListTile(
          leading: widget.leading,
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal, // Texto em negrito ao passar o mouse
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// Widget personalizado para ExpansionTile com efeito de hover
class HoverableExpansionTile extends StatefulWidget {
  final Widget leading;
  final String title;
  final List<Widget> children;

  const HoverableExpansionTile({
    Key? key,
    required this.leading,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  _HoverableExpansionTileState createState() => _HoverableExpansionTileState();
}

class _HoverableExpansionTileState extends State<HoverableExpansionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? Colors.blue.shade700 : Colors.transparent, // Cor de destaque ao passar o mouse
        child: ExpansionTile(
          leading: widget.leading,
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal, // Texto em negrito ao passar o mouse
            ),
          ),
          children: widget.children,
        ),
      ),
    );
  }
}