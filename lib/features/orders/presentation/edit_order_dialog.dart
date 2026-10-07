import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/money_text.dart';
import '../../order/models/food.dart';
import '../../order/models/order.dart';
import '../../order/providers/restaurant_providers.dart';

class EditOrderDialog extends ConsumerStatefulWidget {
  const EditOrderDialog({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends ConsumerState<EditOrderDialog> {
  late List<OrderItem> _items;
  String _search = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items = [...widget.order.items];
  }

  void _add(Food food) {
    setState(() {
      final index = _items.indexWhere((item) => item.foodId == food.id);
      if (index < 0) {
        _items.add(OrderItem.fromFood(food));
      } else {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity + 1,
        );
      }
    });
  }

  void _change(int index, int delta) {
    setState(() {
      final quantity = _items[index].quantity + delta;
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _items.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(restaurantRepositoryProvider)
          .updateOrder(widget.order.copyWith(items: [..._items]));
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(widget.order.id));
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) setState(() => _error = readableApiError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _selectedItems() => _items.isEmpty
      ? const Center(child: Text('No items'))
      : ListView.separated(
          itemCount: _items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Expanded(child: MoneyText(item.total)),
                      IconButton(
                        tooltip: 'Decrease quantity',
                        onPressed: _saving ? null : () => _change(index, -1),
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 32,
                        child: Center(child: Text('${item.quantity}')),
                      ),
                      IconButton(
                        tooltip: 'Increase quantity',
                        onPressed: _saving ? null : () => _change(index, 1),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _items.removeAt(index)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );

  Widget _menu() => Column(
    children: [
      TextField(
        enabled: !_saving,
        onChanged: (value) =>
            setState(() => _search = value.trim().toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search menu',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ref
            .watch(foodsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(readableApiError(error)),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(foodsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (foods) {
                final filtered = foods
                    .where(
                      (food) =>
                          food.isAvailable &&
                          food.name.toLowerCase().contains(_search),
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No items found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final food = filtered[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: MoneyText(food.price),
                      trailing: IconButton(
                        tooltip: 'Add ${food.name}',
                        onPressed: _saving ? null : () => _add(food),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      onTap: _saving ? null : () => _add(food),
                    );
                  },
                );
              },
            ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Text('Edit ${widget.order.orderNumber}'),
        content: SizedBox(
          width: 760,
          height: (size.height * .7).clamp(200.0, 650.0),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 580) {
                      return Row(
                        children: [
                          Expanded(child: _selectedItems()),
                          const VerticalDivider(width: 24),
                          Expanded(child: _menu()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: _selectedItems()),
                        const Divider(),
                        Expanded(child: _menu()),
                      ],
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  MoneyText(widget.order.copyWith(items: _items).total),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: _saving || _items.isEmpty ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
