import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/data/mock_catalog_data.dart';
import '../../catalog/domain/models/product_model.dart';

class FiscalReceiptPage extends StatelessWidget {
  const FiscalReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();

    final List<Map<String, dynamic>> receiptItems = [
      {
        'id': '1',
        'code': '7891000100103',
        'desc': 'ARROZ BRANCO TIPO 1 5KG',
        'qty': 2.0,
        'unit': 'UN',
        'unitPrice': 28.90,
        'totalPrice': 57.80,
      },
      {
        'id': '2',
        'code': '7891000200202',
        'desc': 'FEIJAO CARIOCA 1KG',
        'qty': 3.0,
        'unit': 'UN',
        'unitPrice': 7.49,
        'totalPrice': 22.47,
      },
      {
        'id': '3',
        'code': '7891000300301',
        'desc': 'ALCATRA BOVINA RESFRIADA (KG)',
        'qty': 1.450,
        'unit': 'KG',
        'unitPrice': 44.90,
        'totalPrice': 65.11,
      },
      {
        'id': '4',
        'code': '7891000400400',
        'desc': 'LEITE INTEGRAL UHT 1L',
        'qty': 6.0,
        'unit': 'UN',
        'unitPrice': 4.79,
        'totalPrice': 28.74,
      },
      {
        'id': '5',
        'code': '7891000500509',
        'desc': 'CAFE TORRADO E MOIDO 250G',
        'qty': 2.0,
        'unit': 'UN',
        'unitPrice': 11.90,
        'totalPrice': 23.80,
      },
    ];

    final double totalBruto = receiptItems.fold(0.0, (acc, item) => acc + (item['totalPrice'] as double));
    const double desconto = 9.50;
    final double totalLiquido = totalBruto - desconto;

    void repourchaseAllItems() {
      // Find matching products from MockCatalogData or create models
      for (final item in receiptItems) {
        final productMatch = MockCatalogData.products.firstWhere(
          (p) => p.barcode == item['code'] || p.id == item['id'],
          orElse: () => ProductModel(
            id: item['id'] as String,
            name: item['desc'] as String,
            description: item['desc'] as String,
            barcode: item['code'] as String,
            salePrice: item['unitPrice'] as double,
            clubPrice: item['unitPrice'] as double,
            unit: item['unit'] as String,
            weighable: item['unit'] == 'KG',
            imageUrl: '',
            categoryId: 'mercearia',
          ),
        );

        cart.addProduct(productMatch, quantity: (item['qty'] as num).toDouble());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shopping_cart_checkout, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Todos os 5 itens da compra física foram adicionados ao seu carrinho!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F4),
      appBar: AppBar(
        title: const Text('Cupom Fiscal Digital (NFC-e)', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Fiscal Receipt Card Styled Like Thermal Paper
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Supermarket Header
                    Text(
                      'MERCADINHO DO BAIRRO LTDA',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CNPJ: 12.345.678/0001-90 • IE: 06.123.456-7',
                      style: AppTypography.caption.copyWith(color: AppColors.neutralDark),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Av. Coronel José Inácio, 450 - Centro - Iguatu - CE',
                      style: AppTypography.caption.copyWith(color: AppColors.neutralMedium),
                      textAlign: TextAlign.center,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.black26, thickness: 1),
                    ),
                    Text(
                      'DOCUMENTO AUXILIAR DA NOTA FISCAL\nDE CONSUMIDOR ELETRÔNICA - NFC-e',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'NFC-e Nº 000.084.219 • Série: 001 • Emissão: 01/11/2026 18:42',
                      style: AppTypography.caption.copyWith(color: AppColors.neutralMedium, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.black26, thickness: 1),
                    ),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ITEM / DESCRIÇÃO', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                        Text('QTD x VL.UN = TOTAL', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items List
                    ...receiptItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['id'].toString().padLeft(3, '0')}  ${item['desc']}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '  Cod: ${item['code']}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.neutralMedium),
                                ),
                                Text(
                                  '${item['qty']} ${item['unit']} x ${CurrencyFormatter.formatReal(item['unitPrice'])} = ${CurrencyFormatter.formatReal(item['totalPrice'])}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.black26, thickness: 1),
                    ),

                    // Totals
                    _buildReceiptTotalRow('QTD. TOTAL DE ITENS', '5'),
                    _buildReceiptTotalRow('VALOR TOTAL R\$', CurrencyFormatter.formatReal(totalBruto)),
                    _buildReceiptTotalRow('DESCONTO CLUBE R\$', '- ${CurrencyFormatter.formatReal(desconto)}'),
                    const SizedBox(height: 4),
                    _buildReceiptTotalRow(
                      'VALOR A PAGAR R\$',
                      CurrencyFormatter.formatReal(totalLiquido),
                      isBold: true,
                    ),
                    _buildReceiptTotalRow('FORMA DE PAGAMENTO', 'PIX DINÂMICO PDV'),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(color: Colors.black26, thickness: 1),
                    ),

                    // Consumer & Access Key
                    const Text(
                      'CONSUMIDOR: EVERTON DA SILVA • CPF: ***.456.789-**',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'CHAVE DE ACESSO:\n2326 1112 3456 7800 0190 6500 1000 0842 1910 0984 2194',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Sefaz QR Code Stamp
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neutralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 90, color: AppColors.neutralDark),
                          const SizedBox(height: 4),
                          Text(
                            'Protocolo de Autorização SEFAZ-CE:\n323260009842194 - 01/11/2026 18:42:15',
                            style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.neutralMedium),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Repurchase Action Button (Inovação 14.2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.autorenew_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Inovação: Recompra em 1 Clique',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gostou das compras que fez no caixa da loja física? Adicione todos esses mesmos produtos ao seu carrinho online para receber em casa!',
                      style: AppTypography.caption.copyWith(color: AppColors.neutralDark),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: repourchaseAllItems,
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        label: Text(
                          'Comprar essa lista novamente',
                          style: AppTypography.button.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
