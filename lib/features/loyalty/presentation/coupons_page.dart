import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _availableCoupons = [
    {
      'id': 'cup_01',
      'title': 'R\$ 15,00 OFF em Carnes Nobres',
      'category': 'Açougue',
      'minAmount': 80.0,
      'expires': 'Vence em 3 dias',
      'badge': 'Destaque',
    },
    {
      'id': 'cup_02',
      'title': 'Frete Grátis na Primeira Compra',
      'category': 'Entrega',
      'minAmount': 50.0,
      'expires': 'Vence em 7 dias',
      'badge': 'Novo Cliente',
    },
    {
      'id': 'cup_03',
      'title': '20% OFF na Feirinha Hortifrúti',
      'category': 'Hortifrúti',
      'minAmount': 30.0,
      'expires': 'Vence hoje às 23:59',
      'badge': 'Relâmpago',
    },
  ];

  final List<Map<String, dynamic>> _activeCoupons = [
    {
      'id': 'cup_04',
      'title': '10% de Cashback no PIX',
      'category': 'Clube',
      'minAmount': 60.0,
      'expires': 'Ativo até 15/11',
      'code': 'CLUBE10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _activateCoupon(Map<String, dynamic> coupon) {
    setState(() {
      _availableCoupons.remove(coupon);
      coupon['code'] = 'ATIVO_${coupon['id']}';
      _activeCoupons.add(coupon);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cupom "${coupon['title']}" ativado com sucesso!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Carteira de Cupons'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Disponíveis (${_availableCoupons.length})'),
            Tab(text: 'Meus Cupons (${_activeCoupons.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba Disponíveis
          _buildAvailableList(),

          // Aba Meus Cupons Ativos
          _buildActiveList(),
        ],
      ),
    );
  }

  Widget _buildAvailableList() {
    if (_availableCoupons.isEmpty) {
      return const Center(child: Text('Nenhum cupom disponível no momento.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _availableCoupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final coupon = _availableCoupons[index];
        return _buildCouponCard(coupon, isActive: false);
      },
    );
  }

  Widget _buildActiveList() {
    if (_activeCoupons.isEmpty) {
      return const Center(child: Text('Você ainda não tem cupons ativos.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activeCoupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final coupon = _activeCoupons[index];
        return _buildCouponCard(coupon, isActive: true);
      },
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: isActive ? AppColors.primaryLight : AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'CUPOM ATIVO' : (coupon['badge'] ?? 'OFERTA'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primaryDark : AppColors.secondary,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(coupon['expires'], style: AppTypography.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(coupon['title'], style: AppTypography.heading2.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('Válido em compras acima de R\$ ${coupon['minAmount'].toStringAsFixed(2)}', style: AppTypography.bodySmall),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: isActive
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primaryDark, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Código: ${coupon['code']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _activateCoupon(coupon),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Ativar Cupom', style: TextStyle(fontSize: 13)),
                  ),
          ),
        ],
      ),
    );
  }
}

