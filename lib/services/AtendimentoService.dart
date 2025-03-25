import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/Atendimento.dart';
import 'package:app/models/AtendimentoItem.dart';
import 'package:app/models/AtendimentoDocument.dart';
import 'package:app/models/User.dart';
import 'package:app/models/Veiculo.dart';
import 'package:app/services/AtendimentoItemService.dart';
import 'package:app/services/AtendimentoDocumentService.dart';
import 'package:app/ui/alocacao/ManageAlocarMotoristaPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AtendimentoService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  AtendimentoService(String s); // URL da API

  // Método para buscar a reserveId e, a partir dela, buscar o clientId e os detalhes do usuário
  Future<User> fetchReserveIdAndUserDetails(int reserveId) async {
  try {
    print('Fetching reserve details for reserveId: $reserveId');

    // Passo 1: Buscar a reserva para obter o clientId
    final responseReserve = await http.get(
      Uri.parse('$baseUrl/reserva/$reserveId'),
    );

    print('Response status: ${responseReserve.statusCode}');
    print('Response body: ${responseReserve.body}');

    if (responseReserve.statusCode == 200) {
      final Map<String, dynamic> reserveData = jsonDecode(responseReserve.body);
      print('Reserve data: $reserveData');

      // Verifique se a chave 'clientID' existe no JSON
      if (!reserveData.containsKey('clientID')) {
        throw Exception('clientID not found in reserve data');
      }

      final int clientId = reserveData['clientID']; // Note que é 'clientID', não 'clientId'
      print('Fetching user details for clientId: $clientId');

      // Passo 2: Buscar os detalhes do usuário usando o clientId
      final UserServiceDetails userServiceDetails = UserServiceDetails();
      final responseUser = await userServiceDetails.getUserByName(clientId);

      print('Response from user service: $responseUser');

      if (responseUser == null) {
        throw Exception('User not found for clientId: $clientId');
      }

      final User user = User.fromJson(responseUser as Map<String, dynamic>);
      print('User details: ${user.toJson()}');

      return user;
    } else {
      throw Exception('Failed to fetch reserve details: ${responseReserve.statusCode}');
    }
  } catch (error) {
    print('Error fetching reserve and user details: $error');
    throw Exception('Failed to fetch reserve and user details: $error');
  }
}


