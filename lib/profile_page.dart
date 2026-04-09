import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_page.dart';
import 'main.dart'; // Access global themeNotifier

class ProfilePage extends StatefulWidget {
  final VoidCallback? onClearData;

  const ProfilePage({super.key, this.onClearData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = "Your name";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load saved name and image path from local storage
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Ruvishan Sankalpa";
      String? imagePath = prefs.getString('profile_image');
      if (imagePath != null) _imageFile = File(imagePath);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', pickedFile.path);
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: Text("Are you sure you want to log out?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showClearDataDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Clear All Data?",
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: Text("Are you sure? This will delete all your notes and notifications.",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                NotificationPage.notifications.clear();
              });

              if (widget.onClearData != null) {
                widget.onClearData!();
              }

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All notifications and notes cleared"),
                  backgroundColor: Colors.black,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Yes, Clear"),
          ),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    TextEditingController nameController = TextEditingController(text: _userName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Edit Name", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          cursorColor: isDark ? Colors.white : Colors.black,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white : Colors.black)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', nameController.text.trim());
                setState(() => _userName = nameController.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Widget buildMenuItem({required IconData icon, required String text, Widget? trailing, Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? defaultColor),
      title: Text(text, style: TextStyle(color: color ?? defaultColor, fontSize: 16)),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/images/profile_pic.jpg') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle),
                      child: Icon(Icons.camera_alt, color: isDark ? Colors.black : Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _editName,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 18, color: mainColor.withOpacity(0.5)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            buildMenuItem(
              icon: Icons.dark_mode,
              text: "Dark Mode",
              trailing: Switch(
                value: themeNotifier.value == ThemeMode.dark,
                activeColor: Colors.white,
                activeTrackColor: Colors.grey[800],
                onChanged: (val) => _toggleTheme(val),
              ),
            ),
            const Divider(),
            buildMenuItem(
              icon: Icons.logout,
              text: "Logout",
              color: Colors.red,
              onTap: _logout,
            ),
            buildMenuItem(
              icon: Icons.layers_clear,
              text: "Clear All Data",
              color: Colors.red,
              onTap: _showClearDataDialog,
            ),
          ],
        ),
      ),
    );
  }
}