import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class GreenCouponStatsPage extends StatelessWidget {
  const GreenCouponStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    final ecoMetrics = [
      {
        'icon': 'assets/images/drop-water-icon.svg',
        'value': '14,8 Litros',
        'label': 'Água economizada na fabricação de papel térmico',
      },
      {
        'icon': 'assets/images/co2-icon.svg',
        'value': '620g de CO₂',
        'label': 'Emissões de gás carbônico evitadas',
      },
      {
        'icon': 'assets/images/leaf-icon.svg',
        'value': '38 Cupons',
        'label': 'Notas fiscais digitais sem impressão em papel',
      },
      {
        'icon': 'assets/images/petroleum-icon.svg',
        'value': '190 ml',
        'label': 'Derivados de petróleo poupados na logística',
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Cupom Verde & Economiômetro'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Economiômetro do Clube'),
              Tab(text: 'Cupom Verde (Sustentável)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEconomyStatsTab(appState),
            _buildGreenCouponTab(context, appState, ecoMetrics),
          ],
        ),
      ),
    );
  }

  // Aba 1: Economiômetro (`ConsumptionStatisticPage` & `query_list_shops.graphql`)
  Widget _buildEconomyStatsTab(AppStateController appState) {
    final monthlySavings = [
      {'month': 'Novembro / 2026', 'saved': 68.40, 'spent': 412.90},
      {'month': 'Outubro / 2026', 'saved': 142.10, 'spent': 890.50},
      {'month': 'Setembro / 2026', 'saved': 134.80, 'spent': 780.20},
      {'month': 'Agosto / 2026', 'saved': 137.60, 'spent': 810.00},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ECONOMIÔMETRO ACUMULADO NO CLUBE',
                style: TextStyle(color: Color(0xFFFDE047), fontSize: 10, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(appState.economyTotal),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total que você deixou de pagar graças aos descontos exclusivos do Clube Queira Mais e Cashback!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Histórico Mensal de Economia (list_shops)', style: AppTypography.heading2),
        const SizedBox(height: 10),
        ...monthlySavings.map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['month'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Total em compras: ${CurrencyFormatter.format(m['spent'] as double)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Economizou ${CurrencyFormatter.format(m['saved'] as double)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Aba 2: Cupom Verde (`query_green_coupon_integration.graphql` & `mutation_greenCouponReceiptFlag.graphql`)
  Widget _buildGreenCouponTab(
    BuildContext context,
    AppStateController appState,
    List<Map<String, String>> ecoMetrics,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/icon-cupon-verde.svg',
                width: 42,
                height: 42,
                placeholderBuilder: (_) => const Icon(Icons.eco, color: AppColors.primary, size: 40),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receber Apenas Cupom Digital (Cupom Verde)', style: AppTypography.heading3),
                    Text(
                      'Dispense a impressão em papel térmico no caixa e ajude o meio ambiente.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: appState.greenCouponEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => appState.setGreenCoupon(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Seu Impacto Ambiental Positivo', style: AppTypography.heading2),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: ecoMetrics.length,
          itemBuilder: (context, idx) {
            final item = ecoMetrics[idx];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    item['icon']!,
                    width: 28,
                    height: 28,
                    placeholderBuilder: (_) => const Icon(Icons.eco, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['value']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item['label']!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

