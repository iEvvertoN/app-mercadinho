import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/seal_printer.dart';
import '../domain/picking_models.dart';
import '../domain/seal_label.dart';
import 'picking_controller.dart';
import 'picking_verify_page.dart';

/// Separação guiada: um item por vez, na ordem de caminhada.
class PickingTaskPage extends StatefulWidget {
  const PickingTaskPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<PickingTaskPage> createState() => _PickingTaskPageState();
}

class _PickingTaskPageState extends State<PickingTaskPage> {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PickingController>();
    final task = controller.taskByOrderId(widget.orderId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Separação')),
        body: const Center(child: Text('Pedido não está mais na fila.')),
      );
    }

    final pendentes = task.itemsInWalkOrder.where((item) => !item.isResolved).toList();
    final atual = pendentes.isEmpty ? null : pendentes.first;
    final separando =
        task.status == PickingStatus.inProgress || task.status == PickingStatus.packing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pedido #${task.code}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _StatusChip(status: task.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          _ProgressCard(task: task, pendentes: pendentes.length),
          if (separando) ...[
            const SizedBox(height: 12),
            _ScanField(
              controller: _scanController,
              focusNode: _scanFocus,
              onSubmitted: (value) => _handleScan(controller, task, value),
            ),
            const SizedBox(height: 12),
            if (atual != null)
              _CurrentItemCard(
                item: atual,
                posicao: task.items.length - pendentes.length + 1,
                total: task.items.length,
                onConfirm: () => _askQuantity(controller, task, atual),
                onWeigh: () => _askWeigh(controller, task, atual),
                onMissing: () => _askMissing(controller, task, atual),
              )
            else
              _DoneCard(onClose: () => _confirmarLacres(controller, task)),
          ],
          if (task.status == PickingStatus.ready) _ReadyCard(task: task),
          if (task.status == PickingStatus.verified)
            _VerifiedCard(controller: controller, task: task),
          const SizedBox(height: 16),
          Text(
            'Itens (${task.resolvedCount}/${task.items.length})',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 8),
          ...task.itemsInWalkOrder.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ItemRow(
                item: item,
                onDecide: (approved) async {
                  final result = await controller.decideSubstitution(task, item.id, approved);
                  if (!result.ok) _snack(result.error!);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        task: task,
        busy: _busy,
        onStart: () async {
          final result = await controller.startTask(task);
          if (!result.ok) _snack(result.error!);
          _scanFocus.requestFocus();
        },
        onClose: () => _confirmarLacres(controller, task),
        onVerify: () => _abrirConferencia(controller, task),
        onHandOff: () => _handOff(controller, task),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleScan(
    PickingController controller,
    PickingTask task,
    String value,
  ) async {
    final code = value.trim();
    if (code.isEmpty) return;

    final candidatos =
        task.items.where((item) => item.barcode == code && !item.isResolved).toList();
    if (candidatos.isEmpty) {
      _scanController.clear();
      _snack('Código $code não pertence a este pedido.');
      return;
    }

    final item = candidatos.first;
    _scanController.clear();
    if (item.weighable) {
      await _askWeigh(controller, task, item);
      return;
    }
    final result = await controller.scan(task, item.id, code);
    if (!result.ok) _snack(result.error!);
    _scanFocus.requestFocus();
  }

  Future<void> _askQuantity(
    PickingController controller,
    PickingTask task,
    PickingItem item,
  ) async {
    final textController = TextEditingController(text: item.requestedQty.toString());
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quantidade: ${item.name}'),
        content: TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Encontrado (${item.unit})'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(textController.text.replaceAll(',', '.')),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final result = await controller.scan(task, item.id, item.barcode, qty: value);
    if (!result.ok) _snack(result.error!);
  }

  Future<void> _askWeigh(
    PickingController controller,
    PickingTask task,
    PickingItem item,
  ) async {
    final textController = TextEditingController();
    final grams = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pesar: ${item.name}'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Peso em gramas', hintText: '480'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, double.tryParse(textController.text)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (grams == null || grams <= 0) return;
    final result = await controller.weigh(task, item.id, grams);
    if (!result.ok) _snack(result.error!);
  }

  Future<void> _askMissing(
    PickingController controller,
    PickingTask task,
    PickingItem item,
  ) async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Não encontrei: ${item.name}', style: AppTypography.heading3),
            const SizedBox(height: 8),
            ...['Sem estoque na gôndola', 'Produto avariado', 'Produto vencido'].map(
              (option) => ListTile(
                leading: const Icon(Icons.remove_shopping_cart_outlined, size: 20),
                title: Text(option, style: AppTypography.body),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.info),
              title: const Text('Oferecer substituto'),
              subtitle: const Text('Acima de +20% o cliente aprova pelo app'),
              onTap: () => Navigator.pop(sheetContext, 'substituir'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (escolha == null) return;
    if (escolha == 'substituir') {
      await _askSubstitute(controller, task, item);
      return;
    }
    final result = await controller.markMissing(task, item.id, escolha);
    if (!result.ok) _snack(result.error!);
  }

  Future<void> _askSubstitute(
    PickingController controller,
    PickingTask task,
    PickingItem item,
  ) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Substituir por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Original: ${item.name}', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Produto substituto'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Preço unitário'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Propor'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final preco = double.tryParse(priceController.text.replaceAll(',', '.'));
    if (nameController.text.trim().isEmpty || preco == null) {
      _snack('Informe produto e preço.');
      return;
    }

    final result = await controller.proposeSubstitution(
      task,
      item.id,
      toProductId: 'sub-${item.productId}',
      toProductName: nameController.text.trim(),
      toPrice: preco,
    );
    if (!result.ok) {
      _snack(result.error!);
      return;
    }
    final substituicao = task.itemById(item.id)?.substitution;
    if (substituicao != null && substituicao.requiresApproval) {
      _snack('Acima de +20%: aguardando aprovação do cliente.');
    }
  }

  /// Mostra o conteúdo das sacolas antes de lacrar.
  Future<void> _confirmarLacres(PickingController controller, PickingTask task) async {
    if (task.hasPendingItems) {
      _snack('Ainda há itens pendentes.');
      return;
    }

    final propostas = proposeBags(task);
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fechar separação', style: AppTypography.heading2),
              const SizedBox(height: 4),
              const Text(
                'Confira o que vai em cada sacola. Os lacres são gerados e impressos ao confirmar.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              ...propostas.map((proposta) {
                final itens =
                    proposta.itemIds.map((id) => task.itemById(id)?.name ?? id).toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            proposta.temperature == BagTemperature.cold
                                ? Icons.ac_unit
                                : Icons.inventory_2_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${proposta.bagId} · '
                            '${proposta.temperature == BagTemperature.cold ? "GELADO" : "SECO"}',
                            style: AppTypography.heading3.copyWith(fontSize: 13),
                          ),
                          const Spacer(),
                          Text('${itens.length} itens', style: AppTypography.caption),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...itens.map(
                        (nome) => Text('• $nome', style: AppTypography.caption),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Lacrar e imprimir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmado != true) return;

    setState(() => _busy = true);
    final resultado = await controller.sealAndFinish(task);
    setState(() => _busy = false);

    if (!resultado.result.ok) {
      _snack(resultado.result.error!);
      return;
    }
    if (!mounted) return;
    await _printLabels(controller, resultado.labels);
  }

  Future<void> _printLabels(PickingController controller, List<SealLabel> labels) async {
    if (labels.isEmpty) return;

    final impressos = <String, PrinterResult>{};
    for (final label in labels) {
      impressos[label.sealNumber] = await controller.printLabel(label);
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lacres gerados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: labels.map((label) {
            final status = switch (impressos[label.sealNumber]) {
              PrinterQueued() => 'impresso',
              PrinterNotConfigured() => 'impressora não configurada',
              PrinterFailed() => 'falha ao imprimir',
              null => '',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${label.sealNumber} · ${label.temperatureLabel} · ${label.bagId} ($status)',
                style: AppTypography.bodySmall,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final texto = labels.map(controller.previewLabel).join('\n\n');
              await Clipboard.setData(ClipboardData(text: texto));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Rótulos copiados')),
                );
              }
            },
            child: const Text('Copiar rótulos'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirConferencia(PickingController controller, PickingTask task) async {
    final confirmado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PickingVerifyPage(orderId: task.orderId)),
    );
    if (confirmado == true) {
      _snack('Pedido conferido. Pode entregar ao entregador.');
    }
  }

  Future<void> _handOff(PickingController controller, PickingTask task) async {
    final courierController = TextEditingController(text: 'entregador-01');
    var senhaConferida = false;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setLocal) => AlertDialog(
          title: const Text('Entregar ao entregador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courierController,
                decoration: const InputDecoration(labelText: 'Entregador (ID ou nome)'),
                autofocus: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: senhaConferida,
                onChanged: (value) => setLocal(() => senhaConferida = value ?? false),
                title: const Text('Senha conferida com o cliente'),
              ),
            ],
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
      ),
    );

    if (confirmado != true) return;
    final result = await controller.handOff(
      task,
      courierId: courierController.text.trim(),
      passwordChecked: senhaConferida,
    );
    if (!result.ok) _snack(result.error!);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.task, required this.pendentes});

  final PickingTask task;
  final int pendentes;

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
              Text(
                '${task.resolvedCount} de ${task.items.length} itens',
                style: AppTypography.heading3,
              ),
              const Spacer(),
              Text(
                pendentes == 0 ? 'tudo conferido' : '$pendentes restando',
                style: AppTypography.caption.copyWith(
                  color: pendentes == 0 ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total conferido: ${CurrencyFormatter.format(task.billedTotal)}',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _CurrentItemCard extends StatelessWidget {
  const _CurrentItemCard({
    required this.item,
    required this.posicao,
    required this.total,
    required this.onConfirm,
    required this.onWeigh,
    required this.onMissing,
  });

  final PickingItem item;
  final int posicao;
  final int total;
  final VoidCallback onConfirm;
  final VoidCallback onWeigh;
  final VoidCallback onMissing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Item $posicao de $total', style: AppTypography.caption),
              const Spacer(),
              if (item.aisle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Corredor ${item.aisle}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.name, style: AppTypography.heading2),
          const SizedBox(height: 4),
          Text(
            'Pedido: ${item.requestedQty} ${item.unit}'
            '${item.weighable ? '  ·  pesar na balança' : '  ·  EAN ${item.barcode}'}'
            '${item.isCold ? '  ·  gelado' : ''}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: item.weighable ? onWeigh : onConfirm,
                  icon: Icon(item.weighable ? Icons.scale_outlined : Icons.check, size: 18),
                  label: Text(item.weighable ? 'Pesar' : 'Conferir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onMissing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                child: const Text('Faltou'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                'Todos os itens conferidos',
                style: AppTypography.heading3.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Agora feche a separação: confira as sacolas, gere e imprima os lacres.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Fechar separação e lacrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.task});

  final PickingTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aguardando conferência',
            style: AppTypography.heading3.copyWith(color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 4),
          Text(
            '${task.sealedBags} sacola(s) lacrada(s). Quem separa não deve conferir o próprio pedido.',
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({required this.controller, required this.task});

  final PickingController controller;
  final PickingTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Conferido por ${task.verifiedBy ?? controller.verifier} · ${task.volumesCounted} volumes',
        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onDecide});

  final PickingItem item;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final substitution = item.substitution;
    final aguardando = substitution != null &&
        substitution.requiresApproval &&
        substitution.approval == SubstitutionApproval.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isResolved ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: item.isResolved ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: item.isResolved ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isResolved)
                Text(
                  '${item.billedQty.toStringAsFixed(2)} ${item.unit}',
                  style: AppTypography.caption,
                ),
            ],
          ),
          if (item.missingReason != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                item.missingReason!,
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
            ),
          if (aguardando)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Aguardando cliente',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                  TextButton(onPressed: () => onDecide(true), child: const Text('Aprovado')),
                  TextButton(onPressed: () => onDecide(false), child: const Text('Recusado')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanField extends StatelessWidget {
  const _ScanField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Bipe o código (ou digite e Enter)',
                border: InputBorder.none,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PickingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      PickingStatus.waiting => 'Na fila',
      PickingStatus.inProgress => 'Separando',
      PickingStatus.packing => 'Embalando',
      PickingStatus.ready => 'Pronto',
      PickingStatus.verified => 'Conferido',
      PickingStatus.handedOff => 'Entregue',
      PickingStatus.canceled => 'Cancelado',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.task,
    required this.busy,
    required this.onStart,
    required this.onClose,
    required this.onVerify,
    required this.onHandOff,
  });

  final PickingTask task;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onClose;
  final VoidCallback onVerify;
  final VoidCallback onHandOff;

  @override
  Widget build(BuildContext context) {
    final Widget conteudo;

    switch (task.status) {
      case PickingStatus.waiting:
        conteudo = _botao('Iniciar separação', onStart, Icons.play_arrow_rounded);
      case PickingStatus.inProgress:
      case PickingStatus.packing:
        conteudo = _botao(
          busy ? 'Gerando lacres...' : 'Fechar separação',
          busy || task.hasPendingItems ? null : onClose,
          Icons.inventory_2_outlined,
          dica: task.hasPendingItems ? 'Ainda há itens pendentes' : null,
        );
      case PickingStatus.ready:
        conteudo = _botao('Conferir pedido', onVerify, Icons.fact_check_outlined);
      case PickingStatus.verified:
        conteudo = _botao('Entregar ao entregador', onHandOff, Icons.local_shipping_outlined);
      case PickingStatus.handedOff:
        conteudo = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pedido entregue ao entregador. A rota segue no app de entregas.',
            style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
          ),
        );
      case PickingStatus.canceled:
        conteudo = const Text('Separação cancelada.');
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: conteudo,
      ),
    );
  }

  Widget _botao(String label, VoidCallback? onPressed, IconData icon, {String? dica}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (dica != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(dica, style: AppTypography.caption),
          ),
      ],
    );
  }
}
