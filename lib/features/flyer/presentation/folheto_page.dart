import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../../catalog/data/mock_catalog_data.dart';
import '../../catalog/domain/models/product_model.dart';
import '../../catalog/presentation/product_details_page.dart';

class FolhetoPage extends StatefulWidget {
  final bool isEmbeddedTab;

  const FolhetoPage({super.key, this.isEmbeddedTab = false});

  @override
  State<FolhetoPage> createState() => _FolhetoPageState();
}

class _FolhetoPageState extends State<FolhetoPage> {
  final TransformationController _zoomController = TransformationController();
  double _currentZoom = 1.0;
  bool _isFullScreenMode = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _ensureCatalogLoaded();
  }

  Future<void> _ensureCatalogLoaded() async {
    if (!MockCatalogData.isLiveFromErp && !_isSyncing) {
      setState(() => _isSyncing = true);
      await CatalogApiService.syncWithErp();
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _setZoom(double zoom) {
    final clamped = zoom.clamp(1.0, 3.5);
    setState(() {
      _currentZoom = clamped;
      _zoomController.value = Matrix4.identity()..scale(clamped);
      if (clamped > 1.15 && !_isFullScreenMode) {
        _isFullScreenMode = true;
      } else if (clamped <= 1.02 && _isFullScreenMode) {
        _isFullScreenMode = false;
      }
    });
  }

  bool _hasOfficialPhoto(ProductModel p) {
    return p.imageUrl.contains('/api/marketplace/fotos/');
  }

  /// Seleciona produtos reais do catálogo priorizando aqueles com foto oficial no banco
  List<ProductModel> _selectProductsByKeywords(
    List<ProductModel> pool,
    List<String> keywords,
    int count,
    Set<String> usedIds,
  ) {
    final matches = <ProductModel>[];

    bool matchesKeyword(ProductModel p) {
      final text = '${p.name} ${p.categoryId} ${p.description}'.toUpperCase();
      return keywords.any((k) => text.contains(k));
    }

    // 1ª Passada: Produtos que batem com as palavras-chave E têm foto oficial
    for (final p in pool) {
      if (matches.length >= count) break;
      if (!usedIds.contains(p.id) && _hasOfficialPhoto(p) && matchesKeyword(p)) {
        matches.add(p);
        usedIds.add(p.id);
      }
    }

    // 2ª Passada: Produtos com foto oficial de qualquer categoria para não deixar buraco
    for (final p in pool) {
      if (matches.length >= count) break;
      if (!usedIds.contains(p.id) && _hasOfficialPhoto(p)) {
        matches.add(p);
        usedIds.add(p.id);
      }
    }

    // 3ª Passada: Qualquer produto que bata com a palavra-chave
    for (final p in pool) {
      if (matches.length >= count) break;
      if (!usedIds.contains(p.id) && matchesKeyword(p)) {
        matches.add(p);
        usedIds.add(p.id);
      }
    }

    // 4ª Passada: Qualquer produto restante
    for (final p in pool) {
      if (matches.length >= count) break;
      if (!usedIds.contains(p.id)) {
        matches.add(p);
        usedIds.add(p.id);
      }
    }

    return matches;
  }

  void _openNewspaperProductSheet(BuildContext context, ProductModel product) {
    final double oldPrice = product.hasDiscount
        ? product.salePrice
        : double.parse((product.salePrice * 1.15).toStringAsFixed(2));
    final double clubPrice = product.activePrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<CartController>(
          builder: (context, cart, _) {
            final bool isDiscountActive = cart.isDiscountActivated(product.id);
            final double qtyInCart = cart.getProductQuantity(product.id);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD90416),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OFERTA DO ENCARTE SEMANAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.name,
                                style: AppTypography.heading2.copyWith(fontSize: 15.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'De ${CurrencyFormatter.format(oldPrice)} por:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(clubPrice),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFD90416),
                                    ),
                                  ),
                                  Text(
                                    ' /${product.unit.toLowerCase()} no app',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              cart.toggleDiscountActivation(product.id);
                            },
                            icon: Icon(
                              isDiscountActive ? Icons.check_circle : Icons.bolt,
                              color: isDiscountActive ? AppColors.success : const Color(0xFFD90416),
                            ),
                            label: Text(
                              isDiscountActive ? 'Ativado no App ✓' : 'Ativar no App',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDiscountActive ? AppColors.success : const Color(0xFFD90416),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cart.activateAllDiscounts([product.id]);
                              cart.addProduct(product);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} adicionado ao carrinho!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                            label: Text(
                              qtyInCart > 0
                                  ? 'Mais 1 (${qtyInCart.toStringAsFixed(product.weighable ? 2 : 0)})'
                                  : 'Por no Carrinho',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
                          );
                        },
                        child: const Text('Ver Detalhes Completos do Produto →'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = MockCatalogData.products;
    final usedIds = <String>{};

    // Distribuir produtos reais com foto oficial nas 5 seções fiéis ao modelo enviado
    final clubItems = _selectProductsByKeywords(
      allProducts,
      ['ARROZ', 'FEIJAO', 'FEIJÃO', 'MACARRAO', 'MACARRÃO', 'ACUCAR', 'AÇÚCAR', 'OLEO', 'ÓLEO', 'CAFE', 'CAFÉ', 'LEITE', 'FARINHA', 'MARGARINA', 'MANTEIGA', 'FLOCAO', 'FLOCÃO', 'SARDINHA'],
      16,
      usedIds,
    );

    final cardExclusiveItems = _selectProductsByKeywords(
      allProducts,
      ['BISCOITO', 'CERVEJA', 'REFRIG', 'SUCO', 'ACHOC', 'CREME DE LEITE', 'CONDENSADO', 'MOLHO', 'MAIONESE'],
      8,
      usedIds,
    );

    final padariaItems = _selectProductsByKeywords(
      allProducts,
      ['PAO', 'PÃO', 'BOLO', 'BOLACHA', 'TORRADA', 'ROSQUINHA', 'WAFER', 'PADARIA'],
      4,
      usedIds,
    );

    final hortifrutiItems = _selectProductsByKeywords(
      allProducts,
      ['LIMAO', 'LIMÃO', 'MACA', 'MAÇÃ', 'ALHO', 'CEBOLA', 'TOMATE', 'BANANA', 'BATATA', 'CENOURA', 'LARANJA', 'MANGA', 'VERDURA', 'HORTIFRUTI'],
      4,
      usedIds,
    );

    final festivalItems = _selectProductsByKeywords(
      allProducts,
      ['CARNE', 'FRANGO', 'CALABRESA', 'LINGUICA', 'LINGUIÇA', 'SALSICHA', 'MORTADELA', 'PRESUNTO', 'QUEIJO', 'IOGURTE'],
      3,
      usedIds,
    );

    final acouguePereciveisItems = _selectProductsByKeywords(
      allProducts,
      ['CARNE', 'FRANGO', 'LINGUICA', 'LINGUIÇA', 'SALSICHA', 'MORTADELA', 'QUEIJO', 'IOGURTE', 'DANONE', 'BEBIDA LACTEA', 'REQUEIJAO', 'PRESUNTO', 'HAMBURGUER', 'EMPANADO', 'PEIXE', 'SARDINHA', 'ATUM', 'OVO'],
      21,
      usedIds,
    );

    final merceariaBottomItems = _selectProductsByKeywords(
      allProducts,
      ['CHOCOLATE', 'BOMBOM', 'SABAO', 'SABÃO', 'DETERGENTE', 'DESINFETANTE', 'AGUA SANITARIA', 'PAPEL', 'SHAMPOO', 'SABONETE', 'SALGADINHO', 'BATATA'],
      7,
      usedIds,
    );

    return Scaffold(
      backgroundColor: _isFullScreenMode ? const Color(0xFF1A1A1A) : const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. TÍTULO SUPERIOR FIEL À IMAGEM 2 ("Jornal de ofertas")
                if (!_isFullScreenMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        if (!widget.isEmbeddedTab)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        else
                          const SizedBox(width: 36),
                        const Expanded(
                          child: Text(
                            'Jornal de ofertas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tela Cheia / Zoom',
                          onPressed: () {
                            setState(() {
                              _isFullScreenMode = true;
                              if (_currentZoom < 1.3) {
                                _setZoom(1.45);
                              }
                            });
                          },
                          icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF475569), size: 24),
                        ),
                      ],
                    ),
                  ),

                // 2. CONTAINER DO ENCARTE SEMANAL
                Expanded(
                  child: Container(
                    margin: _isFullScreenMode
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF0F0),
                      borderRadius: _isFullScreenMode
                          ? BorderRadius.zero
                          : const BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: _isFullScreenMode
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, -2),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Faixa Superior Rose ("ENCARTE SEMANAL - ...")
                        if (!_isFullScreenMode)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Text(
                              'ENCARTE SEMANAL – CASA DE VÓ 09 A 15\nDE NOVEMBRO 2026',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7F1D1D),
                                height: 1.25,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                        // Área Branca Interna com o Tabloide Interativo (Zoom + Pan)
                        Expanded(
                          child: Container(
                            margin: _isFullScreenMode
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(horizontal: 8),
                            padding: _isFullScreenMode ? EdgeInsets.zero : const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: _isFullScreenMode
                                  ? BorderRadius.zero
                                  : const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: InteractiveViewer(
                              transformationController: _zoomController,
                              minScale: 1.0,
                              maxScale: 3.5,
                              panEnabled: true,
                              scaleEnabled: true,
                              onInteractionEnd: (_) {
                                final scale = _zoomController.value.getMaxScaleOnAxis();
                                setState(() {
                                  _currentZoom = scale.clamp(1.0, 3.5);
                                });
                              },
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 76),
                                child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: 780, // Largura gráfica oficial de tabloide de supermercado
                                    child: _buildEncarteGraphicCanvas(
                                      context: context,
                                      clubItems: clubItems,
                                      cardExclusiveItems: cardExclusiveItems,
                                      padariaItems: padariaItems,
                                      hortifrutiItems: hortifrutiItems,
                                      festivalItems: festivalItems,
                                      acouguePereciveisItems: acouguePereciveisItems,
                                      merceariaBottomItems: merceariaBottomItems,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 3. BARRA FLUTUANTE DE ZOOM ESTILO IMAGEM 1 (BOTÃO [-] SLIDER [+] E SAIR TELA CHEIA)
            Positioned(
              left: 20,
              right: 20,
              bottom: 14,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Botão Circular (-)
                    InkWell(
                      onTap: () => _setZoom(_currentZoom - 0.35),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.4),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white, size: 18),
                      ),
                    ),
                    // Slider Central com Bolinha Branca
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                        ),
                        child: Slider(
                          value: _currentZoom.clamp(1.0, 3.5),
                          min: 1.0,
                          max: 3.5,
                          onChanged: (val) => _setZoom(val),
                        ),
                      ),
                    ),
                    // Botão Circular (+)
                    InkWell(
                      onTap: () => _setZoom(_currentZoom + 0.35),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.4),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                    if (_isFullScreenMode) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isFullScreenMode = false;
                            _setZoom(1.0);
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 1.2),
                          ),
                          child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o Tabloide Gráfico Completo idêntico às 2 fotos de referência
  Widget _buildEncarteGraphicCanvas({
    required BuildContext context,
    required List<ProductModel> clubItems,
    required List<ProductModel> cardExclusiveItems,
    required List<ProductModel> padariaItems,
    required List<ProductModel> hortifrutiItems,
    required List<ProductModel> festivalItems,
    required List<ProductModel> acouguePereciveisItems,
    required List<ProductModel> merceariaBottomItems,
  }) {
    final clubRow1 = clubItems.take(8).toList();
    final clubRow2 = clubItems.skip(8).take(8).toList();

    return Container(
      color: const Color(0xFFD90416), // Fundo vermelho vivo do encarte
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===================================================================
          // 1. TOPO DARK / NEON "ESQUENTA BLACK CASA DE VÓ"
          // ===================================================================
          Container(
            height: 158,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2A0404),
                  Color(0xFF4A0808),
                  Color(0xFF1C0303),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Coluna Esquerda: Emblema Neon + Localização
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF280606),
                          border: Border.all(color: const Color(0xFFFF4D2A), width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0xAAFF3B1F), blurRadius: 12, spreadRadius: 1),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B35), size: 34),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Localização:\nMercadinho Casa de Vó\nAtendimento Loja Física & App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Coluna Central: Placa 3D "ESQUENTA BLACK CASA DE VÓ"
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1918),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF5722), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99FF5722),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ESQUENTA',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF6D3A),
                            letterSpacing: 3,
                            height: 1.0,
                            shadows: const [
                              Shadow(color: Color(0xFFFF3D00), blurRadius: 10),
                            ],
                          ),
                        ),
                        const Text(
                          'BLACK',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE2E8F0),
                            letterSpacing: 2,
                            height: 1.0,
                            shadows: [
                              Shadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 4),
                            ],
                          ),
                        ),
                        const Text(
                          'CASA DE VÓ',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5252),
                            letterSpacing: 2.5,
                            height: 1.05,
                            shadows: [
                              Shadow(color: Color(0xFFFF1744), blurRadius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Coluna Direita: Selo da Loja + Validade
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD90416), width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              color: const Color(0xFFD90416),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CV ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CASA DE VÓ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        'O barato de verdade!',
                                        style: TextStyle(
                                          color: Color(0xFFFDE047),
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                              child: Column(
                                children: [
                                  Text(
                                    'OFERTAS IMPERDÍVEIS\nMERCADINHO CASA DE VÓ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '09 a 15 de\nnovembro de 2026',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '*Consulte as condições no App.',
                        style: TextStyle(color: Colors.white70, fontSize: 7.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 2. FAIXA "ATIVE NO APP" + GRADE VERMELHA DE OFERTAS DO CLUBE
          // ===================================================================
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            color: const Color(0xFFD90416),
            child: Column(
              children: [
                // Cabeçalho "Ative no APP"
                Row(
                  children: [
                    // Selo inclinado "Ative no APP"
                    Transform.rotate(
                      angle: -0.08,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFACC15), width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.phone_iphone_rounded, color: Color(0xFFD90416), size: 20),
                            Text(
                              'Ative\nno APP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(text: 'Ative essas ofertas no '),
                            TextSpan(
                              text: 'APP CLUBE CASA DE VÓ\n',
                              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                              text: 'MAIS ',
                              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900),
                            ),
                            TextSpan(text: 'e aproveite '),
                            TextSpan(
                              text: 'DESCONTOS EXCLUSIVOS!',
                              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Linha 1 de Produtos do Clube (8 colunas)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: clubRow1
                      .map((p) => Expanded(child: _buildRedClubFlyerItem(context, p)))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Linha 2 de Produtos do Clube (8 colunas)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: clubRow2
                      .map((p) => Expanded(child: _buildRedClubFlyerItem(context, p)))
                      .toList(),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 3. FAIXA PRATA/CINZA: OFERTAS EXCLUSIVAS CARTÃO / PIX CASA DE VÓ
          // ===================================================================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD1D5DB), Color(0xFFF3F4F6), Color(0xFFD1D5DB)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Column(
              children: [
                // Barra título cinza escuro
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5563),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD90416),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'OFERTAS EXCLUSIVAS PARA PAGAMENTOS NO '),
                            TextSpan(
                              text: 'PIX OU CARTÃO CASA DE VÓ PREMIUM',
                              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cardExclusiveItems
                      .map((p) => Expanded(child: _buildSilverCardFlyerItem(context, p)))
                      .toList(),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 4. FAIXA DUPLA LADO A LADO: PADARIA (ESQUERDA) + HORTIFRUTI (DIREITA)
          // ===================================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              children: [
                // Bloco PADARIA
                Expanded(
                  child: _buildSideLabelSection(
                    context: context,
                    label: 'PADARIA',
                    labelBgColor: const Color(0xFFE6C994),
                    labelTextColor: const Color(0xFF3E1F0D),
                    boxBgColor: const Color(0xFFF7EBD4),
                    pricePillColor: const Color(0xFF3E1F0D),
                    items: padariaItems,
                  ),
                ),
                const SizedBox(width: 6),
                // Bloco HORTIFRUTI
                Expanded(
                  child: _buildSideLabelSection(
                    context: context,
                    label: 'HORTIFRUTI',
                    labelBgColor: const Color(0xFFB5D692),
                    labelTextColor: const Color(0xFF233D11),
                    boxBgColor: const Color(0xFFDCECC9),
                    pricePillColor: const Color(0xFF3E1F0D),
                    items: hortifrutiItems,
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 5. BLOCO GRANDE: AÇOUGUE, PERECÍVEIS E CONGELADOS + FESTIVAL
          // ===================================================================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF5C2D16), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Etiqueta Vertical Esquerda "AÇOUGUE, PERECÍVEIS E CONGELADOS"
                  Container(
                    width: 26,
                    color: const Color(0xFF5C2D16),
                    alignment: Alignment.center,
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'AÇOUGUE, PERECÍVEIS E CONGELADOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo Principal do Açougue & Perecíveis
                  Expanded(
                    child: Column(
                      children: [
                        // Linha 1: 5 itens normais à esquerda + Box "FESTIVAL" escuro com 3 itens à direita
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: acouguePereciveisItems
                                      .take(5)
                                      .map((p) => Expanded(child: _buildButcherFlyerItem(context, p)))
                                      .toList(),
                                ),
                              ),
                            ),
                            // Sub-bloco escuro "FESTIVAL CARNES & FRIOS"
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3E1F0D),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'FESTIVAL CARNES & FRIOS',
                                      style: TextStyle(
                                        color: Color(0xFFFACC15),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: festivalItems
                                          .map((p) => Expanded(
                                                child: _buildButcherFlyerItem(context, p, darkTheme: true),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Linha 2 (8 colunas)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: acouguePereciveisItems
                                .skip(5)
                                .take(8)
                                .map((p) => Expanded(child: _buildButcherFlyerItem(context, p)))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Linha 3 (8 colunas)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: acouguePereciveisItems
                                .skip(13)
                                .take(8)
                                .map((p) => Expanded(child: _buildButcherFlyerItem(context, p)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===================================================================
          // 6. FAIXA VERDE WHATSAPP + QR CODE (FIEL AO MODELO)
          // ===================================================================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15803D), Color(0xFF22C55E), Color(0xFF14532D)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Toque em qualquer produto do encarte para ativar o desconto e adicionar direto ao seu carrinho!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 22, color: Colors.black87),
                ),
                const SizedBox(width: 10),
                const Text(
                  'OFERTAS IMPERDÍVEIS PARA O\nMERCADINHO CASA DE VÓ',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 7. BLOCO RODAPÉ: MERCEARIA
          // ===================================================================
          Container(
            margin: const EdgeInsets.fromLTRB(6, 3, 6, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD90416), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 26,
                    color: const Color(0xFFD90416),
                    alignment: Alignment.center,
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'MERCEARIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: merceariaBottomItems
                            .map((p) => Expanded(child: _buildMerceariaBottomItem(context, p)))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item da Grade Vermelha "Ative no APP" (Etiqueta dupla: esquerda "de X,XX", direita amarela "no app Y,YY")
  Widget _buildRedClubFlyerItem(BuildContext context, ProductModel product) {
    final double oldPrice = product.hasDiscount
        ? product.salePrice
        : double.parse((product.salePrice * 1.18).toStringAsFixed(2));
    final String oldFormatted = oldPrice.toStringAsFixed(2).replaceAll('.', ',');
    final String activeFormatted = product.activePrice.toStringAsFixed(2).replaceAll('.', ',');

    return GestureDetector(
      onTap: () => _openNewspaperProductSheet(context, product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Column(
          children: [
            // Foto do Produto
            Container(
              height: 58,
              width: double.infinity,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFD90416),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Etiqueta Dupla "de X,XX" | "no app Y,YY"
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFACC15), width: 0.8),
              ),
              child: Row(
                children: [
                  // Lado esquerdo: "de X,XX"
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                      child: Column(
                        children: [
                          const Text(
                            'de R\$',
                            style: TextStyle(color: Colors.white70, fontSize: 5.5, height: 1.0),
                          ),
                          Text(
                            oldFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.lineThrough,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Lado direito amarelo: "no app Y,YY"
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'no app',
                            style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 5.5,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            activeFormatted,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name.toUpperCase(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 6.2,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item da Faixa Prata "Ofertas Exclusivas Cartão/PIX"
  Widget _buildSilverCardFlyerItem(BuildContext context, ProductModel product) {
    final double oldPrice = product.hasDiscount
        ? product.salePrice
        : double.parse((product.salePrice * 1.15).toStringAsFixed(2));
    final String oldFormatted = oldPrice.toStringAsFixed(2).replaceAll('.', ',');
    final String activeFormatted = product.activePrice.toStringAsFixed(2).replaceAll('.', ',');

    return GestureDetector(
      onTap: () => _openNewspaperProductSheet(context, product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Column(
          children: [
            Container(
              height: 52,
              width: double.infinity,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF4B5563),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Text(
                        oldFormatted,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        activeFormatted,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name.toUpperCase(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 6.0,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bloco com Etiqueta Vertical Lateral (PADARIA / HORTIFRUTI)
  Widget _buildSideLabelSection({
    required BuildContext context,
    required String label,
    required Color labelBgColor,
    required Color labelTextColor,
    required Color boxBgColor,
    required Color pricePillColor,
    required List<ProductModel> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pricePillColor, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 24,
              color: labelBgColor,
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((p) {
                    final String priceStr = p.activePrice.toStringAsFixed(2).replaceAll('.', ',');
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _openNewspaperProductSheet(context, p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                width: double.infinity,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Image.network(
                                  p.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.bakery_dining_rounded,
                                    color: pricePillColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: pricePillColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priceStr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFACC15),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.name.toUpperCase(),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: labelTextColor,
                                  fontSize: 6.0,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item da Grade de Açougue, Perecíveis e Congelados
  Widget _buildButcherFlyerItem(
    BuildContext context,
    ProductModel product, {
    bool darkTheme = false,
  }) {
    final String priceStr = product.activePrice.toStringAsFixed(2).replaceAll('.', ',');

    return GestureDetector(
      onTap: () => _openNewspaperProductSheet(context, product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Column(
          children: [
            Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: darkTheme ? const Color(0xFF92400E) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFF78350F),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF451A03),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFF59E0B), width: 0.7),
              ),
              child: Text(
                priceStr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name.toUpperCase(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkTheme ? Colors.white : const Color(0xFF1F2937),
                fontSize: 5.8,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item do Rodapé MERCEARIA (Etiqueta vermelha vibrante)
  Widget _buildMerceariaBottomItem(BuildContext context, ProductModel product) {
    final String priceStr = product.activePrice.toStringAsFixed(2).replaceAll('.', ',');

    return GestureDetector(
      onTap: () => _openNewspaperProductSheet(context, product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Container(
              height: 52,
              width: double.infinity,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_grocery_store_outlined,
                  color: Color(0xFFD90416),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD90416),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                priceStr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name.toUpperCase(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 6.0,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
