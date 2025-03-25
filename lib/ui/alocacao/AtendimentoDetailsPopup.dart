import 'package:flutter/material.dart';
import 'package:app/models/AtendimentoItem.dart';
import 'package:app/models/AtendimentoDocument.dart';

class AtendimentoDetailsPopup extends StatelessWidget {
  final List<AtendimentoItem> items;
  final List<AtendimentoDocument> documents;

  const AtendimentoDetailsPopup({
    Key? key,
    required this.items,
    required this.documents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: const Text('Atendimento Details'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Items'),
                  Tab(text: 'Documents'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Itens
                    ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.itemDescription ?? 'No item name'),
                        );
                      },
                    ),
                    // Tab 2: Documentos
                    ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        return ListTile(
                          title: Text(document.itemDescription ?? 'No document name'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}