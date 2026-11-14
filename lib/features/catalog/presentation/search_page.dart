import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/catalog_api_service.dart';
import '../data/mock_catalog_data.dart';
import '../domain/models/product_model.dart';
import 'product_details_page.dart';
import 'scanner_page.dart';
import 'widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<ProductModel>? _remoteResults;
  bool _isSearchingRemote = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String val) async {
    final trimmed = val.trim();
    setState(() {
      _query = trimmed;
      if (trimmed.isEmpty) {
        _remoteResults = null;
      }
    });

    if (trimmed.isNotEmpty) {
      setState(() => _isSearchingRemote = true);
      final remote = await CatalogApiService.searchInErp(query: trimmed, limit: 300);
      if (!mounted) return;
      if (_query == trimmed) {
        setState(() {
          _remoteResults = remote;
          _isSearchingRemote = false;
        });
      }
    } else {
      setState(() => _isSearchingRemote = false);
    }
  }

  static String _stripAccents(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tokens = _stripAccents(_query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final List<ProductModel> localFiltered = MockCatalogData.products.where((p) {
      if (tokens.isEmpty) return true;
      final haystack = _stripAccents('${p.name} ${p.description} ${p.barcode} ${p.id}');
      return tokens.every((tk) => haystack.contains(tk));
    }).toList();

    final List<ProductModel> results =
        _query.isEmpty ? localFiltered : (_remoteResults ?? localFiltered);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, marca ou código de barras...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                  IconButton(
                    tooltip: 'Procurar item pelo código de barras',
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScannerPage(
                            mode: ScannerMode.searchOnly,
                            onProductFoundForSearch: (prod) {
                              _searchController.text = prod.barcode;
                              _onSearchChanged(prod.barcode);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        bottom: _isSearchingRemote
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceElevated,
            child: Text(
              _query.isEmpty
                  ? 'Exibindo ${results.length} produtos disponíveis no estoque'
                  : '${results.length} resultado(s) para "$_query"',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Nenhum produto encontrado', style: AppTypography.heading2),
                        SizedBox(height: 6),
                        Text(
                          'Tente buscar por "leite", "biscoito", "shampoo" ou código EAN.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: results.length > 200 ? 200 : results.length,
                    itemBuilder: (context, index) {
                      final ProductModel product = results[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
