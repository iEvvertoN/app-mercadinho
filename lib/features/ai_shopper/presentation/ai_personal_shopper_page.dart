import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../../catalog/domain/models/product_model.dart';

class AiPersonalShopperPage extends StatefulWidget {
  final bool isEmbeddedTab;
  final ValueChanged<int>? onNavigateTab;

  const AiPersonalShopperPage({
    super.key,
    this.isEmbeddedTab = false,
    this.onNavigateTab,
  });

  @override
  State<AiPersonalShopperPage> createState() => _AiPersonalShopperPageState();
}

class _QuickPromptItem {
  final String emoji;
  final String label;
  final String prompt;

  const _QuickPromptItem({
    required this.emoji,
    required this.label,
    required this.prompt,
  });
}

class _AiPersonalShopperPageState extends State<AiPersonalShopperPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;
  List<dynamic> _apiHistory = [];

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          'Bença, meu amor! Que alegria te receber aqui no **Mercadinho Casa de Vó**! 👵💚\n\nMe conta o que você quer preparar hoje, se tem alguma restrição alimentar ou **quanto pode gastar no PIX**, que eu olho agora mesmo nas nossas prateleiras e monto sua cestinha com o melhor preço!',
      'products': null,
      'addedToCart': false,
    },
  ];

  final List<_QuickPromptItem> _quickPrompts = const [
    _QuickPromptItem(
      emoji: '💰',
      label: 'Cesta até R\$ 25',
      prompt:
          'Vó, só tenho R\$ 25,00 no PIX pra passar o fim de semana. Preciso de arroz, feijão, macarrão e ovos. Monta uma cestinha que não passe de R\$ 25 de jeito nenhum!',
    ),
    _QuickPromptItem(
      emoji: '🍵',
      label: 'Chá pra Gripe',
      prompt:
          'Oi vó, tô muito gripado com dor de garganta. Quero fazer um chá com mel, limão e alho. O que você tem aí?',
    ),
    _QuickPromptItem(
      emoji: '🥩',
      label: 'Kit Churrasco',
      prompt:
          'Quero 6 cervejas lata, 2 pacotes de carvão, farofa e 1 refrigerante de 2 litros. Quanto dá tudo?',
    ),
    _QuickPromptItem(
      emoji: '🥕',
      label: 'Bolo de Cenoura',
      prompt:
          'Quero fazer um bolo de cenoura fofinho com cobertura de chocolate. Separa os ingredientes mais em conta pra mim!',
    ),
    _QuickPromptItem(
      emoji: '🥛',
      label: 'Zero Lactose',
      prompt:
          'Sou intolerante a lactose. Quero tomar café da manhã com leite sem lactose e biscoito. O que tem no estoque?',
    ),
    _QuickPromptItem(
      emoji: '🧼',
      label: 'Faxina Econômica',
      prompt:
          'Preciso de sabão em pó, água sanitária, detergente e desinfetante bons e baratos pra faxina.',
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetConversation() {
    setState(() {
      _apiHistory = [];
      _messages
        ..clear()
        ..add({
          'isUser': false,
          'text':
              'Conversa limpinha, meu bem! 👵✨\nMe diz do que você está precisando agora que a Vó busca nas prateleiras pra você!',
          'products': null,
          'addedToCart': false,
        });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleUserMessage(String text) async {
    final userText = text.trim();
    if (userText.isEmpty || _isThinking) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': userText,
        'products': null,
        'addedToCart': false,
      });
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();

    String responseText = '';
    List<Map<String, dynamic>>? suggestedProducts;

    try {
      final urlsToTry = <String>[
        if (CatalogApiService.baseUrl.isNotEmpty) CatalogApiService.baseUrl,
        ...CatalogApiService.candidateUrls,
      ].toSet().toList();

      http.Response? res;
      String activeBase = CatalogApiService.baseUrl;

      for (final candidate in urlsToTry) {
        try {
          final url = Uri.parse('$candidate/api/marketplace/ia-shopper');
          final attempt = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'message': userText,
                  'history': _apiHistory,
                }),
              )
              .timeout(const Duration(seconds: 25));

          if (attempt.statusCode == 200) {
            res = attempt;
            activeBase = candidate;
            CatalogApiService.baseUrl = candidate;
            break;
          }
          res ??= attempt;
        } catch (_) {}
      }

      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        responseText = data['reply'] ?? 'Prontinho meu bem!';
        if (data['contents'] != null) {
          _apiHistory = List<dynamic>.from(data['contents']);
        }

        final prods = data['produtos'] as List<dynamic>?;
        if (prods != null && prods.isNotEmpty) {
          suggestedProducts = prods.map((p) {
            final id = p['id'].toString();
            final nome = p['nome']?.toString() ?? 'Produto';
            final preco = double.tryParse(p['preco']?.toString() ?? '0') ?? 0.0;
            final fotoUrl = p['foto_url'] != null ? '$activeBase${p['foto_url']}' : '';
            final categoria = p['categoria']?.toString() ?? 'Geral';
            final unidade = p['unidade']?.toString().toUpperCase() ?? 'UN';
            final isKg = unidade == 'KG';
            final qty = double.tryParse(p['quantidade']?.toString() ?? '1') ?? 1.0;
            final note = p['observacao']?.toString();

            final model = ProductModel(
              id: id,
              name: nome,
              description: categoria,
              barcode: p['ean']?.toString() ?? '',
              salePrice: preco,
              clubPrice: preco,
              categoryId: categoria,
              unit: unidade,
              weighable: isKg,
              imageUrl: fotoUrl,
            );

            return <String, dynamic>{
              'model': model,
              'qty': qty,
              'note': note,
              'selected': true,
            };
          }).toList();
        }
      } else {
        responseText =
            'Eita meu bem, a vovó teve uma instabilidade rápida (${res?.statusCode ?? "offline"}). Pode me perguntar de novo?';
      }
    } catch (e) {
      responseText =
          'Desculpe meu amor, não consegui falar com o servidor do mercadinho agora. Verifique se o servidor está rodando!';
    }

    if (!mounted) return;

    setState(() {
      _isThinking = false;
      _messages.add({
        'isUser': false,
        'text': responseText,
        'products': suggestedProducts,
        'addedToCart': false,
      });
    });
    _scrollToBottom();
  }

  void _adjustSuggestedItemQty(Map<String, dynamic> item, int direction) {
    final prod = item['model'] as ProductModel;
    final currentQty = (item['qty'] as num).toDouble();
    final step = prod.weighable ? 0.100 : 1.0;
    final nextQty = double.parse((currentQty + (direction * step)).toStringAsFixed(3));

    setState(() {
      if (nextQty <= 0) {
        item['selected'] = false;
        item['qty'] = prod.weighable ? 0.100 : 1.0;
      } else {
        item['selected'] = true;
        item['qty'] = nextQty;
      }
    });
  }

  void _addSuggestedListToCart(
    Map<String, dynamic> msg,
    List<Map<String, dynamic>> items,
    CartController cart,
  ) {
    final selectedItems = items.where((i) => i['selected'] != false).toList();
    if (selectedItems.isEmpty) return;

    for (final item in selectedItems) {
      final product = item['model'] as ProductModel;
      final qty = (item['qty'] as num).toDouble();
      final note = item['note'] as String?;
      cart.addProduct(product, quantity: qty, observation: note);
    }

    setState(() {
      msg['addedToCart'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${selectedItems.length} itens da Cesta da Vó adicionados ao carrinho!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'ABRIR CARRINHO',
          textColor: AppColors.secondaryLight,
          onPressed: _openCart,
        ),
      ),
    );
  }

  void _openCart() {
    if (widget.isEmbeddedTab && widget.onNavigateTab != null) {
      widget.onNavigateTab!(2);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CartPage()),
      );
    }
  }

  /// Renderiza texto com suporte a **negrito** e listas limpas
  Widget _buildFormattedText(String rawText, {required bool isUser}) {
    final cleaned = rawText
        .replaceAllMapped(RegExp(r'^\s*[\*\-]\s+', multiLine: true), (_) => '• ')
        .trim();

    final baseStyle = AppTypography.body.copyWith(
      fontSize: 13.5,
      color: isUser ? Colors.white : AppColors.textPrimary,
      height: 1.48,
    );

    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: isUser ? Colors.white : const Color(0xFF064E3B),
    );

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(cleaned)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: cleaned.substring(lastEnd, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastEnd = match.end;
    }
    if (lastEnd < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(lastEnd), style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      body: Column(
        children: [
          // 1. HEADER PREMIUM "CASA DE VÓ"
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                    child: Row(
                      children: [
                        if (!widget.isEmbeddedTab)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        // Avatar da Vó com anel dourado e indicador online
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text('👵', style: TextStyle(fontSize: 26)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF064E3B), width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Título e Subtítulo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Vó do Mercadinho',
                                      style: AppTypography.heading2.copyWith(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                                    ),
                                    child: const Text(
                                      '✨ IA AO VIVO',
                                      style: TextStyle(
                                        color: Color(0xFFFEF3C7),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estoque real • Preços e receitas na ponta do lápis',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFFD1FAE5),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Botão limpar conversa
                        IconButton(
                          tooltip: 'Nova Conversa',
                          onPressed: _resetConversation,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                        ),
                        // Atalho do Carrinho com total em tempo real
                        if (cart.itemCount > 0)
                          InkWell(
                            onTap: _openCart,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_cart_rounded, color: Color(0xFFFDE68A), size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 2. CARROSSEL DE SUGESTÕES RÁPIDAS (CHIPS ESTILIZADOS)
                  Container(
                    height: 46,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickPrompts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _quickPrompts[index];
                        return Material(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _handleUserMessage(item.prompt),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.22)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. ÁREA DE MENSAGENS DO CHAT
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true;
                final products = msg['products'] as List<Map<String, dynamic>>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(
                              width: 34,
                              height: 34,
                              margin: const EdgeInsets.only(right: 8, top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFEF3C7),
                                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                              ),
                              alignment: Alignment.center,
                              child: const Text('👵', style: TextStyle(fontSize: 18)),
                            ),
                          ],
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.80,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                gradient: isUser
                                    ? const LinearGradient(
                                        colors: [Color(0xFF059669), Color(0xFF047857)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isUser ? null : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isUser ? 18 : 4),
                                  topRight: Radius.circular(isUser ? 4 : 18),
                                  bottomLeft: const Radius.circular(18),
                                  bottomRight: const Radius.circular(18),
                                ),
                                border: isUser
                                    ? null
                                    : Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Vó do Mercadinho',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, color: AppColors.primary, size: 13),
                                        ],
                                      ),
                                    ),
                                  _buildFormattedText(msg['text'] as String, isUser: isUser),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 4. CARD DE CESTA INTERATIVA MONTADA PELA VÓ
                      if (products != null && products.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.only(left: isUser ? 0 : 42),
                          child: _buildInteractiveBasketCard(msg, products, cart),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // 5. INDICADOR DE DIGITAÇÃO DA VÓ
          if (_isThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('👵', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A Vó está olhando as prateleiras e fazendo a conta...',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 6. BARRA DE ENTRADA MODERNA
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _handleUserMessage,
                              style: AppTypography.body.copyWith(fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'Peça uma receita, lista ou diga quanto quer gastar...',
                                hintStyle: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12.5,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _handleUserMessage(_inputController.text),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40059669),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildInteractiveBasketCard(
    Map<String, dynamic> msg,
    List<Map<String, dynamic>> products,
    CartController cart,
  ) {
    final selectedProducts = products.where((p) => p['selected'] != false).toList();
    final basketTotal = selectedProducts.fold<double>(
      0.0,
      (acc, item) => acc + ((item['model'] as ProductModel).price * (item['qty'] as num).toDouble()),
    );
    final bool alreadyAdded = msg['addedToCart'] == true;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo da Cesta da Vó
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cesta Separada pela Vó',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF064E3B),
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        'Você pode ajustar as quantidades antes de levar',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF047857),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    CurrencyFormatter.formatReal(basketTotal),
                    style: const TextStyle(
                      color: Color(0xFFFEF3C7),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Itens da Cesta
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              children: products.map((p) {
                final prod = p['model'] as ProductModel;
                final qty = (p['qty'] as num).toDouble();
                final note = p['note'] as String?;
                final isSelected = p['selected'] != false;
                final itemTotal = isSelected ? prod.price * qty : 0.0;
                final qtyFormatted = prod.weighable
                    ? '${CurrencyFormatter.formatWeight(qty)} kg'
                    : '${qty.toInt()} un';

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.45,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE2E8F0) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Foto Oficial do Produto (ou Ícone)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              p['selected'] = !isSelected;
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: prod.imageUrl.isNotEmpty
                                    ? Image.network(
                                        prod.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 22,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 22,
                                        color: AppColors.primary,
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(9),
                                      bottomRight: Radius.circular(6),
                                    ),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.remove,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Nome, Preço Unitário e Nota da Vó
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.title,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  decoration: isSelected ? null : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.formatReal(prod.price)} / ${prod.unit.toLowerCase()}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (note != null && note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    note,
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.primaryDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Controles de Quantidade (- / +) e Subtotal
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatReal(itemTotal),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isSelected ? const Color(0xFF064E3B) : AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _adjustSuggestedItemQty(p, -1),
                                    borderRadius: BorderRadius.circular(16),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      child: Icon(Icons.remove, size: 13, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      qtyFormatted,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _adjustSuggestedItemQty(p, 1),
                                    borderRadius: BorderRadius.circular(16),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      child: Icon(Icons.add, size: 13, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Botão Principal de Ação
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: selectedProducts.isEmpty
                    ? null
                    : () => _addSuggestedListToCart(msg, products, cart),
                icon: Icon(
                  alreadyAdded ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                label: Text(
                  alreadyAdded
                      ? 'Adicionado! Adicionar novamente (${CurrencyFormatter.formatReal(basketTotal)})'
                      : 'Adicionar Cesta ao Carrinho • ${CurrencyFormatter.formatReal(basketTotal)}',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyAdded ? const Color(0xFF047857) : AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
