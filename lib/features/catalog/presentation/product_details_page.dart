import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/mock_catalog_data.dart';
import '../domain/models/product_model.dart';
import 'widgets/product_card.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late double _selectedQuantity;
  final TextEditingController _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedQuantity = widget.product.weighable ? 0.500 : 1.0;
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _selectedQuantity += widget.product.weighable ? 0.250 : 1.0;
    });
  }

  void _decrement() {
    final double step = widget.product.weighable ? 0.250 : 1.0;
    if (_selectedQuantity > step) {
      setState(() {
        _selectedQuantity -= step;
      });
    }
  }

  void _setPresetWeight(double weight) {
    setState(() {
      _selectedQuantity = weight;
    });
  }

  void _showDiscountRulesModal(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Regras da Oferta & Lojas Participantes (query_discount)', style: AppTypography.heading2),
            const SizedBox(height: 12),
            Text(
              product.ruleText ??
                  'Oferta exclusiva para membros do Clube Queira Mais mediante ativação prévia e identificação do CPF no caixa ou pedido pelo aplicativo.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('• ${product.limitLabel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            if (product.validWeekdays != null)
              Text('• Dias válidos: ${product.validWeekdays}', style: const TextStyle(fontSize: 12)),
            if (product.validTimeIntervals != null)
              Text('• Horário: ${product.validTimeIntervals}', style: const TextStyle(fontSize: 12)),
            const Divider(height: 24),
            const Text('Lojas Participantes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('• Mercadinho Matriz - Centro (Av. Cel. José Inácio, 450)', style: AppTypography.caption),
            const Text('• Mercadinho Filial - Planalto (Rua Floriano Peixoto, 1120)', style: AppTypography.caption),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final appState = context.watch<AppStateController>();
    final bool isFavorite = appState.isFavorite(product.id);
    final double totalEstimated = product.activePrice * _selectedQuantity;

    final relatedProducts = MockCatalogData.products
        .where((p) => p.categoryId == product.categoryId && p.id != product.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(product.name, style: AppTypography.heading3),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.danger : AppColors.textPrimary,
            ),
            onPressed: () {
              appState.toggleFavorite(product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(!isFavorite ? 'Salvo nos seus favoritos!' : 'Removido dos favoritos.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.gavel_rounded),
            tooltip: 'Regras da Oferta',
            onPressed: () => _showDiscountRulesModal(context, product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem Principal em Destaque com Badges
            Container(
              color: Colors.white,
              width: double.infinity,
              height: 260,
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'prod_${product.id}',
                      child: product.imageUrl.trim().isEmpty
                          ? const Center(
                              child: Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textMuted),
                            )
                          : Image.network(
                              product.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textMuted),
                              ),
                            ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: product.hasDiscount ? AppColors.danger : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.badge!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (product.weighable)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Produto Pesável', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Informações Principais do Produto
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTypography.heading1.copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Código EAN: ${product.barcode}', style: AppTypography.caption),
                      Text(product.expirationText ?? 'Estoque disponível', style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Etiquetas de Regra de Supermercado (Limite por CPF e Cashback)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.limitLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (product.cashbackByUnit != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ganha +R\$ ${product.cashbackByUnit!.toStringAsFixed(2)} de Cashback por ${product.unit}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bloco de Preços (Comum vs Clube)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Preço Normal:', style: AppTypography.caption),
                            Text(
                              '${CurrencyFormatter.format(product.salePrice)} ${product.weighable ? '/kg' : 'un'}',
                              style: TextStyle(
                                fontSize: 15,
                                decoration: product.hasDiscount ? TextDecoration.lineThrough : null,
                                color: product.hasDiscount ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (product.clubPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: AppColors.secondary, size: 14),
                                    SizedBox(width: 4),
                                    Text('Exclusivo Clube', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  ],
                                ),
                                Text(
                                  '${CurrencyFormatter.format(product.clubPrice!)} ${product.weighable ? '/kg' : 'un'}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Botão de Ativar Desconto do Clube (mutation_rescueDiscount.graphql)
                  if (product.clubPrice != null) ...[
                    const SizedBox(height: 12),
                    Consumer<CartController>(
                      builder: (context, cart, _) {
                        final bool isDiscountActive = cart.isDiscountActivated(product.id);
                        return InkWell(
                          onTap: () {
                            final nowActive = cart.toggleDiscountActivation(product.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowActive
                                      ? 'Desconto de ${product.name} ativado no seu CPF!'
                                      : 'Desconto desativado.',
                                ),
                                backgroundColor: nowActive ? AppColors.success : AppColors.textSecondary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDiscountActive
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isDiscountActive ? Icons.check_circle_rounded : Icons.bolt_rounded,
                                  color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isDiscountActive
                                      ? 'Desconto Ativado no seu CPF ✓'
                                      : 'Toque para Ativar Desconto do Clube',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Seletor de Quantidade / Peso
                  Text(
                    product.weighable ? 'Quanto você deseja levar?' : 'Quantidade:',
                    style: AppTypography.heading3,
                  ),
                  const SizedBox(height: 10),

                  if (product.weighable) ...[
                    Row(
                      children: [
                        _buildPresetWeightChip(0.250, '250g'),
                        const SizedBox(width: 8),
                        _buildPresetWeightChip(0.500, '500g'),
                        const SizedBox(width: 8),
                        _buildPresetWeightChip(1.000, '1 kg'),
                        const SizedBox(width: 8),
                        _buildPresetWeightChip(1.500, '1,5 kg'),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantidade Selecionada:', style: AppTypography.bodySmall),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrement,
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                            ),
                            Text(
                              product.weighable
                                  ? CurrencyFormatter.formatWeight(_selectedQuantity)
                                  : '${_selectedQuantity.toInt()} un',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: _increment,
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showDiscountRulesModal(context, product),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Ver Regras Completas e Lojas Participantes', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Descrição e Observações para o Separador
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Descrição do Produto', style: AppTypography.heading3),
                  const SizedBox(height: 8),
                  Text(product.description, style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 16),
                  const Text('Observações para o Separador', style: AppTypography.heading3),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _obsController,
                    decoration: InputDecoration(
                      hintText: 'Ex: "Por favor, escolher bananas mais verdes"',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (relatedProducts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Quem comprou este também levou', style: AppTypography.heading2),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: relatedProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: relatedProducts[index],
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailsPage(product: relatedProducts[index])),
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subtotal estimado:', style: AppTypography.caption),
                  Text(
                    CurrencyFormatter.format(totalEstimated),
                    style: AppTypography.priceHighlight.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<CartController>().addProduct(
                            product,
                            quantity: _selectedQuantity,
                            observation: _obsController.text.trim().isEmpty ? null : _obsController.text.trim(),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} adicionado ao carrinho!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Adicionar', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetWeightChip(double weight, String label) {
    final bool isSelected = (_selectedQuantity - weight).abs() < 0.01;
    return Expanded(
      child: InkWell(
        onTap: () => _setPresetWeight(weight),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
