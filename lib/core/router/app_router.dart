import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/order/presentation/take_order_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/take-order',
    redirect: (context, state) {
      final isLogin = state.matchedLocation == '/login';
      if (!authState.isAuthenticated) return isLogin ? null : '/login';
      if (isLogin) return '/take-order';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/take-order', builder: (context, state) => const TakeOrderScreen()),
          GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) => OrderDetailsScreen(orderId: Uri.decodeComponent(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = location.startsWith('/orders') ? 1 : 0;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final navItems = const [
      NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Take Order'),
      NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
    ];
    void go(int index) => context.go(index == 0 ? '/take-order' : '/orders');

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Take Order')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Orders')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: navItems,
        onDestinationSelected: go,
      ),
    );
  }
}
