import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for numeric filtering

class WareHouse extends StatefulWidget {
  const WareHouse({super.key});

  @override
  State<WareHouse> createState() => _WareHouseState();
}

class _WareHouseState extends State<WareHouse> {
  // 1. FILTER STATE
  String _selectedFilter = 'All'; // Options: All, Low Stock, Out of Stock

  // Dummy Inventory Data (Mutable List for updates)
  List<Map<String, dynamic>> inventory = [
    {'name': 'Miniket Rice', 'stock': 45, 'unit': 'kg', 'price': 65},
    {'name': 'Musur Dal', 'stock': 5, 'unit': 'kg', 'price': 120},
    {'name': 'Soybean Oil', 'stock': 120, 'unit': 'Ltr', 'price': 185},
    {'name': 'Sugar', 'stock': 0, 'unit': 'kg', 'price': 130},
    {'name': 'Polo Shirt', 'stock': 50, 'unit': 'XL', 'price': 550},
  ];

  // --- LOGIC: Filter Inventory ---
  List<Map<String, dynamic>> get _filteredInventory {
    if (_selectedFilter == 'All') return inventory;
    if (_selectedFilter == 'Low Stock') {
      return inventory.where((item) => item['stock'] > 0 && item['stock'] < 10).toList();
    }
    if (_selectedFilter == 'Out of Stock') {
      return inventory.where((item) => item['stock'] == 0).toList();
    }
    return inventory;
  }

  // --- LOGIC: Show Add Product Sheet ---
  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddProductForm(),
    );
  }

  // --- LOGIC: Adjust Stock Dialog (Reduce/Add) ---
  void _showAdjustmentDialog(Map<String, dynamic> item) {
    int currentStock = item['stock'];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Adjust ${item['name']}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Update Stock Quantity:"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrease Button
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 40),
                        onPressed: () {
                          if (currentStock > 0) {
                            setDialogState(() => currentStock--);
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "$currentStock",
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      // Increase Button
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 40),
                        onPressed: () {
                          setDialogState(() => currentStock++);
                        },
                      ),
                    ],
                  ),
                  Text(item['unit'], style: const TextStyle(color: Colors.grey)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8500)),
                  onPressed: () {
                    // Update the main state
                    setState(() {
                      item['stock'] = currentStock;
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Warehouse', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8500),
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          // 1. FILTER CHIPS SECTION
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

          // 2. INVENTORY LIST
          Expanded(
            child: _filteredInventory.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredInventory.length,
              itemBuilder: (context, index) {
                final item = _filteredInventory[index];
                final double stock = item['stock'].toDouble();
                final bool isLowStock = stock < 10;
                final bool isOutOfStock = stock == 0;

                return InkWell(
                  // Trigger stock adjustment on tap
                  onTap: () => _showAdjustmentDialog(item),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade200 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: isOutOfStock ? Colors.grey : Colors.orange,
                        ),
                      ),
                      title: Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isOutOfStock ? Colors.grey : Colors.black,
                          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text("Price: ৳${item['price']} / ${item['unit']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${item['stock']} ${item['unit']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isLowStock ? Colors.red : Colors.green,
                            ),
                          ),
                          if (isLowStock)
                            Text(
                              isOutOfStock ? "Out of Stock" : "Low Stock",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for filter chips
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: const Color(0xFFFF8500),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

// --- UPDATED FORM WIDGET ---
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  String selectedUnit = 'kg';
  // Added extra units including sizes
  final List<String> units = ['kg', 'Ltr', 'pcs', 'box', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              "Add New Stock",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                labelText: "Product Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    // Use input formatters if you want ONLY numbers (no text)
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Selling Price",
                      prefixText: "৳ ",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: InputDecoration(
                      labelText: "Unit",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text("Initial Stock", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                keyboardType: TextInputType.number,
                // FORCING NUMERIC ONLY HERE
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter quantity (e.g. 50)",
                  icon: Icon(Icons.numbers),
                ),
              ),
            ),

            const SizedBox(height: 25),

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
                child: const Text("Add to Warehouse", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}