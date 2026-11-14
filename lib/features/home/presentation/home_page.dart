import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../account/presentation/crediario_digital_page.dart';
import '../../account/presentation/notifications_settings_page.dart';
import '../../account/presentation/profile_page.dart';
import '../../ai_shopper/presentation/ai_personal_shopper_page.dart';
import '../../auth/presentation/address_list_page.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../../catalog/data/mock_catalog_data.dart';
import '../../catalog/domain/models/category_model.dart';
import '../../catalog/domain/models/product_model.dart';
import '../../catalog/presentation/categories_page.dart';
import '../../catalog/presentation/favorites_page.dart';
import '../../catalog/presentation/product_details_page.dart';
import '../../catalog/presentation/scanner_page.dart';
import '../../catalog/presentation/search_page.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../flyer/presentation/folheto_page.dart';
import '../../loyalty/presentation/checkin_qrcode_page.dart';
import '../../loyalty/presentation/coupons_page.dart';
import '../../loyalty/presentation/friend_referral_page.dart';
import '../../loyalty/presentation/green_coupon_stats_page.dart';
import '../../loyalty/presentation/missions_journey_page.dart';
import '../../loyalty/presentation/points_cashback_page.dart';
import '../../loyalty/presentation/raffles_page.dart';
import '../../loyalty/presentation/satisfaction_survey_page.dart';
import '../../loyalty/presentation/scratch_card_page.dart';
import '../../loyalty/presentation/sports_bet_page.dart';
import '../../orders/presentation/order_tracking_page.dart';
import '../../store/presentation/store_selection_page.dart';

class HomePage extends StatefulWidget {
  final bool isEmbeddedTab;
  final ValueChanged<int>? onNavigateTab;

