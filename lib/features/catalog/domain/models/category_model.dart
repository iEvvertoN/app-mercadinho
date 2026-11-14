class SubcategoryModel {
  final String id;
  final String name;
  final int totalProdutos;

  const SubcategoryModel({
    required this.id,
    required this.name,
    this.totalProdutos = 0,
  });

  factory SubcategoryModel.fromErpJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: (json['id'] ?? 'todos').toString(),
      name: (json['name'] ?? 'Todos').toString(),
      totalProdutos: ((json['totalProdutos'] ?? json['total_produtos'] ?? 0) as num).toInt(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String iconSvg;
  final String? bannerUrl;
  final String? bannerTitle;
  final int totalProdutos;
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconSvg,
    this.bannerUrl,
    this.bannerTitle,
    this.totalProdutos = 0,
    this.subcategories = const [],
  });

  factory CategoryModel.fromErpJson(Map<String, dynamic> json) {
    final rawSubs = (json['subcategories'] as List?) ?? const [];
    return CategoryModel(
      id: (json['id'] ?? 'mercearia').toString(),
      name: (json['name'] ?? 'Mercearia').toString(),
      iconSvg: (json['iconSvg'] ?? json['icon_svg'] ?? 'assets/icons_ecommerce/shopping_cart.svg').toString(),
      bannerTitle: (json['bannerTitle'] ?? json['banner_title'])?.toString(),
      totalProdutos: ((json['totalProdutos'] ?? json['total_produtos'] ?? 0) as num).toInt(),
      subcategories: rawSubs
          .whereType<Map>()
          .map((m) => SubcategoryModel.fromErpJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}
