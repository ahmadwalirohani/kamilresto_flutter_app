import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../../order/models/order.dart';
import '../../order/providers/restaurant_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredOrdersProvider);
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(ordersProvider),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'logout') ref.read(authControllerProvider.notifier).logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text(user?.name ?? 'Waiter')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersProvider),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search by order or table'),
              onChanged: (value) => ref.read(orderSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 10),
            const _StatusFilters(),
            const SizedBox(height: 12),
            orders.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox(height: 320, child: EmptyView(title: 'No orders', message: 'Orders matching this filter will appear here.', icon: Icons.receipt_long_outlined));
                }
                return _GroupedOrders(items: items);
              },
              error: (_, _) => ErrorView(message: 'Could not load orders.', onRetry: () => ref.invalidate(ordersProvider)),
              loading: () => const SizedBox(height: 320, child: LoadingView(message: 'Loading orders')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedOrders extends StatelessWidget {
  const _GroupedOrders({required this.items});

  final List<Order> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <OrderStatus, List<Order>>{};
    for (final order in items) {
      grouped.putIfAbsent(order.status, () => <Order>[]).add(order);
    }

    const statusOrder = [
      OrderStatus.newOrder,
      OrderStatus.ready,
      OrderStatus.preparing,
      OrderStatus.served,
      OrderStatus.completed,
      OrderStatus.cancelled,
      OrderStatus.draft,
    ];

    return Column(
      children: [
        for (final status in statusOrder)
          if (grouped[status]?.isNotEmpty ?? false) ...[
            _OrderStatusSection(status: status, orders: grouped[status]!),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _OrderStatusSection extends StatelessWidget {
  const _OrderStatusSection({required this.status, required this.orders});

  final OrderStatus status;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context, status);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.$1.withOpacity(.72),
        border: Border(left: BorderSide(color: colors.$2, width: 5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), color: colors.$2, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.label,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colors.$2),
                  ),
                ),
                Chip(
                  label: Text('${orders.length}'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colors.$2.withOpacity(.14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columns == 2 ? 1.62 : 2.05,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

IconData _statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.newOrder:
      return Icons.schedule_outlined;
    case OrderStatus.preparing:
      return Icons.soup_kitchen_outlined;
    case OrderStatus.ready:
      return Icons.check_circle_outline;
    case OrderStatus.served:
      return Icons.room_service_outlined;
    case OrderStatus.completed:
      return Icons.task_alt;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
    case OrderStatus.draft:
      return Icons.edit_note_outlined;
  }
}

(Color, Color) _statusColors(BuildContext context, OrderStatus status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case OrderStatus.newOrder:
      return (const Color(0xFFFFF4D6), const Color(0xFFB26A00));
    case OrderStatus.preparing:
      return (scheme.tertiaryContainer.withOpacity(.42), scheme.tertiary);
    case OrderStatus.ready:
      return (const Color(0xFFDDF7E8), const Color(0xFF16803A));
    case OrderStatus.cancelled:
      return (scheme.errorContainer.withOpacity(.55), scheme.error);
    case OrderStatus.served:
    case OrderStatus.completed:
      return (scheme.secondaryContainer.withOpacity(.38), scheme.secondary);
    case OrderStatus.draft:
      return (scheme.surfaceContainerHighest, scheme.outline);
  }
}

class _StatusFilters extends ConsumerWidget {
  const _StatusFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(orderStatusFilterProvider);
    final statuses = <OrderStatus?>[null, OrderStatus.newOrder, OrderStatus.ready, OrderStatus.preparing, OrderStatus.served, OrderStatus.completed, OrderStatus.cancelled];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses
            .map((status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status?.label ?? 'All'),
                    selected: selected == status,
                    onSelected: (_) => ref.read(orderStatusFilterProvider.notifier).state = status,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _statusColors(context, order.status);
    final lookupId = int.tryParse(order.id) != null ? order.id : order.orderNumber;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go('/orders/${Uri.encodeComponent(lookupId)}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.$1,
          border: Border.all(color: colors.$2, width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: colors.$2.withOpacity(.16), child: Icon(Icons.receipt_long, color: colors.$2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            order.tableName.isEmpty ? 'Table ${order.tableId}' : order.tableName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text('Order ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('${order.guestCount} guests · ${order.itemCount} items', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _OrderStatusChip(status: order.status),
                        const SizedBox(height: 6),
                        MoneyText(order.total, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(_relativeTime(order.createdAt), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _OrderCardActions(order: order),
            ],
          ),
        ),
      ),
    );
  }

}

String _relativeTime(DateTime value) {
  final now = DateTime.now();
  final difference = now.difference(value);
  if (difference.inSeconds < 45) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
  if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
  return '${(difference.inDays / 365).floor()}y ago';
}

class _OrderCardActions extends ConsumerStatefulWidget {
  const _OrderCardActions({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderCardActions> createState() => _OrderCardActionsState();
}

class _OrderCardActionsState extends ConsumerState<_OrderCardActions> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isClosed = order.status == OrderStatus.cancelled || order.status == OrderStatus.ready || order.status == OrderStatus.completed;
    final isBusy = _busyAction != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isClosed || isBusy ? null : () => _editOrder(context),
            icon: _ActionIcon(action: 'edit', busyAction: _busyAction, fallback: Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isClosed || isBusy ? null : () => _cancelOrder(context),
            icon: _ActionIcon(action: 'cancel', busyAction: _busyAction, fallback: Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FilledButton.icon(
            onPressed: isClosed || isBusy ? null : () => _markReady(context),
            icon: _ActionIcon(action: 'ready', busyAction: _busyAction, fallback: Icons.check_circle_outline),
            label: const Text('Ready'),
          ),
        ),
      ],
    );
  }

  Future<void> _markReady(BuildContext context) async {
    setState(() => _busyAction = 'ready');
    try {
      await ref.read(restaurantRepositoryProvider).markOrderReady(widget.order.id);
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked ready.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not mark ready: ${readableApiError(error)}')));
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _CancelOrderDialog(),
    );
    if (reason == null) return;
    setState(() => _busyAction = 'cancel');
    try {
      await ref.read(restaurantRepositoryProvider).cancelOrder(widget.order.id, reason.isEmpty ? 'Cancelled from waiter app' : reason);
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel order: ${readableApiError(error)}')));
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _editOrder(BuildContext context) async {
    final edited = await showDialog<Order>(
      context: context,
      builder: (context) => _EditOrderDialog(order: widget.order),
    );
    if (edited == null) return;
    setState(() => _busyAction = 'edit');
    try {
      await ref.read(restaurantRepositoryProvider).updateOrder(edited);
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update order: ${readableApiError(error)}')));
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action, required this.busyAction, required this.fallback});

  final String action;
  final String? busyAction;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    if (busyAction != action) return Icon(fallback, size: 18);
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: const Text('Cancel Order')),
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
                        IconButton(onPressed: () => _changeQuantity(index, -1), icon: const Icon(Icons.remove)),
                        SizedBox(width: 32, child: Center(child: Text('${item.quantity}'))),
                        IconButton(onPressed: () => _changeQuantity(index, 1), icon: const Icon(Icons.add)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                MoneyText(editedOrder.total, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
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

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      backgroundColor: status == OrderStatus.cancelled ? scheme.errorContainer : scheme.secondaryContainer,
    );
  }
}