  const HomePage({
    super.key,
    this.isEmbeddedTab = false,
    this.onNavigateTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  bool _isSyncingErp = false;

  @override
  void initState() {
    super.initState();
    _syncCatalogFromErp();
  }

  Future<void> _syncCatalogFromErp() async {
    if (_isSyncingErp) return;
    setState(() => _isSyncingErp = true);
    final payload = await CatalogApiService.syncWithErp();
    if (!mounted) return;
    setState(() => _isSyncingErp = false);
    if (payload != null) {
      context.read<AppStateController>().selectedStoreName = payload.storeName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, appState),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de Busca com Atalho para Scanner de Gôndola e Favoritos
            _buildSearchBar(context, appState),

            // Status de Sincronismo em Tempo Real com o Banco do ERP (`CLIPP.FDB`)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: InkWell(
                onTap: _syncCatalogFromErp,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CatalogApiService.isConnectedToErp
                        ? const Color(0xFFECFDF5)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CatalogApiService.isConnectedToErp
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CatalogApiService.isConnectedToErp ? Icons.cloud_done_rounded : Icons.sync_rounded,
                        size: 16,
                        color: CatalogApiService.isConnectedToErp ? const Color(0xFF059669) : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isSyncingErp
                              ? 'Sincronizando catálogo em tempo real com o ERP...'
                              : CatalogApiService.isConnectedToErp
                                  ? 'Catálogo ERP Ativo • ${CatalogApiService.totalErpProductsCount} produtos sincronizados'
                                  : 'Modo Catálogo Local • Toque para conectar ao servidor ERP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CatalogApiService.isConnectedToErp
                                ? const Color(0xFF065F46)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF059669)),
                    ],
                  ),
                ),
              ),
            ),

            // Barra de Contadores do Clube (`app_home_counters_order`: Economiômetro, Cashback, Pontos, Raspadinhas, QR)
            _buildClubCountersBar(context, appState),

            // Banner de Pedido em Andamento (`hasOrderInProgress`)
            if (appState.hasOrderInProgress && appState.activeOrders.isNotEmpty)
              _buildActiveOrderBanner(context, appState),

            // Carrossel de Banner Promocional (Jornal de Ofertas)
            _buildPromotionalBanner(context),

            // Card Destaque: Personal Shopper com IA (Inovação 14.3)
            _buildAiShopperCard(context),

            // Atalhos Rápidos Principais (Jornal, Crediário, Raspadinha, Leitor)
            _buildQuickActions(context),

            // Hub de Gamificação & Fidelidade Clube Queira Mais
            _buildClubEcosystemSection(context, appState),

            // Régua de Departamentos / Categorias
            _buildCategorySection(context),

            const SizedBox(height: 16),

            // Seção "Ofertas do Clube"
            _buildProductCarousel(
              context: context,
              title: '⭐ Ofertas Exclusivas do Clube',
              subtitle: 'Preços especiais ativados pelo seu CPF/CNPJ',
              products: MockCatalogData.clubOffers.take(16).toList(),
            ),

            const SizedBox(height: 16),

            // Seção "Hortifrúti & Feirinha"
            _buildProductCarousel(
              context: context,
              title: '🥬 Feirinha, Laticínios & Fresquinhos',
              subtitle: 'Itens selecionados direto do estoque da loja',
              products: MockCatalogData.weighableHighlights.take(16).toList(),
            ),

            const SizedBox(height: 16),

            // Seção "Destaques do Estoque ERP"
            _buildProductCarousel(
              context: context,
              title: '📦 Mais Procurados no Mercadinho',
              subtitle: 'Catálogo completo sincronizado com o caixa',
              products: MockCatalogData.products.take(20).toList(),
            ),

            // Banner de Pesquisa Rápida Pós-Compra
            if (!appState.surveySubmitted) _buildSurveyBanner(context),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: widget.isEmbeddedTab ? null : _buildBottomNav(context),
      floatingActionButton: widget.isEmbeddedTab ? null : _buildCartFab(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppStateController appState) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSelectionPage()));
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, color: AppColors.primaryDark, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSelectionPage()));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Queiroz Atacadão • Matriz', style: AppTypography.heading3),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressListPage(selectMode: true)),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: AppColors.primary),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          'Entregar em: Av. José Inácio, 450',
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: 'Meus Favoritos',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notificações',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()),
                );
              },
            ),
            if (appState.unreadNotificationsCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildClubCountersBar(BuildContext context, AppStateController appState) {
    return Container(
      height: 76,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCounterPill(
            icon: Icons.savings_outlined,
            title: 'Economiômetro',
            value: CurrencyFormatter.format(appState.economiometroTotal),
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GreenCouponStatsPage()));
            },
          ),
          const SizedBox(width: 8),
          _buildCounterPill(
            icon: Icons.monetization_on_outlined,
            title: 'Saldo Cashback',
            value: CurrencyFormatter.format(appState.cashbackBalance),
            color: const Color(0xFFB45309),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsCashbackPage(initialTabIndex: 0)));
            },
          ),
          const SizedBox(width: 8),
          _buildCounterPill(
            icon: Icons.stars_rounded,
            title: 'Meus Pontos',
            value: '${appState.pointsBalance} pts',
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsCashbackPage(initialTabIndex: 2)));
            },
          ),
          const SizedBox(width: 8),
          _buildCounterPill(
            icon: Icons.auto_awesome,
            title: 'Raspadinhas',
            value: '${appState.pendingScratchCards.length} pendentes',
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScratchCardPage()));
            },
          ),
          const SizedBox(width: 8),
          _buildCounterPill(
            icon: Icons.qr_code_2_rounded,
            title: 'Check-in Loja',
            value: appState.isCheckedInStore ? 'Ativo' : 'Identificar',
            color: const Color(0xFF0284C7),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinQrCodePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterPill({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withAlpha(28),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderBanner(BuildContext context, AppStateController appState) {
    final activeOrder = appState.activeOrders.first;
    final bool needsApproval = activeOrder.needsClientApproval && !activeOrder.clientApprovedChanges;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: needsApproval ? AppColors.warningLight : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: needsApproval ? AppColors.warning : AppColors.primary,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingPage(order: activeOrder)),
          );
        },
        child: Row(
          children: [
            Icon(
              needsApproval ? Icons.scale_rounded : Icons.local_shipping_outlined,
              color: needsApproval ? AppColors.warning : AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${activeOrder.code} • ${activeOrder.statusLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: needsApproval ? const Color(0xFF92400E) : AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    needsApproval
                        ? 'Diferença de pesagem aguarda sua aprovação! Toque para conferir.'
                        : 'Separador: ${activeOrder.separatorName} • Toque para acompanhar.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildAiShopperCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (widget.onNavigateTab != null) {
            widget.onNavigateTab!(3);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPersonalShopperPage()));
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Personal Shopper com IA',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Novo',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Peça receitas, churrasco ou lista do mês calculados na hora.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppStateController appState) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Buscar produtos, marcas ou departamentos...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScannerPage(mode: ScannerMode.searchOnly),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Tooltip(
              message: 'Procurar item por código de barras',
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(1);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FolhetoPage()));
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB91C1C).withAlpha(55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.newspaper_rounded, size: 140, color: Colors.white.withAlpha(30)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'JORNAL DE OFERTAS',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Toque nas Ofertas para Comprar',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tabloide Impresso Interativo\nEspecial Fim de Semana e Hortifruti',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionTile(
              icon: Icons.newspaper_rounded,
              label: 'Jornal de\nOfertas',
              badge: 'Tabloide',
              color: const Color(0xFFDC2626),
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FolhetoPage()));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Crediário\nDigital',
              badge: 'Ativo',
              color: AppColors.primary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CrediarioDigitalPage()));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionTile(
              icon: Icons.stars_rounded,
              label: 'Raspadinha\ndo Clube',
              badge: 'Raspar',
              color: AppColors.secondary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScratchCardPage()));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionTile(
              icon: Icons.confirmation_number_outlined,
              label: 'Meus\nCupons',
              badge: 'Ativar',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsPage()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubEcosystemSection(BuildContext context, AppStateController appState) {
    final clubItems = [
      {
        'icon': Icons.emoji_events_outlined,
        'title': 'Missões do Mês',
        'sub': 'Ganhe Cashback',
        'color': const Color(0xFFD97706),
        'page': const MissionsJourneyPage(),
      },
      {
        'icon': Icons.local_activity_outlined,
        'title': 'Sorteios & Séries',
        'sub': '${appState.raffleTicketsCount} números',
        'color': const Color(0xFF7C3AED),
        'page': const RafflesPage(),
      },
      {
        'icon': Icons.sports_soccer_rounded,
        'title': 'Palpite Premiado',
        'sub': 'Bolão do Clube',
        'color': const Color(0xFF047857),
        'page': const SportsBetPage(),
      },
      {
        'icon': Icons.eco_outlined,
        'title': 'Cupom Verde',
        'sub': 'Sustentabilidade',
        'color': const Color(0xFF059669),
        'page': const GreenCouponStatsPage(),
      },
      {
        'icon': Icons.group_add_outlined,
        'title': 'Indique e Ganhe',
        'sub': '+200 pts/amigo',
        'color': const Color(0xFF0284C7),
        'page': const FriendReferralPage(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Text('Benefícios & Jogos do Clube Queira Mais', style: AppTypography.heading3),
        ),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: clubItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = clubItems[index];
              final color = item['color'] as Color;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['page'] as Widget),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withAlpha(25),
                        child: Icon(item['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item['sub'] as String,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review_outlined, color: AppColors.secondary, size: 26),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avalie sua última compra e ganhe +100 pts!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Responda nossa pesquisa rápida de satisfação (NPS).',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SatisfactionSurveyPage()),
              );
            },
            child: const Text('Avaliar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    String? badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  radius: 16,
                  child: Icon(icon, size: 18, color: color),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Departamentos', style: AppTypography.heading2),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
                },
                child: const Text(
                  'Ver todos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: MockCatalogData.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final CategoryModel category = MockCatalogData.categories[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoriesPage(initialCategoryId: category.id)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(category.id),
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(category.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String id) {
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

  Widget _buildProductCarousel({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<ProductModel> products,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heading2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
                },
                child: const Text(
                  'Ver todos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 256,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
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
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FolhetoPage()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPersonalShopperPage()));
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper_rounded), label: 'Jornal'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart_rounded), label: 'Carrinho'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Personal IA'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
      ],
    );
  }

  Widget _buildCartFab(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, cart, _) {
        if (cart.items.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Row(
            children: [
              Text(
                '${cart.itemCount} itens  |  ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                'R\$ ${cart.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
