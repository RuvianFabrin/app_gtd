import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../logic/gtd_service.dart';
import 'gtd_pages.dart'; // Reutiliza o GtdItemListView

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<GtdService>().referenceItems;
    
    return GtdItemListView(
      items: items,
      emptyListMessage: "Nenhum item de referência guardado.",
      subtitleBuilder: (item) {
        if (item.description == null || item.description!.isEmpty) {
          return null;
        }
        try {
          // Tenta converter o JSON do editor para texto simples
          final doc = quill.Document.fromJson(jsonDecode(item.description!));
          return Text(
            doc.toPlainText().replaceAll('\n', ' '), // Mostra como uma única linha
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        } catch (e) {
          // Se não for JSON, mostra o texto normal
          return Text(
            item.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
