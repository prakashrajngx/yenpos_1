import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yenposapp/screens/regular_mode_page/provider/regular_mode_screen_provider.dart';
import 'package:yenposapp/screens/regular_mode_page/widget/custom_reusable_widget/letter_keyborard.dart';
import 'package:yenposapp/services/branchwise_item_fetch.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';

class Variance {
  final String varianceName;
  double varianceDefaultPrice;

  Variance({required this.varianceName, required this.varianceDefaultPrice});
}

class OrderModifyDialog extends StatefulWidget {
  final String itemName;
  final List<Variance> variances;
  final Function onAdd;
  // final Map<String, dynamic> mixbox;
  const OrderModifyDialog({
    super.key,
    required this.itemName,
    required this.variances,
    required this.onAdd,
    // required this.mixbox,
  });

  @override
  _OrderModifyDialogState createState() => _OrderModifyDialogState();
}

class _OrderModifyDialogState extends State<OrderModifyDialog> {
  Map<String, bool> selectedVariances = {};
  bool isSearchMode = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  SingleValueDropDownController _dropDownController =
      SingleValueDropDownController();
  List<Map<String, dynamic>> addedVariances = [];

  @override
  void initState() {
    super.initState();
    for (Variance variance in widget.variances) {
      selectedVariances[variance.varianceName] = false;
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showCustomKeyboard(context);
      } else {
        _overlayEntry?.remove();
      }
    });
  }

  double _calculateTotalWeight() {
    double total = 0;

    // Add predefined variances' weights
    total += widget.variances
        .fold(0, (sum, variance) => sum + variance.varianceDefaultPrice);

    // Add dynamically added variances' weights
    total += addedVariances.fold(
        0, (sum, variance) => sum + (variance['weight'] ?? 0));

    return total;
  }

  void _showCustomKeyboard(BuildContext context) {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            20, // Adjust bottom padding as needed
        left: MediaQuery.of(context).size.width * 0.25, // Center horizontally
        width: MediaQuery.of(context).size.width *
            0.5, // Set a fixed width (50% of screen width)
        child: Material(
          elevation: 8.0,
          borderRadius:
              BorderRadius.circular(10), // Optional: Add rounded corners
          child: CustomKeyboard(
            onTextInput: (myText) {
              _insertText(myText);
            },
            onBackspace: () {
              _backspaceText();
            },
            onClose: () {
              _focusNode.unfocus();
            },
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _insertText(String myText) {
    final text = _controller.text;
    final textSelection = _controller.selection;
    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      myText,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: textSelection.start + myText.length),
    );

    // Update the provider or search logic here if needed
    RegularModeProvider().setShowCustomKeyboard(true);
    print("Search query: $newText");
  }

  void _backspaceText() {
    final text = _controller.text;
    final textSelection = _controller.selection;
    final selectionLength = textSelection.end - textSelection.start;

    if (selectionLength > 0) {
      _insertText('');
    } else if (textSelection.start > 0) {
      final newText = text.substring(0, textSelection.start - 1) +
          text.substring(textSelection.end);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: textSelection.start - 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 30),
          ),
          Text(widget.itemName, style: const TextStyle(color: Colors.black)),
          ElevatedButton(
            onPressed: () async {
              // Combine predefined and added variances into a structured format
              // final combinedVariances = [
              //   ...widget.variances.map((v) => {
              //         'itemData': {
              //           'itemName': widget.itemName,
              //           'category': '', // Example category
              //           'itemGroup': '', // Example group
              //           'ItemType': '', // Example type
              //           'item_Uom': '', // Example unit
              //           'tax': 5, // Example tax percentage
              //           'item_Defaultprice': v.varianceDefaultPrice,
              //           'description': '', // Example description
              //           'hsnCode': '', // Example HSN code
              //           'status': 'Active',
              //         },
              //         'varianceData': {
              //           'varianceitemCode': '', // Example item code
              //           'varianceName': v.varianceName,
              //           'variance_Defaultprice': v.varianceDefaultPrice,
              //           'variance_Uom': 'Kg', // Example unit of measure
              //           'selfLife': 1, // Example self-life
              //           'reorderLevel': 10, // Example reorder level
              //         },
              //         'quantity': 1, // Default quantity
              //         'status': 'active', // Default status
              //       }),
              //   ...addedVariances.map((v) => {
              //         'itemData': {
              //           'itemName': widget.itemName,
              //           'category': '', // Example category
              //           'itemGroup': '', // Example group
              //           'ItemType': '', // Example type
              //           'item_Uom': '', // Example unit
              //           'tax': 5, // Example tax percentage
              //           'item_Defaultprice': v['weight'],
              //           'description': '', // Example description
              //           'hsnCode': '', // Example HSN code
              //           'status': 'Active',
              //         },
              //         'varianceData': {
              //           'varianceitemCode': '', // Example item code
              //           'varianceName': v['varianceName'],
              //           'variance_Defaultprice': v['weight'],
              //           'variance_Uom': 'Kg', // Example unit of measure
              //           'selfLife': 1, // Example self-life
              //           'reorderLevel': 10, // Example reorder level
              //         },
              //         'quantity': 1, // Default quantity
              //         'status': 'active', // Default status
              //       }),
              // ];

              Navigator.of(context).pop();
            },
            style: const ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              backgroundColor: WidgetStatePropertyAll(Colors.blue),
            ),
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVarianceGrid(),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Weight: ${_calculateTotalWeight().toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Reset predefined variances
                      widget.variances.forEach((v) {
                        v.varianceDefaultPrice = 0.0;
                      });
                      // Clear added variances
                      addedVariances.clear();
                    });
                  },
                  child: const Text(
                    "Clear All",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceGrid() {
    final itemProvider = Provider.of<ItemProvider>(context);

    // Combine both predefined variances and added variances
    final combinedVariances = [
      ...widget.variances.map((v) => {
            'varianceName': v.varianceName,
            'weight': v.varianceDefaultPrice,
            'isPredefined': true,
            'quantity': 1, // Default quantity for predefined variances
          }),
      ...addedVariances.map((v) => {
            'varianceName': v['varianceName'],
            'weight': v['weight'],
            'isPredefined': false,
            'quantity':
                v['quantity'] ?? 1, // Default quantity for added variances
          }),
    ];

    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 400,
          width: 500,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: combinedVariances.length +
                1, // +1 for the dropdown to add new variances
            itemBuilder: (context, index) {
              // Dropdown for adding new variances
              if (index == combinedVariances.length) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSearchMode = !isSearchMode;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.black12),
                    ),
                    alignment: Alignment.center,
                    child: DropdownSearch<String>(
                      popupProps: PopupProps.dialog(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Add items',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        title: const Text('Select a Variance'),
                      ),
                      items: itemProvider.varianceNames, // Variance names
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: 'Add items',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onChanged: (String? selectedVariance) {
                        if (selectedVariance != null) {
                          _addNewVariance(selectedVariance);
                        }
                      },
                    ),
                  ),
                );
              }

              final variance = combinedVariances[index];
              final isSelected =
                  selectedVariances[variance['varianceName']] ?? false;

              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (variance['isPredefined']) {
                        setState(() {
                          selectedVariances.updateAll((key, value) => false);
                          selectedVariances[variance['varianceName']] = true;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[800] : Colors.grey[200],
                        border: Border.all(
                          color:
                              isSelected ? Colors.grey[800]! : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              variance['varianceName'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (variance['weight'] !=
                              null) // Exclude weight for search-added items
                            Text(
                              '${variance['weight'].toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          // Quantity control for added variances
                          if (!variance['isPredefined'])
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove,
                                      size: 16, color: Colors.red),
                                  onPressed: variance['quantity'] > 1
                                      ? () {
                                          setState(() {
                                            variance['quantity']--;
                                          });
                                        }
                                      : null, // Prevent going below 1
                                ),
                                Text(
                                  '${variance['quantity']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add,
                                      size: 16, color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      variance['quantity']++;
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Remove single variance
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          if (variance['isPredefined']) {
                            final target = widget.variances.firstWhere((v) =>
                                v.varianceName == variance['varianceName']);
                            // Reset any price if needed
                          } else {
                            addedVariances.removeWhere((v) =>
                                v['varianceName'] == variance['varianceName']);
                          }
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _addNewVariance(String varianceName) {
    setState(() {
      addedVariances.add({
        "varianceName": varianceName,
        "weight": null, // No weight for search-added variances
        "quantity": 1, // Default quantity
      });
    });
  }

  Widget _buildVarianceList() {
    return Column(
      children: addedVariances.map((variance) {
        return ListTile(
          title: Text(
            variance['varianceName'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Weight: ${variance['weight'].toStringAsFixed(2)} kg'),
        );
      }).toList(),
    );
  }
}
