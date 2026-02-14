import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// Import the activity service for logging
import '../services/ActivityServices.dart';

class OrdersManagement extends StatefulWidget {
  final String username;
  const OrdersManagement({super.key, required this.username});

  @override
  State<OrdersManagement> createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- LOGIC: DELETE ORDER ---
  void _deleteOrder(String orderId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Order?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order deleted")));
    }
  }


  void _handOverOrder(DocumentSnapshot orderDoc) async {
    // 1. Get data safely
    Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
    String orderId = orderDoc.id;
    String? productId = orderData['product_id'];

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Old Order (No ID). Delete manually."), backgroundColor: Colors.red),
      );
      return;
    }

    double orderQty = (orderData['quantity'] as num).toDouble();
    String productName = orderData['product_name'] ?? "Unknown";
    String unit = orderData['unit'] ?? "";

    // 2. Confirmation Dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hand Over Order?"),
        content: Text("1. Deduct $orderQty $unit from stock\n2. Add Income to Sales Balance\n3. Remove from active orders"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Confirm Handover", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      // 3. THE TRANSACTION
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // A. Get Product Data (For Stock & Price)
        DocumentReference productRef = FirebaseFirestore.instance.collection('warehouse').doc(productId);
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) throw Exception("Product not found in Warehouse");

        double currentStock = (productSnapshot.get('stock') as num).toDouble();
        // Get Price to calculate income
        double pricePerUnit = (productSnapshot.get('price') as num).toDouble();
        double totalIncome = pricePerUnit * orderQty;

        if (currentStock < orderQty) throw Exception("Insufficient Stock");

        // B. Update Stock
        transaction.update(productRef, {'stock': currentStock - orderQty});

        // C. Add to Sales History (ADDS BALANCE)
        DocumentReference saleRef = FirebaseFirestore.instance.collection('sales_history').doc();
        transaction.set(saleRef, {
          'uid': uid,
          'name': "Order: $productName", // Description
          'amount': totalIncome,         // Amount to add
          'type': 'Sale',                // 'Sale' adds to balance
          'timestamp': FieldValue.serverTimestamp(),
          'month_year': DateFormat('MM_yyyy').format(DateTime.now()),
        });

        // D. Delete Order
        transaction.delete(FirebaseFirestore.instance.collection('orders').doc(orderId));
      });

      // 4. Log Activity
      await ActivityServices.log(
          title: "Order Handed Over",
          subTitle: "$productName ($orderQty $unit)",
          type: "order"
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Handed Over! Balance Updated.")));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _showAddOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => AddOrderForm(uid: uid),
    );
  }

  bool _isUrgent(Timestamp? dueTimestamp) {
    if (dueTimestamp == null) return false;
    DateTime dueDate = dueTimestamp.toDate();
    Duration difference = dueDate.difference(DateTime.now());
    return difference.inDays <= 2 && difference.inDays >= -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8500),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Order", style: TextStyle(color: Colors.white)),
        onPressed: _showAddOrderSheet,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('uid', isEqualTo: uid)
            .orderBy('due_date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading orders"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No active orders."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool urgent = _isUrgent(data['due_date']);
              DateTime date = (data['due_date'] as Timestamp).toDate();

              return Card(
                elevation: urgent ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: urgent ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      leading: CircleAvatar(
                        backgroundColor: urgent ? Colors.red.shade100 : Colors.orange.shade50,
                        child: Icon(Icons.shopping_cart, color: urgent ? Colors.red : Colors.orange),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (urgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                              child: const Text("URGENT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Qty: ${data['quantity']} ${data['unit']}"),
                          Text("Addr: ${data['address']}"),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(DateFormat('dd MMM yyyy').format(date)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // --- BUTTON ROW ---
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _deleteOrder(doc.id),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            label: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),

                          // --- RENAMED BUTTON: HAND OVERED ---
                          ElevatedButton.icon(
                            onPressed: () => _handOverOrder(doc), // Calls the updated function
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.handshake, size: 18), // Changed icon to handshake
                            label: const Text("Hand Overed"), // Renamed Text
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- ADD ORDER FORM (Unchanged) ---
class AddOrderForm extends StatefulWidget {
  final String uid;
  const AddOrderForm({super.key, required this.uid});

  @override
  State<AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<AddOrderForm> {
  String? selectedProductId;
  Map<String, dynamic>? selectedProductData;
  double quantity = 1.0;
  DateTime? dueDate;
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  int get maxStock => selectedProductData != null ? selectedProductData!['stock'] : 0;
  String get unit => selectedProductData != null ? selectedProductData!['unit'] : '';
  String get productName => selectedProductData != null ? selectedProductData!['name'] : '';

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => dueDate = picked);
  }

  void _saveOrder() async {
    if (selectedProductId == null || _addressController.text.isEmpty || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'uid': widget.uid,
        'product_id': selectedProductId,
        'product_name': productName,
        'quantity': quantity,
        'unit': unit,
        'address': _addressController.text.trim(),
        'due_date': Timestamp.fromDate(dueDate!),
        'created_at': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      await ActivityServices.log(
          title: "New Order",
          subTitle: "$productName ($quantity $unit)",
          type: "order"
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create New Order", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('warehouse').where('uid', isEqualTo: widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Select Product", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  value: selectedProductId,
                  items: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text("${data['name']} | ${data['stock']} ${data['unit']}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedProductId = val;
                      selectedProductData = docs.firstWhere((d) => d.id == val).data() as Map<String, dynamic>;
                      quantity = 1.0;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if(quantity>1) quantity--; })),
                    Text(quantity.toStringAsFixed(0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => quantity++)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(dueDate == null ? "Select Due Date" : DateFormat('dd MMM yyyy').format(dueDate!)),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveOrder,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8500)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm Order", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}