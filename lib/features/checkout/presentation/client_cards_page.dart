import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Módulo de Carteira de Cartões de Crédito (ClientCardsPage, AddCardPage,
/// AddBillingAddressPage, query_clientCards.graphql, query_identifyCardBrandByBin.graphql,
/// mutation_addClientCard.graphql, mutation_deleteClientCard.graphql, mutation_updateMainCard.graphql)
class ClientCardsPage extends StatelessWidget {
  final bool selectMode;

  const ClientCardsPage({super.key, this.selectMode = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    final cards = appState.clientCards;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selectMode ? 'Selecionar Cartão' : 'Meus Cartões'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCardSheet(context, appState),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Novo Cartão'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withAlpha(60)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.info, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seus cartões são tokenizados com criptografia PCI-DSS e vinculados ao seu endereço de cobrança.',
                    style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...cards.map((card) => _buildCardItem(context, card, appState)),
        ],
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    ClientCardRecord card,
    AppStateController appState,
  ) {
    final Color brandColor = _brandColor(card.brand);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.main ? AppColors.primary : AppColors.border,
          width: card.main ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visual Credit Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor, brandColor.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        card.brand.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (card.main)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRINCIPAL',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '••••  ••••  ••••  ${card.last4Digits}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.holderName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'VAL ${card.expirationDate}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Billing Address & Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Fatura: ${card.billingStreet}, ${card.billingNumber} - CEP ${card.billingZipCode}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!card.main)
                      TextButton.icon(
                        onPressed: () {
                          appState.setMainClientCard(card.id);
                          if (selectMode) {
                            Navigator.pop(context, card);
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(
                          selectMode ? 'Usar este Cartão' : 'Tornar Principal',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    else if (selectMode)
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, card),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Selecionado', style: TextStyle(fontSize: 12)),
                      ),
                    if (appState.clientCards.length > 1)
                      IconButton(
                        onPressed: () => appState.deleteClientCard(card.id),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        tooltip: 'Remover cartão',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _brandColor(String brand) {
    final b = brand.toLowerCase();
    if (b.contains('master')) return const Color(0xFF1E293B);
    if (b.contains('visa')) return const Color(0xFF1E3A8A);
    if (b.contains('elo')) return const Color(0xFF0F766E);
    if (b.contains('hiper')) return const Color(0xFF991B1B);
    return const Color(0xFF334155);
  }

  void _openAddCardSheet(BuildContext context, AppStateController appState) {
    final numberCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final expCtrl = TextEditingController(text: '12/29');
    final cvvCtrl = TextEditingController();
    final docCtrl = TextEditingController(text: appState.userDocument);
    final zipCtrl = TextEditingController(text: '63500-000');
    final streetCtrl = TextEditingController(text: 'Av. Coronel José Inácio');
    final numCtrl = TextEditingController(text: '450');
    String detectedBrand = 'Visa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adicionar Cartão de Crédito', style: AppTypography.heading2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BIN: $detectedBrand',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setModalState(() {
                      detectedBrand = AppStateController.identifyBrandByBin(val);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Número do Cartão (Identificação automática por BIN)',
                    hintText: '5412 75•• •••• 1234',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: holderCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Nome Impresso no Cartão',
                    hintText: 'MARIA F SILVA',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Validade (MM/AA)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: docCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CPF/CNPJ do Titular',
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Endereço de Cobrança da Fatura (AddBillingAddressPage)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: zipCtrl,
                        decoration: const InputDecoration(labelText: 'CEP'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: numCtrl,
                        decoration: const InputDecoration(labelText: 'Número'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(labelText: 'Logradouro / Rua'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final digits = numberCtrl.text.replaceAll(RegExp(r'\D'), '');
                      final last4 = digits.length >= 4
                          ? digits.substring(digits.length - 4)
                          : '9012';
                      appState.addClientCard(
                        ClientCardRecord(
                          id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                          holderName: holderCtrl.text.trim().isEmpty
                              ? 'MARIA F SILVA'
                              : holderCtrl.text.trim().toUpperCase(),
                          last4Digits: last4,
                          first6Digits: digits.length >= 6 ? digits.substring(0, 6) : '411111',
                          brand: detectedBrand,
                          expirationDate: expCtrl.text,
                          main: true,
                          billingZipCode: zipCtrl.text,
                          billingStreet: streetCtrl.text,
                          billingNumber: numCtrl.text,
                        ),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cartão $detectedBrand final $last4 salvo com sucesso!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Salvar Cartão Seguro'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

