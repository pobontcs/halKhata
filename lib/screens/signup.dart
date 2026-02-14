import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../services/auth_services.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 1. Text Controllers
  final _nameController = TextEditingController();
  final _shopController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // 2. Role State
  String _selectedRole = 'Admin';
  final List<String> _roles = ['Admin', 'Manager', 'Accounts'];

  // 3. Image State
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // 4. Loading State
  bool _isLoading = false;
  final _authService = AuthService();

  // --- LOGIC: PICK IMAGE ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // --- LOGIC: HANDLE SIGNUP ---
  void _handleSignup() async {
    // 1. Validation
    if (_nameController.text.isEmpty ||
        _shopController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // 2. Start Loading
    if (mounted) setState(() => _isLoading = true);

    // 3. RUN SIGNUP
    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
      name: _nameController.text.trim(),
      shopName: _shopController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      imageFile: _selectedImage, // <--- Pass the image here
    );

    // 4. Stop Loading
    if (mounted) setState(() => _isLoading = false);

    // 5. Check Result
    if (error == null) {
      print("✅ Database save successful.");
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } else {
      print("❌ Signup failed: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF8500)),
              ),
              const Text(
                "Start managing your business digitally",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // --- PROFILE IMAGE PICKER ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : null,
                        child: _selectedImage == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8500),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("Add Profile Photo", style: TextStyle(color: Colors.grey, fontSize: 12)),
              )),
              const SizedBox(height: 30),

              // Inputs
              _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _shopController, label: "Shop / Business Name", icon: Icons.store_outlined),
              const SizedBox(height: 16),

              // Role Selector
              const Text("Select Role", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _roles.map((role) {
                  final bool isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF8500),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      if (selected) setState(() => _selectedRole = role);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_outlined, inputType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: "Email Address", icon: Icons.email_outlined, inputType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: _passController, label: "Password", icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 30),

              // Signup Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              // Back to Login
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Login", style: TextStyle(color: Color(0xFFFF8500), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8500), width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}