Future<Map<String, dynamic>> fetchAtendimentoDetails(int atendimentoId) async {
  try {
    print('Fetching details for atendimentoId: $atendimentoId');

    // Buscar detalhes do atendimento
    final responseAtendimento = await http.get(
      Uri.parse('$baseUrl/atendimento/$atendimentoId'),
    );

    if (responseAtendimento.statusCode == 200) {
      final Map<String, dynamic> atendimentoData = jsonDecode(responseAtendimento.body);

      // Buscar itens do atendimento
      final responseItems = await http.get(
        Uri.parse('$baseUrl/atendimento/$atendimentoId/items'),
      );
      final List<dynamic> itemsJson = jsonDecode(responseItems.body);
      final List<AtendimentoItem> items = itemsJson
          .map((item) => AtendimentoItem.fromJson(item))
          .toList();

      // Buscar documentos do atendimento
      final responseDocuments = await http.get(
        Uri.parse('$baseUrl/atendimento/$atendimentoId/documents'),
      );
      final List<dynamic> documentsJson = jsonDecode(responseDocuments.body);
      final List<AtendimentoDocument> documents = documentsJson
          .map((doc) => AtendimentoDocument.fromJson(doc))
          .toList();

      // Retornar os dados em um mapa
      return {
        'atendimento': atendimentoData,
        'items': items,
        'documents': documents,
      };
    } else {
      throw Exception('Failed to fetch atendimento details: ${responseAtendimento.statusCode}');
    }
  } catch (error) {
    print('Error fetching atendimento details: $error');
    throw Exception('Failed to fetch atendimento details: $error');
  }
}


  // Métodos existentes do AtendimentoService...
  Future<void> allocateDriver(int atendimentoId, int driverId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/atendimento/$atendimentoId/allocateDriver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'driverId': driverId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to allocate driver');
    }
  }

  Future<List<Atendimento>> fetchAtendimentos() async {
    final response = await http.get(Uri.parse('$baseUrl/atendimento'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Atendimento.fromJson(data)).toList();
    } else {
      throw Exception('Failed to fetch atendimentos');
    }
  }

  Map<DateTime, int> agruparAtendimentosPorData(List<Atendimento> atendimentos) {
    Map<DateTime, int> atendimentosPorData = {};

    for (var atendimento in atendimentos) {
      if (atendimento.dataSaida != null) {
        DateTime data = DateTime(
          atendimento.dataSaida!.year,
          atendimento.dataSaida!.month,
          atendimento.dataSaida!.day,
        );

        if (atendimentosPorData.containsKey(data)) {
          atendimentosPorData[data] = atendimentosPorData[data]! + 1;
        } else {
          atendimentosPorData[data] = 1;
        }
      }
    }

    return atendimentosPorData;
  }

  Future<Atendimento> addAtendimento(Atendimento atendimento,
      {required DateTime dataSaida,
      required DateTime dataChegada,
      required String destino,
      required double? kmInicial,
      required int? reserveID}) async {
    try {
      Map<String, dynamic> atendimentoData = {
        'data_saida': dataSaida.toIso8601String(),
        'data_chegada': dataChegada.toIso8601String(),
        'destino': destino,
        'km_inicial': kmInicial,
        'reserveID': reserveID,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/atendimento'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(atendimentoData),
      );

      if (response.statusCode == 201) {
        final atendimentoResponse = jsonDecode(response.body);
        print("Atendimento criado com sucesso: $atendimentoResponse");
        return Atendimento.fromJson(atendimentoResponse);
      } else {
        print("Erro ao adicionar atendimento: ${response.body}");
        throw Exception('Erro ao adicionar atendimento');
      }
    } catch (error) {
      print("Erro na requisição ao adicionar atendimento: $error");
      throw Exception('Erro na requisição: $error');
    }
  }

  Future<void> addAtendimentoItems(
      List<String> checkedItems, int atendimentoID) async {
    AtendimentoItemService atendimentoItemService =
        AtendimentoItemService(baseUrl!);

    for (String itemDescription in checkedItems) {
      final atendimentoItem = AtendimentoItem(
        atendimentoID: atendimentoID,
        itemDescription: itemDescription,
      );

      try {
        print('Enviando: ${atendimentoItem.toJson()}');
        await atendimentoItemService.addAtendimentoItem(atendimentoItem);
        print('Item adicionado com sucesso: $itemDescription');
      } catch (e) {
        print('Erro ao adicionar item: $e');
      }
    }
  }

  Future<void> addAtendimentoDocuments(
      List<Map<String, dynamic>> documents, int atendimentoID) async {
    AtendimentoDocumentService atendimentoDocumentService =
        AtendimentoDocumentService(baseUrl!);

    for (var doc in documents) {
      final atendimentoDocument = AtendimentoDocument(
        atendimentoID: atendimentoID,
        itemDescription: doc['itemDescription'],
        image: doc['image'] as Uint8List?,
      );

      try {
        print('Enviando documento: ${atendimentoDocument.toJson()}');
        await atendimentoDocumentService
            .addAtendimentoDocument(atendimentoDocument);
        print('Documento adicionado com sucesso: ${doc['itemDescription']}');
      } catch (e) {
        print('Erro ao adicionar documento: $e');
      }
    }
  }

  Future<void> addCompleteAtendimento(
    DateTime dateTime, {
    required DateTime dataSaida,
    required DateTime dataChegada,
    required String destino,
    required double kmInicial,
    required int reserveID,
    required List<String> checkedItems,
    required List<Map<String, dynamic>> documents,
  }) async {
    final atendimento = Atendimento(
      dataSaida: dataSaida,
      dataChegada: dataChegada,
      destino: destino,
      kmInicial: kmInicial,
      reserveID: reserveID,
    );

    try {
      final createdAtendimento = await addAtendimento(
        atendimento,
        dataSaida: dataSaida,
        dataChegada: dataChegada,
        destino: destino,
        kmInicial: kmInicial,
        reserveID: reserveID,
      );

      if (createdAtendimento.id == null) {
        print('Falha ao criar atendimento. ID inválido.');
        throw Exception('Falha ao criar atendimento. ID inválido.');
      }

      if (checkedItems.isNotEmpty) {
        await addAtendimentoItems(checkedItems, createdAtendimento.id!);
      }

      if (documents.isNotEmpty) {
        await addAtendimentoDocuments(documents, createdAtendimento.id!);
      }

      print("Atendimento completo adicionado com sucesso!");
    } catch (e) {
      print("Erro ao adicionar atendimento completo: $e");
      throw Exception('Erro ao adicionar atendimento completo');
    }
  }

  Future<void> updateAtendimento({
    required int atendimentoId,
    required DateTime dataSaida,
    required DateTime dataChegada,
    required String destino,
    required int kmInicial,
    required int kmFinal,
  }) async {
    try {
      Map<String, dynamic> atendimentoData = {
        'data_saida': dataSaida.toIso8601String(),
        'data_chegada': dataChegada.toIso8601String(),
        'destino': destino,
        'km_inicial': kmInicial,
        'km_final': kmFinal,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/atendimento/$atendimentoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(atendimentoData),
      );

      if (response.statusCode == 200) {
        print("Atendimento atualizado com sucesso: ${response.body}");
      } else {
        print("Erro ao atualizar atendimento: ${response.body}");
        throw Exception('Erro ao atualizar atendimento');
      }
    } catch (error) {
      print("Erro na requisição ao atualizar atendimento: $error");
      throw Exception('Erro na requisição: $error');
    }
  }

  Future<void> updateKmFinal({
    required int atendimentoId,
    required double kmFinal,
    required DateTime dataDevolucao,
  }) async {
    try {
      Map<String, dynamic> data = {
        'km_final': kmFinal,
        'data_devolucao': dataDevolucao.toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$baseUrl/atendimento/$atendimentoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("Km final atualizado com sucesso: ${response.body}");
      } else {
        print("Erro ao atualizar km final: ${response.body}");
        throw Exception('Erro ao atualizar km final');
      }
    } catch (error) {
      print("Erro na requisição ao atualizar km final: $error");
      throw Exception('Erro na requisição: $error');
    }
  }

  Future<User?> fetchUserByReserveID(String reserveID) async {
    final response = await http.get(Uri.parse('$baseUrl/reserves/$reserveID/user'));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load user for reserveID: $reserveID');
  }

  Future<Veiculo?> fetchVeiculoByReserveID(String reserveID) async {
    final response = await http.get(Uri.parse('$baseUrl/reserves/$reserveID/veiculo'));
    if (response.statusCode == 200) {
      return Veiculo.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load veiculo for reserveID: $reserveID');
  }

  Future<void> deleteAtendimento(int atendimentoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/atendimento/$atendimentoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("Atendimento com ID $atendimentoId deletado com sucesso.");
      } else {
        print(
            "Erro ao deletar atendimento com ID $atendimentoId: ${response.body}");
        throw Exception('Erro ao deletar atendimento');
      }
    } catch (error) {
      print("Erro na requisição ao deletar atendimento: $error");
      throw Exception('Erro na requisição: $error');
    }
  }
}