import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config.dart';
import '../../core/api_client.dart';
import 'clients_provider.dart';
import '../inventory/inventory_provider.dart';

/// Client detail screen.
class ClientDetailScreen extends ConsumerStatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  final List<XFile> _videos = [];
  final List<XFile> _docs = [];
  bool _saving = false;

  Future<void> _takePhoto() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (f != null) setState(() => _photos.add(f));
  }

  Future<void> _takeVideo() async {
    final f = await _picker.pickVideo(source: ImageSource.camera);
    if (f != null) setState(() => _videos.add(f));
  }

  Future<void> _takeDoc() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (f != null) setState(() => _docs.add(f));
  }

  Future<void> _saveNext() async {
    if (_photos.isEmpty && _videos.isEmpty && _docs.isEmpty) return;
    await _doSave();
    setState(() {
      _photos.clear();
      _videos.clear();
      _docs.clear();
    });
  }

  Future<void> _saveLast() async {
    if (_photos.isEmpty && _videos.isEmpty && _docs.isEmpty) return;
    await _doSave();
    setState(() {
      _photos.clear();
      _videos.clear();
      _docs.clear();
    });
  }

  Future<void> _doSave() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .createInventoryWithMedia(
            clientId: widget.clientId,
            title: 'Новый товар',
            files: [..._photos, ..._videos, ..._docs],
          );
      ref.invalidate(clientInventoryProvider(widget.clientId));
      ref.invalidate(inventoryProvider); // Also refresh main inventory tab
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар сохранен!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientDetailProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Клиент')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(clientDetailProvider(widget.clientId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (client) => _buildContent(context, client),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Client client) {
    final inv = ref.watch(clientInventoryProvider(widget.clientId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + bidder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(
                      client.isCompany ? Icons.business : Icons.person,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Bidder #${client.id}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Capture buttons
          Text(
            'Добавить товар',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _btn(
                Icons.camera_alt,
                'Фото',
                Colors.blue,
                _photos.length,
                _takePhoto,
              ),
              const SizedBox(width: 12),
              _btn(
                Icons.videocam,
                'Видео',
                Colors.red,
                _videos.length,
                _takeVideo,
              ),
              const SizedBox(width: 12),
              _btn(
                Icons.description,
                'Документы',
                Colors.orange,
                _docs.length,
                _takeDoc,
              ),
            ],
          ),
          // Previews & buttons
          if (_photos.isNotEmpty || _videos.isNotEmpty || _docs.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _photos
                      .asMap()
                      .entries
                      .map(
                        (e) => _thumb(
                          e.value,
                          () => setState(() => _photos.removeAt(e.key)),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Следующий'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveLast,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_saving) const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 24),
          // Inventory list
          Text(
            'Товары',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: inv.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (items) => items.isEmpty
                    ? const Text('Нет товаров')
                    : Column(children: items.map(_item).toList()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    IconData icon,
    String label,
    Color color,
    int count,
    VoidCallback onTap,
  ) => Expanded(
    child: Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: color),
                  if (count > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _thumb(XFile f, VoidCallback onRemove) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(f.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _item(InventoryItem item) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/inventory/${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: item.firstPhoto != null
                ? Image.network(
                    '${AppConfig.baseUrl.replaceAll('/api', '')}${item.firstPhoto}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.inventory_2, color: Colors.grey),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.manufacturer != null || item.model != null)
                    Text(
                      [
                        item.manufacturer,
                        item.model,
                      ].where((s) => s != null).join(' - '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
}
