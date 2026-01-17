import 'package:flutter/material.dart';

class SalesManagementPage extends StatefulWidget {
  const SalesManagementPage({super.key});

  @override
  State<SalesManagementPage> createState() => _SalesManagementPageState();
}

class _SalesManagementPageState extends State<SalesManagementPage> {
  // 1. Dummy Data List
  List<SaleItem> salesList = [
    SaleItem(
        id: "INV-001",
        customerName: "Rahim Store",
        amount: 5400,
        date: "Today, 10:23 AM"),
    SaleItem(
        id: "INV-002",
        customerName: "Karim Enterprise",
        amount: 1250,
        date: "Yesterday, 4:00 PM"),
    SaleItem(
        id: "INV-003",
        customerName: "Unknown Customer",
        amount: 320,
        date: "12 Jan, 9:30 AM"),
  ];

  // 2. Controller for inputs
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();

  // 3. Function to Add New Sale
  void _addNewSale() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow keyboard to push sheet up
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Sale",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _customerController,
                decoration: InputDecoration(
                  labelText: "Customer Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (৳)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_customerController.text.isNotEmpty &&
                        _amountController.text.isNotEmpty) {
                      setState(() {
                        salesList.insert(
                          0,
                          SaleItem(
                            id: "INV-NEW",
                            customerName: _customerController.text,
                            amount: double.parse(_amountController.text),
                            date: "Just Now",
                          ),
                        );
                      });
                      _customerController.clear();
                      _amountController.clear();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    "Save Sale",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Sales Management",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      // --- FAB (Add Button) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewSale,
        backgroundColor: const Color(0xFFFF8500),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Sale", style: TextStyle(color: Colors.white)),
      ),

      // --- BODY ---
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar (Visual only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search Invoice or Name...",
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions (${salesList.length})",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                TextButton(onPressed: () {}, child: const Text("Filter"))
              ],
            ),

            // The List
            Expanded(
              child: ListView.builder(
                itemCount: salesList.length,
                itemBuilder: (context, index) {
                  final sale = salesList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: const Icon(Icons.shopping_bag,
                            color: Colors.orange),
                      ),
                      title: Text(
                        sale.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${sale.id} • ${sale.date}",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      trailing: Text(
                        "+ ৳${sale.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Data Model for this page ---
class SaleItem {
  final String id;
  final String customerName;
  final double amount;
  final String date;

  SaleItem({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
  });
}