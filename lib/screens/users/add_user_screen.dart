import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_user_model.dart';
import '../../models/enums.dart';
import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.manager;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appUser = ref.read(currentAppUserProvider).value;
      if (appUser == null) throw Exception('Not authenticated');

      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // Create auth user
      final credential = await authService.createUser(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // Create app user doc
      final newUser = AppUser(
        id: uid,
        uid: uid,
        name: _nameController.text.trim(),
        email: credential.user!.email!,
        username: _usernameController.text.trim(),
        role: _selectedRole,
        active: true,
        organizationId: appUser.organizationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await firestoreService.createUserDocument(appUser.organizationId, newUser);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'User created successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Add User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length < 4) return 'Minimum 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'User Role',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<UserRole>(
                      title: const Text('Manager'),
                      subtitle: const Text('Can manage all records, except users.'),
                      value: UserRole.manager,
                      groupValue: _selectedRole,
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<UserRole>(
                      title: const Text('Staff'),
                      subtitle: const Text('Can only view their own ledger.'),
                      value: UserRole.staff,
                      groupValue: _selectedRole,
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
