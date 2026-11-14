import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/models/delivery_models.dart';
import 'delivery_controller.dart';
import 'delivery_proof_sheet.dart';
import 'widgets/delivery_status_chip.dart';

class DeliveryStopPage extends StatelessWidget {
  const DeliveryStopPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    final stop = controller.route?.stopByOrderId(orderId);

    if (stop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const Center(child: Text('Pedido não está mais nesta rota.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pedido #${stop.code}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: DeliveryStatusChip(status: stop.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _InfoCard(stop: stop),
          const SizedBox(height: 12),
          _VolumesCard(stop: stop),
          const SizedBox(height: 12),
          _TimelineCard(stop: stop),
        ],
      ),
      bottomNavigationBar: _ActionsBar(controller: controller, stop: stop),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.stop});

  final DeliveryStop stop;

  @override
  Widget build(BuildContext context) {
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
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(stop.customerName, style: AppTypography.heading3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(stop.addressText, style: AppTypography.body),
              ),
            ],
          ),
          if (stop.timeSlot != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(stop.timeSlot!, style: AppTypography.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openNavigation(context, stop),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Maps'),
                ),
              ],
            ),
          ],
          if (stop.phone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(stop.phone!, style: AppTypography.bodySmall)),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: stop.phone!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Telefone copiado')),
                      );
                    }
                  },
                  child: const Text('Copiar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Navegação turn-by-turn é delegada ao Google Maps/Waze: o app só manda o
  /// destino da parada atual. Quem decide a **sequência** é o despacho.
  Future<void> _openNavigation(BuildContext context, DeliveryStop stop) async {
    final lat = stop.latitude;
    final lng = stop.longitude;
    final uri = (lat != null && lng != null)
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(stop.addressText)}');

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!opened && context.mounted) {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Maps. Link copiado.')),
        );
      }
    }
  }
}

class _VolumesCard extends StatelessWidget {
  const _VolumesCard({required this.stop});

  final DeliveryStop stop;

  @override
  Widget build(BuildContext context) {
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
          const Text('Carga do pedido', style: AppTypography.heading3),
          const SizedBox(height: 12),
          Row(
            children: [
              _VolumeBadge(
                icon: Icons.inventory_2_outlined,
                label: 'Secos',
                value: '${stop.dryVolumes}',
              ),
              const SizedBox(width: 10),
              _VolumeBadge(
                icon: Icons.ac_unit_outlined,
                label: 'Gelados',
                value: '${stop.coldVolumes}',
              ),
              const SizedBox(width: 10),
              _VolumeBadge(
                icon: Icons.shopping_basket_outlined,
                label: 'Itens',
                value: '${stop.itemsCount}',
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valor do pedido', style: AppTypography.bodySmall),
              Text(
                CurrencyFormatter.format(stop.totalAmount),
                style: AppTypography.priceHighlight.copyWith(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolumeBadge extends StatelessWidget {
  const _VolumeBadge({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.heading3.copyWith(fontSize: 15)),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.stop});

  final DeliveryStop stop;

  String _time(DateTime? value) {
    if (value == null) return '--:--';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String time, bool done})>[
      (label: 'Saiu para entrega', time: '—', done: stop.status != StopStatus.pending),
      (label: 'Chegou no cliente', time: _time(stop.arrivedAt), done: stop.arrivedAt != null),
      (
        label: stop.status == StopStatus.failed ? 'Falha registrada' : 'Entregue',
        time: _time(stop.deliveredAt),
        done: stop.status == StopStatus.delivered || stop.status == StopStatus.failed,
      ),
    ];

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
          const Text('Histórico', style: AppTypography.heading3),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    row.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: row.done ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: row.done ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: row.done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(row.time, style: AppTypography.caption),
                ],
              ),
            ),
          ),
          if (stop.failureReason != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Motivo: ${stop.failureReason}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionsBar extends StatelessWidget {
  const _ActionsBar({required this.controller, required this.stop});

  final DeliveryController controller;
  final DeliveryStop stop;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    switch (stop.status) {
      case StopStatus.pending:
        children.addAll([
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.startStop(stop),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Saiu para entrega'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => controller.markArrived(stop),
              icon: const Icon(Icons.place_outlined, size: 18),
              label: const Text('Já estou no cliente'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]);
      case StopStatus.onRoute:
        children.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.markArrived(stop),
              icon: const Icon(Icons.place, size: 18),
              label: const Text('Cheguei no cliente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        );
      case StopStatus.arrived:
        children.addAll([
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelivery(context),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Confirmar entrega'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _reportFailure(context),
              icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
              label: const Text('Não entregue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]);
      case StopStatus.delivered:
        children.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primaryDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrega confirmada. Prova registrada no aparelho.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        );
      case StopStatus.failed:
        children.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Falha registrada: ${stop.failureReason ?? 'motivo não informado'}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final proof = await DeliveryProofSheet.show(
      context: context,
      stop: stop,
      captureLocation: controller.captureLocation,
    );
    if (proof == null) return;
    final err = await controller.deliver(stop, proof: proof);
    if (context.mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível confirmar entrega: $err'),
            backgroundColor: AppColors.danger,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega confirmada'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _reportFailure(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Por que não entregou?', style: AppTypography.heading3),
            const SizedBox(height: 8),
            ...deliveryFailureReasons.map(
              (option) => ListTile(
                title: Text(option, style: AppTypography.body),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (reason == null) return;
    await controller.failDelivery(stop, reason: reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha registrada: $reason')),
      );
    }
  }
}
