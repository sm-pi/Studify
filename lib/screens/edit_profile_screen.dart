// lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:studify/services/database_services.dart';
import 'package:studify/services/storage_service.dart';
import 'package:studify/widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final DatabaseService _databaseService;
  final StorageService _storageService = StorageService();

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _intakeController; // <-- Kept for Student Intake

  // --- THIS IS THE FIX ---
  // We remove _deptController and add _selectedDepartment
  String? _selectedRole;
  String? _selectedDesignation;
  String? _selectedDepartment; // <-- ADDED THIS
  // -------------------------

  bool _isLoading = true;
  bool _isSaving = false;

  String? _existingProfilePicUrl;
  File? _newImageFile;

  final List<String> _roles = ['Student', 'Faculty Member'];
  final List<String> _designations = [
    'Professor', 'Asst. Professor', 'Lecturer', 'Lab Assistant',
    'Research Assistant', 'Teaching Assistant'
  ];
  final List<String> _departments = ['CSE', 'EEE', 'Civil', 'BBA', 'Textile', 'English', 'Law'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _intakeController = TextEditingController();
    // _deptController is no longer initialized

    if (currentUser != null) {
      _databaseService = DatabaseService(uid: currentUser!.uid);
      _loadUserData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _intakeController.dispose();
    // _deptController is no longer disposed
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc =
      await _databaseService.userCollection.doc(currentUser!.uid).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _intakeController.text = data['intake'] ?? ''; // For student
        _selectedRole = data['role'];
        _selectedDesignation = data['designation'];
        _selectedDepartment = data['department']; // <-- USE THIS

        // This logic handles "" (empty string) by converting it to null
        if (_selectedDesignation != null && !_designations.contains(_selectedDesignation)) {
          _selectedDesignation = null;
        }
        if (_selectedDepartment != null && !_departments.contains(_selectedDepartment)) {
          _selectedDepartment = null;
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final File? image = await _storageService.pickProfileImage();
      if (image != null) {
        setState(() {
          _newImageFile = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image pick failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      String? newProfilePicUrl;

      if (_newImageFile != null) {
        newProfilePicUrl = await _storageService.uploadFile(_newImageFile!);
      }

      Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDepartment ?? '', // <-- USE THIS
        'profileCompleted': true,
      };

      if (newProfilePicUrl != null) {
        dataToUpdate['profilePicUrl'] = newProfilePicUrl;
      }

      if (_selectedRole == 'Student') {
        dataToUpdate['intake'] = _intakeController.text.trim();
        dataToUpdate['designation'] = '';
      } else if (_selectedRole == 'Faculty Member') {
        dataToUpdate['designation'] = _selectedDesignation;
        dataToUpdate['intake'] = '';
      }

      await _databaseService.updateUserProfile(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profile Updated!"), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.save),
            onPressed: _saveProfile,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: _newImageFile != null
                        ? FileImage(_newImageFile!)
                        : (_existingProfilePicUrl != null && _existingProfilePicUrl!.isNotEmpty
                        ? NetworkImage(_existingProfilePicUrl!)
                        : null) as ImageProvider?,
                    child: (_newImageFile == null && (_existingProfilePicUrl == null || _existingProfilePicUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 50, color: Colors.indigo)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.indigo,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            CustomTextField(
              hintText: "Full Name",
              controller: _nameController,
              validator: (val) => val!.isEmpty ? "Enter your name" : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: "Your Bio",
              controller: _bioController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Your Role *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              hint: const Text("Select your role"),
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRole = value);
              },
              validator: (val) => val == null ? "Please select a role" : null,
            ),
            const SizedBox(height: 16),

            // --- THIS IS THE FIXED DROPDOWN (Line 281) ---
            DropdownButtonFormField<String>(
              value: _selectedDepartment, // <-- USE STATE VARIABLE
              decoration: const InputDecoration(
                labelText: "Department *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
              hint: const Text("Select your department"),
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDepartment = value); // <-- UPDATE STATE VARIABLE
              },
              validator: (val) => val == null ? "Please select a department" : null, // <-- SIMPLIFIED
            ),
            const SizedBox(height: 16),

            if (_selectedRole == 'Student')
              CustomTextField(
                hintText: "Intake (e.g., 52) *",
                controller: _intakeController, // <-- This is correct, it's a text field
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_outlined,
                validator: (val) => val!.isEmpty ? "Enter your intake" : null,
              ),

            if (_selectedRole == 'Faculty Member')
              DropdownButtonFormField<String>(
                value: _selectedDesignation, // <-- This is correct, it's a state variable
                decoration: const InputDecoration(
                  labelText: "Designation *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                hint: const Text("Select your designation"),
                items: _designations.map((designation) {
                  return DropdownMenuItem(
                      value: designation, child: Text(designation));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDesignation = value);
                },
                validator: (val) =>
                val == null ? "Please select a designation" : null,
              ),
          ],
        ),
      ),
    );
  }
}