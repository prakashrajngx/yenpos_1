import 'package:flutter/material.dart';
import '../../../data/global_data_manager.dart';
import '../../../services/branchwise_item_fetch.dart';

class RegularModeProvider with ChangeNotifier {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> originalItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<String> filteredVarianceNames = []; // To store filtered variance names
  TextEditingController searchController = TextEditingController();
  List<String> categories = [
    'Favorite',
    'Mixed',
    'Savouries'
  ]; // Add Favorite and Mixed here
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'Savouries';
  bool showCustomKeyboard = false;
  final ScrollController _scrollController = ScrollController();
  bool isFavoriteSelected = false; // To track favorite selection
  bool isMixedSelected = false; // To track mixed selection
  List<Map<String, dynamic>> favoriteItems = [];
  bool showMoreButton = false; // To show the square button after 25 items
  RegularModeProvider() {
    loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of ScrollController
    super.dispose();
  }

  String? selectedVariance;

  void setSelectedVariance(String? newValue) {
    selectedVariance = newValue;
    notifyListeners();
  }

  void setFavorite(bool value) {
    isFavoriteSelected = value;
    isMixedSelected = false; // Reset Mixed selection
    if (value) {
      favoriteItems = originalItems.take(25).toList(); // Show first 25 items
      showMoreButton =
          originalItems.length > 25; // Show button if more than 25 items
      items = favoriteItems;
    } else {
      items = List.from(originalItems); // Reset to original items
    }
    notifyListeners();
  }

  void showMoreItems() {
    if (isFavoriteSelected) {
      // Show the remaining favorite items when the square button is clicked
      favoriteItems = originalItems;
      showMoreButton = false; // Hide the button
      items = favoriteItems;
      notifyListeners();
    }
  }

  void setMixed(bool value) {
    isMixedSelected = value;
    isFavoriteSelected = false; // Reset Favorite selection
    if (value) {
      items =
          originalItems; // You can reset or filter items for mixed selection here
    } else {
      items = List.from(originalItems); // Reset to original items
    }
    notifyListeners();
  }

  void clearVarianceSearch() {
    filteredVarianceNames = [];
    notifyListeners();
  }

