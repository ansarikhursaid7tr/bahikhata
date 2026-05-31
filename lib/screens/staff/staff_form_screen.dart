import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_model.dart';
import '../../models/enums.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class StaffFormScreen extends ConsumerStatefulWidget {
  final String? staffId;
  const StaffFormScreen({super.key, this.staffId});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  StaffType _staffType = StaffType.tailor;
  bool _active = true;
  bool _isLoading = false;
  bool _isLoadingData = true;
  Staff? _existingStaff;

  bool get isEditing => widget.staffId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadStaff();
    } else {
      _isLoadingData = false;
    }
  }

  Future<void> _loadStaff() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final staff =
        await firestoreService.getStaff(appUser.organizationId, widget.staffId!);
    if (staff != null && mounted) {
      setState(() {
        _existingStaff = staff;
        _nameController.text = staff.name;
        _phoneController.text = staff.phone ?? '';
        _staffType = staff.staffType;
        _active = staff.active;
        _isLoadingData = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appUser = ref.read(currentAppUserProvider).value!;
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      if (isEditing && _existingStaff != null) {
        final updatedStaff = _existingStaff!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          staffType: _staffType,
          active: _active,
          updatedAt: now,
        );
        await firestoreService.updateStaff(
            appUser.organizationId, updatedStaff);
      } else {
        await firestoreService.addStaff(
          appUser.organizationId,
          Staff(
            id: '',
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            staffType: _staffType,
            active: _active,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, isEditing ? 'Staff updated' : 'Staff added');
context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return AppScaffold(appBar: AppBar(), body: const LoadingView());

    return AppScaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Staff' : 'Add Staff'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Staff Name',
                hint: 'Enter staff name',
                controller: _nameController,
                validator: (v) => Validators.validateRequired(v, 'Name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter phone number (optional)',
                controller: _phoneController,
                validator: Validators.validatePhone,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
              Text('Staff Type',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<StaffType>(
                value: _staffType,
                items: StaffType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _staffType = v!),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(_active ? 'Staff is active' : 'Staff is inactive'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: isEditing ? 'Update Staff' : 'Add Staff',
                onPressed: _save,
                isLoading: _isLoading,
                icon: isEditing ? Icons.save : Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
