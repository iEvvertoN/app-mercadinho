import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/product_model.dart';
import '../../../cart/presentation/cart_controller.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartController, AppStateController>(
      builder: (context, cart, appState, _) {
        final double qtyInCart = cart.getProductQuantity(product.id);
        final bool inCart = qtyInCart > 0;
        final bool isDiscountActive = cart.isDiscountActivated(product.id);
        final bool isFav = appState.isFavorite(product.id);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 170,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem com Badge Promocional e Favorito (suporta com ou sem foto)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: AspectRatio(
                        aspectRatio: 1.32,
                        child: product.imageUrl.trim().isEmpty
                            ? _buildProductPlaceholder()
                            : Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
                              ),
                      ),
                    ),
                    if (product.badge != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: product.hasDiscount ? AppColors.danger : AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.badge!,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => appState.toggleFavorite(product.id),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: isFav ? AppColors.danger : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (product.limitPerCpf != null)
                      Positioned(
                        bottom: 4,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Máx ${product.limitPerCpf} ${product.unit}/CPF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Detalhes do Produto
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading3.copyWith(fontSize: 12, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              product.weighable ? 'Pesável /kg' : 'Unidade',
                              style: AppTypography.caption.copyWith(fontSize: 10),
                            ),
                            if (product.cashbackByUnit != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+R\$ ${product.cashbackByUnit!.toStringAsFixed(2)} CB',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),

                        // Preços
                        if (product.hasDiscount)
                          Text(
                            CurrencyFormatter.format(product.salePrice),
                            style: AppTypography.priceOld.copyWith(fontSize: 10),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              CurrencyFormatter.format(product.activePrice),
                              style: AppTypography.priceHighlight.copyWith(fontSize: 15),
                            ),
                            if (product.weighable)
                              Text(
                                ' /kg',
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                              ),
                          ],
                        ),

                        // Botão de Ativar Desconto do Clube (mutation_rescueDiscount.graphql)
                        if (product.clubPrice != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
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
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: nowActive ? AppColors.success : AppColors.textSecondary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: isDiscountActive
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDiscountActive ? Icons.check_circle_rounded : Icons.bolt_rounded,
                                    size: 12,
                                    color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isDiscountActive ? 'Ativo no CPF' : 'Ativar Clube',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDiscountActive ? AppColors.success : AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),

                        // Botão de Adição Reativa ao Carrinho
                        if (!inCart)
                          SizedBox(
                            width: double.infinity,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () => cart.addProduct(product),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 15),
                                  SizedBox(width: 3),
                                  Text('Adicionar', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 15, color: AppColors.primaryDark),
                                  onPressed: () => cart.decrement(product),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text(
                                  product.weighable
                                      ? CurrencyFormatter.formatWeight(qtyInCart)
                                      : '${qtyInCart.toInt()} un',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 15, color: AppColors.primaryDark),
                                    onPressed: () => cart.increment(product),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

  Widget _buildProductPlaceholder() {
    IconData iconData = Icons.shopping_basket_outlined;
    switch (product.categoryId) {
      case 'acougue':
        iconData = Icons.kebab_dining;
        break;
      case 'hortifruti':
        iconData = Icons.eco;
        break;
      case 'padaria':
        iconData = Icons.bakery_dining;
        break;
      case 'bebidas':
        iconData = Icons.sports_bar;
        break;
      case 'laticinios':
        iconData = Icons.egg;
        break;
      case 'limpeza':
        iconData = Icons.cleaning_services;
        break;
      default:
        iconData = Icons.shopping_basket_outlined;
    }

    return Container(
      color: AppColors.surfaceElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: AppColors.primary.withOpacity(0.55), size: 36),
          const SizedBox(height: 4),
          Text(
            product.unit,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
