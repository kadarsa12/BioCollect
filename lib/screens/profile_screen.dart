import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _organizationController = TextEditingController();
  final _titleController = TextEditingController();
  final _specializationController = TextEditingController();
  final _emailController = TextEditingController();
  UserType? _type;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _type = user?.userType;
    _organizationController.text = user?.organization ?? '';
    _titleController.text = user?.title ?? '';
    _specializationController.text = user?.specialization ?? '';
    _emailController.text = user?.email ?? '';
    if (user?.avatar != null) _avatarFile = File(user!.avatar!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _titleController.dispose();
    _specializationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _orgLabel {
    switch (_type) {
      case UserType.academicResearcher:
        return 'Institution (optional)';
      case UserType.independentConsultant:
      case UserType.companyEmployee:
        return 'Company (optional)';
      case UserType.student:
        return 'University (optional)';
      default:
        return 'Organization (optional)';
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _avatarFile = File(img.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final current = userProvider.currentUser!;
    final updated = User(
      id: current.id,
      name: _nameController.text.trim(),
      userType: _type,
      organization: _organizationController.text.isEmpty ? null : _organizationController.text,
      title: _titleController.text.isEmpty ? null : _titleController.text,
      specialization: _specializationController.text.isEmpty ? null : _specializationController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      avatar: _avatarFile?.path,
      createdAt: current.createdAt,
    );
    await userProvider.updateUser(updated);
    Navigator.pop(context);
  }

  Widget _buildRadio(UserType type) {
    return RadioListTile<UserType>(
      title: Text(type.displayName),
      value: type,
      groupValue: _type,
      onChanged: (val) => setState(() => _type = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null ? Icon(Icons.camera_alt) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ...UserType.values.map(_buildRadio),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizationController,
                decoration: InputDecoration(labelText: _orgLabel),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specializationController,
                decoration:
                    const InputDecoration(labelText: 'Specialization (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
