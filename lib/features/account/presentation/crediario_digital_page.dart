import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class CrediarioDigitalPage extends StatelessWidget {
  const CrediarioDigitalPage({super.key});

  @override
  Widget build(BuildContext context) {
    const double totalLimit = 600.00;
    const double usedAmount = 184.50;
    const double availableLimit = totalLimit - usedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Crediário no Mercadinho'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Principal do Limite (Caderninho Digital)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Conta do Mercadinho',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Ativo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Limite Disponível para Compras:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    CurrencyFormatter.format(availableLimit),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usedAmount / totalLimit,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Usado: ${CurrencyFormatter.format(usedAmount)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('Total: ${CurrencyFormatter.format(totalLimit)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão de Quitação Rápida via PIX
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pix, color: Color(0xFF32BCAD), size: 22),
                      SizedBox(width: 8),
                      Text('Pagar Fatura com PIX', style: AppTypography.heading3),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pague sua conta a prazo pelo celular a qualquer hora sem precisar ir até o balcão da loja.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPixModal(context, usedAmount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF32BCAD),
                      ),
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: Text('Quitar Saldo de ${CurrencyFormatter.format(usedAmount)}'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Extrato de Compras a Prazo
            const Text('Últimas Compras a Prazo (No Caixa e no App)', style: AppTypography.heading2),
            const SizedBox(height: 12),

            _buildStatementTile('Compra no Caixa 01', 'Ontem às 18:24', 84.50, 'Pendente'),
            _buildStatementTile('Pedido Online #1089', '28/10/2026', 100.00, 'Pendente'),
            _buildStatementTile('Pagamento PIX', '15/10/2026', -150.00, 'Quitado'),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatementTile(String title, String date, double value, String status) {
    final bool isPayment = value < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isPayment ? AppColors.primaryLight : AppColors.surfaceElevated,
                radius: 20,
                child: Icon(
                  isPayment ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                  size: 20,
                  color: isPayment ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heading3.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(date, style: AppTypography.caption),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (isPayment ? '- ' : '') + CurrencyFormatter.format(value.abs()),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPayment ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: status == 'Quitado' ? AppColors.success : AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPixModal(BuildContext context, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 72, color: Color(0xFF32BCAD)),
              const SizedBox(height: 12),
              const Text('PIX Copia e Cola', style: AppTypography.heading2),
              const SizedBox(height: 6),
              Text(
                'Valor a Pagar: ${CurrencyFormatter.format(amount)}',
                style: AppTypography.priceHighlight.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SelectableText(
                  '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-4266141740005204000053039865406184.505802BR5913MERCADINHO6009SAOPAULO62070503***6304E2CA',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código PIX copiado para a área de transferência!'),
                        backgroundColor: Color(0xFF32BCAD),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar Código PIX'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

