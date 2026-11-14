import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RafflesPage extends StatelessWidget {
  const RafflesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Sorteios & Números da Sorte'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Sorteios Ativos'),
              Tab(text: 'Meus Números'),
              Tab(text: 'Ganhadores'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveRafflesTab(context, appState),
            _buildMyCouponsTab(appState),
            _buildWinnersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRafflesTab(BuildContext context, AppStateController appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.secondary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SORTEIO VIGENTE (pending_raffles)',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'Você tem ${appState.raffleVouchersCount} cupons!',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Show de Prêmios Aniversário do Mercadinho: 1 Moto 0km + 10 Carrinhos Cheios',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 6),
              const Text(
                'Período: 01/10/2026 a 20/12/2026 • Sorteio pela Loteria Federal em 24/12/2026',
                style: AppTypography.caption,
              ),
              const Divider(height: 24),
              const Text(
                'Regra (raffle_detail): A cada R\$ 50,00 em compras identificadas com seu CPF no caixa ou pelo aplicativo, você recebe automaticamente 1 Número da Sorte.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyCouponsTab(AppStateController appState) {
    final coupons = [
      {
        'shopId': '#8942',
        'date': '05/11/2026',
        'value': 'R\$ 129,08',
        'numbers': ['Série 04 • Nº 84920', 'Série 04 • Nº 84921', 'Série 04 • Nº 84922'],
      },
      {
        'shopId': '#7721',
        'date': '01/11/2026',
        'value': 'R\$ 98,40',
        'numbers': ['Série 04 • Nº 61204', 'Série 04 • Nº 61205'],
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Seus Números da Sorte por Compra (raffle_coupon_sortables)', style: AppTypography.heading3),
        const SizedBox(height: 12),
        ...coupons.map((c) {
          final nums = c['numbers'] as List<String>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Compra ${c['shopId']} em ${c['date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(c['value'] as String, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: nums
                      .map(
                        (n) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            n,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWinnersTab() {
    final winners = [
      {'name': 'Maria de Fátima S.', 'number': 'Série 02 • Nº 31948', 'prize': 'Vale-Compras R\$ 1.000,00'},
      {'name': 'João Batista O.', 'number': 'Série 02 • Nº 10492', 'prize': 'Smart TV 55" 4K'},
      {'name': 'Francisca Tereza L.', 'number': 'Série 01 • Nº 88310', 'prize': '1 Ano de Supermercado Grátis'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: winners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final w = winners[idx];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          leading: const CircleAvatar(
            backgroundColor: AppColors.secondaryLight,
            child: Icon(Icons.emoji_events, color: AppColors.secondary),
          ),
          title: Text(w['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${w['prize']}\nBilhete Premiado: ${w['number']}'),
          isThreeLine: true,
        );
      },
    );
  }
}

