import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'clients_provider.dart';

/// Client form screen for create/edit.
class ClientFormScreen extends ConsumerStatefulWidget {
  final int? clientId;

  const ClientFormScreen({super.key, this.clientId});

  bool get isEditing => clientId != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _type = 'company';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadClient();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/clients/${widget.clientId}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _type = data['type'] as String? ?? 'company';
        _nameController.text = data['name'] as String? ?? '';
        _contactPersonController.text = data['contact_person'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _emailController.text = data['email'] as String? ?? '';
        _addressController.text = data['address'] as String? ?? '';
        _countryController.text = data['country'] as String? ?? '';
        _cityController.text = data['city'] as String? ?? '';
        _notesController.text = data['notes'] as String? ?? '';
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
        'type': _type,
        'name': _nameController.text,
      };

      // Only add non-empty fields
      if (_contactPersonController.text.isNotEmpty) {
        data['contact_person'] = _contactPersonController.text;
      }
      if (_phoneController.text.isNotEmpty) {
        data['phone'] = _phoneController.text;
      }
      if (_emailController.text.isNotEmpty) {
        data['email'] = _emailController.text;
      }
      if (_addressController.text.isNotEmpty) {
        data['address'] = _addressController.text;
      }
      if (_countryController.text.isNotEmpty) {
        data['country'] = _countryController.text;
      }
      if (_cityController.text.isNotEmpty) {
        data['city'] = _cityController.text;
      }
      if (_notesController.text.isNotEmpty) {
        data['notes'] = _notesController.text;
      }

      if (widget.isEditing) {
        // Update existing client
        await dio.put('/clients/${widget.clientId}', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client updated successfully')),
          );
          ref.invalidate(clientDetailProvider(widget.clientId!));
          ref.read(clientsProvider.notifier).refresh();
          context.pop();
        }
      } else {
        // Create new client
        final response = await dio.post('/clients', data: data);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client created successfully')),
            );
            ref.read(clientsProvider.notifier).refresh();
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
        title: Text(widget.isEditing ? 'Edit Client' : 'New Client'),
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

            // Client type toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'company',
                          label: Text('Company'),
                          icon: Icon(Icons.business),
                        ),
                        ButtonSegment(
                          value: 'individual',
                          label: Text('Individual'),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (value) {
                        setState(() {
                          _type = value.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _type == 'company'
                    ? 'Company Name *'
                    : 'Full Name *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _type == 'company' ? Icons.business : Icons.person,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact person (for companies)
            if (_type == 'company')
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            if (_type == 'company') const SizedBox(height: 16),

            // Contact info section
            Text(
              'Contact Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Address section
            Text(
              'Address',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(widget.isEditing ? 'Update Client' : 'Create Client'),
            ),
          ],
        ),
      ),
    );
  }
}
