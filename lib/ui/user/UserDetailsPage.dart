import 'package:flutter/material.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'dart:convert';
import 'dart:typed_data';

class UserDetailsPage extends StatelessWidget {
  final UserBase64 user;

  const UserDetailsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com imagem e informações básicas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem do usuário
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: user.imgBase64 != null && user.imgBase64!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_addPadding(_removeDataPrefix(user.imgBase64!))),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.person, size: 60, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Detalhes básicos do usuário
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.person, 'Username', user.username),
                          _buildDetailRow(Icons.badge, 'First Name', user.firstName),
                          _buildDetailRow(Icons.badge, 'Last Name', user.lastName),
                          _buildDetailRow(Icons.email, 'Email', user.email),
                          if (user.gender != null)
                            _buildDetailRow(Icons.transgender, 'Gender', user.gender!),
                          if (user.birthdate != null)
                            _buildDetailRow(Icons.cake, 'Birthdate', user.birthdate as String), 
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Colors.grey),
              
              // Seção de informações de contato
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (user.phone1 != null)
                      _buildInfoCard(Icons.phone, 'Primary Phone', user.phone1!),
                    if (user.phone2 != null)
                      _buildInfoCard(Icons.phone_android, 'Secondary Phone', user.phone2!),
                    if (user.address != null)
                      _buildInfoCard(Icons.home, 'Address', user.address!),
                    if (user.neighborhood != null)
                      _buildInfoCard(Icons.location_city, 'Neighborhood', user.neighborhood!),
                    if (user.state != null)
                      _buildInfoCard(Icons.flag, 'State', user.state!),
                  ],
                ),
              ),
              
              // Seção de informações adicionais
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (user.password != null)
                      _buildInfoCard(Icons.lock, 'Password', user.password!),
                    if (user.createdAt != null)
                      _buildInfoCard(Icons.calendar_today, 'Account Created', 
                          user.createdAt!.toLocal().toString().split(' ')[0]),
                  ],
                ),
              ),
              
              // Botão de fechar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _removeDataPrefix(String base64String) {
    const prefix = 'data:image/jpeg;base64,';
    if (base64String.startsWith(prefix)) {
      return base64String.substring(prefix.length);
    }
    return base64String;
  }

  String _addPadding(String base64String) {
    final remainder = base64String.length % 4;
    if (remainder == 0) return base64String;
    return base64String.padRight(base64String.length + (4 - remainder), '=');
  }
}