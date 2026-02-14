import 'dart:convert'; // Needed for Base64 decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import your existing pages
import '../components/boxes.dart';
import 'sales_management.dart';
import 'orders.dart';
import 'warehouse.dart';
import 'customize.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Navigation Methods
  void onOrdersClick(BuildContext context, String username) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => OrdersManagement(username: username)));
  }
  void onCustomizeClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Customize()));
  }
  void onSalesClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesManagementPage()));
  }
  void onWareClick(BuildContext context, String username) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WareHouse(username: username)));
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch User Profile (Shop Name & Photo)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {

        // Default values
        String shopName = "My Shop";
        String userName = "User";
        ImageProvider? profileImage;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var data = userSnapshot.data!.data() as Map<String, dynamic>;
          shopName = data['shop_name'] ?? "My Shop";
          userName = data['name'] ?? "User";

          // --- PROFILE IMAGE LOGIC ---
          String? photoUrl = data['photo_url'];
          if (photoUrl != null && photoUrl.isNotEmpty) {
            if (photoUrl.startsWith('http')) {
              // It's a URL (Google Sign In)
              profileImage = NetworkImage(photoUrl);
            } else {
              // It's Base64 (Manual Upload)
              try {
                profileImage = MemoryImage(base64Decode(photoUrl));
              } catch (e) {
                print("Error decoding image: $e");
              }
            }
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(shopName, style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFFF8500),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
                },
              )
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFFFF8500)),
                  accountName: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ""),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? const Icon(Icons.store, color: Color(0xFFFF8500), size: 40)
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Inventory'),
                  onTap: () => onWareClick(context, userName),
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
                  height: 80, // Slightly taller to fit avatar nicely
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome back to", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Text(
                            shopName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      // --- PROFILE PICTURE INSTEAD OF VERIFIED ICON ---
                      InkWell(
                        onTap: () => onCustomizeClick(context), // Shortcut to profile settings
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profileImage,
                          child: profileImage == null
                              ? const Icon(Icons.person, color: Colors.grey, size: 30)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- STAT BOXES ROW 1 ---
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => onSalesClick(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const StatBox(title: "Sales", value: "40"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => onOrdersClick(context, userName),
                        borderRadius: BorderRadius.circular(12),
                        child: const StatBox(title: "Orders", isTitleBold: true, icon: Icons.shop, iconColor: Colors.red),
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
                        onTap: () => onWareClick(context, userName),
                        child: const StatBox(title: "Warehouse", isTitleBold: true, icon: Icons.warehouse, iconColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => onCustomizeClick(context),
                        child: const StatBox(title: "Customize", icon: Icons.construction, iconColor: Colors.grey, isTitleBold: true),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 25),

                // --- SECTION TITLE ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // --- 2. INNER STREAM: FETCH ACTIVITIES ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .where('uid', isEqualTo: uid)
                        .orderBy('timestamp', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text("Error loading activity"));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("No recent activity.", style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;

                          // Format Data
                          String title = data['title'] ?? "Activity";
                          String subtitle = data['subtitle'] ?? "";
                          String type = data['type'] ?? "info";

                          // Format Time
                          Timestamp? t = data['timestamp'];
                          String timeStr = t != null
                              ? DateFormat('hh:mm a, dd MMM').format(t.toDate())
                              : "Just now";

                          // Determine Visuals
                          bool isOrder = type == 'order';
                          Color iconBg = isOrder ? Colors.green.shade50 : Colors.orange.shade50;
                          Color iconColor = isOrder ? Colors.green : Colors.orange;
                          IconData icon = isOrder ? Icons.shopping_cart : Icons.inventory_2;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 15),

                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}