import 'package:flutter/material.dart';

import '../model/variance.dart';
import 'custom_reusable_widget/gridItem_widget.dart';
import 'item_card.dart';
import 'variance_dialog.dart';

class MyGridView extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const MyGridView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridViewUI(
      items: items,
      itemBuilder: (context, item) => ItemCard(item: item),
      onTap: (item) {
        List<Variance> variances = item['variances']
            .map<Variance>((v) => Variance.fromJson(v))
            .toList();

        if (variances.isNotEmpty) {
          showVarianceDialog(context, variances, item['name']);
        }
      },
    );
  }
}
