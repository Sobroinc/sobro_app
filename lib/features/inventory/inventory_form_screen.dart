import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'inventory_provider.dart';

/// Inventory form screen for create/edit.
class InventoryFormScreen extends ConsumerStatefulWidget {
  final int? itemId;
  final int? parentGroupId;

  const InventoryFormScreen({super.key, this.itemId, this.parentGroupId});

  bool get isEditing => itemId != null;

  @override
  ConsumerState<InventoryFormScreen> createState() =>
      _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _condition;
  bool _isGroup = false;
  bool _inCatalog = false;

  final List<String> _conditions = ['New', 'Excellent', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadItem();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/inventory/${widget.itemId}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _titleController.text = data['title'] as String? ?? '';
        _descriptionController.text = data['description'] as String? ?? '';
        _manufacturerController.text = data['manufacturer'] as String? ?? '';
        _modelController.text = data['model'] as String? ?? '';
        _yearController.text = data['year']?.toString() ?? '';
        _serialNumberController.text = data['serial_number'] as String? ?? '';
        _purchasePriceController.text =
            data['purchase_price']?.toString() ?? '';
        _salePriceController.text = data['sale_price']?.toString() ?? '';
        _quantityController.text = (data['quantity'] as int? ?? 1).toString();
        _locationController.text = data['location'] as String? ?? '';
        _cityController.text = data['city'] as String? ?? '';
        _notesController.text = data['notes'] as String? ?? '';
        _condition = data['condition'] as String?;
        _isGroup = data['is_group'] as bool? ?? false;
        _inCatalog = data['in_catalog'] as bool? ?? false;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);

      final data = <String, dynamic>{
        'title': _titleController.text,
        'is_group': _isGroup,
        'in_catalog': _inCatalog,
      };

      // Only add non-empty fields
      if (_descriptionController.text.isNotEmpty) {
        data['description'] = _descriptionController.text;
      }
      if (_manufacturerController.text.isNotEmpty) {
        data['manufacturer'] = _manufacturerController.text;
      }
      if (_modelController.text.isNotEmpty) {
        data['model'] = _modelController.text;
      }
      if (_yearController.text.isNotEmpty) {
        data['year'] = int.tryParse(_yearController.text);
      }
      if (_serialNumberController.text.isNotEmpty) {
        data['serial_number'] = _serialNumberController.text;
      }
      if (_purchasePriceController.text.isNotEmpty) {
        data['purchase_price'] = double.tryParse(_purchasePriceController.text);
      }
      if (_salePriceController.text.isNotEmpty) {
        data['sale_price'] = double.tryParse(_salePriceController.text);
      }
      if (_quantityController.text.isNotEmpty) {
        data['quantity'] = int.tryParse(_quantityController.text) ?? 1;
      }
      if (_locationController.text.isNotEmpty) {
        data['location'] = _locationController.text;
      }
      if (_cityController.text.isNotEmpty) {
        data['city'] = _cityController.text;
      }
      if (_notesController.text.isNotEmpty) {
        data['notes'] = _notesController.text;
      }
      if (_condition != null) {
        data['condition'] = _condition;
      }
      if (widget.parentGroupId != null) {
        data['parent_id'] = widget.parentGroupId;
      }

      if (widget.isEditing) {
        // Update existing item
        await dio.put('/inventory/${widget.itemId}', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
          ref.invalidate(inventoryDetailProvider(widget.itemId!));
          ref.read(inventoryProvider.notifier).refresh();
          context.pop();
        }
      } else {
        // Create new item
        final response = await dio.post('/inventory', data: data);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isGroup
                      ? 'Group created successfully'
                      : 'Item created successfully',
                ),
              ),
            );
            ref.read(inventoryProvider.notifier).refresh();
            context.pop();
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit ${_isGroup ? 'Group' : 'Item'}'
              : (_isGroup ? 'New Group' : 'New Item'),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_error != null) const SizedBox(height: 16),

            // Item type toggle (only for new items)
            if (!widget.isEditing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Item'),
                            icon: Icon(Icons.inventory_2),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Group'),
                            icon: Icon(Icons.folder),
                          ),
                        ],
                        selected: {_isGroup},
                        onSelectionChanged: (value) {
                          setState(() {
                            _isGroup = value.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (!widget.isEditing) const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_isGroup ? Icons.folder : Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Only show additional fields for items, not groups
            if (!_isGroup) ...[
              // Specifications section
              Text(
                'Specifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _manufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: _conditions
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _condition = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pricing section
              Text(
                'Pricing',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Sale Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location section
              Text(
                'Location',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Warehouse A, Shelf 3',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // In catalog toggle
            SwitchListTile(
              title: const Text('Show in Catalog'),
              subtitle: const Text('Make this item visible in public catalog'),
              value: _inCatalog,
              onChanged: (value) {
                setState(() {
                  _inCatalog = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(widget.isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
