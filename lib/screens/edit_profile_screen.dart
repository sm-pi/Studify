// lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _intakeController = TextEditingController();

  // Lists
  final List<String> _departments = [
    'CSE', 'EEE', 'Civil', 'Textile', 'BBA',
    'English', 'Law', 'Economics', 'Mathematics', 'Architecture'
  ];

  final List<String> _designations = [
    'Lecturer', 'Senior Lecturer', 'Assistant Professor',
    'Associate Professor', 'Professor', 'Chairman', 'Dean'
  ];

  String? _role;
  String? _selectedDept;
  String? _selectedDesignation;
  File? _imageFile;
  String _currentPhotoUrl = "";
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentPhotoUrl = data['profilePicUrl'] ?? '';
          _role = data['role'];

          String? loadedDept = data['department'];
          if (_departments.contains(loadedDept)) _selectedDept = loadedDept;

          String? loadedDesignation = data['designation'];
          if (_designations.contains(loadedDesignation)) _selectedDesignation = loadedDesignation;

          _intakeController.text = data['intake'] ?? '';
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    File? file = await _storageService.pickProfileImage();
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a role")));
      return;
    }
    // Admin needs NO department. Others DO.
    if (_role != 'Admin' && _selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Department")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String finalPhotoUrl = _currentPhotoUrl;
      if (_imageFile != null) {
        finalPhotoUrl = await _storageService.uploadFile(_imageFile!, 'image');
      }

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'role': _role,
        'profilePicUrl': finalPhotoUrl,
        'profileCompleted': true,
      };

      // --- CLEAN DATA LOGIC ---
      if (_role == 'Admin') {
        // Admin gets "Administration" as dept automatically, others removed
        updateData['department'] = 'Administration';
        updateData['intake'] = FieldValue.delete();
        updateData['designation'] = FieldValue.delete();
      } else {
        // Students/Faculty save their specific fields
        updateData['department'] = _selectedDept;

        if (_role == 'Student') {
          updateData['intake'] = _intakeController.text.trim();
          updateData['designation'] = FieldValue.delete();
        } else if (_role == 'Faculty Member') {
          updateData['designation'] = _selectedDesignation;
          updateData['intake'] = FieldValue.delete();
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Check if user selected Admin to hide fields dynamically
    bool isAdmin = _role == 'Admin';

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_currentPhotoUrl.isNotEmpty ? NetworkImage(_currentPhotoUrl) : null) as ImageProvider?,
                  child: (_imageFile == null && _currentPhotoUrl.isEmpty) ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter Name" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Student", child: Text("Student")),
                  DropdownMenuItem(value: "Faculty Member", child: Text("Faculty Member")),
                  DropdownMenuItem(value: "Admin", child: Text("Admin (App Manager)")),
                ],
                onChanged: (val) {
                  setState(() {
                    _role = val;
                    if (val == 'Admin') {
                      // Clear academic fields immediately if Admin selected
                      _selectedDept = null;
                      _selectedDesignation = null;
                      _intakeController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // --- ONLY SHOW ACADEMIC FIELDS IF NOT ADMIN ---
              if (!isAdmin) ...[
                DropdownButtonFormField<String>(
                  value: _selectedDept,
                  decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                  menuMaxHeight: 300,
                  items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                  onChanged: (val) => setState(() => _selectedDept = val),
                  validator: (val) => val == null ? "Select Department" : null,
                ),
                const SizedBox(height: 16),

                if (_role == 'Student')
                  TextFormField(
                    controller: _intakeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Intake (e.g. 45)", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter Intake" : null,
                  ),

                if (_role == 'Faculty Member')
                  DropdownButtonFormField<String>(
                    value: _selectedDesignation,
                    decoration: const InputDecoration(labelText: "Designation", border: OutlineInputBorder()),
                    menuMaxHeight: 300,
                    items: _designations.map((desig) => DropdownMenuItem(value: desig, child: Text(desig))).toList(),
                    onChanged: (val) => setState(() => _selectedDesignation = val),
                    validator: (val) => val == null ? "Select Designation" : null,
                  ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Bio / About Me", border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),

              if (_isUploading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("SAVE CHANGES"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}