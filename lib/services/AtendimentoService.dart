import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/Atendimento.dart';
import 'package:app/models/AtendimentoItem.dart';
import 'package:app/models/AtendimentoDocument.dart';
import 'package:app/models/User.dart';
import 'package:app/models/Veiculo.dart';
import 'package:app/services/AtendimentoItemService.dart';
import 'package:app/services/AtendimentoDocumentService.dart';
import 'package:http/http.dart' as http;

class AtendimentoService {
  final String baseUrl = 'http://localhost:5000';

  AtendimentoService(String s); // URL da API


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
    // Simulação de chamada à API
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
    // Verifica se a data de saída não é nula
    if (atendimento.dataSaida != null) {
      // Normaliza a data para remover a hora, mantendo apenas o dia
      DateTime data = DateTime(
        atendimento.dataSaida!.year,
        atendimento.dataSaida!.month,
        atendimento.dataSaida!.day,
      );

      // Incrementa a contagem de reservas para essa data
      if (atendimentosPorData.containsKey(data)) {
        atendimentosPorData[data] = atendimentosPorData[data]! + 1;
      } else {
        atendimentosPorData[data] = 1;
      }
    }
  }

  return atendimentosPorData; // Retorna o mapa ao final do método
}

  // Método para adicionar atendimento
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

  // Método para adicionar itens ao atendimento
  Future<void> addAtendimentoItems(
      List<String> checkedItems, int atendimentoID) async {
    AtendimentoItemService atendimentoItemService =
        AtendimentoItemService(baseUrl);

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

  // Método para adicionar documentos ao atendimento
  Future<void> addAtendimentoDocuments(
      List<Map<String, dynamic>> documents, int atendimentoID) async {
    AtendimentoDocumentService atendimentoDocumentService =
        AtendimentoDocumentService(baseUrl);

    for (var doc in documents) {
      final atendimentoDocument = AtendimentoDocument(
        atendimentoID: atendimentoID,
        itemDescription: doc['itemDescription'],
        image: doc['image'] as Uint8List?, // Imagem no formato Uint8List
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

  // Função para adicionar um atendimento completo com itens e documentos
  Future<void> addCompleteAtendimento(
    DateTime dateTime, {
    required DateTime dataSaida,
    required DateTime dataChegada,
    required String destino,
    required double kmInicial,
    required int reserveID,
    required List<String> checkedItems, // Lista de itens selecionados
    required List<Map<String, dynamic>> documents, // Lista de documentos
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

      // Adiciona itens ao atendimento
      if (checkedItems.isNotEmpty) {
        await addAtendimentoItems(checkedItems, createdAtendimento.id!);
      }

      // Adiciona documentos ao atendimento
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
      // Cria um mapa com os dados atualizados do atendimento
      Map<String, dynamic> atendimentoData = {
        'data_saida': dataSaida.toIso8601String(),
        'data_chegada': dataChegada.toIso8601String(),
        'destino': destino,
        'km_inicial': kmInicial,
        'km_final': kmFinal,
      };

      // Envia uma requisição PUT para a API
      final response = await http.put(
        Uri.parse('$baseUrl/atendimento/$atendimentoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(atendimentoData),
      );

      // Verifica se a requisição foi bem-sucedida
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
      // Criar um mapa com os dados convertidos para JSON
      Map<String, dynamic> data = {
        'km_final': kmFinal,
        'data_devolucao': dataDevolucao.toIso8601String(), // Converte para String compatível com JSON
      };

      // Enviar a requisição PUT para a API
      final response = await http.put(
        Uri.parse('$baseUrl/atendimento/$atendimentoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // Verificar se a requisição foi bem-sucedida
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

  // Método para deletar atendimento pelo ID
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
