import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/data/mock_catalog_data.dart';

class CheckinQrCodePage extends StatefulWidget {
  final bool isEmbeddedTab;

  const CheckinQrCodePage({super.key, this.isEmbeddedTab = false});

  @override
  State<CheckinQrCodePage> createState() => _CheckinQrCodePageState();
}

class _CheckinQrCodePageState extends State<CheckinQrCodePage> {
  bool _isCheckingIn = false;

  Future<void> _doCheckIn(AppStateController appState) async {
    setState(() => _isCheckingIn = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    appState.performStoreCheckIn();
    setState(() => _isCheckingIn = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in confirmado! Você ganhou +50 Pontos, +1 Nº da Sorte e destravou ofertas de loja!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    final cart = context.watch<CartController>();
    final checkInProducts = MockCatalogData.products
        .where((p) => p.checkInOnly || p.clubPrice != null)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedTab,
        title: const Text('Meu QR Code & Check-in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cartão Digital de Identificação no Caixa (QrcodeModule)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARTÃO CLUBE QUEIRA MAIS',
                            style: TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'CPF: ${appState.userCpf}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${appState.pointsBalance} pts',
                          style: const TextStyle(
                            color: Color(0xFFFDE047),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bloco Branco do QR Code para Leitura no Caixa / Totem
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 130,
                          width: 130,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 130, color: Color(0xFF111827)),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Lottie.asset(
                                    'assets/animation/loading_qrcode_flutter.json',
                                    repeat: true,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Apresente este QR Code ao operador de caixa\npara ativar descontos, cashback e cupom verde',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Card de Check-in Presencial na Loja (`mutation_checkin.graphql`)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: appState.isCheckedInStore ? AppColors.success : AppColors.secondary,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: appState.isCheckedInStore
                            ? AppColors.primaryLight
                            : AppColors.secondaryLight,
                        child: Icon(
                          appState.isCheckedInStore ? Icons.verified_rounded : Icons.where_to_vote_outlined,
                          color: appState.isCheckedInStore ? AppColors.primaryDark : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.isCheckedInStore
                                  ? 'Check-in Realizado na Loja!'
                                  : 'Você está no ${appState.selectedStoreName}?',
                              style: AppTypography.heading3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.isCheckedInStore
                                  ? 'Suas ofertas presenciais de check-in e +50 pontos já estão liberados hoje.'
                                  : 'Faça check-in ao entrar na loja para ganhar +50 pts, +1 Nº da Sorte e destravar preços secretos!',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: appState.isCheckedInStore || _isCheckingIn
                          ? null
                          : () => _doCheckIn(appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appState.isCheckedInStore ? AppColors.success : AppColors.secondary,
                      ),
                      icon: _isCheckingIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(appState.isCheckedInStore ? Icons.check_circle : Icons.pin_drop_outlined),
                      label: Text(
                        appState.isCheckedInStore
                            ? 'Check-in Ativo Hoje ✓'
                            : 'Fazer Check-in Agora (+50 pts)',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ofertas Exclusivas de Check-in (`query_app_carousels.graphql` -> `check_in: true`)
            const Text('🔥 Ofertas Destravadas no Check-in da Loja', style: AppTypography.heading2),
            const SizedBox(height: 4),
            const Text(
              'Ative no seu CPF antes de passar no caixa ou adicione ao pedido:',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),

            ...checkInProducts.map((product) {
              final isLocked = product.checkInOnly && !appState.isCheckedInStore;
              final isActivated = cart.isDiscountActivated(product.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceElevated,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: AppTypography.heading3.copyWith(fontSize: 13)),
                          Text(
                            'De ${CurrencyFormatter.format(product.salePrice)} por ${CurrencyFormatter.format(product.activePrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLocked
                          ? () => _doCheckIn(appState)
                          : () => cart.toggleDiscountActivation(product.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked
                            ? AppColors.secondary
                            : (isActivated ? AppColors.success : AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        isLocked ? 'Check-in' : (isActivated ? 'Ativo ✓' : 'Ativar'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
