import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'address_form_page.dart';

class AddressListPage extends StatefulWidget {
  final bool selectMode;

  const AddressListPage({super.key, this.selectMode = false});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'tag': 'Casa',
      'street': 'Av. Coronel José Inácio',
      'number': '450',
      'complement': 'Apto 201',
      'neighborhood': 'Centro',
      'city': 'Iguatu - CE',
      'cep': '63500-000',
      'reference': 'Próximo à Praça da Matriz',
      'isDefault': true,
    },
    {
      'id': '2',
      'tag': 'Trabalho',
      'street': 'Rua Floriano Peixoto',
      'number': '1120',
      'complement': 'Sala 4',
      'neighborhood': 'Planalto',
      'city': 'Iguatu - CE',
      'cep': '63502-150',
      'reference': 'Comercial Centro Sul',
      'isDefault': false,
    },
  ];

  void _selectDefault(int index) {
    setState(() {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i]['isDefault'] = (i == index);
      }
    });

    if (widget.selectMode) {
      Navigator.of(context).pop(_addresses[index]);
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const AddressFormPage()),
    );

    if (result != null) {
      setState(() {
        for (var addr in _addresses) {
          addr['isDefault'] = false;
        }
        result['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        result['isDefault'] = true;
        _addresses.insert(0, result);
      });

      if (widget.selectMode && mounted) {
        Navigator.of(context).pop(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.selectMode ? 'Selecionar Endereço' : 'Meus Endereços',
          style: AppTypography.heading2,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: _addresses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final addr = _addresses[index];
                  final isDefault = addr['isDefault'] == true;

                  return InkWell(
                    onTap: () => _selectDefault(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDefault ? AppColors.primary : Colors.grey.shade200,
                          width: isDefault ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            addr['tag'] == 'Casa'
                                ? Icons.home_rounded
                                : (addr['tag'] == 'Trabalho' ? Icons.work_rounded : Icons.location_on_rounded),
                            color: isDefault ? AppColors.primary : AppColors.neutralMedium,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      addr['tag'] ?? 'Endereço',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutralDark,
                                      ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Principal',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${addr['street']}, ${addr['number']}${addr['complement'] != null && addr['complement'].toString().isNotEmpty ? ' - ${addr['complement']}' : ''}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.neutralDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${addr['neighborhood']}, ${addr['city']} - CEP: ${addr['cep']}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutralMedium,
                                  ),
                                ),
                                if (addr['reference'] != null && addr['reference'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ponto de ref: ${addr['reference']}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.neutralMedium,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Radio<bool>(
                            value: true,
                            groupValue: isDefault,
                            activeColor: AppColors.primary,
                            onChanged: (_) => _selectDefault(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add New Address Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _addNewAddress,
                  icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                  label: Text(
                    'Cadastrar Novo Endereço',
                    style: AppTypography.button.copyWith(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

