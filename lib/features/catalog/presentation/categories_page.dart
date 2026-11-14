import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/mock_catalog_data.dart';
import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import 'product_details_page.dart';
import 'widgets/product_card.dart';

class CategoriesPage extends StatefulWidget {
  final String? initialCategoryId;
  final bool isEmbeddedTab;

  const CategoriesPage({
    super.key,
    this.initialCategoryId,
    this.isEmbeddedTab = false,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late String _selectedCategoryId;
  String _selectedSubcategoryId = 'todos';
  String _sortBy = 'destaques'; // 'destaques', 'menor_preco', 'maior_desconto'

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? MockCatalogData.categories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final CategoryModel currentCategory = MockCatalogData.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => MockCatalogData.categories.first,
    );

    final List<ProductModel> filteredProducts = MockCatalogData.products.where((p) {
      if (p.categoryId != _selectedCategoryId) return false;
      if (_selectedSubcategoryId != 'todos' && p.subcategoryId != _selectedSubcategoryId) {
        return false;
      }
      return true;
    }).toList();

    if (_sortBy == 'menor_preco') {
      filteredProducts.sort((a, b) => a.activePrice.compareTo(b.activePrice));
    } else if (_sortBy == 'maior_desconto') {
      filteredProducts.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedTab,
        title: const Text('Departamentos & Subcategorias'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Ordenar Produtos',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'destaques', child: Text('Ordenar: Destaques')),
              PopupMenuItem(value: 'menor_preco', child: Text('Ordenar: Menor Preço')),
              PopupMenuItem(value: 'maior_desconto', child: Text('Ordenar: Maior Desconto')),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Barra Lateral de Departamentos
          Container(
            width: 96,
            color: Colors.white,
            child: ListView.builder(
              itemCount: MockCatalogData.categories.length,
              itemBuilder: (context, index) {
                final CategoryModel category = MockCatalogData.categories[index];
                final bool isSelected = category.id == _selectedCategoryId;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                      _selectedSubcategoryId = 'todos';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight.withOpacity(0.5) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                          radius: 19,
                          child: Icon(
                            _getIcon(category.id),
                            size: 19,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Área Principal: Banner da Categoria + Subcategorias (`query_category.graphql`) + Grade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner do Departamento
                if (currentCategory.bannerTitle != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentCategory.bannerTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Régua de Subcategorias (`subcategories`)
                if (currentCategory.subcategories.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: currentCategory.subcategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final sub = currentCategory.subcategories[idx];
                        final isSel = sub.id == _selectedSubcategoryId;
                        return ChoiceChip(
                          label: Text(sub.name),
                          selected: isSel,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                          onSelected: (_) => setState(() => _selectedSubcategoryId = sub.id),
                        );
                      },
                    ),
                  ),

                // Grade de Produtos
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum produto encontrado nesta subcategoria.',
                            style: AppTypography.bodySmall,
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.54,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final ProductModel product = filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsPage(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String id) {
    switch (id) {
      case 'acougue':
        return Icons.kebab_dining;
      case 'hortifruti':
        return Icons.eco;
      case 'padaria':
        return Icons.bakery_dining;
      case 'bebidas':
        return Icons.sports_bar;
      case 'laticinios':
        return Icons.egg;
      case 'mercearia':
        return Icons.rice_bowl;
      case 'limpeza':
        return Icons.cleaning_services;
      default:
        return Icons.local_grocery_store;
    }
  }
}
