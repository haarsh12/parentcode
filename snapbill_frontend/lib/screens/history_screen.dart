import 'package:flutter/material.dart';
import '../models/shop_details.dart';
import '../core/theme.dart';
import '../widgets/bill_receipt_widget.dart'; // Ensure this is imported

class HistoryScreen extends StatelessWidget {
  final ShopDetails shopDetails;
  final List<Map<String, dynamic>> pastBills;

  const HistoryScreen({
    super.key,
    required this.shopDetails,
    required this.pastBills,
  });

  // Helper: Format number without .0 for whole numbers
  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (pastBills.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Past 7 Days Bills")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_rounded,
                  size: 60, color: Colors.grey),
              const SizedBox(height: 10),
              Text("No bills found",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
        ),
      );
    }

    void showBillPopup(BuildContext context, Map<String, dynamic> billData) {
      // FIXED: Ensure 'items' are properly extracted for the receipt widget
      // This makes sure the list is not empty or null
      List<dynamic> billItems = billData['items'] ?? [];

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reusing the BillReceiptWidget ensures visual consistency
                // and shows all items, rates, and totals.
                BillReceiptWidget(
                  shopDetails: shopDetails,
                  snapshotShopName: billData['shopName'],
                  snapshotAddress: billData['shopAddress'],
                  snapshotPhone: billData['shopPhone'],
                  billId: billData['id'],
                  date: billData['date'],
                  time: billData['time'],
                  items: billItems, // Passing the full items list here
                  total: (billData['total'] as num).toDouble(),
                  isHindi: false,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Past 7 Days Bills")),
      backgroundColor: Colors.grey[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pastBills.length,
        itemBuilder: (context, index) {
          final bill = pastBills[index];
          return Card(
            elevation: 2,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => showBillPopup(context, bill),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bill['id'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("${bill['date']} • ${bill['time']}",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      "₹${_formatNumber((bill['total'] as num).toDouble())}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
