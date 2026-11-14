import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/models/delivery_models.dart';
import 'delivery_controller.dart';
import 'delivery_stop_page.dart';
import 'widgets/delivery_status_chip.dart';

class DeliveryHomePage extends StatelessWidget {
  const DeliveryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    final route = controller.route;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Entregas'),
        actions: [
          if (controller.pendingCount > 0)
            IconButton(
              tooltip: 'Sincronizar (${controller.pendingCount})',
              onPressed: controller.syncing ? null : controller.flushQueue,
              icon: Badge(
                label: Text('${controller.pendingCount}'),
                child: const Icon(Icons.cloud_sync_outlined),
              ),
            ),
          IconButton(
            tooltip: 'Atualizar rota',
            onPressed: controller.loading ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _ShiftCard(controller: controller),
            if (controller.isDemo) ...[
              const SizedBox(height: 12),
              const _Banner(
                icon: Icons.science_outlined,
                background: AppColors.infoLight,
                foreground: AppColors.info,
                title: 'Modo demonstração',
                message:
                    'O ERP ainda não expõe os endpoints de entrega. A rota abaixo é de exemplo e nada é enviado.',
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.wifi_off_outlined,
                background: AppColors.warningLight,
                foreground: const Color(0xFF92400E),
                title: 'Sem conexão',
                message: controller.errorMessage!,
              ),
            ],
            if (controller.pendingCount > 0) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.cloud_upload_outlined,
                background: AppColors.surfaceElevated,
                foreground: AppColors.textSecondary,
                title: '${controller.pendingCount} evento(s) aguardando envio',
                message: 'As entregas já foram registradas no aparelho. Toque em sincronizar quando tiver sinal.',
                action: controller.syncing
                    ? null
                    : TextButton(
                        onPressed: controller.flushQueue,
                        child: const Text('Sincronizar'),
                      ),
              ),
            ],
            const SizedBox(height: 16),
            if (controller.loading && route == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (route == null)
              _EmptyRoute(onRefresh: controller.refresh)
            else ...[
              _RouteSummary(route: route, controller: controller),
              const SizedBox(height: 16),
              const Text('Paradas', style: AppTypography.heading3),
              const SizedBox(height: 8),
              ...route.stops.map(
                (stop) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StopCard(
                    stop: stop,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryStopPage(orderId: stop.orderId),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.controller});

  final DeliveryController controller;

  @override
  Widget build(BuildContext context) {
    final open = controller.shiftOpen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: open ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: open ? AppColors.primaryDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: open ? Colors.white24 : AppColors.primaryLight,
                child: Icon(
                  Icons.two_wheeler,
                  color: open ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.courierName,
                      style: AppTypography.heading3.copyWith(
                        color: open ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      controller.shiftLabel,
                      style: AppTypography.caption.copyWith(
                        color: open ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: open,
                activeColor: Colors.white,
                activeTrackColor: Colors.white38,
                onChanged: (value) async {
                  if (value) {
                    await controller.openShift();
                  } else {
                    await controller.closeShift();
                  }
                },
              ),
            ],
          ),
          if (!open) ...[
            const SizedBox(height: 8),
            const Text(
              'Abra o turno para receber a rota do dia.',
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route, required this.controller});

  final DeliveryRoute route;
  final DeliveryController controller;

  @override
  Widget build(BuildContext context) {
    final hasPendingStart = route.stops.any((s) => s.status == StopStatus.pending);
    final pendingCount = route.stops.where((s) => s.status == StopStatus.pending).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  const Text('Rota de hoje', style: AppTypography.heading3),
                  Text(
                    route.storeName ?? 'Mercadinho',
                    style: AppTypography.caption,
                  ),
                ],
              ),
              Text(
                '${route.delivered}/${route.total}',
                style: AppTypography.priceHighlight.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: route.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: 'Entregues', value: '${route.delivered}'),
              _Metric(label: 'Restantes', value: '${route.remaining}'),
              _Metric(label: 'Volumes', value: '${route.totalVolumes}'),
              _Metric(label: 'Falhas', value: '${route.failed}'),
            ],
          ),
          if (hasPendingStart) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmarRetirada(context, controller, route),
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text('Confirmar retirada de $pendingCount pedido(s)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Para liberar um pedido por vez, abra a parada e toque em "Saiu para entrega".',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
  /// Retirada em lote: só acontece com confirmação explícita.
  Future<void> _confirmarRetirada(
    BuildContext context,
    DeliveryController controller,
    DeliveryRoute route,
  ) async {
    final pendentes = route.stops.where((s) => s.status == StopStatus.pending).length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar retirada?'),
        content: Text(
          'Isso marca $pendentes pedido(s) como "saiu para entrega" de uma vez.\n\n'
          'Use só se você está levando todos agora. Para liberar um por vez, '
          'abra a parada e use "Saiu para entrega".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm == true) await controller.startAllStops();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.heading2.copyWith(fontSize: 17)),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, required this.onTap});

  final DeliveryStop stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${stop.sequence}',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedido #${stop.code}',
                          style: AppTypography.heading3.copyWith(fontSize: 14),
                        ),
                      ),
                      DeliveryStatusChip(status: stop.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(stop.customerName, style: AppTypography.bodySmall),
                  Text(
                    stop.addressText,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stop.totalVolumes} volumes · ${stop.itemsCount} itens · ${CurrencyFormatter.format(stop.totalAmount)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 11, color: foreground),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Nenhuma rota para hoje', style: AppTypography.heading3),
          const SizedBox(height: 4),
          const Text(
            'Quando o mercadinho separar e faturar os pedidos, a rota aparece aqui.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
