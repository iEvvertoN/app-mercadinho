import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/picking_models.dart';
import 'picking_controller.dart';

/// Conferência de verdade: lista o que foi separado, os lacres e pede a
/// contagem de volumes. Antes era um diálogo que só pedia um número — o
/// conferente não tinha o que conferir.
class PickingVerifyPage extends StatefulWidget {
  const PickingVerifyPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<PickingVerifyPage> createState() => _PickingVerifyPageState();
}

class _PickingVerifyPageState extends State<PickingVerifyPage> {
  late final TextEditingController _verifierController;
  int _volumes = 0;
  bool _iniciado = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PickingController>();
    _verifierController = TextEditingController(text: controller.verifier);
  }

  @override
  void dispose() {
    _verifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PickingController>();
    final task = controller.taskByOrderId(widget.orderId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conferência')),
        body: const Center(child: Text('Pedido não está mais na fila.')),
      );
    }

    if (!_iniciado) {
      _volumes = task.expectedVolumes;
      _iniciado = true;
    }

    final mesmoSeparador = (task.assigneeId ?? '').trim().toLowerCase() ==
        _verifierController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Conferir #${task.code}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _card(
            titulo: 'Itens separados (${task.items.length})',
            child: Column(
              children: task.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            item.isResolved ? Icons.check_circle : Icons.error_outline,
                            size: 15,
                            color: item.isResolved ? AppColors.primary : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.billedQty.toStringAsFixed(2)} ${item.unit}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            titulo: 'Sacolas e lacres (${task.sealedBags}/${task.bags.length})',
            child: Column(
              children: task.bags
                  .map(
                    (bag) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            bag.temperature == BagTemperature.cold
                                ? Icons.ac_unit
                                : Icons.inventory_2_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${bag.id} · ${bag.temperature == BagTemperature.cold ? "GELADO" : "SECO"}',
                            style: AppTypography.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            bag.sealNumber ?? 'sem lacre',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: bag.isSealed ? AppColors.primaryDark : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            titulo: 'Conferência',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _verifierController,
                  decoration: const InputDecoration(
                    labelText: 'Quem conferiu',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (mesmoSeparador) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF92400E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mesmo nome do separador. O processo pede outra pessoa na conferência.',
                          style: AppTypography.caption.copyWith(color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Volumes contados', style: AppTypography.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      onPressed: _volumes > 0 ? () => setState(() => _volumes -= 1) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_volumes',
                      style: AppTypography.heading2.copyWith(fontSize: 22),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _volumes += 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    Text(
                      'esperado: ${task.expectedVolumes}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confira fisicamente as sacolas. A contagem precisa bater com o número de lacres.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enviando || _volumes != task.expectedVolumes
                  ? null
                  : () => _confirmar(controller, task),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(_enviando ? 'Registrando...' : 'Confirmar conferência'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_volumes != task.expectedVolumes)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'A contagem precisa ser igual a ${task.expectedVolumes} para liberar.',
                style: AppTypography.caption.copyWith(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required String titulo, required Widget child}) {
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
          Text(titulo, style: AppTypography.heading3),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmar(PickingController controller, PickingTask task) async {
    setState(() => _enviando = true);
    await controller.setVerifier(_verifierController.text);
    final result = await controller.verifyTask(task, volumes: _volumes);
    setState(() => _enviando = false);

    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    Navigator.of(context).pop(true);
  }
}
