import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/current_order_state.dart';
import '../models/food.dart';
import '../models/order.dart';
import '../models/restaurant_table.dart';
import '../providers/restaurant_providers.dart';

class TakeOrderScreen extends ConsumerWidget {
  const TakeOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider);
    final user = ref.watch(authControllerProvider).user;
    final useTabletLayout = MediaQuery.sizeOf(context).width >= 700;
    final content = useTabletLayout
        ? const _TabletOrderLayout()
        : ListView(
            padding: const EdgeInsets.all(12),
            children: const [
              _MenuColumn(),
              SizedBox(height: 12),
              _CartPanel(),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(order.selectedTable?.name ?? AppConfig.appName),
        actions: [
          const _SavePreviewButton(),
          if (user != null)
            PopupMenuButton<String>(
              tooltip: 'Profile',
              onSelected: (value) {
                if (value == 'logout') ref.read(authControllerProvider.notifier).logout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(enabled: false, child: Text('${user.name}\n${user.role}')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(child: Text((user.name.isNotEmpty ? user.name[0] : 'W').toUpperCase())),
              ),
            ),
        ],
      ),
      body: useTabletLayout ? Padding(padding: const EdgeInsets.all(12), child: content) : content,
    );
  }
}

class _TabletOrderLayout extends StatelessWidget {
  const _TabletOrderLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 136, child: _TableRail()),
        SizedBox(width: 10),
        Expanded(child: _FoodSelectionPanel()),
      ],
    );
  }
}

class _SavePreviewButton extends ConsumerWidget {
  const _SavePreviewButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton.icon(
        onPressed: order.items.isEmpty ? null : () => _showOrderPreview(context, ref),
        icon: const Icon(Icons.save_outlined),
        label: Text(order.items.isEmpty ? 'Save' : 'Save (${order.items.length})'),
      ),
    );
  }
}

class _TableRail extends StatelessWidget {
  const _TableRail();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CompactGuestCounter(),
        SizedBox(height: 10),
        Expanded(child: _VerticalTableSelector()),
      ],
    );
  }
}

class _FoodSelectionPanel extends StatelessWidget {
  const _FoodSelectionPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CategorySelector(compact: true),
        SizedBox(height: 10),
        _FoodSearch(),
        SizedBox(height: 10),
        Expanded(child: _FoodGrid(scrollable: true)),
      ],
    );
  }
}

class _MenuColumn extends ConsumerWidget {
  const _MenuColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _TableSelector(),
        SizedBox(height: 12),
        _GuestCounter(),
        SizedBox(height: 12),
        _CategorySelector(),
        SizedBox(height: 12),
        _FoodSearch(),
        SizedBox(height: 12),
        _FoodGrid(),
      ],
    );
  }
}

class _TableSelector extends ConsumerWidget {
  const _TableSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentOrderProvider).selectedTable;
    return SectionPanel(
      title: 'Tables',
      trailing: IconButton(
        tooltip: 'Refresh tables',
        onPressed: () => ref.invalidate(tablesProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: ref.watch(tablesProvider).when(
            data: (tables) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                childAspectRatio: 1.35,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final active = selected?.id == table.id;
                return _TableCard(table: table, active: active);
              },
            ),
            error: (_, _) => const ErrorView(message: 'Could not load tables.'),
            loading: () => const SizedBox(height: 96, child: LoadingView(message: 'Loading tables')),
          ),
    );
  }
}

