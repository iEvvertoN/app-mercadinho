import 'package:flutter/material.dart';
import '../domain/models/cart_item_model.dart';
import '../../catalog/domain/models/product_model.dart';
import '../../orders/domain/models/order_model.dart';
import '../../catalog/data/mock_catalog_data.dart';

class CartController extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  String _missingItemPolicy = 'substitute'; // 'substitute', 'call', 'cancel'
  String _cartObservation = '';
  bool _applyVoucherBalance = false;
  double _voucherDiscountAmount = 0.0;

  // Gestão de Descontos Ativados do Clube (mutation_rescueDiscount.graphql)
  final Set<String> _activatedDiscounts = {
    'prod_001',
    'prod_002',
    'prod_006',
    'prod_008',
  };

  Set<String> get activatedDiscounts => _activatedDiscounts;
  bool isDiscountActivated(String productId) => _activatedDiscounts.contains(productId);

  bool toggleDiscountActivation(String productId) {
    final bool nowActive;
    if (_activatedDiscounts.contains(productId)) {
      _activatedDiscounts.remove(productId);
      nowActive = false;
    } else {
      _activatedDiscounts.add(productId);
      nowActive = true;
    }
    notifyListeners();
    return nowActive;
  }

  void activateAllDiscounts(Iterable<String> productIds) {
    _activatedDiscounts.addAll(productIds);
    notifyListeners();
  }

  List<CartItemModel> get items => _items.values.toList();
  int get itemCount => _items.length;
  String get missingItemPolicy => _missingItemPolicy;
  String get cartObservation => _cartObservation;
  bool get applyVoucherBalance => _applyVoucherBalance;

  void setMissingItemPolicy(String policy) {
    _missingItemPolicy = policy;
    notifyListeners();
  }

  void setCartObservation(String obs) {
    _cartObservation = obs;
    notifyListeners();
  }

  void toggleVoucherBalance(bool value, {double availableBalance = 25.0}) {
    _applyVoucherBalance = value;
    _voucherDiscountAmount = value ? availableBalance : 0.0;
    notifyListeners();
  }

  bool hasProduct(String productId) => _items.containsKey(productId);

  double getProductQuantity(String productId) {
    return _items[productId]?.quantity ?? 0.0;
  }

  void addProduct(ProductModel product, {double? quantity, String? observation}) {
    final double qtyToAdd = quantity ?? (product.weighable ? 0.500 : 1.0);

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += qtyToAdd;
      if (observation != null && observation.isNotEmpty) {
        _items[product.id]!.observation = observation;
      }
    } else {
      _items[product.id] = CartItemModel(
        product: product,
        quantity: qtyToAdd,
        observation: observation,
      );
    }
    notifyListeners();
  }

  /// Recupera itens de um pedido anterior (`mutation_recoverCart.graphql`)
  void recoverOrderItems(List<OrderItemRecord> orderItems) {
    for (final rec in orderItems) {
      try {
        final product = MockCatalogData.products.firstWhere((p) => p.id == rec.productId);
        addProduct(product, quantity: rec.requestQuantity, observation: rec.observation);
      } catch (_) {}
    }
  }

  void increment(ProductModel product) {
    if (!_items.containsKey(product.id)) {
      addProduct(product);
      return;
    }

    final double step = product.weighable ? 0.250 : 1.0;
    _items[product.id]!.quantity += step;
    notifyListeners();
  }

  void decrement(ProductModel product) {
    if (!_items.containsKey(product.id)) return;

    final double step = product.weighable ? 0.250 : 1.0;
    if (_items[product.id]!.quantity <= step) {
      _items.remove(product.id);
    } else {
      _items[product.id]!.quantity -= step;
    }
    notifyListeners();
  }

  void updateItemObservation(String productId, String observation) {
    if (_items.containsKey(productId)) {
      _items[productId]!.observation = observation.trim().isEmpty ? null : observation.trim();
      notifyListeners();
    }
  }

  void removeProduct(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _cartObservation = '';
    _applyVoucherBalance = false;
    _voucherDiscountAmount = 0.0;
    notifyListeners();
  }

  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalRegular => _items.values.fold(0.0, (sum, item) => sum + item.totalRegularPrice);
  double get totalSavings => _items.values.fold(0.0, (sum, item) => sum + item.totalSavings);
  double get totalCashbackEarned => _items.values.fold(
        0.0,
        (sum, item) => sum + ((item.product.cashbackByUnit ?? 0.0) * item.discountedQuantity),
      );

  // Taxa de serviço de separação (`query_serviceFee.graphql`)
  double get serviceFee => _items.isEmpty ? 0.0 : 2.50;

  // Regra de Frete Grátis acima de R$ 100,00 (`query_deliveryFreeMessage.graphql`)
  static const double freeShippingThreshold = 100.0;
  bool get isFreeShipping => subtotal >= freeShippingThreshold;
  double get remainingForFreeShipping => (freeShippingThreshold - subtotal).clamp(0.0, freeShippingThreshold);
  double get freeShippingProgress => (subtotal / freeShippingThreshold).clamp(0.0, 1.0);
  double get deliveryFee => isFreeShipping || _items.isEmpty ? 0.0 : 8.90;

  double get voucherApplied =>
      _applyVoucherBalance ? _voucherDiscountAmount.clamp(0.0, subtotal) : 0.0;

  double get voucherDiscountApplied => voucherApplied;

  double get finalTotal =>
      (subtotal + deliveryFee + serviceFee - voucherApplied).clamp(0.0, double.infinity);
}
