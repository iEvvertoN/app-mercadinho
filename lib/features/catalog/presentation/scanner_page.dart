import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/scanner_sound_service.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../loyalty/presentation/checkin_qrcode_page.dart';
import '../data/catalog_api_service.dart';
import '../data/mock_catalog_data.dart';
import '../domain/models/product_model.dart';
import 'product_details_page.dart';
import 'widgets/web_barcode_scanner.dart';

/// Define a função específica de onde o leitor foi chamado:
/// - `searchOnly`: Chamado pela Barra de Pesquisa (apenas procura/consulta o item).
/// - `scanAndGo`: Chamado dentro da aba do Carrinho (bipa o produto e já joga direto pro carrinho).
enum ScannerMode {
  searchOnly,
  scanAndGo,
}

class ScannerPage extends StatefulWidget {
  final bool isEmbeddedTab;
  final ScannerMode mode;
  final ValueChanged<ProductModel>? onProductFoundForSearch;

  const ScannerPage({
    super.key,
    this.isEmbeddedTab = false,
    this.mode = ScannerMode.scanAndGo,
    this.onProductFoundForSearch,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf,
      BarcodeFormat.qrCode,
    ],
  );

  final TextEditingController _barcodeInputController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  late final AnimationController _laserAnimController;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  late bool _autoAddToCart;
  bool _showSuccessFlash = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  ProductModel? _lastAddedProduct;

