import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../domain/models/order_model.dart';

class OrderTrackingPage extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    Future<void> poll() async {
      final erpId = widget.order.erpOrderId ??
          int.tryParse(widget.order.id.replaceAll(RegExp(r'\D'), '')) ??
          int.tryParse(widget.order.code);

      if (erpId != null && mounted) {
        final orderData = await CatalogApiService.fetchOrderStatus(erpId);
        if (orderData != null && mounted) {
          final appState = Provider.of<AppStateController>(context, listen: false);
          appState.syncOrderFromErp(orderData);
        }
      }
    }

    poll();
    // Sincroniza a cada 4 segundos com o ERP para refletir ações do separador/caixa/motoboy ao vivo
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => poll());
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    // Busca versão reativa do pedido se estiver no controller
    final liveOrder = appState.orders.firstWhere(
      (o) => o.id == widget.order.id || o.code == widget.order.code,
      orElse: () => widget.order,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pedido #${liveOrder.code}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Senha da Comanda / Pré-Venda F10 (se emitida)
            if (liveOrder.passwordNumber != null && liveOrder.passwordNumber!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFF1D4ED8), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMANDA / SENHA DO CAIXA',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                          Text(
                            '#${liveOrder.passwordNumber}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                          ),
                          const Text(
                            'Diga esta senha ao operador para puxar os itens no F10',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pix Copia e Cola (se método Pix com código)
            if (liveOrder.pixCopiaECola != null && liveOrder.pixCopiaECola!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pix_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pagar com Pix Copia e Cola',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        liveOrder.pixCopiaECola!,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: liveOrder.pixCopiaECola!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código Pix copiado!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                      label: const Text('Copiar Código Pix', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Card de Status Atual + Logística (Separador, Entregador, Volumes)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status do Pedido', style: AppTypography.heading3.copyWith(color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: liveOrder.status == 'cancelled' ? AppColors.dangerLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          liveOrder.statusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: liveOrder.status == 'cancelled' ? AppColors.danger : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Janela Agendada: ${liveOrder.scheduledWindow}', style: AppTypography.heading2),
                  const Divider(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLogisticsBadge(
                          Icons.badge_outlined,
                          'Separador',
                          liveOrder.separatorName,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildLogisticsBadge(
                          Icons.two_wheeler_outlined,
                          'Entregador',
                          liveOrder.deliverymanName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLogisticsBadge(
                          Icons.inventory_2_outlined,
                          'Sacolas Secas (dryVolumes)',
                          '${liveOrder.dryVolumes} volumes',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildLogisticsBadge(
                          Icons.ac_unit_rounded,
                          'Refrigerados (coldVolumes)',
                          '${liveOrder.coldVolumes} volumes térmicos',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card de Divergência de Pesagem e Aprovação (`approveOrderChanges`)
            if (liveOrder.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (liveOrder.needsClientApproval && !liveOrder.clientApprovedChanges)
                        ? AppColors.warning
                        : AppColors.border,
                    width: (liveOrder.needsClientApproval && !liveOrder.clientApprovedChanges) ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.scale_rounded, size: 20, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Conferência de Separação e Pesagem', style: AppTypography.heading3),
                          ],
                        ),
                        if (liveOrder.clientApprovedChanges)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'APROVADO',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Comparativo entre quantidade pedida (requestQuantity) e pesada na balança (foundQuantity):',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...liveOrder.items.map((item) {
                      final diff = item.itemChangeDifference;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.hasDivergence ? const Color(0xFFFFFBEB) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item.product.weighable
                                        ? 'Pedido: ${CurrencyFormatter.formatWeight(item.requestQuantity)} → Pesado: ${CurrencyFormatter.formatWeight(item.foundQuantity)}'
                                        : 'Pedido: ${item.requestQuantity.toInt()} un → Separado: ${item.foundQuantity.toInt()} un',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.foundTotal),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                if (diff.abs() > 0.01)
                                  Text(
                                    '${diff > 0 ? "+" : ""}${CurrencyFormatter.format(diff)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: diff > 0 ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diferença de Pesagem (orderChangeDifference):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${liveOrder.orderChangeDifference >= 0 ? "+" : ""}${CurrencyFormatter.format(liveOrder.orderChangeDifference)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: liveOrder.orderChangeDifference > 0 ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    if (liveOrder.needsClientApproval && !liveOrder.clientApprovedChanges) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final erpId = liveOrder.erpOrderId ??
                                int.tryParse(liveOrder.id.replaceAll(RegExp(r'\D'), '')) ??
                                int.tryParse(liveOrder.code);
                            if (erpId != null) {
                              await CatalogApiService.approveOrderChanges(erpId, approved: true);
                            }
                            if (!context.mounted) return;
                            appState.approveOrderChanges(liveOrder.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alterações de separação/substituição aprovadas! Pedido liberado.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Aprovar Alterações da Separação'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Linha do Tempo (Timeline de 4 Etapas)
            const Text('Linha do Tempo (stateHistory)', style: AppTypography.heading2),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildTimelineStep(1, 'Pedido Recebido', 'Seu pedido foi registrado no sistema.', true),
                  _buildTimelineConnector(liveOrder.statusStep >= 2),
                  _buildTimelineStep(
                    2,
                    'Em Separação no Mercado',
                    'Os itens estão sendo separados e pesados por ${liveOrder.separatorName}.',
                    liveOrder.statusStep >= 2,
                  ),
                  _buildTimelineConnector(liveOrder.statusStep >= 3),
                  _buildTimelineStep(
                    3,
                    'Saiu para Entrega',
                    'O entregador ${liveOrder.deliverymanName} está a caminho.',
                    liveOrder.statusStep >= 3,
                  ),
                  _buildTimelineConnector(liveOrder.statusStep >= 4),
                  _buildTimelineStep(
                    4,
                    'Entregue com Sucesso',
                    'Pedido finalizado e cupom fiscal emitido.',
                    liveOrder.statusStep >= 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Resumo Financeiro Completo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detalhes Financeiros', style: AppTypography.heading3),
                  const SizedBox(height: 12),
                  _buildDetailRow('Forma de Pagamento:', '${liveOrder.paymentMethod} (${liveOrder.installments}x)'),
                  _buildDetailRow('Cartão / Bandeira:', '${liveOrder.cardBrand} final ${liveOrder.cardLast4}'),
                  _buildDetailRow('Subtotal:', CurrencyFormatter.format(liveOrder.subtotalAmount)),
                  _buildDetailRow('Taxa de Serviço:', CurrencyFormatter.format(liveOrder.serviceFee)),
                  _buildDetailRow('Frete:', CurrencyFormatter.format(liveOrder.deliveryCost)),
                  if (liveOrder.discountValue > 0)
                    _buildDetailRow('Descontos / Clube:', '- ${CurrencyFormatter.format(liveOrder.discountValue)}'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Final:', style: AppTypography.heading3),
                      Text(
                        CurrencyFormatter.format(liveOrder.totalAmount),
                        style: AppTypography.heading2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botão de Suporte via WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abrindo WhatsApp da Loja Matriz (88) 3581-9000...')),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                label: const Text(
                  'Falar com a Loja no WhatsApp',
                  style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (liveOrder.status != 'completed' && liveOrder.status != 'cancelled') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  onPressed: () => _openCancelOrderModal(context, appState, liveOrder),
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 18),
                  label: const Text(
                    'Cancelar Pedido (cancelOrder)',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _openCancelOrderModal(
    BuildContext context,
    AppStateController appState,
    OrderModel liveOrder,
  ) {
    String selectedReason = appState.orderCancelReasons.first;
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancelar Pedido', style: AppTypography.heading2),
              const SizedBox(height: 6),
              const Text(
                'Selecione o motivo do cancelamento (query_orderCancelReasons.graphql):',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              ...appState.orderCancelReasons.map(
                (r) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                  value: r,
                  groupValue: selectedReason,
                  onChanged: (v) => setModalState(() => selectedReason = v!),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observação adicional (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () {
                    appState.cancelOrder(
                      liveOrder.id,
                      reason: selectedReason,
                      observation: obsCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pedido cancelado com sucesso.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  },
                  child: const Text('Confirmar Cancelamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int stepNum, String title, String subtitle, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted ? AppColors.primary : AppColors.surfaceElevated,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('$stepNum', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: isCompleted ? AppColors.textSecondary : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
      width: 2,
      height: 28,
      color: isCompleted ? AppColors.primary : AppColors.border,
      alignment: Alignment.centerLeft,
    );
  }
}