class _VerticalTableSelector extends ConsumerWidget {
  const _VerticalTableSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentOrderProvider).selectedTable;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Tables', style: Theme.of(context).textTheme.titleSmall)),
                SizedBox.square(
                  dimension: 32,
                  child: IconButton(
                    tooltip: 'Refresh tables',
                    padding: EdgeInsets.zero,
                    onPressed: () => ref.invalidate(tablesProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ref.watch(tablesProvider).when(
                    data: (tables) => ListView.separated(
                      itemCount: tables.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return SizedBox(
                          height: 86,
                          child: _TableCard(table: table, active: selected?.id == table.id),
                        );
                      },
                    ),
                    error: (_, _) => const ErrorView(message: 'Could not load tables.'),
                    loading: () => const LoadingView(message: 'Tables'),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends ConsumerWidget {
  const _TableCard({required this.table, required this.active});

  final RestaurantTable table;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (table.status) {
      TableStatus.available => scheme.primary,
      TableStatus.occupied => scheme.error,
      TableStatus.reserved => Colors.amber.shade700,
      TableStatus.ordering => scheme.tertiary,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref.read(currentOrderProvider.notifier).selectTable(table),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : scheme.surface,
          border: Border.all(color: active ? scheme.primary : scheme.outlineVariant, width: active ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Expanded(child: Text(table.name, style: const TextStyle(fontWeight: FontWeight.w700))), Icon(Icons.circle, size: 10, color: color)]),
              Text(table.status.label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              Text('${table.currentGuests > 0 ? table.currentGuests : table.capacity} guests', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCounter extends ConsumerWidget {
  const _GuestCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(currentOrderProvider).guestCount;
    final controller = ref.read(currentOrderProvider.notifier);
    return SectionPanel(
      title: 'Guests',
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(onPressed: () => controller.setGuestCount(count - 1), icon: const Icon(Icons.remove)),
              Expanded(child: Center(child: Text('$count', style: Theme.of(context).textTheme.headlineSmall))),
              IconButton.filledTonal(onPressed: () => controller.setGuestCount(count + 1), icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5, 6, 8, 10]
                .map((value) => ChoiceChip(label: Text('$value'), selected: value == count, onSelected: (_) => controller.setGuestCount(value)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CompactGuestCounter extends ConsumerWidget {
  const _CompactGuestCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(currentOrderProvider).guestCount;
    final controller = ref.read(currentOrderProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guests', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox.square(
                  dimension: 32,
                  child: IconButton.filledTonal(
                    padding: EdgeInsets.zero,
                    onPressed: () => controller.setGuestCount(count - 1),
                    icon: const Icon(Icons.remove, size: 16),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SizedBox.square(
                  dimension: 32,
                  child: IconButton.filledTonal(
                    padding: EdgeInsets.zero,
                    onPressed: () => controller.setGuestCount(count + 1),
                    icon: const Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [1, 2, 3, 4, 6, 8].map((value) {
                return SizedBox(
                  width: 34,
                  height: 30,
                  child: ChoiceChip(
                    label: Text('$value'),
                    selected: value == count,
                    showCheckmark: false,
                    labelPadding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => controller.setGuestCount(value),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends ConsumerWidget {
  const _CategorySelector({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentOrderProvider).selectedCategoryId;
    final chips = ref.watch(categoriesProvider).when(
          data: (categories) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: selected == category.id,
                          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                          onSelected: (_) => ref.read(currentOrderProvider.notifier).setCategory(category.id),
                        ),
                      ))
                  .toList(),
            ),
          ),
          error: (_, _) => const ErrorView(message: 'Could not load categories.'),
          loading: () => const LinearProgressIndicator(),
        );
    if (compact) return chips;
    return SectionPanel(title: 'Categories', child: chips);
  }
}

class _FoodSearch extends ConsumerWidget {
  const _FoodSearch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search menu', hintText: 'Food name, description'),
      onChanged: ref.read(currentOrderProvider.notifier).setSearch,
    );
  }
}

class _FoodGrid extends ConsumerWidget {
  const _FoodGrid({this.scrollable = false});

  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(foodsProvider);
    final foods = ref.watch(filteredFoodsProvider);
    final cartItems = ref.watch(currentOrderProvider).items;
    return foodsAsync.when(
      data: (_) {
        if (foods.isEmpty) return const SizedBox(height: 180, child: EmptyView(title: 'No foods found', message: 'Try another category or search term.', icon: Icons.no_meals_outlined));
        return GridView.builder(
          shrinkWrap: !scrollable,
          physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: .9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: foods.length,
          itemBuilder: (context, index) {
            final food = foods[index];
            final quantity = cartItems.where((item) => item.foodId == food.id).fold(0, (sum, item) => sum + item.quantity);
            return _FoodCard(food: food, quantity: quantity);
          },
        );
      },
      error: (_, _) => const ErrorView(message: 'Could not load menu items.'),
      loading: () => const SizedBox(height: 220, child: LoadingView(message: 'Loading menu')),
    );
  }
}

class _FoodCard extends ConsumerWidget {
  const _FoodCard({required this.food, required this.quantity});

  final Food food;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(currentOrderProvider.notifier);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: food.isAvailable ? () => controller.addFood(food) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: food.isAvailable ? scheme.surfaceContainerLowest : scheme.surfaceContainerHighest,
          border: Border.all(color: quantity > 0 ? scheme.primary : scheme.outlineVariant, width: quantity > 0 ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: scheme.primaryContainer.withOpacity(.45), borderRadius: BorderRadius.circular(8)),
                  child: food.image == null || food.image!.isEmpty
                      ? Icon(food.isAvailable ? Icons.lunch_dining : Icons.block, size: 42, color: scheme.primary)
                      : Image.network(
                          food.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(food.isAvailable ? Icons.lunch_dining : Icons.block, size: 42, color: scheme.primary);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes == null
                                      ? null
                                      : loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(food.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(food.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: MoneyText(food.price, style: const TextStyle(fontWeight: FontWeight.w700))),
                  if (quantity > 0)
                    _FoodQuantityControls(
                      quantity: quantity,
                      onRemove: () => controller.changeQuantity(food.id, -1),
                      onAdd: () => controller.addFood(food),
                    )
                  else
                    IconButton.filled(
                      tooltip: 'Add item',
                      onPressed: food.isAvailable ? () => controller.addFood(food) : null,
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodQuantityControls extends StatelessWidget {
  const _FoodQuantityControls({
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
  });

  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 34,
            child: IconButton(
              tooltip: 'Remove item',
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              icon: const Icon(Icons.remove, size: 18),
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox.square(
            dimension: 34,
            child: IconButton(
              tooltip: 'Add item',
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider);
    final controller = ref.read(currentOrderProvider.notifier);
    return SectionPanel(
      title: 'Current Order',
      trailing: TextButton.icon(onPressed: order.items.isEmpty ? null : controller.clearOrder, icon: const Icon(Icons.delete_outline), label: const Text('Clear')),
      child: Column(
        children: [
          if (order.errorMessage != null) _MessageBanner(message: order.errorMessage!, isError: true),
          if (order.successMessage != null) _MessageBanner(message: order.successMessage!, isError: false),
          if (order.items.isEmpty)
            const SizedBox(height: 120, child: EmptyView(title: 'Cart is empty', message: 'Tap foods to add them.', icon: Icons.shopping_bag_outlined))
          else
            ...order.items.map((item) => _OrderItemTile(item: item)),
          TextField(
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.sticky_note_2_outlined), labelText: 'Order notes'),
            onChanged: controller.setGeneralNotes,
          ),
          const SizedBox(height: 12),
          _Totals(order: order),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: order.isSubmitting ? null : controller.submitOrder,
                  icon: order.isSubmitting
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Send Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showOrderPreview(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _OrderPreviewDialog(),
  );
}

class _OrderPreviewDialog extends ConsumerWidget {
  const _OrderPreviewDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider);
    final controller = ref.read(currentOrderProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Order Preview')),
          if (order.selectedTable != null)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(order.selectedTable!.name),
            ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.items.isEmpty)
              const SizedBox(
                height: 140,
                child: EmptyView(
                  title: 'No items selected',
                  message: 'Add foods before saving.',
                  icon: Icons.shopping_bag_outlined,
                ),
              )
            else
              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: order.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${item.quantity} x ؋${item.unitPrice.toStringAsFixed(2)}', style: TextStyle(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          _FoodQuantityControls(
                            quantity: item.quantity,
                            onRemove: () => controller.changeQuantity(item.foodId, -1),
                            onAdd: () => controller.changeQuantity(item.foodId, 1),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(width: 78, child: Align(alignment: Alignment.centerRight, child: MoneyText(item.total))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            _TotalRow(
              label: 'Total',
              value: order.total,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (order.errorMessage != null) ...[
              const SizedBox(height: 10),
              _MessageBanner(message: order.errorMessage!, isError: true),
            ],
            if (order.successMessage != null) ...[
              const SizedBox(height: 10),
              _MessageBanner(message: order.successMessage!, isError: false),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          onPressed: order.items.isEmpty ? null : controller.clearOrder,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear'),
        ),
        FilledButton.icon(
          onPressed: order.isSubmitting
              ? null
              : () async {
                  final createdOrder = await controller.submitOrder();
                  if (context.mounted && createdOrder != null) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Order ${createdOrder.orderNumber} created successfully.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                  }
                },
          icon: order.isSubmitting
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('Send Order'),
        ),
      ],
    );
  }
}

class _OrderItemTile extends ConsumerWidget {
  const _OrderItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(currentOrderProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w700))),
              MoneyText(item.total),
              IconButton(tooltip: 'Remove', onPressed: () => controller.removeItem(item.foodId), icon: const Icon(Icons.close)),
            ],
          ),
          Row(
            children: [
              IconButton.filledTonal(onPressed: () => controller.changeQuantity(item.foodId, -1), icon: const Icon(Icons.remove)),
              SizedBox(width: 36, child: Center(child: Text('${item.quantity}'))),
              IconButton.filledTonal(onPressed: () => controller.changeQuantity(item.foodId, 1), icon: const Icon(Icons.add)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(isDense: true, labelText: 'Item notes'),
                  onChanged: (value) => controller.updateItemNotes(item.foodId, value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.order});

  final CurrentOrderState order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _TotalRow(label: 'Total', value: order.total, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.style});

  final String label;
  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          MoneyText(value, style: style),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer)),
    );
  }
}
