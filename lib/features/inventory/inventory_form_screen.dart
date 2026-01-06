import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
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

  // Photo handling
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _productPhotos = [];
  final List<XFile> _documentPhotos = [];
  final List<String> _existingProductPhotos = [];
  final List<String> _existingDocumentPhotos = [];

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

  // Photo picking methods
  Future<void> _pickProductPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _productPhotos.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
      }
    }
  }

  Future<void> _pickDocumentPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _documentPhotos.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
      }
    }
  }

  void _showPhotoSourceDialog(bool isProduct) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(ctx);
                if (isProduct) {
                  _pickProductPhoto(ImageSource.camera);
                } else {
                  _pickDocumentPhoto(ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(ctx);
                if (isProduct) {
                  _pickProductPhoto(ImageSource.gallery);
                } else {
                  _pickDocumentPhoto(ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeProductPhoto(int index) {
    setState(() {
      _productPhotos.removeAt(index);
    });
  }

  void _removeDocumentPhoto(int index) {
    setState(() {
      _documentPhotos.removeAt(index);
    });
  }

  Future<List<String>> _uploadPhotos(List<XFile> photos) async {
    if (photos.isEmpty) return [];

    final dio = ref.read(dioProvider);
    final List<String> urls = [];

    // Upload all photos at once using 'files' field (backend expects list)
    final List<MultipartFile> multipartFiles = [];
    for (final photo in photos) {
      multipartFiles.add(
        await MultipartFile.fromFile(photo.path, filename: photo.name),
      );
    }

    final formData = FormData.fromMap({'files': multipartFiles});

    final response = await dio.post('/inventory/upload', data: formData);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      if (data['urls'] != null) {
        urls.addAll((data['urls'] as List).map((e) => e.toString()));
      }
    }

    return urls;
  }

  Widget _buildPhotoGrid({
    required List<XFile> photos,
    required List<String> existingUrls,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required void Function(int) onRemoveExisting,
  }) {
    final totalCount = existingUrls.length + photos.length;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount + 1, // +1 for add button
        itemBuilder: (context, index) {
          // Add button at the end
          if (index == totalCount) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Добавить',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Existing photos from server
          if (index < existingUrls.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      existingUrls[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => onRemoveExisting(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // New photos (local files)
          final photoIndex = index - existingUrls.length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(photos[photoIndex].path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => onRemove(photoIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

        // Load existing photos (backend uses 'photos' field)
        if (data['photos'] != null) {
          _existingProductPhotos.addAll(
            (data['photos'] as List).map((e) => e.toString()),
          );
        }
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

      // Upload photos - combine product and document photos into 'photos' field
      final List<String> allPhotos = [
        ..._existingProductPhotos,
        ..._existingDocumentPhotos,
      ];

      if (_productPhotos.isNotEmpty) {
        final productUrls = await _uploadPhotos(_productPhotos);
        allPhotos.addAll(productUrls);
      }

      if (_documentPhotos.isNotEmpty) {
        final documentUrls = await _uploadPhotos(_documentPhotos);
        allPhotos.addAll(documentUrls);
      }

      if (allPhotos.isNotEmpty) {
        data['photos'] = allPhotos;
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
            const SizedBox(height: 24),

            // Product Photos Section
            if (!_isGroup) ...[
              Text(
                'Фото товара',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPhotoGrid(
                photos: _productPhotos,
                existingUrls: _existingProductPhotos,
                onAdd: () => _showPhotoSourceDialog(true),
                onRemove: _removeProductPhoto,
                onRemoveExisting: (index) {
                  setState(() {
                    _existingProductPhotos.removeAt(index);
                  });
                },
              ),
              const SizedBox(height: 24),

              // Document Photos Section
              Text(
                'Документация',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPhotoGrid(
                photos: _documentPhotos,
                existingUrls: _existingDocumentPhotos,
                onAdd: () => _showPhotoSourceDialog(false),
                onRemove: _removeDocumentPhoto,
                onRemoveExisting: (index) {
                  setState(() {
                    _existingDocumentPhotos.removeAt(index);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

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
