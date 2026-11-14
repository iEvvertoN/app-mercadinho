import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import 'cart_controller.dart';
import '../domain/models/cart_item_model.dart';
import '../../catalog/presentation/scanner_page.dart';
import '../../checkout/presentation/checkout_page.dart';

class CartPage extends StatelessWidget {
  final bool isEmbeddedTab;
  final ValueChanged<int>? onNavigateTab;

  const CartPage({
    super.key,
    this.isEmbeddedTab = false,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isEmbeddedTab,
        title: const Text('Meu Carrinho'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScannerPage(mode: ScannerMode.scanAndGo),
                  ),
                );
              },
              icon: const Icon(Icons.barcode_reader, size: 17),
              label: const Text(
                'Scan & Go',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Consumer<CartController>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearCart(context, cart),
                child: const Text('Limpar', style: TextStyle(color: AppColors.danger)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartController>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('Seu carrinho está vazio', style: AppTypography.heading2),
                    const SizedBox(height: 8),
                    const Text(
                      'Use o Scan & Go para bipar produtos direto para o carrinho ou navegue pelas ofertas.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScannerPage(mode: ScannerMode.scanAndGo),
                            ),
                          );
                        },
                        icon: const Icon(Icons.barcode_reader),
                        label: const Text(
                          'Scan & Go • Bipar Produto',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (isEmbeddedTab && onNavigateTab != null) {
                            onNavigateTab!(0);
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: const Text('Explorar Ofertas na Home'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Destaque Scan & Go no topo do Carrinho
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScannerPage(mode: ScannerMode.scanAndGo),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.barcode_reader, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan & Go • Bipar mais produtos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Aponte a câmera para o código de barras e some na hora',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              // Barra de Frete Grátis
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: cart.isFreeShipping ? AppColors.primaryLight : AppColors.secondaryLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          cart.isFreeShipping ? Icons.check_circle : Icons.local_shipping_outlined,
                          size: 18,
                          color: cart.isFreeShipping ? AppColors.primaryDark : AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cart.isFreeShipping
                                ? 'Parabéns! Você ganhou Frete Grátis!'
                                : 'Faltam ${CurrencyFormatter.format(cart.remainingForFreeShipping)} para Frete Grátis!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cart.isFreeShipping ? AppColors.primaryDark : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cart.freeShippingProgress,
                        backgroundColor: Colors.white.withAlpha(155),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cart.isFreeShipping ? AppColors.primary : AppColors.secondary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de Produtos + Observação Geral + Vale-Compras
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCartItemTile(context, item, cart),
                      ),
                    ),

                    // Observação Geral do Pedido (mutation_editCart.graphql)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Observação Geral da Separação / Entrega',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _editCartObservationDialog(context, cart),
                                child: Text(
                                  cart.cartObservation.isEmpty ? 'Adicionar' : 'Editar',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (cart.cartObservation.isNotEmpty)
                            Text(
                              '"${cart.cartObservation}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Text(
                              'Ex: Sacolas reforçadas, tocar interfone 201, frutas mais verdes...',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aplicar Saldo de Vale-Compras / Cashback (cartVoucherDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withAlpha(80)),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppColors.primary,
                        title: const Text(
                          'Usar Saldo de Vale-Compras / Cashback',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                        subtitle: Text(
                          'Saldo disponível: ${CurrencyFormatter.format(appState.voucherBalance + appState.cashbackBalance)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        value: cart.applyVoucherBalance,
                        onChanged: (val) => cart.toggleVoucherBalance(
                          val,
                          availableBalance: 15.00, // Desconto imediato de vale-compras
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Política de Itens Faltantes (Ruptura / Picking)
              _buildMissingItemSelector(context, cart),

              // Resumo Financeiro & Botão de Checkout
              _buildCheckoutBar(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, CartItemModel item, CartController cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.exceededCpfLimit ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.network(
                    item.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceElevated),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: AppTypography.heading3.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(item.product.activePrice)} ${item.product.weighable ? '/kg' : 'cada'}',
                      style: AppTypography.caption,
                    ),
                    if (item.observation != null && item.observation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Obs: "${item.observation}"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: AppTypography.priceHighlight.copyWith(fontSize: 15),
                            ),
                            if (item.totalCashback > 0)
                              Text(
                                '+ ${CurrencyFormatter.format(item.totalCashback)} cashback',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                onPressed: () => cart.decrement(item.product),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  item.product.weighable
                                      ? CurrencyFormatter.formatWeight(item.quantity)
                                      : item.quantity.toInt().toString(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                onPressed: () => cart.increment(item.product),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.exceededCpfLimit) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Limite Clube atingido (${item.discountedQuantity.toInt()} un com desconto de ${CurrencyFormatter.format(item.product.activePrice)} + ${item.regularPriceQuantity.toInt()} un no preço normal de ${CurrencyFormatter.format(item.product.price)}).',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editCartObservationDialog(BuildContext context, CartController cart) {
    final ctrl = TextEditingController(text: cart.cartObservation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Observação Geral do Pedido'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Instruções para o separador ou entregador...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              cart.setCartObservation(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItemSelector(BuildContext context, CartController cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se faltar algum item na separação da loja:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildPolicyChip(cart, 'substitute', 'Substituir por similar'),
              const SizedBox(width: 8),
              _buildPolicyChip(cart, 'call', 'Avisar no WhatsApp'),
              const SizedBox(width: 8),
              _buildPolicyChip(cart, 'cancel', 'Apenas estornar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyChip(CartController cart, String policyKey, String label) {
    final bool isSelected = cart.missingItemPolicy == policyKey;
    return Expanded(
      child: InkWell(
        onTap: () => cart.setMissingItemPolicy(policyKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartController cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal dos Itens', style: AppTypography.bodySmall),
                Text(CurrencyFormatter.format(cart.subtotal), style: AppTypography.body),
              ],
            ),
            if (cart.totalSavings > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Economia Clube Queira Mais',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '- ${CurrencyFormatter.format(cart.totalSavings)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (cart.voucherDiscountApplied > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vale-Compras / Cashback aplicado',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '- ${CurrencyFormatter.format(cart.voucherDiscountApplied)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Taxa de Serviço / Separação', style: AppTypography.bodySmall),
                Text(CurrencyFormatter.format(cart.serviceFee), style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Taxa de Entrega', style: AppTypography.bodySmall),
                Text(
                  cart.deliveryFee == 0 ? 'GRÁTIS' : CurrencyFormatter.format(cart.deliveryFee),
                  style: TextStyle(
                    fontSize: 13,
                    color: cart.deliveryFee == 0 ? AppColors.success : AppColors.textPrimary,
                    fontWeight: cart.deliveryFee == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total a Pagar', style: AppTypography.heading2),
                    if (cart.totalCashbackEarned > 0)
                      Text(
                        'Você ganha +${CurrencyFormatter.format(cart.totalCashbackEarned)} de Cashback',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(cart.finalTotal),
                  style: AppTypography.heading1.copyWith(color: AppColors.primary, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CheckoutPage()),
                  );
                },
                child: const Text('Confirmar e Escolher Horário', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, CartController cart) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Limpar Carrinho'),
        content: const Text('Deseja remover todos os itens do carrinho?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Limpar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
