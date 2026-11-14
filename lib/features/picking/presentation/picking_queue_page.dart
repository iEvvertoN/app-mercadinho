import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/picking_models.dart';
import 'picking_controller.dart';
import 'picking_task_page.dart';

class PickingQueuePage extends StatelessWidget {
  const PickingQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PickingController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Separação'),
        actions: [
          IconButton(
            tooltip: 'Impressora de lacre',
            onPressed: () => _configurePrinter(context, controller),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar fila',
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
            _SeparatorCard(controller: controller),
            if (controller.mode == PickingMode.demo) ...[
              const SizedBox(height: 12),
              const _Banner(
                icon: Icons.science_outlined,
                color: AppColors.infoLight,
                foreground: AppColors.info,
                text: 'Modo demonstração: o ERP ainda não tem /picking/tasks. '
                    'A fila abaixo é de exemplo.',
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.wifi_off_outlined,
                color: AppColors.warningLight,
                foreground: const Color(0xFF92400E),
                text: controller.errorMessage!,
              ),
            ],
            if (controller.lastSyncWarning != null) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.sync_problem,
                color: AppColors.warningLight,
                foreground: const Color(0xFF92400E),
                text: controller.lastSyncWarning!,
              ),
            ],
            const SizedBox(height: 16),
            _Section(
              title: 'Em andamento',
              tasks: controller.inProgress,
              emptyLabel: 'Nenhuma separação aberta.',
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Aguardando (${controller.queue.length})',
              tasks: controller.queue,
              emptyLabel: 'Fila vazia.',
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Concluídos hoje',
              tasks: controller.done,
              emptyLabel: 'Nada concluído ainda.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configurePrinter(BuildContext context, PickingController controller) async {
    final config = await controller.printerConfig();
    final hostController = TextEditingController(text: config.host);
    final portController = TextEditingController(text: config.port.toString());

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Impressora de lacre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'IP ou host',
                hintText: '192.168.0.50',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Porta', hintText: '9100'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Impressora térmica ESC/POS na rede. Sem impressora configurada, '
              'o app mostra o rótulo na tela.',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.configurePrinter(
                hostController.text,
                int.tryParse(portController.text) ?? 9100,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _SeparatorCard extends StatefulWidget {
  const _SeparatorCard({required this.controller});

  final PickingController controller;

  @override
  State<_SeparatorCard> createState() => _SeparatorCardState();
}

class _SeparatorCardState extends State<_SeparatorCard> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.controller.assignee);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_pin_circle_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Separador',
                isDense: true,
              ),
              onSubmitted: widget.controller.setAssignee,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => widget.controller.setAssignee(_nameController.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tasks, required this.emptyLabel});

  final String title;
  final List<PickingTask> tasks;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.heading3),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(emptyLabel, style: AppTypography.bodySmall),
          )
        else
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskCard(task: task),
              )),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final PickingTask task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PickingTaskPage(orderId: task.orderId)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                task.resolvedCount.toString(),
                style: AppTypography.heading3.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${task.code}',
                    style: AppTypography.heading3.copyWith(fontSize: 14),
                  ),
                  Text(
                    '${task.items.length} itens · ${task.resolvedCount} conferidos',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            _StatusChip(status: task.status),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PickingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      PickingStatus.waiting => ('Na fila', AppColors.textSecondary, AppColors.surfaceElevated),
      PickingStatus.inProgress => ('Separando', AppColors.info, AppColors.infoLight),
      PickingStatus.packing => ('Embalando', AppColors.secondary, AppColors.secondaryLight),
      PickingStatus.ready => ('Pronto', AppColors.primaryDark, AppColors.primaryLight),
      PickingStatus.verified => ('Conferido', AppColors.primaryDark, AppColors.primaryLight),
      PickingStatus.handedOff => ('Entregue', AppColors.primaryDark, AppColors.primaryLight),
      PickingStatus.canceled => ('Cancelado', AppColors.danger, AppColors.dangerLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 11, color: foreground)),
          ),
        ],
      ),
    );
  }
}

