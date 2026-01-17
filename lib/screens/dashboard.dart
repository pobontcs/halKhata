import 'package:flutter/material.dart';
import '../components/boxes.dart'; // Ensure this file exists
import 'sales_management.dart';
class DashboardPage extends StatelessWidget {
  final String username;
  final int totalSales = 40;

  // --- FIX 1: Move the list HERE (Class Level) ---
  // Now the 'build' method can access it.
  final List<ActivityItem> recentActivities = [
    ActivityItem(
      title: "Sold Goods",
      amount: "5,400",
      date: "10:23 AM",
      entity: "Rahim Store",
      isIncome: true, // Green
    ),
    ActivityItem(
      title: "Shop Rent",
      amount: "12,000",
      date: "Yesterday",
      isIncome: false, // Red
    ),
    ActivityItem(
      title: "Inventory Check",
      date: "Mon, 12 Jan",
      // amount is null, entity is null
    ),
  ];

  // Change this line in DashboardPage class
  void onSalesClick(BuildContext context) {
    Navigator.push( // changed to push (not replacement) so you can go back
      context,
      MaterialPageRoute(
        builder: (context) => const SalesManagementPage(), // Link the new page here
      ),
    );
  }

  // --- FIX 3: Remove 'const' from constructor ---
  // (Since the list above contains objects, this widget isn't a compile-time constant)
  DashboardPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFFF8500)),
              accountName: Text(username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: const Text("admin@halkhata.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFFFF8500), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- HEADER CONTAINER ---
            Container(
              width: double.infinity,
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Welcome back $username",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.star, color: Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // --- STAT BOXES ROW 1 ---
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap:()=> onSalesClick(context),
                    borderRadius: BorderRadius.circular(12),
                    child: StatBox(
                      title: "Sales",
                      value: totalSales.toString(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: StatBox(
                      title: "Expense",
                      isTitleBold: true,
                      icon: Icons.trending_down,
                      iconColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- STAT BOXES ROW 2 ---
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: StatBox(
                      title: "WareHouse",
                      isTitleBold: true,
                      icon: Icons.warehouse,
                      iconColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(

                      child: StatBox(
                        title: "Customize",
                        icon: Icons.construction,
                        iconColor: Colors.grey,
                        isTitleBold: true,
                      )),
                )
              ],
            ),

            const SizedBox(height: 25),

            // --- SECTION TITLE ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- THE DYNAMIC LIST ---
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: recentActivities.length,
                itemBuilder: (context, index) {
                  final item = recentActivities[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        // 1. Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.isIncome
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: item.isIncome ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)
                              ),
                              if (item.entity != null)
                                Text(
                                  "To: ${item.entity}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              Text(
                                item.date,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),

                        // 3. Amount
                        if (item.amount != null)
                          Text(
                            "${item.isIncome ? '+' : '-'} ৳${item.amount}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: item.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                      ],
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

// --- FIX 2: Define the Class HERE ---
class ActivityItem {
  final String title;
  final String date;
  final String? amount;
  final String? entity;
  final bool isIncome;

  ActivityItem({
    required this.title,
    required this.date,
    this.amount,
    this.entity,
    this.isIncome = false,
  });
}