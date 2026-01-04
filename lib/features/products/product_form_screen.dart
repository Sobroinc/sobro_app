import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'products_provider.dart';

/// Product form screen for create/edit.
class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _auctionPriceController = TextEditingController();
  final _directPriceController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  int? _categoryId;
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _auctionPriceController.dispose();
    _directPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);

      // Load categories
      final catResponse = await dio.get('/products/categories');
      if (catResponse.statusCode == 200) {
        _categories = (catResponse.data as List)
            .map((c) => ProductCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      // Load product if editing
      if (widget.isEditing) {
        final response = await dio.get('/products/${widget.productId}');
        if (response.statusCode == 200) {
          final product = Product.fromJson(
            response.data as Map<String, dynamic>,
          );
          _titleController.text = product.title;
          _contentController.text = product.content ?? '';
          _priceController.text = product.price?.toString() ?? '';
          _purchasePriceController.text =
              product.purchasePrice?.toString() ?? '';
          _auctionPriceController.text = product.auctionPrice?.toString() ?? '';
          _directPriceController.text =
              product.directSalePrice?.toString() ?? '';
          _categoryId = product.categoryId;
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

      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        if (_priceController.text.isNotEmpty)
          'price': double.tryParse(_priceController.text),
        if (_purchasePriceController.text.isNotEmpty)
          'purchase_price': double.tryParse(_purchasePriceController.text),
        if (_auctionPriceController.text.isNotEmpty)
          'auction_price': double.tryParse(_auctionPriceController.text),
        if (_directPriceController.text.isNotEmpty)
          'direct_sale_price': double.tryParse(_directPriceController.text),
      };

      if (widget.isEditing) {
        // Update existing product
        await dio.post('/products/${widget.productId}/update', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          ref.invalidate(productDetailProvider(widget.productId!));
          context.pop();
        }
      } else {
        // Create new product
        final response = await dio.post('/products', data: data);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product created successfully')),
            );
            ref.read(productsProvider.notifier).refresh();
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
        title: Text(widget.isEditing ? 'Edit Product' : 'New Product'),
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
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            if (_categories.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryId = value;
                  });
                },
              ),
            if (_categories.isNotEmpty) const SizedBox(height: 16),

            // Content/Description
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // Prices section
            Text(
              'Pricing',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Main price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (USD)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Purchase price
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price (USD)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                helperText: 'What you paid for this item',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Direct sale price
            TextFormField(
              controller: _directPriceController,
              decoration: const InputDecoration(
                labelText: 'Direct Sale Price (USD)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Auction price
            TextFormField(
              controller: _auctionPriceController,
              decoration: const InputDecoration(
                labelText: 'Auction Start Price (USD)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                widget.isEditing ? 'Update Product' : 'Create Product',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
