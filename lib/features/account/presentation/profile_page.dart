import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../ai_shopper/presentation/ai_personal_shopper_page.dart';
import '../../auth/presentation/address_list_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../catalog/presentation/favorites_page.dart';
import '../../checkout/presentation/client_cards_page.dart';
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
import '../../orders/presentation/orders_page.dart';
import '../../store/presentation/store_selection_page.dart';
import 'crediario_digital_page.dart';
import 'fiscal_receipt_page.dart';
import 'help_support_privacy_page.dart';
import 'notifications_settings_page.dart';
import 'personal_info_crm_page.dart';

class ProfilePage extends StatelessWidget {
  final bool isEmbeddedTab;

  const ProfilePage({super.key, this.isEmbeddedTab = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !isEmbeddedTab,
        title: const Text('Menu & Minha Conta'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, size: 36, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appState.userName, style: AppTypography.heading2),
                        const SizedBox(height: 2),
                        Text(
                          '${appState.isCnpj ? "CNPJ" : "CPF"}: ${appState.userDocument}',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⭐ Clube Queira Mais VIP',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Economia: ${CurrencyFormatter.format(appState.economiometroTotal)}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoCrmPage()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card Destacado: Crediário Próprio (Inovação 14.1)
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CrediarioDigitalPage()));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 20,
                      child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meu Crediário / Caderninho Digital',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Limite disponível: R\$ 415,50 • Quitação via PIX',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Compras, Pagamentos & ERP', style: AppTypography.heading3),
            const SizedBox(height: 8),

            // Bloco 1: Compras, Cartões e Inovações ERP
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Meus Pedidos & Separação',
                subtitle: 'Acompanhamento de peso, entregador e recompra',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())),
              ),
              _buildMenuItem(
                icon: Icons.credit_card_rounded,
                title: 'Meus Cartões (ClientCardsPage)',
                subtitle: '${appState.clientCards.length} cartões salvos com identificação BIN',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCardsPage())),
              ),
              _buildMenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Meus Produtos Favoritos',
                subtitle: '${appState.favoriteProductIds.length} itens salvos para compra rápida',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
              ),
              _buildMenuItem(
                icon: Icons.auto_awesome,
                title: 'Personal Shopper com IA',
                subtitle: 'Planeje receitas e monte compras com 1 clique',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPersonalShopperPage())),
              ),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Cupons Fiscais (NFC-e do PDV)',
                subtitle: 'Espelhamento digital de compras na loja física',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FiscalReceiptPage())),
              ),
            ]),

            const SizedBox(height: 20),
            const Text('Clube Queira Mais & Gamificação', style: AppTypography.heading3),
            const SizedBox(height: 8),

            // Bloco 2: Todos os Módulos do Clube Queira Mais
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.qr_code_2_rounded,
                title: 'Cartão Digital & Check-in QR Code',
                subtitle: 'Identifique-se no caixa ou totem da loja',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinQrCodePage())),
              ),
              _buildMenuItem(
                icon: Icons.monetization_on_outlined,
                title: 'Cashback, Pontos, Transferência & Vales',
                subtitle: 'Saldo: ${CurrencyFormatter.format(appState.cashbackBalance)} • ${appState.pointsBalance} pts',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsCashbackPage())),
              ),
              _buildMenuItem(
                icon: Icons.stars_rounded,
                title: 'Raspadinhas Premiada (ScratchCard)',
                subtitle: '${appState.pendingScratchCards.length} raspadinhas disponíveis para raspar',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScratchCardPage())),
              ),
              _buildMenuItem(
                icon: Icons.local_activity_outlined,
                title: 'Sorteios & Números da Sorte (Raffles)',
                subtitle: '${appState.raffleTicketsCount} bilhetes concorrendo',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RafflesPage())),
              ),
              _buildMenuItem(
                icon: Icons.emoji_events_outlined,
                title: 'Jornada de Missões do Mês',
                subtitle: 'Complete metas nos departamentos e ganhe bônus',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsJourneyPage())),
              ),
              _buildMenuItem(
                icon: Icons.eco_outlined,
                title: 'Economiômetro & Cupom Verde',
                subtitle: 'Sustentabilidade ecológica (Água, CO₂, Árvores)',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GreenCouponStatsPage())),
              ),
              _buildMenuItem(
                icon: Icons.sports_soccer_rounded,
                title: 'Bolão / Palpite Premiado (SportsBet)',
                subtitle: 'Dê seus palpites nos jogos da rodada',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SportsBetPage())),
              ),
              _buildMenuItem(
                icon: Icons.group_add_outlined,
                title: 'Indique um Amigo (friend_code)',
                subtitle: 'Código: ${appState.referralCode} • Ganhe +200 pts',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendReferralPage())),
              ),
              _buildMenuItem(
                icon: Icons.confirmation_number_outlined,
                title: 'Carteira de Cupons de Desconto',
                subtitle: 'Ative descontos exclusivos por CPF',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsPage())),
              ),
              _buildMenuItem(
                icon: Icons.rate_review_outlined,
                title: 'Pesquisa de Satisfação (Survey)',
                subtitle: 'Avalie a loja e ganhe +100 pontos no Clube',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SatisfactionSurveyPage())),
              ),
            ]),

            const SizedBox(height: 20),
            const Text('Cadastro, Lojas, Suporte & LGPD', style: AppTypography.heading3),
            const SizedBox(height: 8),

            // Bloco 3: Conta, Endereços, Notificações e LGPD
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.badge_outlined,
                title: 'Dados Pessoais, Senha & Perfil CRM',
                subtitle: 'E-mail verificado, profissão, renda e dependentes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoCrmPage())),
              ),
              _buildMenuItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notificações Push & Preferências Opt-in',
                subtitle: 'Gerencie alertas de WhatsApp, SMS, Push e E-mail',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsPage())),
              ),
              _buildMenuItem(
                icon: Icons.storefront_outlined,
                title: 'Nossas Lojas & Loja Favorita',
                subtitle: 'Queiroz Atacadão - Matriz Centro',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSelectionPage())),
              ),
              _buildMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Meus Endereços de Entrega',
                subtitle: 'Casa, Trabalho e consulta por CEP',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListPage())),
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Central de Ajuda, FAQ, Trocas e LGPD',
                subtitle: 'Dúvidas, Fale Conosco, Relatório de Dados e Exclusão',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPrivacyPage())),
              ),
            ]),

            const SizedBox(height: 24),

            // Botão Sair
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.exit_to_app, color: AppColors.danger),
                label: const Text(
                  'Sair da Conta',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    final List<Widget> separated = [];
    for (int i = 0; i < items.length; i++) {
      separated.add(items[i]);
      if (i < items.length - 1) {
        separated.add(const Divider(height: 1));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: separated),
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceElevated,
        radius: 18,
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title, style: AppTypography.heading3.copyWith(fontSize: 13.5)),
      subtitle: Text(subtitle, style: AppTypography.caption),
      trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
