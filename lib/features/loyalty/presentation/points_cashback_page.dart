import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';

class PointsCashbackPage extends StatefulWidget {
  final int initialTabIndex;

  const PointsCashbackPage({super.key, this.initialTabIndex = 0});

  @override
  State<PointsCashbackPage> createState() => _PointsCashbackPageState();
}

class _PointsCashbackPageState extends State<PointsCashbackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _transferCpfController = TextEditingController();
  final TextEditingController _transferAmountController = TextEditingController();
  final TextEditingController _transferPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transferCpfController.dispose();
    _transferAmountController.dispose();
    _transferPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pontos, Cashback & Vales'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Cashback'),
            Tab(text: 'Transferir Saldo'),
            Tab(text: 'Meus Pontos'),
            Tab(text: 'Vales-Compra'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCashbackTab(appState),
          _buildTransferBalanceTab(appState),
          _buildPointsTab(appState),
          _buildGiftCardsTab(appState),
        ],
      ),
    );
  }

  // 1. Aba Cashback (`query_list_aquisition_balances.graphql` & `mutation_exchangeBalance.graphql`)
  Widget _buildCashbackTab(AppStateController appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SALDO DE CASHBACK DISPONÍVEL',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(appState.cashbackBalance),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: appState.cashbackBalance >= 10
                          ? () {
                              appState.convertCashbackToGiftCard(10.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('R\$ 10,00 convertidos em Vale-Compra ativo para usar no carrinho!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Converter R\$ 10 em Vale', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Extrato de Cashback (list_aquisition_balances)', style: AppTypography.heading2),
        const SizedBox(height: 10),
        _buildHistoryTile(
          title: 'Cashback Oferta Clube - Sabão Líquido Omo',
          date: '03/11/2026 • Expira em 03/12/2026',
          value: '+ R\$ 4,00',
          isPositive: true,
        ),
        _buildHistoryTile(
          title: 'Prêmio Raspadinha do Clube',
          date: '24/10/2026 • Creditado na carteira',
          value: '+ R\$ 10,00',
          isPositive: true,
        ),
        _buildHistoryTile(
          title: 'Cashback Campanha Fim de Semana Churrasco',
          date: '19/10/2026 • Compra #039102',
          value: '+ R\$ 47,30',
          isPositive: true,
        ),
      ],
    );
  }

  // 2. Aba Transferência de Saldo entre Clientes (`mutation_transferBalance.graphql`)
  Widget _buildTransferBalanceTab(AppStateController appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transferir Cashback para Outro Cliente', style: AppTypography.heading2),
            const SizedBox(height: 4),
            Text(
              'Saldo disponível para transferência: ${CurrencyFormatter.format(appState.cashbackBalance)}',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('CPF do Destinatário no Clube', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _transferCpfController,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final f = Validators.formatCpf(v);
                if (f != v) {
                  _transferCpfController.value = TextEditingValue(
                    text: f,
                    selection: TextSelection.collapsed(offset: f.length),
                  );
                }
              },
              decoration: const InputDecoration(
                hintText: '000.000.000-00',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Valor a Transferir (R\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _transferAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Ex: 15,00',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Sua Senha de Segurança', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _transferPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Digite sua senha para confirmar',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final double? amount = double.tryParse(
                    _transferAmountController.text.replaceAll(',', '.'),
                  );
                  if (_transferCpfController.text.length < 11) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe o CPF do destinatário.'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  if (amount == null || amount <= 0 || amount > appState.cashbackBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valor inválido ou acima do saldo disponível.'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  if (_transferPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Confirme sua senha para transferir.'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  appState.transferCashback(targetCpf: _transferCpfController.text, amount: amount);
                  _transferAmountController.clear();
                  _transferPasswordController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transferência de ${CurrencyFormatter.format(amount)} enviada para CPF ${_transferCpfController.text}!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Confirmar Transferência Instantânea'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Aba Pontos & Troca por Produtos/Milhas (`query_list_aquisition_points.graphql` & `query_discounts_with_points.graphql`)
  Widget _buildPointsTab(AppStateController appState) {
    final rewards = [
      {
        'title': 'Vale-Compra de R\$ 15,00 no App/Caixa',
        'points': 500,
        'voucher': 15.0,
        'type': 'Vale-Compra',
      },
      {
        'title': 'Cashback Direto de R\$ 25,00',
        'points': 800,
        'cashback': 25.0,
        'type': 'Cashback',
      },
      {
        'title': 'Pacote 1.000 Milhas Aéreas Parceiras',
        'points': 1200,
        'voucher': 0.0,
        'type': 'Pacote de Milhas (discounts_mile_packs)',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SEUS PONTOS ACUMULADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    '${appState.pointsBalance} pts',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.secondary),
                  ),
                ],
              ),
              const Icon(Icons.stars_rounded, size: 44, color: AppColors.secondary),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Trocar Pontos por Recompensas', style: AppTypography.heading2),
        const SizedBox(height: 10),
        ...rewards.map((r) {
          final int cost = r['points'] as int;
          final bool canRedeem = appState.pointsBalance >= cost;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['type'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text(r['title'] as String, style: AppTypography.heading3),
                      Text('Custo: $cost pontos', style: AppTypography.caption),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: canRedeem
                      ? () {
                          appState.redeemPointsForReward(
                            pointsCost: cost,
                            cashbackAdded: r['cashback'] as double?,
                            voucherAdded: r['voucher'] as double?,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recompensa "${r['title']}" resgatada com sucesso!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Trocar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 4. Aba Vales-Compra / Gift Cards (`query_list_active_gift_cards.graphql`)
  Widget _buildGiftCardsTab(AppStateController appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SALDO EM VALES-COMPRA (GIFT CARDS)', style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(appState.activeGiftCardBalance),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Você pode abater este saldo diretamente no Meu Carrinho ou informando seu CPF no caixa físico.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Vales Ativos (list_active_gift_cards)', style: AppTypography.heading2),
        const SizedBox(height: 10),
        _buildHistoryTile(
          title: 'Vale-Compra Aniversário do Clube',
          date: 'Válido até 30/11/2026 • Compra mínima R\$ 50,00',
          value: CurrencyFormatter.format(appState.activeGiftCardBalance),
          isPositive: true,
        ),
      ],
    );
  }

  Widget _buildHistoryTile({
    required String title,
    required String date,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(date, style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

