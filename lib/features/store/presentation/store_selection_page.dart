import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StoreSelectionPage extends StatefulWidget {
  final String? currentStoreId;

  const StoreSelectionPage({super.key, this.currentStoreId});

  @override
  State<StoreSelectionPage> createState() => _StoreSelectionPageState();
}

class _StoreSelectionPageState extends State<StoreSelectionPage> {
  late String _selectedId;

  final List<Map<String, dynamic>> _stores = [
    {
      'id': 'loja-01',
      'name': 'Mercadinho Matriz - Centro',
      'address': 'Av. Coronel José Inácio, 450 - Centro, Iguatu - CE',
      'distance': '1.2 km',
      'isOpen': true,
      'closingTime': '21:00',
      'minOrder': 30.0,
      'freeShippingOver': 99.0,
      'hasDelivery': true,
      'hasTakeaway': true,
    },
    {
      'id': 'loja-02',
      'name': 'Mercadinho Filial - Planalto',
      'address': 'Rua Floriano Peixoto, 1120 - Planalto, Iguatu - CE',
      'distance': '3.5 km',
      'isOpen': true,
      'closingTime': '20:00',
      'minOrder': 30.0,
      'freeShippingOver': 80.0,
      'hasDelivery': true,
      'hasTakeaway': true,
    },
    {
      'id': 'loja-03',
      'name': 'Mercadinho Atacado & Varejo - Sul',
      'address': 'Rodovia CE-060, Km 4 - Distrito Industrial, Iguatu - CE',
      'distance': '5.8 km',
      'isOpen': false,
      'closingTime': '22:00',
      'minOrder': 50.0,
      'freeShippingOver': 150.0,
      'hasDelivery': true,
      'hasTakeaway': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentStoreId ?? 'loja-01';
  }

  Future<void> _selectStore(Map<String, dynamic> store) async {
    setState(() => _selectedId = store['id']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_store_id', store['id']);
    await prefs.setString('selected_store_name', store['name']);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loja definida: ${store['name']}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(store);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Selecionar Loja', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: _stores.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final store = _stores[index];
            final isSelected = store['id'] == _selectedId;
            final isOpen = store['isOpen'] == true;

            return InkWell(
              onTap: () => _selectStore(store),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade200,
                    width: isSelected ? 2.0 : 1.0,
                  ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store['name'],
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.neutralDark,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store['address'],
                                style: AppTypography.caption.copyWith(color: AppColors.neutralMedium),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: store['id'],
                          groupValue: _selectedId,
                          activeColor: AppColors.primary,
                          onChanged: (_) => _selectStore(store),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Open/Closed badge
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOpen ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOpen ? 'Aberta até ${store['closingTime']}' : 'Fechada no momento',
                              style: AppTypography.caption.copyWith(
                                color: isOpen ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        // Distance
                        Row(
                          children: [
                            const Icon(Icons.near_me_outlined, size: 14, color: AppColors.neutralMedium),
                            const SizedBox(width: 4),
                            Text(
                              store['distance'],
                              style: AppTypography.caption.copyWith(color: AppColors.neutralMedium),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Operation rules summary
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildRuleChip(
                          Icons.shopping_bag_outlined,
                          'Mínimo R\$ ${(store['minOrder'] as double).toStringAsFixed(2)}',
                        ),
                        _buildRuleChip(
                          Icons.local_shipping_outlined,
                          'Frete Grátis > R\$ ${(store['freeShippingOver'] as double).toStringAsFixed(0)}',
                        ),
                        if (store['hasTakeaway'])
                          _buildRuleChip(
                            Icons.directions_walk_rounded,
                            'Retire na loja',
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
    );
  }

  Widget _buildRuleChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.neutralDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.neutralDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
