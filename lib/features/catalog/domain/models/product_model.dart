class ProductModel {
  final String id;
  final String name;
  final String description;
  final String barcode;
  final double salePrice;
  final double? promotionalPrice;
  final double? clubPrice;
  final String imageUrl;
  final String categoryId;
  final String subcategoryId;
  final bool weighable;
  final double unitWeight;
  final String unit;
  final double stock;
  final bool continuousStockProduct;
  final String? badge;
  final int? limitPerCpf;
  final String? expirationText;
  final double? cashbackByUnit;
  final String? promotionType;
  final bool oneCent;
  final bool checkInOnly;
  final String? validWeekdays;
  final String? validTimeIntervals;
  final String? ruleText;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.barcode,
    required this.salePrice,
    this.promotionalPrice,
    this.clubPrice,
    required this.imageUrl,
    required this.categoryId,
    this.subcategoryId = 'todos',
    this.weighable = false,
    this.unitWeight = 1.0,
    this.unit = 'UN',
    this.stock = 100.0,
    this.continuousStockProduct = true,
    this.badge,
    this.limitPerCpf,
    this.expirationText,
    this.cashbackByUnit,
    this.promotionType,
    this.oneCent = false,
    this.checkInOnly = false,
    this.validWeekdays,
    this.validTimeIntervals,
    this.ruleText,
  });

  String get title => name;
  double get price => activePrice;
  double get regularPrice => salePrice;

  double get activePrice => clubPrice ?? promotionalPrice ?? salePrice;
  bool get hasDiscount => activePrice < salePrice;
  double get discountPercent =>
      hasDiscount ? ((salePrice - activePrice) / salePrice) * 100 : 0.0;

  String get limitLabel {
    if (limitPerCpf == null) return 'Sem limite por CPF';
    return weighable
        ? 'Limite: $limitPerCpf kg no preço Clube por CPF'
        : 'Limite: $limitPerCpf un. no preço Clube por CPF';
  }

  factory ProductModel.fromErpJson(
    Map<String, dynamic> json, {
    String baseUrl = 'http://127.0.0.1:3333',
  }) {
    String rawImage = (json['imageUrl'] ?? json['image_url'] ?? '').toString();
    if (rawImage.startsWith('/')) {
      rawImage = '$baseUrl$rawImage';
    } else if (rawImage.isEmpty) {
      rawImage = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&q=80';
    }

    final double salePrice = ((json['salePrice'] ?? json['sale_price'] ?? 0.01) as num).toDouble();
    final double? promoPrice = json['promotionalPrice'] != null
        ? (json['promotionalPrice'] as num).toDouble()
        : (json['promotional_price'] != null ? (json['promotional_price'] as num).toDouble() : null);
    final double? clubPrice = json['clubPrice'] != null
        ? (json['clubPrice'] as num).toDouble()
        : (json['club_price'] != null ? (json['club_price'] as num).toDouble() : null);

    return ProductModel(
      id: (json['id'] ?? 'prod_${json['idProduto'] ?? json['id_produto'] ?? 0}').toString(),
      name: (json['name'] ?? json['descricao'] ?? 'Produto').toString(),
      description: (json['description'] ?? json['name'] ?? '').toString(),
      barcode: (json['barcode'] ?? json['codigo_barras'] ?? '').toString(),
      salePrice: salePrice,
      promotionalPrice: promoPrice,
      clubPrice: clubPrice,
      imageUrl: rawImage,
      categoryId: (json['categoryId'] ?? json['category_id'] ?? 'mercearia').toString(),
      subcategoryId: (json['subcategoryId'] ?? json['subcategory_id'] ?? 'todos').toString(),
      weighable: (json['weighable'] ?? false) == true,
      unitWeight: ((json['unitWeight'] ?? json['unit_weight'] ?? 1.0) as num).toDouble(),
      unit: (json['unit'] ?? json['unidade'] ?? 'UN').toString(),
      stock: ((json['stock'] ?? json['estoque_atual'] ?? 0.0) as num).toDouble(),
      continuousStockProduct: (json['continuousStockProduct'] ?? true) == true,
      badge: json['badge']?.toString(),
      limitPerCpf: json['limitPerCpf'] != null ? (json['limitPerCpf'] as num).toInt() : null,
      cashbackByUnit: json['cashbackByUnit'] != null ? (json['cashbackByUnit'] as num).toDouble() : null,
      promotionType: json['promotionType']?.toString(),
    );
  }
}
