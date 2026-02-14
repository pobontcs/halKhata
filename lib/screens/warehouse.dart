import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ✅ ADDED THIS IMPORT
import '../services/ActivityServices.dart';

class WareHouse extends StatefulWidget {
  final String username;
  const WareHouse({super.key, required this.username});

  @override
  State<WareHouse> createState() => _WareHouseState();
}

class _WareHouseState extends State<WareHouse> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String _selectedFilter = 'All';

  // --- LOGIC: Update Stock ---
  void _updateStock(String docId, int newStock) {
    FirebaseFirestore.instance
        .collection('warehouse')
        .doc(docId)
        .update({'stock': newStock});
  }

  // --- LOGIC: DELETE PRODUCT ---
  void _deleteProduct(String docId, String productName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to remove '$productName'? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('warehouse').doc(docId).delete();
        await ActivityServices.log(
          title: "Product Deleted",
          subTitle: "Removed $productName from inventory",
          type: "delete",
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$productName deleted")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- LOGIC: Show Dialog to Edit Quantity ---
  void _showAdjustmentDialog(String docId, String name, int currentStock, String unit) {
    int tempStock = currentStock;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Adjust $name"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Update Stock Quantity:"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 40),
                        onPressed: () { if (tempStock > 0) setDialogState(() => tempStock--); },
                      ),
                      const SizedBox(width: 20),
                      Text("$tempStock", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 40),
                        onPressed: () => setDialogState(() => tempStock++),
                      ),
                    ],
                  ),
                  Text(unit, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8500)),
                  onPressed: () {
                    _updateStock(docId, tempStock);
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => AddProductForm(uid: uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Warehouse', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8500),
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Low Stock'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Out of Stock'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('warehouse')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int stock = (data['stock'] as num?)?.toInt() ?? 0;
                  if (_selectedFilter == 'Low Stock') return stock > 0 && stock < 10;
                  if (_selectedFilter == 'Out of Stock') return stock == 0;
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text("No items found"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    String docId = filteredDocs[index].id;
                    int stock = (data['stock'] as num?)?.toInt() ?? 0;
                    int price = (data['price'] as num?)?.toInt() ?? 0;
                    bool isOut = stock == 0;
                    bool isLow = stock < 10;

                    return InkWell(
                      onTap: () => _showAdjustmentDialog(docId, data['name'], stock, data['unit']),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOut ? Colors.grey.shade200 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2, color: isOut ? Colors.grey : Colors.orange),
                          ),
                          title: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isOut ? TextDecoration.lineThrough : null, color: isOut ? Colors.grey : Colors.black)),
                          subtitle: Text("Price: ৳$price / ${data['unit']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("$stock ${data['unit']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLow ? Colors.red : Colors.green)),
                                  if (isLow || isOut) Text(isOut ? "Out of Stock" : "Low Stock", style: const TextStyle(fontSize: 10, color: Colors.red)),
                                ],
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteProduct(docId, data['name']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
      selectedColor: const Color(0xFFFF8500),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class AddProductForm extends StatefulWidget {
  final String uid;
  const AddProductForm({super.key, required this.uid});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  String selectedUnit = 'kg';
  bool _isLoading = false;

  final List<String> units = ['kg', 'Ltr', 'pcs', 'box', 'S', 'M', 'L', 'XL', 'XXL'];

  void _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _costController.text.isEmpty || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String name = _nameController.text.trim();
      double sellingPrice = double.parse(_priceController.text.trim());
      double costPrice = double.parse(_costController.text.trim());
      int stockQty = int.parse(_stockController.text.trim());
      double totalInvestment = costPrice * stockQty;

      QuerySnapshot salesSnap = await FirebaseFirestore.instance
          .collection('sales_history')
          .where('uid', isEqualTo: widget.uid)
          .get();

      double currentBalance = 0;
      for (var doc in salesSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] as num).toDouble();
        if (data['type'] == 'Sale') currentBalance += amount;
        else currentBalance -= amount;
      }

      if (currentBalance < totalInvestment) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient Balance! Need ৳${totalInvestment.toStringAsFixed(0)}, have ৳${currentBalance.toStringAsFixed(0)}"), backgroundColor: Colors.red));
        }
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference newProductRef = FirebaseFirestore.instance.collection('warehouse').doc();
        transaction.set(newProductRef, {
          'uid': widget.uid,
          'name': name,
          'price': sellingPrice,
          'cost_price': costPrice,
          'stock': stockQty,
          'unit': selectedUnit,
          'created_at': FieldValue.serverTimestamp(),
        });

        DocumentReference newExpenseRef = FirebaseFirestore.instance.collection('sales_history').doc();
        transaction.set(newExpenseRef, {
          'uid': widget.uid,
          'name': "Stock Purchase: $name",
          'amount': totalInvestment,
          'type': 'Expense',
          'timestamp': FieldValue.serverTimestamp(),
          // ✅ FIX: Use DateFormat so it matches Sales Page (e.g., "02_2026")
          'month_year': DateFormat('MM_yyyy').format(DateTime.now()),
        });
      });

      await ActivityServices.log(
          title: "Stock Purchased",
          subTitle: "- ৳${totalInvestment.toStringAsFixed(0)} ($name)",
          type: "stock"
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Stock", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Product Name", prefixIcon: const Icon(Icons.shopping_bag_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _costController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: "Buying Price", prefixText: "৳ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.red.shade50))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: "Selling Price", prefixText: "৳ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.green.shade50))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(controller: _stockController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: "Initial Quantity", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: DropdownButtonFormField<String>(value: selectedUnit, decoration: InputDecoration(labelText: "Unit", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (val) => setState(() => selectedUnit = val!))),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Purchase & Add Stock", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}