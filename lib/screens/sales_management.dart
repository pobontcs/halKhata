import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:displayside/services/ActivityServices.dart';

class SalesManagementPage extends StatefulWidget {
  const SalesManagementPage({super.key});

  @override
  State<SalesManagementPage> createState() => _SalesManagementPageState();
}

class _SalesManagementPageState extends State<SalesManagementPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  bool isExpense = false;
  bool _showGraph = false;

  void _saveTransaction() async {
    if (_customerController.text.isEmpty || _amountController.text.isEmpty) return;
    double amount = double.parse(_amountController.text.trim());
    String type = isExpense ? 'Expense' : 'Sale';

    try {
      await FirebaseFirestore.instance.collection('sales_history').add({
        'uid': uid,
        'name': _customerController.text.trim(),
        'amount': amount,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'month_year': DateFormat('MM_yyyy').format(DateTime.now()),
        'day': DateFormat('dd').format(DateTime.now()),
      });

      await ActivityServices.log(
        title: isExpense ? "Expense Recorded" : "New Sale",
        subTitle: "${isExpense ? '-' : '+'} ৳$amount (${_customerController.text})",
        type: isExpense ? "stock" : "money",
      );

      _customerController.clear();
      _amountController.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddTransactionSheet() {
    isExpense = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Record Transaction", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(controller: _customerController, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount", prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Row(children: [
                    Checkbox(value: isExpense, activeColor: Colors.red, onChanged: (val) => setModalState(() => isExpense = val!)),
                    const Text("Mark as Expense"),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isExpense ? Colors.red : const Color(0xFFFF8500)), onPressed: _saveTransaction, child: Text(isExpense ? "Save Expense" : "Save Sale", style: const TextStyle(color: Colors.white)))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAreaChart(List<double> data, Color color, String title) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Expanded(
            child: data.isEmpty
                ? Center(child: Text("No data yet", style: TextStyle(color: Colors.grey[400])))
                : CustomPaint(
              size: Size.infinite,
              painter: ChartPainter(data: data, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Sales & Finance", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFFF8500), iconTheme: const IconThemeData(color: Colors.white)),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showAddTransactionSheet, backgroundColor: const Color(0xFFFF8500), icon: const Icon(Icons.add, color: Colors.white), label: const Text("New Entry", style: TextStyle(color: Colors.white))),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          String shopName = userSnapshot.hasData && userSnapshot.data!.exists ? userSnapshot.data!.get('shop_name') ?? "My Shop" : "My Shop";

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('sales_history').where('uid', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
            builder: (context, salesSnapshot) {
              if (salesSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              var docs = salesSnapshot.data?.docs ?? [];

              double totalBalance = 0;
              double monthlySales = 0;
              double monthlyExpense = 0;
              String currentMonth = DateFormat('MM_yyyy').format(DateTime.now());

              List<double> saleTrend = [];
              List<double> expenseTrend = [];

              for (var doc in docs) {
                var data = doc.data() as Map<String, dynamic>;
                double amount = (data['amount'] as num).toDouble();
                String type = data['type'] ?? 'Sale';
                String month = data['month_year'] ?? '';

                if (type == 'Sale') {
                  totalBalance += amount;
                  if (month == currentMonth) {
                    monthlySales += amount;
                    if (saleTrend.length < 15) saleTrend.add(amount);
                  }
                } else {
                  totalBalance -= amount;
                  if (month == currentMonth) {
                    monthlyExpense += amount;
                    if (expenseTrend.length < 15) expenseTrend.add(amount);
                  }
                }
              }
              saleTrend = saleTrend.reversed.toList();
              expenseTrend = expenseTrend.reversed.toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))]),
                      child: Text("Welcome to $shopName", style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),

                    // --- TOGGLE BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Icon(Icons.numbers, size: 18),
                          selected: !_showGraph,
                          onSelected: (val) => setState(() => _showGraph = false),
                          selectedColor: const Color(0xFFFF8500),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Icon(Icons.show_chart, size: 18),
                          selected: _showGraph,
                          onSelected: (val) => setState(() => _showGraph = true),
                          selectedColor: const Color(0xFFFF8500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- CONTENT SWITCHER ---
                    Expanded(
                      child: _showGraph
                      // VIEW 1: GRAPH MODE (Only Charts)
                          ? SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAreaChart(saleTrend, Colors.green, "Sales Trend"),
                            const SizedBox(height: 15),
                            _buildAreaChart(expenseTrend, Colors.red, "Expense Trend"),
                            const SizedBox(height: 80), // Padding for FAB
                          ],
                        ),
                      )
                      // VIEW 2: NUMBER MODE (Fixed Balance + Scrollable History)
                          : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            width: double.infinity,
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF8500), Color(0xFFFF6F00)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Net Balance", style: TextStyle(fontSize: 14, color: Colors.white70)), const SizedBox(height: 5), Text("৳${totalBalance.toStringAsFixed(0)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))]),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard("Monthly Sales", "+ ৳${monthlySales.toStringAsFixed(0)}", Colors.green, Icons.arrow_upward)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildSummaryCard("Monthly Expense", "- ৳${monthlyExpense.toStringAsFixed(0)}", Colors.red, Icons.arrow_downward)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(children: [Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 10),

                          // --- SCROLLABLE HISTORY LIST (Fixes Overflow) ---
                          Expanded(
                            child: docs.isEmpty
                                ? const Center(child: Text("No history found", style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                              itemCount: docs.length,
                              padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                              itemBuilder: (context, index) {
                                var data = docs[index].data() as Map<String, dynamic>;
                                bool isSale = data['type'] == 'Sale';
                                Timestamp? t = data['timestamp'];
                                String time = t != null ? DateFormat('dd MMM, hh:mm a').format(t.toDate()) : "Just Now";
                                return Card(
                                  elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                  child: ListTile(
                                    leading: CircleAvatar(backgroundColor: isSale ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), child: Icon(isSale ? Icons.arrow_upward : Icons.arrow_downward, color: isSale ? Colors.green : Colors.red)),
                                    title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                    trailing: Text("${isSale ? '+' : '-'} ৳${data['amount']}", style: TextStyle(color: isSale ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
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

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  ChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);

    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    double w = size.width;
    double h = size.height;

    // Fix for single data point
    if (data.length < 2) {
      canvas.drawLine(Offset(0, h/2), Offset(w, h/2), linePaint);
      return;
    }

    double dx = w / (data.length - 1);
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    Path path = Path();
    double startY = h - ((data[0] - minVal) / range * h * 0.8) - (h * 0.1);
    path.moveTo(0, startY);

    for (int i = 1; i < data.length; i++) {
      double x = i * dx;
      double normalizedY = (data[i] - minVal) / range;
      double y = h - (normalizedY * h * 0.8) - (h * 0.1);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, linePaint);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}