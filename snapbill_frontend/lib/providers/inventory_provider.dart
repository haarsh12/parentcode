import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/inventory_service.dart';
import '../core/master_list.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();

  // Start with Master List (all price = 0.0)
  List<Item> _items = List.from(masterInventoryList);

  bool _isLoading = false;
  String _selectedCategory = 'Anaj';

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  // Filter Logic for Display
  List<Item> getFilteredItems(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _items.where((i) => i.category == _selectedCategory).toList();
    } else {
      return _items
          .where((i) => i.names
              .any((n) => n.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }
  }

  // CRITICAL: Get only items with price > 0 for AI and Backend operations
  List<Item> getItemsForBackend() {
    return _items.where((i) => i.price > 0).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // MODIFIED: Smart fetch that merges backend items with master list
  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("📥 Fetching items from backend...");
      final backendItems = await _service.getItems();
      print("✅ Fetched ${backendItems.length} items from backend");

      // Strategy: Update master list prices with backend data
      for (var backendItem in backendItems) {
        final index = _items.indexWhere((local) => local.id == backendItem.id);

        if (index != -1) {
          // Update existing item in master list with backend data
          _items[index] = Item(
            id: backendItem.id,
            names: backendItem.names.isNotEmpty
                ? backendItem.names
                : _items[index]
                    .names, // Use backend names if available, else keep master
            price: backendItem.price, // Use backend price
            unit: backendItem.unit,
            category: backendItem.category,
          );
          print(
              "🔄 Updated item ${backendItem.id}: ${backendItem.names[0]} - ₹${backendItem.price}");
        } else {
          // Item not in master list, add it (custom user item)
          _items.add(backendItem);
          print("➕ Added custom item: ${backendItem.names[0]}");
        }
      }
    } catch (e) {
      print("❌ Error fetching items: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // SIMPLIFIED: Add or Update item (Backend handles upsert logic)
  Future<void> addItem(Item newItem) async {
    try {
      print(
          "💾 Saving item: ${newItem.id} (${newItem.names[0]}) - ₹${newItem.price}");

      // Call backend - it will handle update vs create automatically
      await _service.addItem(newItem);

      // Update local state immediately for responsive UI
      final index = _items.indexWhere((i) => i.id == newItem.id);
      if (index != -1) {
        _items[index] = newItem;
        print("✅ Updated local item: ${newItem.names[0]}");
      } else {
        _items.add(newItem);
        print("✅ Added local item: ${newItem.names[0]}");
      }

      // Notify UI immediately
      notifyListeners();
    } catch (e) {
      print("❌ Save Error: $e");
      // Re-fetch on error to restore correct state
      await fetchItems();
    }
  }

  // Delete item (remove from backend and reset to price=0 locally)
  Future<void> deleteItem(String id) async {
    try {
      print("🗑️ Deleting item: $id");

      // Find item in master list
      final masterItem = masterInventoryList.firstWhere(
        (item) => item.id == id,
        orElse: () =>
            Item(id: '', names: [], price: 0.0, unit: '', category: ''),
      );

      if (masterItem.id.isNotEmpty) {
        // Item is from master list - reset to price 0.0
        final index = _items.indexWhere((item) => item.id == id);
        if (index != -1) {
          _items[index] = Item(
            id: masterItem.id,
            names: masterItem.names,
            price: 0.0, // Reset to 0
            unit: masterItem.unit,
            category: masterItem.category,
          );
          print("♻️ Reset item to price 0: ${masterItem.names[0]}");
        }
      } else {
        // Custom item not in master list - remove completely
        _items.removeWhere((item) => item.id == id);
        print("🗑️ Removed custom item completely");
      }

      notifyListeners();

      // Delete from backend
      await _service.deleteItem(id);
      print("✅ Deleted from backend");
    } catch (e) {
      print("❌ Delete Error: $e");
      // Re-fetch on error
      await fetchItems();
    }
  }
}
