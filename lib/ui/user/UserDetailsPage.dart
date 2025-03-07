import 'package:app/models/UserRenderImgBase64.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatelessWidget {
  final UserBase64 user;

  const UserDetailsPage({super.key, required this.user, required int userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            Text('Username: ${user.username}'),
            Text('First Name: ${user.firstName}'),
            Text('Last Name: ${user.lastName}'),
            Text('Email: ${user.email}'),
            // Adicione outros campos conforme necessário.
          ],
        ),
      ),
    );
  }
}
