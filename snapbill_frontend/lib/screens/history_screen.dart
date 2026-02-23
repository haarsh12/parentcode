import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_details.dart';
import '../models/dashboard.dart';
import '../core/theme.dart';
import '../services/analytics_service.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/top_selling_items_widget.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/peak_hours_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final ShopDetails shopDetails;

  const HistoryScreen({
    super.key,
    required this.shopDetails,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  DashboardData? _dashboardData;
  List<BillHistory> _bills = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('user_token'); // Changed from 'auth_token' to 'user_token'

    print('🔑 Auth token: ${_token != null ? "Found" : "Not found"}');

    if (_token != null) {
      final dashboard = await _analyticsService.getDashboard(_token!);
      final bills = await _analyticsService.getBills(_token!);
      
      print('📊 Dashboard loaded: ${dashboard != null}');
      print('📋 Bills loaded: ${bills.length} bills');
      
      setState(() {
        _dashboardData = dashboard;
        _bills = bills;
        _isLoading = false;
      });
    } else {
      print('❌ No auth token found');
      setState(() => _isLoading = false);
    }
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${_formatNumber(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard & History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards - 2x2 Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              DashboardSummaryCard(
                                title: 'Total Revenue',
                                value: _formatCurrency(_dashboardData?.summary.totalRevenue ?? 0),
                                icon: Icons.currency_rupee,
                                color: Colors.green,
                              ),
                              DashboardSummaryCard(
                                title: 'Total Bills',
                                value: (_dashboardData?.summary.totalBills ?? 0).toString(),
                                icon: Icons.receipt_long,
                                color: Colors.blue,
                              ),
                              DashboardSummaryCard(
                                title: 'Avg Bill Value',
                                value: _formatCurrency(_dashboardData?.summary.averageBillValue ?? 0),
                                icon: Icons.trending_up,
                                color: Colors.orange,
                              ),
                              DashboardSummaryCard(
                                title: 'Inventory Items',
                                value: (_dashboardData?.summary.totalInventoryItems ?? 0).toString(),
                                icon: Icons.inventory_2,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Top Selling Items and Category Chart - Side by Side
                          SizedBox(
                            height: 250,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TopSellingItemsWidget(
                                    items: _dashboardData?.topSellingItems ?? [],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CategoryPieChart(
                                    categories: _dashboardData?.categoryBreakdown ?? [],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Peak Hours Chart - Full Width
                          PeakHoursChart(
                            peakHours: _dashboardData?.peakHours ?? [],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Bills History Section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_bills.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off_rounded,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No bills found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Print a bill to see it here',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _bills.length,
                              itemBuilder: (context, index) {
                                final bill = _bills[index];
                                return Card(
                                  elevation: 1,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _showBillDetails(bill),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.lightGreenBg,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.receipt_long,
                                              color: AppColors.primaryGreen,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bill #${bill.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${DateFormat('dd MMM yyyy').format(bill.billDate)} • ${DateFormat('hh:mm a').format(bill.billDate)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (bill.customerName != null)
                                                  Text(
                                                    bill.customerName!,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${_formatNumber(bill.totalAmount)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                              Text(
                                                '${bill.totalItems} items',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showBillDetails(BillHistory bill) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bill #${bill.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (bill.customerName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Customer: ${bill.customerName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (bill.customerPhone != null) ...[
                        Text(
                          'Phone: ${bill.customerPhone}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const Divider(height: 24),
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...bill.items.map((item) {
                        final name = item['name'] ?? '';
                        final qty = item['quantity'] ?? item['qty'] ?? 0;
                        final unit = item['unit'] ?? '';
                        final price = item['price'] ?? item['rate'] ?? 0;
                        final total = item['total'] ?? 0;
                        
                        // Convert to double safely
                        final qtyDouble = qty is num ? qty.toDouble() : 0.0;
                        final priceDouble = price is num ? price.toDouble() : 0.0;
                        final totalDouble = total is num ? total.toDouble() : 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_formatNumber(qtyDouble)} $unit × ₹${_formatNumber(priceDouble)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${_formatNumber(totalDouble)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_formatNumber(bill.totalAmount)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