  Future<void> loadData() async {
    final globalData = GlobalDataManager().branchwiseItems;
    final data = globalData['data'];
    ItemProvider().CategoriesFromData(globalData);

    if (data is Map) {
      items = data.entries
          .map((entry) {
            final itemEntry = entry.value;
            if (itemEntry is Map) {
              final item = itemEntry['item'] as Map?;
              final variances = itemEntry['variance'] as Map? ?? {};
              List<Map<String, dynamic>> variancesList =
                  variances.entries.map((v) {
                final variance = v.value as Map? ?? {};
                final orderType = variance['orderType'] as Map? ?? {};
                final branchwise = variance['branchwise'] as Map? ?? {};
                return {
                  'varianceName': variance['varianceName'] as String? ?? '',
                  'varianceDefaultPrice':
                      (variance['variance_Defaultprice'] as num?)?.toDouble() ??
                          0.0,
                  'varianceUOM': (variance['variance_Uom'] as String?) ?? '',
                  'takeawayPrice':
                      (orderType['TakeAway']?['TakeAway_Price'] as num?)
                              ?.toDouble() ??
                          0.0,
                  'branchPriceAR':
                      (branchwise['AR']?['Price_AR'] as num?)?.toDouble() ??
                          0.0,
                };
              }).toList();
              return {
                'name': item?['itemName'] as String? ?? '',
                'category': item?['category'] as String? ?? '',
                'imagePath': '', // Add image path if needed
                'variances': variancesList,
              };
            }
            return null;
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();

      originalItems = List.from(items); // Keep original items for reset
      categories = globalData['categories'].cast<String>();
      isLoading = false;
      notifyListeners();

      // Automatically apply the filter for the "Bakery" category if it exists
      if (categories.contains(selectedCategory)) {
        filterItemsByCategory(selectedCategory);
      }
    } else {
      items = [];
      categories = [];
      isLoading = false;
      notifyListeners();
    }
  }

  void filterItemsByCategory(String category) {
    if (category == 'Favorite') {
      setFavorite(true);
    } else if (category == 'Mixed') {
      setMixed(true);
    } else {
      isFavoriteSelected = false;
      isMixedSelected = false;
      selectedCategory = category; // Remember the last selected category
      items =
          originalItems.where((item) => item['category'] == category).toList();
    }
    notifyListeners();
  }

  String getUOMForVariance(String varianceName) {
    for (var item in originalItems) {
      for (var variance in item['variances']) {
        if (variance['varianceName'] == varianceName) {
          return variance['varianceUOM'] ?? 'N/A'; // Return the UOM
        }
      }
    }
    return 'N/A'; // Default if variance name is not found
  }

// Get full item data for the given variance name
  Map<String, dynamic> getItemDataForVariance(String varianceName) {
    return originalItems.firstWhere(
      (item) => item['variances']
          .any((variance) => variance['varianceName'] == varianceName),
      orElse: () => {},
    );
  }

// Get variance details for the given variance name
  Map<String, dynamic> getVarianceDetails(String varianceName) {
    return originalItems
        .expand((item) => item['variances'])
        .firstWhere((variance) => variance['varianceName'] == varianceName);
  }

  void filterItemsBySearchQuery(String query) {
    searchQuery = query;
    if (query.isEmpty) {
      // If the query is empty, check if a category is selected to filter by category
      if (selectedCategory.isNotEmpty) {
        items = originalItems
            .where((item) => item['category'] == selectedCategory)
            .toList();
      } else {
        // If no category is selected, reset to the full list
        items = List.from(originalItems);
      }
    } else {
      // Search across all items regardless of the category
      items = originalItems
          .where((item) =>
              item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void changeCategory(int delta) {
    int currentIndex = categories.indexOf(selectedCategory);
    int newIndex = (currentIndex + delta) % categories.length;
    if (newIndex < 0) {
      newIndex = categories.length - 1; // wrap to the last category
    }
    selectedCategory = categories[newIndex];
    filterItemsByCategory(selectedCategory);

    // Scroll to the selected category
    _scrollController.animateTo(
      (newIndex * 100.0), // Adjust 100.0 based on your button width
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onTextInput(String input) {
    searchQuery += input;
    filterItemsBySearchQuery(searchQuery);
  }

  void onBackspace() {
    if (searchQuery.isNotEmpty) {
      searchQuery = searchQuery.substring(0, searchQuery.length - 1);
      filterItemsBySearchQuery(searchQuery);
    }
  }

  void setShowCustomKeyboard(bool value) {
    showCustomKeyboard = value;
    notifyListeners();
  }

  void filterItemsByVarianceName(String query) {
    if (query.isEmpty) {
      filteredItems =
          List.from(originalItems); // Reset to original items if query is empty
    } else {
      filteredItems = originalItems.where((item) {
        // Check each item for variances that match the query
        return item['variances'].any((variance) =>
            (variance['varianceName'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()));
      }).toList();
    }
    notifyListeners();
  }

  void updateFilteredVarianceNames() {
    Set<String> varianceNamesSet = {};
    for (var item in originalItems) {
      for (var variance in item['variances']) {
        varianceNamesSet.add(variance['varianceName']);
      }
    }
    filteredVarianceNames = varianceNamesSet.toList();
    notifyListeners();
  }

  void filterVarianceNamesBySearchQuery(String query) {
    if (query.isEmpty) {
      updateFilteredVarianceNames(); // Reset to all variance names
    } else {
      filteredVarianceNames = originalItems
          .expand((item) => item['variances'])
          .where((variance) => variance['varianceName']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .map((variance) => variance['varianceName'] as String)
          .toSet()
          .toList(); // Ensure unique entries
      notifyListeners();
    }
  }

  ScrollController get scrollController => _scrollController;

  void changeCategoryOrOption(int i) {}
}