  @override
  void initState() {
    super.initState();
    // Na Barra de Pesquisa só procura o item; no Scan & Go do Carrinho já bipa direto pro carrinho!
    _autoAddToCart = widget.mode == ScannerMode.scanAndGo;
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _scannerController.dispose();
    _barcodeInputController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _triggerVisualFlash() {
    setState(() => _showSuccessFlash = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showSuccessFlash = false);
      }
    });
  }

  Future<void> _lookupAndProcessBarcode(String rawValue, {bool fromCamera = false}) async {
    if (_isProcessing) return;
    final clean = rawValue.trim();
    if (clean.isEmpty) return;

    // Evita leituras duplicadas em menos de 1.6s do mesmo código pela câmera
    if (fromCamera &&
        _lastScannedBarcode == clean &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!).inMilliseconds < 1600) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = clean;
      _lastScanTime = DateTime.now();
    });

    final ProductModel? product =
        await CatalogApiService.lookupBarcodeInErp(clean) ?? MockCatalogData.findByBarcode(clean);

    if (!mounted) return;

    if (product != null) {
      // Efeito sonoro real de BIP de leitor de supermercado (2650Hz) + Flash Visual
      ScannerSoundService.playSuccessBeep();
      _triggerVisualFlash();
      _barcodeInputController.clear();

      setState(() {
        _lastAddedProduct = product;
      });

      // Se a tela de busca pediu retorno direto do produto pesquisado:
      if (widget.onProductFoundForSearch != null) {
        widget.onProductFoundForSearch!(product);
        if (Navigator.canPop(context)) {
          Navigator.pop(context, product);
          return;
        }
      }

      if (_autoAddToCart) {
        // Modo Scan & Go: adiciona direto no carrinho!
        context.read<CartController>().addProduct(product);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1600),
            content: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BIP! +1 ${product.name} (${CurrencyFormatter.format(product.activePrice)}) no carrinho!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'DESFAZER',
              textColor: Colors.amberAccent,
              onPressed: () {
                context.read<CartController>().decrement(product);
              },
            ),
          ),
        );

        setState(() => _isProcessing = false);
      } else {
        // Modo Busca da Barra de Pesquisa: apenas procura e exibe a ficha do produto!
        if (!kIsWeb) {
          _scannerController.stop();
        }
        _showProductSheet(product);
      }
    } else {
      // Som grave de erro quando não encontra o código
      ScannerSoundService.playErrorBeep();
      setState(() => _isProcessing = false);
      _showNotFoundSnackBar(clean);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _lookupAndProcessBarcode(rawValue, fromCamera: true);
  }

  void _showNotFoundSnackBar(String barcode) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Código "$barcode" não localizado nos ${CatalogApiService.totalErpProductsCount > 0 ? CatalogApiService.totalErpProductsCount : 7903} itens do ERP.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductSheet(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Text(
                      'PRODUTO LOCALIZADO NO ERP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: product.imageUrl.trim().isEmpty
                          ? Container(
                              color: AppColors.surfaceElevated,
                              child: const Icon(Icons.shopping_basket_outlined, color: AppColors.textMuted),
                            )
                          : Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceElevated,
                                child: const Icon(Icons.shopping_basket_outlined, color: AppColors.textMuted),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.badge != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.badge!,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(product.name, style: AppTypography.heading3),
                        const SizedBox(height: 4),
                        Text('Código EAN: ${product.barcode}', style: AppTypography.caption),
                        Text(
                          'Estoque disponível: ${product.stock.toInt()} ${product.unit}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preço Unitário', style: AppTypography.caption),
                        Text(
                          CurrencyFormatter.format(product.salePrice),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: product.hasDiscount ? TextDecoration.lineThrough : null,
                            color: product.hasDiscount ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (product.clubPrice != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: AppColors.secondary, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Preço Clube',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(product.clubPrice!),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Ver Detalhes', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () {
                        ScannerSoundService.playSuccessBeep();
                        context.read<CartController>().addProduct(product);
                        Navigator.pop(bottomSheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} adicionado ao carrinho!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Por no Carrinho', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (!kIsWeb) {
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final bool isSearchMode = !_autoAddToCart;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedTab,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              isSearchMode ? Icons.manage_search_rounded : Icons.barcode_reader,
              color: isSearchMode ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSearchMode ? 'Buscar Item por Código' : 'Scan & Go • Bipar Produto',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Testar Som do Bip',
            icon: const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 20),
            onPressed: () {
              ScannerSoundService.playSuccessBeep();
              _triggerVisualFlash();
            },
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckinQrCodePage()),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 18),
            label: const Text('Meu QR', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          IconButton(
            tooltip: 'Lanterna da Câmera',
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? AppColors.secondary : Colors.white,
            ),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _scannerController.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Barra Superior de Modo + Digitação / Pistola USB / Código EAN
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Indicador claro da função ativa (Busca vs Scan & Go)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _autoAddToCart
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : const Color(0xFF38BDF8).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _autoAddToCart ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                              ),
                            ),
                            child: Text(
                              _autoAddToCart ? 'SCAN & GO ATIVO' : 'MODO BUSCA / CONSULTA',
                              style: TextStyle(
                                color: _autoAddToCart ? const Color(0xFF34D399) : const Color(0xFF7DD3FC),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _autoAddToCart
                                  ? 'Bipou com som -> Vai direto pro carrinho!'
                                  : 'Procura o item e mostra preço e estoque',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoAddToCart,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _autoAddToCart = val),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Campo para digitar ou usar leitor de código de barras
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeInputController,
                        focusNode: _barcodeFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (val) {
                          _lookupAndProcessBarcode(val);
                          _barcodeFocusNode.requestFocus();
                        },
                        decoration: InputDecoration(
                          hintText: isSearchMode
                              ? 'Digite o código EAN ou Cód. ERP para procurar...'
                              : 'Digite ou bipe o código EAN para jogar no carrinho...',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: Icon(
                            isSearchMode ? Icons.search_rounded : Icons.qr_code_scanner_rounded,
                            color: isSearchMode ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                            size: 19,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSearchMode ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _lookupAndProcessBarcode(_barcodeInputController.text);
                        },
                        icon: Icon(
                          isSearchMode ? Icons.search_rounded : Icons.add_shopping_cart_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isSearchMode ? 'Procurar' : 'Bipar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Área do Visor da Câmera com Mira Laser Animada e Flash de Bip
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                if (kIsWeb)
                  WebBarcodeScannerView(
                    torchEnabled: _isTorchOn,
                    onBarcodeDetected: (code) => _lookupAndProcessBarcode(code, fromCamera: true),
                  )
                else
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return Container(
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                isSearchMode
                                    ? 'Simulador de Leitura para Busca de Produtos'
                                    : 'Simulador Scan & Go (Com Som de Bip Real!)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSearchMode
                                    ? 'Toque num produto abaixo para testar o bip sonoro e abrir a consulta do item:'
                                    : 'Toque num produto abaixo para ouvir o BIP de supermercado e adicionar direto no carrinho:',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildQuickTestChip('8050', 'Recheado Turmix'),
                                  _buildQuickTestChip('8045', 'Tortuguita 40g'),
                                  _buildQuickTestChip('8055', 'Aveia Jasmine'),
                                  _buildQuickTestChip('2', 'Leite Betânia 1L'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Mira de Leitura de Código de Barras (EAN-13 / EAN-8) com Feixe Laser Animado
                IgnorePointer(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: _showSuccessFlash ? 286 : 270,
                      height: _showSuccessFlash ? 152 : 140,
                      decoration: BoxDecoration(
                        color: _showSuccessFlash
                            ? const Color(0xFF10B981).withOpacity(0.28)
                            : Colors.transparent,
                        border: Border.all(
                          color: _showSuccessFlash
                              ? const Color(0xFF34D399)
                              : (isSearchMode ? const Color(0xFF38BDF8) : const Color(0xFF10B981)),
                          width: _showSuccessFlash ? 4.0 : 2.5,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _showSuccessFlash
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.6),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Laser animado subindo e descendo
                          AnimatedBuilder(
                            animation: _laserAnimController,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment(0, (_laserAnimController.value * 1.6) - 0.8),
                                child: Container(
                                  height: 2.5,
                                  width: 245,
                                  decoration: BoxDecoration(
                                    color: _showSuccessFlash ? Colors.greenAccent : Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_showSuccessFlash ? Colors.greenAccent : Colors.redAccent)
                                            .withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 1.5,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Selo central quando bipa com sucesso
                          if (_showSuccessFlash)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSearchMode ? 'BIP! PRODUTO ENCONTRADO' : 'BIP! +1 NO CARRINHO',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.68),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSearchMode
                            ? 'Aponte para o código de barras para procurar o item e consultar o preço'
                            : 'Aponte para o código de barras para bipar direto para o seu carrinho',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Painel Inferior do Último Item Bipado + Resumo Rápido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastAddedProduct != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showProductSheet(_lastAddedProduct!),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSearchMode ? 'ÚLTIMO ITEM CONSULTADO' : 'ÚLTIMO PRODUTO BIPADO NO CARRINHO',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              Text(
                                _lastAddedProduct!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Cód: ${_lastAddedProduct!.barcode}  •  ${CurrencyFormatter.format(_lastAddedProduct!.activePrice)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Controles rápidos de + e - do último item
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => cart.decrement(_lastAddedProduct!),
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${cart.getProductQuantity(_lastAddedProduct!.id).toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            onPressed: () {
                              ScannerSoundService.playSuccessBeep();
                              cart.increment(_lastAddedProduct!);
                            },
                            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSearchMode
                              ? 'Bipe um código de barras para procurar o produto no catálogo'
                              : 'Bipe os produtos da prateleira para somar direto no carrinho',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (cart.items.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                          label: Text('Carrinho (${cart.itemCount})'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestChip(String code, String label) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF10B981)),
      avatar: const Icon(Icons.volume_up_rounded, size: 15, color: Colors.amberAccent),
      label: Text(
        '$label (#$code)',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _lookupAndProcessBarcode(code),
    );
  }
}
