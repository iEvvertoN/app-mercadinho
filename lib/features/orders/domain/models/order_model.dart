import 'package:app_mercadinho/features/catalog/domain/models/product_model.dart';

class OrderItemRecord {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final bool weighable;
  final double unitPrice;
  final double requestQuantity;
  final double foundQuantity;
  final bool notFound;
  final bool giveUp;
  final bool lateAdded;
  final String? observation;
  final String? substitutedBy;
  final ProductModel? _product;

  OrderItemRecord({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    ProductModel? product,
    bool? weighable,
    required this.unitPrice,
    required this.requestQuantity,
    required this.foundQuantity,
    this.notFound = false,
    this.giveUp = false,
    this.lateAdded = false,
    this.observation,
    this.substitutedBy,
  })  : _product = product,
        id = id ?? productId ?? product?.id ?? 'oi_item',
        productId = productId ?? product?.id ?? 'prod_001',
        productName = productName ?? product?.name ?? 'Produto',
        imageUrl = imageUrl ?? product?.imageUrl ?? '',
        weighable = weighable ?? product?.weighable ?? false;

  ProductModel get product =>
      _product ??
      ProductModel(
        id: productId,
        name: productName,
        description: productName,
        barcode: '7890000000000',
        categoryId: 'mercearia',
        imageUrl: imageUrl,
        salePrice: unitPrice,
        weighable: weighable,
        unit: weighable ? 'kg' : 'un',
      );

  double get requestedTotal => unitPrice * requestQuantity;
  double get foundTotal => notFound ? 0.0 : (unitPrice * foundQuantity);
  double get itemChangeDifference => foundTotal - requestedTotal;
  bool get hasQuantityChange =>
      (foundQuantity - requestQuantity).abs() > 0.001 || notFound || substitutedBy != null;
  bool get hasDivergence => hasQuantityChange;
}

class OrderStateHistoryRecord {
  final String name;
  final String description;
  final String date;
  final String status;

  const OrderStateHistoryRecord({
    required this.name,
    required this.description,
    required this.date,
    required this.status,
  });
}

class OrderModel {
  final String id;
  final String code;
  final DateTime date;
  final double grossValue;
  final double discountValue;
  final double deliveryFee;
  final double serviceFee;
  final double purchaseVoucherValue;
  final double totalAmount;
  final int itemsCount;
  final String status; // 'received', 'picking', 'delivering', 'completed', 'canceled', 'cancelled'
  final String deliveryType; // 'delivery' | 'takeaway'
  final String paymentMethod;
  final String cardBrand;
  final String cardLast4;
  final int installments;
  final String? timeSlot;
  final String? deliveryAddressText;
  final String? observation;
  final int dryVolumes;
  final int coldVolumes;
  final String separatorName;
  final String deliverymanName;
  final String? passwordNumber;
  final String? pixCopiaECola;
  final int? preSaleId;
  final int? erpOrderId;
  final bool canCancel;
  final bool needsClientApproval;
  final bool clientApprovedChanges;
  final String? cancelReason;
  final String? cancelObservation;
  final List<OrderItemRecord> items;
  final List<OrderStateHistoryRecord> statesHistory;

  const OrderModel({
    required this.id,
    required this.code,
    required this.date,
    double? grossValue,
    double? subtotalAmount,
    this.discountValue = 0.0,
    double? deliveryFee,
    double? deliveryCost,
    this.serviceFee = 0.0,
    this.purchaseVoucherValue = 0.0,
    required this.totalAmount,
    required this.itemsCount,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    this.cardBrand = 'Mastercard',
    this.cardLast4 = '4289',
    this.installments = 1,
    String? timeSlot,
    String? scheduledWindow,
    this.deliveryAddressText,
    this.observation,
    this.dryVolumes = 2,
    this.coldVolumes = 1,
    String? separatorName,
    String? deliverymanName,
    this.passwordNumber,
    this.pixCopiaECola,
    this.preSaleId,
    this.erpOrderId,
    this.canCancel = true,
    this.needsClientApproval = false,
    this.clientApprovedChanges = false,
    this.cancelReason,
    this.cancelObservation,
    this.items = const [],
    this.statesHistory = const [],
  })  : grossValue = grossValue ?? subtotalAmount ?? totalAmount,
        deliveryFee = deliveryFee ?? deliveryCost ?? 0.0,
        timeSlot = timeSlot ?? scheduledWindow ?? 'Hoje, 14:00 - 16:00',
        separatorName = separatorName ?? 'Maria Fernanda (Separadora #04)',
        deliverymanName = deliverymanName ?? 'Carlos Eduardo (Moto #12)';

  String get scheduledWindow => timeSlot ?? 'Hoje, 14:00 - 16:00';
  double get subtotalAmount => grossValue;
  double get deliveryCost => deliveryFee;

  double get orderChangeDifference {
    if (items.isEmpty) return 0.0;
    return items.fold(0.0, (sum, item) => sum + item.itemChangeDifference);
  }

  OrderModel copyWith({
    String? status,
    bool? canCancel,
    bool? needsClientApproval,
    bool? clientApprovedChanges,
    String? cancelReason,
    String? cancelObservation,
    double? totalAmount,
    int? dryVolumes,
    int? coldVolumes,
    String? separatorName,
    String? deliverymanName,
    String? passwordNumber,
    List<OrderItemRecord>? items,
  }) {
    return OrderModel(
      id: id,
      code: code,
      date: date,
      grossValue: grossValue,
      discountValue: discountValue,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      purchaseVoucherValue: purchaseVoucherValue,
      totalAmount: totalAmount ?? this.totalAmount,
      itemsCount: items != null ? items.length : itemsCount,
      status: status ?? this.status,
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      cardBrand: cardBrand,
      cardLast4: cardLast4,
      installments: installments,
      timeSlot: timeSlot,
      deliveryAddressText: deliveryAddressText,
      observation: observation,
      dryVolumes: dryVolumes ?? this.dryVolumes,
      coldVolumes: coldVolumes ?? this.coldVolumes,
      separatorName: separatorName ?? this.separatorName,
      deliverymanName: deliverymanName ?? this.deliverymanName,
      passwordNumber: passwordNumber ?? this.passwordNumber,
      pixCopiaECola: pixCopiaECola,
      preSaleId: preSaleId,
      erpOrderId: erpOrderId,
      canCancel: canCancel ?? this.canCancel,
      needsClientApproval: needsClientApproval ?? this.needsClientApproval,
      clientApprovedChanges: clientApprovedChanges ?? this.clientApprovedChanges,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelObservation: cancelObservation ?? this.cancelObservation,
      items: items ?? this.items,
      statesHistory: statesHistory,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'received':
        return 'Pedido Recebido';
      case 'picking':
        return needsClientApproval && !clientApprovedChanges
            ? 'Aguardando Sua Aprovação'
            : 'Em Separação no Mercado';
      case 'ready_to_invoice':
        return 'Separado (Pronto para o Caixa)';
      case 'invoiced':
        return 'Faturado no Caixa (Aguardando Motoboy)';
      case 'delivering':
        return 'Saiu para Entrega';
      case 'completed':
        return 'Entregue';
      case 'canceled':
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Processando';
    }
  }

  int get statusStep {
    switch (status) {
      case 'received':
        return 1;
      case 'picking':
      case 'ready_to_invoice':
        return 2;
      case 'invoiced':
      case 'delivering':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }
}
