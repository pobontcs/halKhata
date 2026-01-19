import 'package:flutter/material.dart';

class OrdersManagement extends StatefulWidget {
  const OrdersManagement({super.key});

  @override
  State<OrdersManagement> createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  // --- LOGIC: Show the Add Order Form ---
  void _showAddOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to go full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddOrderForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8500),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Order", style: TextStyle(color: Colors.white)),
        onPressed: _showAddOrderSheet,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text("No orders yet. Tap 'New Order' to start."),
        ),
      ),
    );
  }
}

// --- NEW WIDGET: The Form inside the Bottom Sheet ---
class AddOrderForm extends StatefulWidget {
  const AddOrderForm({super.key});

  @override
  State<AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<AddOrderForm> {
  // Form Variables
  String? selectedProduct;
  String? selectedSize;
  double quantity = 1.0;
  DateTime? dueDate;
  final TextEditingController _addressController = TextEditingController();

  // Dummy Data
  final List<String> products = ['Rice (Miniket)', 'Lentils', 'Sugar', 'Flour'];
  final List<String> sizes = ['S', 'M', 'L', 'XL', 'Kg', 'Sack'];

  // Date Picker Function
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != dueDate) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(

        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      // FIX START: Wrap the Column in SingleChildScrollView
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Create New Order",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 1. PRODUCT SELECTION
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Product",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: selectedProduct,
              items: products.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            ),
            const SizedBox(height: 16),

            // 2. SIZE SELECTION
            const Text("Size / Unit (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: sizes.map((size) {
                final isSelected = selectedSize == size;
                return ChoiceChip(
                  label: Text(size),
                  selected: isSelected,
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.deepOrange : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      selectedSize = selected ? size : null;// main conclusion
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 3. QUANTITY ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantity / Weight", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () {
                          if (quantity > 0.5) setState(() => quantity -= 0.5);
                        },
                      ),
                      Text(
                        "$quantity",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          setState(() => quantity += 0.5);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. DELIVERY ADDRESS
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Delivery Address",
                hintText: "Enter full address...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // 5. DATE PICKER
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      dueDate == null
                          ? "Select Due Date"
                          : "Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                      style: TextStyle(
                        color: dueDate == null ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 6. BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Confirm Order", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ), // FIX END: Close SingleChildScrollView
    );
  }
}