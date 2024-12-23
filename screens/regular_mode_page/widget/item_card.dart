import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Global/custom_colors.dart';
import '../../../Global/custom_textWidgets.dart';
import '../provider/favorite_page_provider.dart';

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemCard({super.key, required this.item});

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    bool isFavorite = favoriteProvider.isFavorite(widget.item);

    return Card(
      color: CustomColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      elevation: 4,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CustomText(
                      text: widget.item['name']?.isNotEmpty ?? false
                          ? widget.item['name'][0]
                          : '',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: CustomText(
                  text: widget.item['name'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CustomColors.black,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  favoriteProvider.toggleFavorite(widget.item);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
