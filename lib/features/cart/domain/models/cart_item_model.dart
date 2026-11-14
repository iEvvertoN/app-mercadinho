import 'package:app_mercadinho/features/catalog/domain/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  double quantity;
  String? observation;

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
    this.observation,
  });

  /// Quantidade que recebe o preço promocional/Clube respeitando o limite por CPF (`discounts.limit`)
  double get discountedQuantity {
    if (product.limitPerCpf == null) return quantity;
    final double limit = product.limitPerCpf!.toDouble();
    return quantity > limit ? limit : quantity;
  }

  /// Quantidade excedente ao limite por CPF (cobrada no preço normal `salePrice`)
  double get regularPriceQuantity {
    if (product.limitPerCpf == null) return 0.0;
    final double limit = product.limitPerCpf!.toDouble();
    return quantity > limit ? (quantity - limit) : 0.0;
  }

  bool get exceededCpfLimit => regularPriceQuantity > 0;

  double get totalPrice =>
      (discountedQuantity * product.activePrice) +
      (regularPriceQuantity * product.salePrice);

  double get totalRegularPrice => product.salePrice * quantity;
  double get totalSavings => totalRegularPrice - totalPrice;
  double get totalCashback => (product.cashbackByUnit ?? 0.0) * discountedQuantity;
}
