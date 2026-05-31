import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/organization_model.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';

import '../../utils/snackbar_utils.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _orgNameController = TextEditingController();
  final _currencyController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  BusinessType _businessType = BusinessType.tailorShop;
  String _calendarType = 'AD';
  String? _logoBase64;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _currencyController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _loadOrgData(Organization? org) {
    if (_loaded || org == null) return;
    _orgNameController.text = org.name;
    _currencyController.text = org.currency;
    _addressController.text = org.address ?? '';
    _contactController.text = org.contact ?? '';
    _businessType = org.businessType;
    _calendarType = org.calendarType;
    _logoBase64 = org.logoBase64;
    _loaded = true;
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() => _logoBase64 = base64Str);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error uploading logo: $e');
}
    }
  }

  Future<void> _saveSettings() async {
    final org = ref.read(currentOrganizationProvider).value;
    if (org == null) return;

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final updated = org.copyWith(
        name: _orgNameController.text.trim(),
        currency: _currencyController.text.trim(),
        address: _addressController.text.trim(),
        contact: _contactController.text.trim(),
        businessType: _businessType,
        calendarType: _calendarType,
        logoBase64: _logoBase64,
        updatedAt: DateTime.now(),
      );
      await firestoreService.updateOrganization(updated);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Settings saved');
ref.invalidate(currentOrganizationProvider);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
}
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Logout'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );

    if (confirmed != true) return;

    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      validator: (val) {
                        if (val != newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            await ref.read(authServiceProvider).changePassword(
                                  currentPasswordController.text,
                                  newPasswordController.text,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              AppSnackBar.showSuccess(context, 'Password changed successfully');
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.showError(context, e.toString());
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final appUser = ref.watch(currentAppUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: orgAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (org) {
          _loadOrgData(org);

          Uint8List? imageBytes;
          if (_logoBase64 != null && _logoBase64!.isNotEmpty) {
            try {
              imageBytes = base64Decode(_logoBase64!);
            } catch (_) {}
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.dividerColor,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(imageBytes, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 32, color: AppTheme.textLight),
                                SizedBox(height: 4),
                                Text('Add Logo', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to upload logo for reports',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),

                // Organization Details
                TextFormField(
                  controller: _orgNameController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number(s)',
                    hintText: 'e.g. 9843403403, 9804613646',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BusinessType>(
                  value: _businessType,
                  items: BusinessType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _businessType = v!),
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _calendarType,
                  items: const [
                    DropdownMenuItem(value: 'AD', child: Text('AD (Gregorian)')),
                    DropdownMenuItem(value: 'BS', child: Text('BS (Nepali)')),
                  ],
                  onChanged: (v) => setState(() => _calendarType = v!),
                  decoration: const InputDecoration(
                    labelText: 'Calendar Type',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Save Settings',
                  onPressed: _saveSettings,
                  isLoading: _isSaving,
                  icon: Icons.save,
                ),
                const SizedBox(height: 32),

                // App Info
                Text('App Info', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow('App Name', Constants.appName),
                        _InfoRow('Version', Constants.appVersion),
                        _InfoRow('User', appUser?.name ?? '-'),
                        _InfoRow('Role', appUser?.role.displayName ?? '-'),
                        _InfoRow('Username', appUser?.username ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Security
                Text('Security', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Change Password',
                  onPressed: _showChangePasswordDialog,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.lock_reset,
                ),
                const SizedBox(height: 32),

                // Logout
                AppButton(
                  label: 'Logout',
                  onPressed: _logout,
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

