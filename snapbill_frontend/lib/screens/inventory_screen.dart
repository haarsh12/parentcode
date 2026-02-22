import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Anaj',
    'Atta',
    'Dal',
    'Masale',
    'Tel',
    'Dry Fruits',
    'Upvas',
    'Other'
  ];

  // List of standard units
  final List<String> _standardUnits = [
    'kg',
    'plate',
    'pis',
    'dozen',
    'litre',
    'pkt',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<InventoryProvider>(context, listen: false).fetchItems());
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2)));
  }

  void _showItemDialog({Item? item}) {
    final bool isEdit = item != null;

    // 4 NAME FIELDS
    final name1Ctrl = TextEditingController(
        text: isEdit && item.names.isNotEmpty ? item.names[0] : '');
    final name2Ctrl = TextEditingController(
        text: isEdit && item.names.length > 1 ? item.names[1] : '');
    final name3Ctrl = TextEditingController(
        text: isEdit && item.names.length > 2 ? item.names[2] : '');
    final name4Ctrl = TextEditingController(
        text: isEdit && item.names.length > 3 ? item.names[3] : '');

    final priceCtrl =
        TextEditingController(text: isEdit ? item.price.toString() : '');
    final customUnitCtrl = TextEditingController(text: isEdit ? item.unit : '');

    String selectedCategory = isEdit
        ? item.category
        : Provider.of<InventoryProvider>(context, listen: false)
            .selectedCategory;

    // Initial Unit Selection Logic
    String selectedUnit = 'kg';
    bool isCustomUnit = false;
    if (isEdit) {
      if (_standardUnits.contains(item.unit) && item.unit != 'Other') {
        selectedUnit = item.unit;
      } else {
        selectedUnit = 'Other';
        isCustomUnit = true;
        customUnitCtrl.text = item.unit;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? "Edit Item" : "Add New Item"),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _categories.contains(selectedCategory)
                      ? selectedCategory
                      : _categories[0],
                  decoration: const InputDecoration(labelText: "Category"),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 10),

                // NAME FIELD 1
                TextField(
                  controller: name1Ctrl,
                  decoration:
                      const InputDecoration(labelText: "Name 1 (Primary)"),
                ),
                const SizedBox(height: 10),

                // PRICE & UNIT PANEL
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedUnit,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Unit"),
                          items: _standardUnits
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedUnit = val!;
                              isCustomUnit = (val == 'Other');
                            });
                          },
                        ),
                        // Show text field ONLY if "Other" is selected
                        if (isCustomUnit)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: TextField(
                              controller: customUnitCtrl,
                              decoration: const InputDecoration(
                                  labelText: "Type Unit", isDense: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 15),

                // EXTRA NAME FIELDS (2, 3, 4)
                const Text("Other Names / Aliases",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                TextField(
                    controller: name2Ctrl,
                    decoration: const InputDecoration(
                        labelText: "Name 2", isDense: true)),
                const SizedBox(height: 5),
                TextField(
                    controller: name3Ctrl,
                    decoration: const InputDecoration(
                        labelText: "Name 3", isDense: true)),
                const SizedBox(height: 5),
                TextField(
                    controller: name4Ctrl,
                    decoration: const InputDecoration(
                        labelText: "Name 4", isDense: true)),

                // DELETE BUTTON
                if (isEdit) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                          onPressed: () {
                            Provider.of<InventoryProvider>(context,
                                    listen: false)
                                .deleteItem(item.id);
                            Navigator.pop(context);
                            _showNotification("${name1Ctrl.text} deleted");
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("DELETE ITEM",
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red)))),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (name1Ctrl.text.isEmpty) return;

                  // Collect all names
                  List<String> names = [name1Ctrl.text];
                  if (name2Ctrl.text.isNotEmpty) names.add(name2Ctrl.text);
                  if (name3Ctrl.text.isNotEmpty) names.add(name3Ctrl.text);
                  if (name4Ctrl.text.isNotEmpty) names.add(name4Ctrl.text);

                  // Determine Unit
                  String finalUnit =
                      isCustomUnit ? customUnitCtrl.text : selectedUnit;
                  if (finalUnit.isEmpty) finalUnit = 'kg';

                  final newItem = Item(
                    id: isEdit ? item.id : '',
                    names: names,
                    price: double.tryParse(priceCtrl.text) ?? 0,
                    unit: finalUnit,
                    category: selectedCategory,
                  );

                  // Save the item
                  await Provider.of<InventoryProvider>(context, listen: false)
                      .addItem(newItem);

                  // CRITICAL: Force refresh from backend to ensure UI shows latest data
                  await Provider.of<InventoryProvider>(context, listen: false)
                      .fetchItems();

                  if (mounted) {
                    Navigator.pop(context);
                    _showNotification("${names[0]} saved");
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final filteredItems = provider.getFilteredItems(_searchController.text);

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Text("Inventory",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = provider.selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) => provider.setCategory(cat),
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                  "No items found in ${provider.selectedCategory}",
                                  style: const TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    onTap: () => _showItemDialog(item: item),
                                    onLongPress: () =>
                                        _showItemDialog(item: item),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.lightGreenBg,
                                      child: Text(item.names[0][0],
                                          style: const TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(item.names[0],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    // SHOW MULTIPLE NAMES IN SUBTITLE
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item.names.length > 1)
                                          Text(item.names.sublist(1).join(", "),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                        Text("₹${item.price} / ${item.unit}",
                                            style: const TextStyle(
                                                color: AppColors.primaryGreen,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.grey),
                                      onPressed: () =>
                                          _showItemDialog(item: item),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showItemDialog(),
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
