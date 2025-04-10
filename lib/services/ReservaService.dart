import 'dart:convert';
import 'package:app/models/Reserva.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReservaService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  ReservaService(baseUrl);

  // Método para criar uma nova reserva
  Future<void> createReserva({
    required DateTime date,
    required String destination,
    required int numberOfDays,
    required int userID,
    required String inService, // ✅ Adicione no construtor
    required int clientID,
    required int veiculoID,
    required String state,
  }) async {
    final url = Uri.parse('$baseUrl/reserva');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date.toIso8601String(),
        'destination': destination,
        'number_of_days': numberOfDays,
        'inService': inService,
        'userID': userID,
        'clientID': clientID,
        'veiculoID': veiculoID,
        'state': state,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create reserva');
    }
  }

  Future<List<Reserva>> getReservas({int page = 1, int pageSize = 5}) async {
    final response = await http.get(Uri.parse('$baseUrl/reserva'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Reserva.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reservas');
    }
  }

  Map<DateTime, int> agruparReservasPorData(List<Reserva> reservas) {
    Map<DateTime, int> reservasPorData = {};

    for (var reserva in reservas) {
      // Normaliza a data para remover a hora, mantendo apenas o dia
      DateTime data = DateTime(reserva.date.year, reserva.date.month, reserva.date.day);

      // Incrementa a contagem de reservas para essa data
      if (reservasPorData.containsKey(data)) {
        reservasPorData[data] = reservasPorData[data]! + 1;
      } else {
        reservasPorData[data] = 1;
      }
    }

    return reservasPorData;
  }

  Future<void> confirmReserva(String reservaId) async {
    final url =
        '$baseUrl/reserva/state/$reservaId'; // Garante que a URL completa seja formada corretamente
    final body = jsonEncode({'state': 'Confirmed'});

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Reserva confirmed successfully');
      } else {
        print(
            'Failed to confirm reservation. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to confirm reserva');
      }
    } catch (e) {
      print('Exception occurred in confirmReserva: $e');
      throw Exception('Failed to confirm reserva');
    }
  }

  Future<void> unconfirmReserva(String reservaId) async {
    final url =
        '$baseUrl/reserva/state/$reservaId'; // Garante que a URL completa seja formada corretamente
    final body = jsonEncode({'state': 'Not Confirmed'});

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Reserva confirmed successfully');
      } else {
        print(
            'Failed to confirm reservation. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to confirm reserva');
      }
    } catch (e) {
      print('Exception occurred in confirmReserva: $e');
      throw Exception('Failed to confirm reserva');
    }
  }

 

  // Obter uma reserva pelo ID
  Future<Reserva> getReservaById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/reserva/$id'));

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reserva');
    }
  }

  // Atualizar uma reserva pelo ID
  Future<Reserva> updateReserva(int id, Reserva reserva) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reserva/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reserva.toJson()),
    );

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update reserva');
    }
  }

  // Deletar uma reserva pelo ID
  Future<void> deleteReserva(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/reserva/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete reserva');
    }
  }

  // Obter detalhes da reserva, usuário e veículo
  Future<Reserva> getReservaDetails(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/reserva/details/$id'));

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reserva details');
    }
  }

  Future<void> startAtendimento({
    required int reservaId,
    required DateTime dataSaida,
    required DateTime dataChegada,
    required String destino,
    required double kmInicial,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/atendimentos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reservaId': reservaId,
        'data_saida': dataSaida.toIso8601String(),
        'data_chegada': dataChegada.toIso8601String(),
        'destino': destino,
        'km_inicial': kmInicial,
      }),
    );

      if (response.statusCode != 201) {
        throw Exception('Failed to start rental process');
      }
    }

  Future<void> updateInService({
        required int reservaId,
        required String inService,
      }) async {
        final url = Uri.parse('$baseUrl/reserva/$reservaId/inService');
        final body = jsonEncode({'inService': inService});

        try {
          final response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          if (response.statusCode == 200) {
            print('inService updated successfully');
          } else {
            print('Failed to update inService. Status code: ${response.statusCode}');
            print('Response body: ${response.body}');
            throw Exception('Failed to update inService');
          }
        } catch (e) {
          print('Exception occurred in updateInService: $e');
          throw Exception('Failed to update inService');
        }
  }
}

