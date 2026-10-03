import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../order/models/order.dart';
import '../../order/providers/restaurant_providers.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/orders'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Order Details'),
      ),
      body: order.when(
        data: (value) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SectionPanel(
              title: 'Order ${value.orderNumber}',
              trailing: Chip(label: Text(value.status.label)),
              child: Column(
                children: [
                  _DetailRow(label: 'Table', value: value.tableName),
                  _DetailRow(label: 'Waiter', value: value.waiterName),
                  _DetailRow(label: 'Guests', value: '${value.guestCount}'),
                  _DetailRow(label: 'Time', value: TimeOfDay.fromDateTime(value.createdAt).format(context)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: 'Items',
              child: Column(
                children: value.items.map((item) => _ItemRow(item: item)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: 'Total',
              child: Column(
                children: [
                  _MoneyRow(label: 'Total', value: value.total, prominent: true),
                ],
              ),
            ),
            if (value.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionPanel(title: 'Notes', child: Text(value.notes)),
            ],
            const SizedBox(height: 12),
            _OrderActions(order: value),
          ],
        ),
        error: (_, _) => ErrorView(message: 'Could not load this order.', onRetry: () => ref.invalidate(orderByIdProvider(orderId))),
        loading: () => const LoadingView(message: 'Loading order'),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w700))),
          _ItemImage(image: item.image),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.notes.isNotEmpty) Text(item.notes, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          MoneyText(item.total),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 54,
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: image == null || image!.isEmpty
          ? Icon(Icons.lunch_dining, color: scheme.primary)
          : Image.network(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.lunch_dining, color: scheme.primary),
            ),
    );
  }
}

class _OrderActions extends ConsumerWidget {
  const _OrderActions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClosed = order.status == OrderStatus.cancelled || order.status == OrderStatus.ready || order.status == OrderStatus.completed;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isClosed ? null : () => _editOrder(context, ref, order),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isClosed ? null : () => _cancelOrder(context, ref, order),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: isClosed ? null : () => _markReady(context, ref, order),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Ready'),
          ),
        ),
      ],
    );
  }

  Future<void> _markReady(BuildContext context, WidgetRef ref, Order order) async {
    try {
      await ref.read(restaurantRepositoryProvider).markOrderReady(order.id);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(order.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked ready.')));
        context.go('/orders');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not mark ready: ${readableApiError(error)}')));
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, Order order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _CancelOrderDialog(),
    );
    if (reason == null) return;
    try {
      await ref.read(restaurantRepositoryProvider).cancelOrder(order.id, reason.isEmpty ? 'Cancelled from waiter app' : reason);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(order.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled.')));
        context.go('/orders');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel order: ${readableApiError(error)}')));
      }
    }
  }

  Future<void> _editOrder(BuildContext context, WidgetRef ref, Order order) async {
    final edited = await showDialog<Order>(
      context: context,
      builder: (context) => _EditOrderDialog(order: order),
    );
    if (edited == null) return;
    try {
      await ref.read(restaurantRepositoryProvider).updateOrder(edited);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(order.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update order: ${readableApiError(error)}')));
      }
    }
  }
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog();

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}

class _EditOrderDialog extends StatefulWidget {
  const _EditOrderDialog({required this.order});

  final Order order;

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  late List<OrderItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.order.items];
  }

  @override
  Widget build(BuildContext context) {
    final editedOrder = widget.order.copyWith(items: _items);
    return AlertDialog(
      title: Text('Edit ${widget.order.orderNumber}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 260,
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.foodName),
                    subtitle: MoneyText(item.unitPrice),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _changeQuantity(index, -1),
                          icon: const Icon(Icons.remove),
                        ),
                        SizedBox(width: 32, child: Center(child: Text('${item.quantity}'))),
                        IconButton(
                          onPressed: () => _changeQuantity(index, 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            _MoneyRow(label: 'Total', value: editedOrder.total, prominent: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        FilledButton(
          onPressed: _items.isEmpty ? null : () => Navigator.of(context).pop(editedOrder),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      final item = _items[index];
      final quantity = item.quantity + delta;
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = item.copyWith(quantity: quantity);
      }
    });
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.prominent = false});

  final String label;
  final double value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final style = prominent ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label, style: style)), MoneyText(value, style: style)]),
    );
  }
}
