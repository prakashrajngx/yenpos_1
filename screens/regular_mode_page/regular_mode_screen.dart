import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Global/custom_textWidgets.dart';
import '../../Global/search_drop_filed.dart';
import 'provider/cart_page_provider.dart';
import 'provider/regular_mode_screen_provider.dart';
import 'widget/current_sale_section.dart';
import 'widget/custom_reusable_widget/letter_keyborard.dart';
import 'widget/favoritePage_widget.dart';
import 'widget/mixedBox_page_widget.dart';
import 'widget/my_grid_view.dart';

class RegularModeScreen extends StatelessWidget {
  const RegularModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegularModeProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                Consumer<RegularModeProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onHorizontalDragEnd:
                                      (DragEndDetails details) {
                                    if (details.primaryVelocity! < 0) {
                                      // User swiped Left
                                      provider.changeCategory(
                                          1); // Move to next category
                                    } else if (details.primaryVelocity! > 0) {
                                      // User swiped Right
                                      provider.changeCategory(
                                          -1); // Move to previous category
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: Column(
                                                  children: [
                                                    SearchDropdown(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: SingleChildScrollView(
                                                controller:
                                                    provider.scrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    TextButton(
                                                      onPressed: () {
                                                        final saleProvider =
                                                            Provider.of<
                                                                    CurrentSaleProvider>(
                                                                context,
                                                                listen: false);
                                                        final currentItems =
                                                            saleProvider
                                                                .currentSaleItems;
                                                        // provider
                                                        //     .setFavorite(true);
                                                        saleProvider
                                                            .clearItems();
                                                      },
                                                      child: const Text(
                                                        "Favorite",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors
                                                                .lightBlue),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        provider.setMixed(
                                                            true); // Set Mixed as selected
                                                      },
                                                      child: const Text(
                                                        "Mixed",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors
                                                                .lightBlue),
                                                      ),
                                                    ),
                                                    ...provider.categories
                                                        .map((category) {
                                                      return TextButton(
                                                        onPressed: () {
                                                          provider
                                                              .filterItemsByCategory(
                                                                  category);
                                                        },
                                                        style: ButtonStyle(
                                                          shape:
                                                              const WidgetStatePropertyAll(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(Radius
                                                                          .circular(
                                                                              5)),
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              WidgetStateProperty
                                                                  .resolveWith<
                                                                      Color>(
                                                            (Set<WidgetState>
                                                                states) {
                                                              return category ==
                                                                      provider
                                                                          .selectedCategory
                                                                  ? const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      4,
                                                                      170,
                                                                      247)
                                                                  : Colors
                                                                      .white;
                                                            },
                                                          ),
                                                          foregroundColor:
                                                              WidgetStateProperty
                                                                  .resolveWith<
                                                                      Color>(
                                                            (Set<WidgetState>
                                                                states) {
                                                              return category ==
                                                                      provider
                                                                          .selectedCategory
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black;
                                                            },
                                                          ),
                                                        ),
                                                        child: CustomText(
                                                          text: category,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: RepaintBoundary(
                                          child: provider.isLoading
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator())
                                              : provider.isFavoriteSelected
                                                  ? const FavoritePageWidget() // Show Favorite page if selected
                                                  : provider.isMixedSelected
                                                      ? const MixedboxPageWidget() // Show Mixed page if selected
                                                      : MyGridView(
                                                          items: provider
                                                              .items), // Otherwise, show grid view
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              const Expanded(
                                flex: 1,
                                child: RepaintBoundary(
                                    child: CurrentSaleSection()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Consumer<RegularModeProvider>(
                  builder: (context, provider, child) {
                    return provider.showCustomKeyboard
                        ? Align(
                            alignment: Alignment.bottomLeft,
                            child: CustomKeyboard(
                              onTextInput: provider.onTextInput,
                              onBackspace: provider.onBackspace,
                              onClose: () {
                                provider.setShowCustomKeyboard(false);
                              },
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
