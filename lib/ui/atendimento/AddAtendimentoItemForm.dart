import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AddAtendimentoItemForm extends StatefulWidget {
  const AddAtendimentoItemForm({super.key});

  @override
  _AddAtendimentoItemFormState createState() => _AddAtendimentoItemFormState();
}

class _AddAtendimentoItemFormState extends State<AddAtendimentoItemForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _checkedItems = []; // Para armazenar os itens selecionados
  List<Map<String, dynamic>> _availableItems = []; // Itens da tabela de itens

  @override
  void initState() {
    super.initState();
    _fetchAvailableItems(); // Buscar itens da tabela
  }

  // Função para buscar os itens da tabela de itens
  Future<void> _fetchAvailableItems() async {
    final response = await http.get(Uri.parse(
        '${dotenv.env['BASE_URL']}/Item')); // Substitua pelo endpoint correto

    if (response.statusCode == 200) {
      setState(() {
        _availableItems =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Falha ao buscar itens disponíveis');
    }
  }

  // Função para enviar os itens selecionados para a API
  Future<void> _submitItems() async {
    if (_checkedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos um item.')));
      return;
    }

    try {
      for (String item in _checkedItems) {
        final atendimentoItem = {
          'atendimentoID': 1,
          'itemDescription': item,
        };

        final response = await http.post(
          Uri.parse('${dotenv.env['BASE_URL']}/atendimentoItem'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(atendimentoItem),
        );

        if (response.statusCode != 201) {
          throw Exception('Erro ao adicionar item: ${response.body}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itens adicionados com sucesso.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao adicionar itens: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Itens ao Atendimento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _availableItems.length,
                  itemBuilder: (context, index) {
                    final item = _availableItems[index];
                    return CheckboxListTile(
                      title: Text(
                          item['description']), // Substitua pelo campo correto
                      value: _checkedItems.contains(item['description']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _checkedItems.add(item['description']);
                          } else {
                            _checkedItems.remove(item['description']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _submitItems,
                child: const Text('Salvar Itens'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
