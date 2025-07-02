import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  late String uid;

  int totalSalesToday = 0;
  int totalRevenueToday = 0;
  int totalProductsInStock = 0;
  int lowStockCount = 0;
  int allTimeRevenue = 0;
  int expiredProductCount = 0;
  List<Map<String, dynamic>> recentSales = [];
  List<Map<String, dynamic>> lowStockItems = [];
  Map<String, Map<String, dynamic>> categorySales = {};
  List<Map<String, dynamic>> bestSellingProducts = [];

  @override
  void initState() {
    super.initState();
    uid = _auth.currentUser!.uid;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // DEBUG: Print the path being accessed for sales
    print('Reading sales from: user_inventory/$uid/sales');
    final salesSnapshot = await _dbRef.child('user_inventory/$uid/sales').get();
    final productsSnapshot = await _dbRef.child('user_inventory/$uid/products').get();

    // Maps for product and category aggregation
    Map<String, int> productSalesCount = {};
    Map<String, String> productToCategory = {};
    Map<String, String> productToName = {};
    Map<String, int> categoryTotalSales = {};

    // For each product, track total sold and total ever stocked
    Map<String, int> productTotalSold = {};
    Map<String, int> productCurrentStock = {};

    // Build product-to-category and product-to-name maps
    if (productsSnapshot.exists) {
      for (final product in productsSnapshot.children) {
        final data = product.value as Map;
        final barcode = data['barcode']?.toString() ?? '';
        final category = data['category']?.toString() ?? 'Uncategorized';
        final name = data['name']?.toString() ?? '';
        final currentQty = int.tryParse(data['quantity'].toString()) ?? 0;
        productToCategory[barcode] = category;
        productToName[barcode] = name;
        productCurrentStock[barcode] = currentQty;
      }
    }

    // Aggregate sales per product and per category
    if (salesSnapshot.exists) {
      for (final saleEntry in salesSnapshot.children) {
        final data = saleEntry.value as Map;
        // Use 'products' instead of 'items' for the list of sold products
        final productsList = data['products'] as List<dynamic>?;
        if (productsList != null) {
          for (final item in productsList) {
            final itemMap = item as Map;
            final barcode = itemMap['barcode']?.toString() ?? '';
            final qty = int.tryParse(itemMap['quantity'].toString()) ?? 0;
            productTotalSold[barcode] = (productTotalSold[barcode] ?? 0) + qty;
            productSalesCount[barcode] = (productSalesCount[barcode] ?? 0) + qty;
            final category = productToCategory[barcode] ?? 'Uncategorized';
            categoryTotalSales[category] = (categoryTotalSales[category] ?? 0) + qty;
          }
        }
      }
    }

    // Find best selling product per category and calculate percentage sold
    Map<String, Map<String, dynamic>> bestPerCategory = {};
    productSalesCount.forEach((barcode, qty) {
      final category = productToCategory[barcode] ?? 'Uncategorized';
      final name = productToName[barcode] ?? '';
      final totalSold = productTotalSold[barcode] ?? 0;
      final currentStock = productCurrentStock[barcode] ?? 0;
      final totalEverStocked = totalSold + currentStock;
      final percentSold = totalEverStocked > 0 ? (totalSold / totalEverStocked * 100).toStringAsFixed(1) : '0.0';
      // DEBUG: Print calculation for each product
      print('Product: $name, Barcode: $barcode, Category: $category, Total Sold: $totalSold, Current Stock: $currentStock, Total Ever Stocked: $totalEverStocked, Percent Sold: $percentSold');
      if (!bestPerCategory.containsKey(category) || qty > bestPerCategory[category]!['qty']) {
        bestPerCategory[category] = {
          'name': name,
          'qty': qty,
          'percentSold': percentSold,
        };
      }
    });
    bestSellingProducts = bestPerCategory.entries.map((e) => {
      'category': e.key,
      'name': e.value['name'],
      'qty': e.value['qty'],
      'percentSold': e.value['percentSold'],
    }).toList();

    

    if (salesSnapshot.exists) {
      List<Map<String, dynamic>> salesList = [];
      int todaySales = 0;
      int todayRevenue = 0;
      int totalRevenue = 0;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (final saleEntry in salesSnapshot.children) {
        final data = saleEntry.value as Map;
        final saleDateStr = data['saleDate'] as String?;
        final totalAmount = int.tryParse(data['totalAmount'].toString()) ?? 0;

        if (saleDateStr != null) {
          final saleDate = DateTime.parse(saleDateStr);
          if (DateFormat('yyyy-MM-dd').format(saleDate) == today) {
            todaySales++;
            todayRevenue += totalAmount;
          }
        }

        totalRevenue += totalAmount;
        salesList.add({
          'date': saleDateStr ?? '',
          'amount': totalAmount,
        });
      }

      salesList.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        totalSalesToday = todaySales;
        totalRevenueToday = todayRevenue;
        allTimeRevenue = totalRevenue;
        recentSales = salesList.take(5).toList();
      });
    }

    if (productsSnapshot.exists) {
      int totalStock = 0;
      int lowStock = 0;
      List<Map<String, dynamic>> lowStockList = [];
      final now = DateTime.now();
      int expiredCount = 0;
      for (final product in productsSnapshot.children) {
        final data = product.value as Map;
        final quantity = int.tryParse(data['quantity'].toString()) ?? 0;

        totalStock += quantity;
        if (quantity <= 2) {
          lowStock++;
          lowStockList.add({
            'name': data['name'],
            'quantity': quantity
          });
        }
        // Check for expiry
        if (data['expiry_date'] != null && data['expiry_date'].toString().isNotEmpty) {
          try {
            final expiry = DateTime.parse(data['expiry_date'].toString());
            if (expiry.isBefore(now)) {
              expiredCount++;
            }
          } catch (e) {}
        }
      }
      setState(() {
        totalProductsInStock = totalStock;
        lowStockCount = lowStock;
        lowStockItems = lowStockList;
        expiredProductCount = expiredCount;
      });
      // Show popup if there are expired products
      if (expiredCount > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Expired Products'),
              content: Text('You have $expiredCount expired product(s) in your inventory.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    }

  }

  Widget _buildCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(children: [
              _buildCard("Today's Sales", "$totalSalesToday", Colors.blue),
              _buildCard("Revenue Today", "Tsh $totalRevenueToday", Colors.green),
            ]),
            Row(children: [
              _buildCard("Products In Stock", "$totalProductsInStock", Colors.purple),
              _buildCard("Low Stock Count", "$lowStockCount", Colors.redAccent),
            ]),
            Row(children: [
              Expanded(child: _buildCard("All-Time Revenue", "Tsh $allTimeRevenue", Colors.teal)),
              Expanded(child: _buildCard("Expired Products", "$expiredProductCount", Colors.orangeAccent)),
            ]),
           const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Low Stock Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                ),
                child: DataTable(
                columnSpacing: (constraints.maxWidth - 40) / 2, // Adjust spacing to fill width
                columns: const [
                  DataColumn(label: Text('Product Name')),
                ],
                rows: lowStockItems.map((item) {
                  return DataRow(
                  cells: [
                    DataCell(Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(item['name'].toString()),
                    ],
                    )),
                  ],
                  );
                }).toList(),
                dividerThickness: 1,
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.grey.shade100;
                  }
                  return null;
                  },
                ),
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                ),
              );
              },
            ),
              const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Best Selling Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (bestSellingProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No sales data available yet.', style: TextStyle(color: Colors.grey)),
              )
            else ...bestSellingProducts.map((prod) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: Text(prod['name'] != null && prod['name'].toString().isNotEmpty
                    ? "${prod['name']} (${prod['category']})"
                    : "Unknown Product (${prod['category']})"),
                subtitle: Text("Total sold: "+(prod['qty']?.toString() ?? '0')+"  |  % Sold: "+(prod['percentSold']?.toString() ?? '0.0')+"%"),
              ),
            )),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Recent Sales", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...recentSales.map((sale) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                title: Text(
                  "Amount: Tsh ${sale['amount']}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Date: ${sale['date']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                leading: const Icon(Icons.attach_money, color: Colors.green),
                ),
              )),
        
          ],
        ),
      ),
    );
  }
}
