import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/item_type_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class ItemTypeFormScreen extends ConsumerStatefulWidget {
  final String? itemTypeId;
  const ItemTypeFormScreen({super.key, this.itemTypeId});

  @override
  ConsumerState<ItemTypeFormScreen> createState() => _ItemTypeFormScreenState();
}

class _ItemTypeFormScreenState extends ConsumerState<ItemTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _active = true;
  bool _isLoading = false;
  bool _isLoadingData = true;
  ItemType? _existingItem;

  bool get isEditing => widget.itemTypeId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadItemType();
    } else {
      _isLoadingData = false;
    }
  }

  Future<void> _loadItemType() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(appUser.organizationId)
        .collection('itemTypes')
        .doc(widget.itemTypeId)
        .get();

    if (snapshot.exists && mounted) {
      final item = ItemType.fromFirestore(snapshot);
      setState(() {
        _existingItem = item;
        _nameController.text = item.name;
        _categoryController.text = item.category ?? '';
        _active = item.active;
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

      if (isEditing && _existingItem != null) {
        final updated = _existingItem!.copyWith(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          active: _active,
          updatedAt: now,
        );
        await firestoreService.updateItemType(
            appUser.organizationId, updated);
      } else {
        await firestoreService.addItemType(
          appUser.organizationId,
          ItemType(
            id: '',
            name: _nameController.text.trim(),
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            active: _active,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, isEditing ? 'Item type updated' : 'Item type added');
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
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return AppScaffold(appBar: AppBar(), body: const LoadingView());

    return AppScaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item Type' : 'Add Item Type')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Item Type Name',
                hint: 'e.g., Coat, Pant, Shirt',
                controller: _nameController,
                validator: (v) => Validators.validateRequired(v, 'Name'),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Category (Optional)',
                hint: 'e.g., Clothing, Services',
                controller: _categoryController,
                prefixIcon: const Icon(Icons.folder_outlined),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: isEditing ? 'Update Item Type' : 'Add Item Type',
                onPressed: _save,
                isLoading: _isLoading,
                icon: isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
