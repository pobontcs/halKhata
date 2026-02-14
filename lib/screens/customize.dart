import 'dart:convert'; // Needed for Base64 conversion
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ActivityServices.dart';

class Customize extends StatefulWidget {
  const Customize({super.key});

  @override
  State<Customize> createState() => _CustomizeState();
}

class _CustomizeState extends State<Customize> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // --- LOGIC: UPDATE TEXT FIELDS ---
  Future<void> _updateField(String fieldKey, String newValue, String label) async {
    if (newValue.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        fieldKey: newValue.trim(),
      });
      await ActivityServices.log(title: "Profile Updated", subTitle: "Changed $label", type: "edit");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIC: PICK & SAVE IMAGE AS TEXT (BASE64) ---
  Future<void> _pickAndSaveImage() async {
    try {
      // 1. Pick Image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Resize image to be small (Crucial for Firestore limit)
        maxHeight: 512,
        imageQuality: 50, // Reduce quality to save space
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // 2. Convert Image to Text (Base64)
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 3. Update Firestore (Saving to 'photo_url')
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'photo_url': base64Image,
      });

      // 4. Log Activity
      await ActivityServices.log(title: "Photo Updated", subTitle: "Changed profile picture", type: "edit");

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI: EDIT TEXT SHEET ---
  void _showEditSheet(String label, String fieldKey, String currentValue, {bool isNumber = false}) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update $label", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
              decoration: InputDecoration(labelText: "New $label", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8500)),
                onPressed: () => _updateField(fieldKey, controller.text, label),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Not Logged In"));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Customize Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User profile not found."));

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // --- SMART IMAGE LOGIC ---
          // This handles both old Google URLs and new Base64 strings
          String? photoData = userData['photo_url'];
          ImageProvider? profileImage;

          if (photoData != null && photoData.isNotEmpty) {
            if (photoData.startsWith('http')) {
              // It's a URL (from Google Sign In)
              profileImage = NetworkImage(photoData);
            } else {
              // It's a Base64 string (from our manual upload)
              try {
                profileImage = MemoryImage(base64Decode(photoData));
              } catch (e) {
                print("Error decoding image: $e");
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // --- PROFILE IMAGE SECTION ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: profileImage,
                        child: profileImage == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndSaveImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFFF8500), shape: BoxShape.circle),
                            child: _isUploading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(userData['role'] ?? 'User', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // --- INFO TILES ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("General Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildOptionTile(
                      icon: Icons.store,
                      title: "Company Name",
                      value: userData['shop_name'] ?? "Not Set",
                      onTap: () => _showEditSheet("Company Name", "shop_name", userData['shop_name'] ?? ""),
                    ),
                    _buildOptionTile(
                      icon: Icons.person,
                      title: "User Name",
                      value: userData['name'] ?? "Not Set",
                      onTap: () => _showEditSheet("User Name", "name", userData['name'] ?? ""),
                    ),
                    _buildOptionTile(
                      icon: Icons.phone,
                      title: "Phone Number",
                      value: userData['phone'] ?? "Not Set",
                      onTap: () => _showEditSheet("Phone Number", "phone", userData['phone'] ?? "", isNumber: true),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFF8500).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFFFF8500)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}