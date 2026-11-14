import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../domain/models/order_model.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _syncOrders();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncOrders());
  }

  Future<void> _syncOrders() async {
    final list = await CatalogApiService.fetchOrders();
    if (!mounted || list.isEmpty) return;
    context.read<AppStateController>().syncOrdersListFromErp(list);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    final activeOrders = appState.activeOrders;
    final pastOrders = appState.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Em Andamento (${activeOrders.length})'),
            Tab(text: 'Histórico (${pastOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(activeOrders, isActive: true),
          _buildOrdersList(pastOrders, isActive: false),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isActive ? 'Nenhum pedido em andamento no momento.' : 'Nenhum pedido anterior.',
          style: AppTypography.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isActive: isActive);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isActive}) {
    final bool needsApproval = order.needsClientApproval && !order.clientApprovedChanges;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsApproval ? AppColors.warning : AppColors.border,
          width: needsApproval ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedido #${order.code}', style: AppTypography.heading2.copyWith(fontSize: 16)),
                  Text(
                    '${order.deliveryType == "delivery" ? "Entrega" : "Retirada"} • ${order.scheduledWindow}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'cancelled'
                      ? AppColors.dangerLight
                      : (isActive ? AppColors.secondaryLight : AppColors.surfaceElevated),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: order.status == 'cancelled'
                        ? AppColors.danger
                        : (isActive ? AppColors.secondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          if (needsApproval) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.scale_outlined, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pesagem concluída! Há ajuste de peso aguardando sua aprovação.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemsCount} itens • ${order.paymentMethod}',
                style: AppTypography.bodySmall,
              ),
              Text(
                CurrencyFormatter.format(order.totalAmount),
                style: AppTypography.priceHighlight.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              if (isActive)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackingPage(order: order)),
                      );
                    },
                    icon: Icon(
                      needsApproval ? Icons.fact_check_outlined : Icons.local_shipping_outlined,
                      size: 18,
                    ),
                    label: Text(
                      needsApproval ? 'Revisar Pesagem e Acompanhar' : 'Acompanhar Pedido',
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackingPage(order: order)),
                      );
                    },
                    child: const Text('Ver Detalhes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final cart = context.read<CartController>();
                      cart.recoverOrderItems(order.items);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${order.items.length} itens do Pedido #${order.code} adicionados ao carrinho!'),
                          backgroundColor: AppColors.primary,
                          action: SnackBarAction(
                            label: 'VER CARRINHO',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartPage()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Comprar de Novo'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
