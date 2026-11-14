import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../home/presentation/tabs_page.dart';
import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_tracking_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final double totalAmount;
  final String fulfillmentType;
  final String timeSlot;
  final String paymentMethod;
  final String? passwordNumber;
  final String? pixCopiaECola;
  final String? pixQrCodeUrl;
  final int? preSaleId;
  final int? erpOrderId;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.fulfillmentType,
    required this.timeSlot,
    required this.paymentMethod,
    this.passwordNumber,
    this.pixCopiaECola,
    this.pixQrCodeUrl,
    this.preSaleId,
    this.erpOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TabsPage()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Celebration Lottie or Success Icon
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Lottie.asset(
                    'assets/animation/loading_winner.json',
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pedido Realizado com Sucesso!',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.neutralDark,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O Mercadinho já recebeu seu pedido e gravou no sistema da loja!',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutralMedium,
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Comanda / Senha do Caixa F10 (se disponível)
                if (passwordNumber != null && passwordNumber!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFF1D4ED8), size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'COMANDA / SENHA DO CAIXA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '#$passwordNumber',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E3A8A),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No caixa da loja, informe esta senha ou peça para o operador digitar F10 no Clipp para puxar seu carrinho e faturar na hora!',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Card Pix Copia e Cola (se método Pix e código disponível)
                if (pixCopiaECola != null && pixCopiaECola!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pix_rounded, color: AppColors.success, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Pagamento Pix Instantâneo',
                              style: AppTypography.heading3.copyWith(color: const Color(0xFF166534), fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Copie o código abaixo e pague pelo Pix Copia e Cola do seu banco:',
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            pixCopiaECola!,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.neutralDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: pixCopiaECola!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Código Pix copiado para a área de transferência!'),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                          label: const Text('Copiar Código Pix', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Order Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Número do Pedido', style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMedium)),
                          Text(
                            orderId,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tipo de Atendimento', style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMedium)),
                          Text(
                            fulfillmentType,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Previsão de Atendimento', style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMedium)),
                          Text(
                            timeSlot,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Forma de Pagamento', style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMedium)),
                          Text(
                            paymentMethod,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valor Total',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            CurrencyFormatter.formatReal(totalAmount),
                            style: AppTypography.priceClub.copyWith(
                              fontSize: 18,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Track Order Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingPage(
                            order: OrderModel(
                              id: orderId,
                              code: orderId.replaceAll('#', '').replaceAll('MERC-', ''),
                              date: DateTime.now(),
                              totalAmount: totalAmount,
                              itemsCount: 5,
                              status: 'received',
                              deliveryType: fulfillmentType.contains('Retirada') ? 'takeaway' : 'delivery',
                              paymentMethod: paymentMethod,
                              scheduledWindow: timeSlot,
                              passwordNumber: passwordNumber,
                              pixCopiaECola: pixCopiaECola,
                              preSaleId: preSaleId,
                              erpOrderId: erpOrderId,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                    label: Text(
                      'Acompanhar Pedido ao Vivo',
                      style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const TabsPage()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Voltar para a Página Inicial',
                      style: AppTypography.button.copyWith(
                        color: AppColors.neutralDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
