import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/quotation_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_date_picker.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class AddQuotationScreen extends ConsumerStatefulWidget {
  final String? quotationId;
  const AddQuotationScreen({super.key, this.quotationId});

  @override
  ConsumerState<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends ConsumerState<AddQuotationScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedDateStr;
  List<QuotationSection> _sections = [];
  bool _isSaving = false;
  Quotation? _editingQuotation;

  @override
  void initState() {
    super.initState();
    if (widget.quotationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadQuotation();
      });
    } else {
      _sections.add(QuotationSection(sectionName: '', items: [])); // Add default section
    }
  }

  Future<void> _loadQuotation() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    final quotation = await ref.read(firestoreServiceProvider).getQuotationById(appUser.organizationId, widget.quotationId!);
    if (quotation != null && mounted) {
      setState(() {
        _editingQuotation = quotation;
        _titleController.text = quotation.title;
        _noteController.text = quotation.note ?? '';
        _selectedDateStr = quotation.date;
        _sections = List.from(quotation.sections);
      });
    }
  }

  String _currentDate(String defaultCalendar) {
    return _selectedDateStr ?? AppDateUtils.today(calendarType: defaultCalendar);
  }

  Future<void> _save(String orgId, String calendarType) async {
    if (_titleController.text.isEmpty) {
      AppSnackBar.showSuccess(context, 'Please enter a quotation title');
return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final appUser = ref.read(currentAppUserProvider).value!;
      
      final quotation = Quotation(
        id: _editingQuotation?.id ?? '',
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        date: _currentDate(calendarType),
        sections: _sections,
        createdBy: _editingQuotation?.createdBy ?? appUser.uid,
        createdAt: _editingQuotation?.createdAt ?? now,
        updatedAt: now,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      if (_editingQuotation != null) {
        await firestoreService.updateQuotation(orgId, quotation);
      } else {
        await firestoreService.addQuotation(orgId, quotation);
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Quotation saved!');
context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error saving quotation');
}
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(QuotationSection(sectionName: 'Quality ${_sections.length + 1}', items: []));
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _addItem(int sectionIndex) {
    _showItemDialog(sectionIndex);
  }

  void _editItem(int sectionIndex, int itemIndex) {
    _showItemDialog(sectionIndex, itemIndex: itemIndex);
  }

  void _removeItem(int sectionIndex, int itemIndex) {
    setState(() {
      _sections[sectionIndex].items.removeAt(itemIndex);
    });
  }

  Future<void> _showItemDialog(int sectionIndex, {int? itemIndex}) async {
    final isEditing = itemIndex != null;
    final item = isEditing ? _sections[sectionIndex].items[itemIndex] : null;
    
    final descController = TextEditingController(text: item?.description ?? '');
    final amountController = TextEditingController(text: item?.amount.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Item' : 'Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description (e.g. 2 Pant, 2 Shirt)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount (NPR)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final desc = descController.text.trim();
                final amt = double.tryParse(amountController.text) ?? 0;
                if (desc.isNotEmpty && amt > 0) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        final newItem = QuotationItem(
          description: descController.text.trim(),
          amount: double.tryParse(amountController.text) ?? 0,
        );
        if (isEditing) {
          _sections[sectionIndex].items[itemIndex] = newItem;
        } else {
          _sections[sectionIndex].items.add(newItem);
        }
      });
    }
  }

  void _editSectionName(int index) {
    final sectionController = TextEditingController(text: _sections[index].sectionName);
    final groupController = TextEditingController(text: _sections[index].groupName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Section Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupController,
              decoration: const InputDecoration(labelText: 'Super Section (Optional)', hintText: 'e.g. Quotation for Nursing'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sectionController,
              decoration: const InputDecoration(labelText: 'Section Name', hintText: 'e.g. Quality 1, Stitching, or blank'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    ).then((_) {
      setState(() {
        _sections[index] = QuotationSection(
          groupName: groupController.text,
          sectionName: sectionController.text,
          items: _sections[index].items,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(currentOrganizationProvider).value;
    if (org == null) return const AppScaffold(body: LoadingView());

    final dateStr = _currentDate(org.calendarType);

    return AppScaffold(
      appBar: AppBar(title: Text(_editingQuotation != null ? 'Edit Quotation' : 'New Quotation')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quotation Title',
                      hintText: 'e.g. Balmiki International School',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Optional Note',
                      hintText: 'e.g. Note: Delivery within 7 days',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await AppDatePicker.show(context, calendarType: org.calendarType, initialDate: dateStr);
                      if (date != null) setState(() => _selectedDateStr = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Date'),
                      child: Text(AppDateUtils.displayDate(dateStr)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sections', style: Theme.of(context).textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Section'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._sections.asMap().entries.map((entry) {
                    final sIdx = entry.key;
                    final section = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _editSectionName(sIdx),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (section.groupName.isNotEmpty) ...[
                                          Text(
                                            section.groupName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary, decoration: TextDecoration.underline),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          section.sectionName.isEmpty ? '(No Name - Tap to edit)' : section.sectionName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeSection(sIdx),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...section.items.asMap().entries.map((iEntry) {
                              final iIdx = iEntry.key;
                              final item = iEntry.value;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.description),
                                subtitle: Text('NPR ${item.amount}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editItem(sIdx, iIdx)),
                                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeItem(sIdx, iIdx)),
                                  ],
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => _addItem(sIdx),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Save Quotation',
              onPressed: () => _save(org.id, org.calendarType),
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }
}
