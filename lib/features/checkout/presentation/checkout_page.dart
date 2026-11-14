import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/presentation/address_list_page.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/data/catalog_api_service.dart';
import '../../orders/domain/models/order_model.dart';
import 'client_cards_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Fulfillment: 0 = Delivery, 1 = Takeaway
  int _fulfillmentMode = 0;
  Map<String, dynamic> _selectedAddress = {
    'tag': 'Casa',
    'street': 'Av. Coronel José Inácio',
    'number': '450',
    'complement': 'Apto 201',
    'neighborhood': 'Centro',
    'city': 'Iguatu - CE',
    'cep': '63500-000',
  };

  // Schedule (operationTimes with remainingOrders)
  String _selectedDay = 'Hoje';
  String _selectedSlot = '14:00 - 16:00';

  final List<Map<String, dynamic>> _slotDetails = [
    {'slot': '09:00 - 11:00', 'remainingOrders': 2},
    {'slot': '11:00 - 13:00', 'remainingOrders': 5},
    {'slot': '14:00 - 16:00', 'remainingOrders': 8},
    {'slot': '17:00 - 19:00', 'remainingOrders': 4},
    {'slot': '19:00 - 21:00', 'remainingOrders': 9},
  ];

  // Payment method: 'pix', 'credit_card', 'food_card', 'crediario', 'delivery_payment'
  String _paymentMethod = 'pix';
  String _deliveryPaymentSub = 'card_machine'; // 'card_machine' or 'cash'
  String _selectedFoodBrand = 'Alelo Alimentação';
  final _cashChangeController = TextEditingController();
  int _installments = 1;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _cashChangeController.dispose();
    super.dispose();
  }

  Future<void> _changeAddress() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const AddressListPage(selectMode: true),
      ),
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _submitOrder(CartController cart, AppStateController appState) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seu carrinho está vazio!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final double deliveryFee = _fulfillmentMode == 0 ? cart.deliveryFee : 0.0;
    final double pixDiscount = _paymentMethod == 'pix' ? (cart.subtotal * 0.02) : 0.0;
    final double totalFinal = (cart.subtotal + deliveryFee + cart.serviceFee - cart.voucherDiscountApplied - pixDiscount)
        .clamp(0.0, 999999.0);

    final mainCard = appState.mainClientCard;
    String paymentLabel = 'Pix Instantâneo';
    if (_paymentMethod == 'credit_card') {
      paymentLabel =
          'Cartão ${mainCard?.brand ?? "Crédito"} final ${mainCard?.last4Digits ?? "4289"} (${_installments}x)';
    } else if (_paymentMethod == 'food_card') {
      paymentLabel = 'Vale-Alimentação ($_selectedFoodBrand)';
    } else if (_paymentMethod == 'crediario') {
      paymentLabel = 'Caderninho Digital / Crediário';
    } else if (_paymentMethod == 'delivery_payment') {
      paymentLabel = _deliveryPaymentSub == 'card_machine'
          ? 'Cartão na Entrega (Maquininha)'
          : 'Dinheiro na Entrega (Troco: ${_cashChangeController.text.isNotEmpty ? _cashChangeController.text : "Não"})';
    }

    final String fulfillmentLabel = _fulfillmentMode == 0
        ? 'Entrega em ${_selectedAddress['street']}, ${_selectedAddress['number']}'
        : 'Retirada no Balcão (Loja Matriz Centro)';

    final String timeSlotLabel = '$_selectedDay, $_selectedSlot';

    // Monta o payload padronizado para gravação no ERP (TB_PEDIDO_VENDA + TB_PREVENDA F10)
    final orderPayload = {
      'fulfillmentMode': _fulfillmentMode == 0 ? 'delivery' : 'takeaway',
      'customer': {
        'name': appState.userName.isNotEmpty ? appState.userName : 'Cliente Mercadinho',
        'phone': appState.userPhone,
        'cpf': appState.userCpf,
      },
      'deliveryAddress': _fulfillmentMode == 0 ? _selectedAddress : null,
      'scheduledWindow': timeSlotLabel,
      'paymentMethod': _paymentMethod,
      'paymentDetails': {
        'subType': _deliveryPaymentSub,
        'cashChangeFor': _cashChangeController.text.trim(),
        'installments': _installments,
        'foodBrand': _paymentMethod == 'food_card' ? _selectedFoodBrand : null,
      },
      'observation': cart.cartObservation,
      'subtotal': cart.subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': cart.serviceFee,
      'discount': cart.totalSavings + cart.voucherDiscountApplied + pixDiscount,
      'total': totalFinal,
      'items': cart.items.map((ci) {
        int productId = int.tryParse(ci.product.id.replaceAll(RegExp(r'\D'), '')) ?? 1;
        return {
          'idProduto': productId,
          'barcode': ci.product.barcode,
          'name': ci.product.name,
          'quantity': ci.quantity,
          'unitPrice': ci.product.activePrice,
          'totalPrice': ci.product.activePrice * ci.quantity,
          'observation': ci.observation,
        };
      }).toList(),
    };

    Map<String, dynamic>? erpResponse;
    try {
      erpResponse = await CatalogApiService.submitOrder(orderPayload);
    } catch (e) {
      debugPrint('[CheckoutPage] Erro ao gravar pedido no ERP: $e');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Dados retornados do ERP ou fallback de segurança
    final bool isErpSuccess = erpResponse != null && erpResponse['success'] == true;
    final int? erpOrderId = isErpSuccess ? (erpResponse['orderId'] as int?) : null;
    final String orderCode = isErpSuccess
        ? (erpResponse['orderCode'] ?? '00000$erpOrderId').toString()
        : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final String orderIdFormatted = '#MERC-$orderCode';
    final String? passwordNumber = isErpSuccess ? erpResponse['passwordNumber']?.toString() : null;
    final int? preSaleId = isErpSuccess ? (erpResponse['preSaleId'] as int?) : null;

    final pixData = erpResponse?['pix'] as Map<String, dynamic>?;
    final String? pixCopiaECola = pixData?['copiaECola'] as String?;
    final String? pixQrCodeUrl = pixData?['qrCodeUrl'] as String?;

    // Registra o pedido no estado global para aparecer em Meus Pedidos
    final newOrder = OrderModel(
      id: 'ord_$orderCode',
      code: orderCode,
      date: DateTime.now(),
      totalAmount: totalFinal,
      subtotalAmount: cart.subtotal,
      deliveryCost: deliveryFee,
      serviceFee: cart.serviceFee,
      discountValue: cart.totalSavings + cart.voucherDiscountApplied + pixDiscount,
      itemsCount: cart.itemCount,
      status: 'received',
      deliveryType: _fulfillmentMode == 0 ? 'delivery' : 'takeaway',
      paymentMethod: paymentLabel,
      cardBrand: mainCard?.brand ?? 'MasterCard',
      cardLast4: mainCard?.last4Digits ?? '4289',
      installments: _installments,
      scheduledWindow: timeSlotLabel,
      separatorName: 'Central Clipp ERP (Loja 01)',
      deliverymanName: _fulfillmentMode == 0 ? 'Marcos Silva (Moto #04)' : 'Balcão de Retirada',
      dryVolumes: 1,
      coldVolumes: 0,
      observation: cart.cartObservation,
      passwordNumber: passwordNumber,
      pixCopiaECola: pixCopiaECola,
      preSaleId: preSaleId,
      erpOrderId: erpOrderId,
      items: cart.items
          .map(
            (ci) => OrderItemRecord(
              id: 'oi_${ci.product.id}',
              product: ci.product,
              requestQuantity: ci.quantity,
              foundQuantity: ci.quantity,
              unitPrice: ci.product.activePrice,
              observation: ci.observation,
            ),
          )
          .toList(),
    );
    appState.addOrder(newOrder);

    // Esvazia o carrinho após finalização com sucesso
    cart.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderSuccessPage(
          orderId: orderIdFormatted,
          totalAmount: totalFinal,
          fulfillmentType: fulfillmentLabel,
          timeSlot: timeSlotLabel,
          paymentMethod: paymentLabel,
          passwordNumber: passwordNumber,
          pixCopiaECola: pixCopiaECola,
          pixQrCodeUrl: pixQrCodeUrl,
          preSaleId: preSaleId,
          erpOrderId: erpOrderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final appState = context.watch<AppStateController>();

    final double deliveryFee = _fulfillmentMode == 0 ? cart.deliveryFee : 0.0;
    final double pixDiscount = _paymentMethod == 'pix' ? (cart.subtotal * 0.02) : 0.0;
    final double finalAmount =
        (cart.subtotal + deliveryFee + cart.serviceFee - cart.voucherDiscountApplied - pixDiscount)
            .clamp(0.0, 999999.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finalizar Pedido', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFulfillmentSelector(),
              const SizedBox(height: 16),
              if (_fulfillmentMode == 0) _buildDeliveryAddressCard() else _buildTakeawayCard(),
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildMissingItemCard(cart),
              const SizedBox(height: 16),
              _buildPaymentMethodCard(cart, appState, finalAmount),
              const SizedBox(height: 16),
              _buildOrderSummaryCard(cart, deliveryFee, pixDiscount, finalAmount),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting || cart.items.isEmpty
                      ? null
                      : () => _submitOrder(cart, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Confirmar Pedido • ${CurrencyFormatter.formatReal(finalAmount)}',
                              style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFulfillmentSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _fulfillmentMode = 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _fulfillmentMode == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delivery_dining_rounded,
                      size: 20,
                      color: _fulfillmentMode == 0 ? Colors.white : AppColors.neutralMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Receber em Casa',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _fulfillmentMode == 0 ? Colors.white : AppColors.neutralDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _fulfillmentMode = 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _fulfillmentMode == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 20,
                      color: _fulfillmentMode == 1 ? Colors.white : AppColors.neutralMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Retirar na Loja',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _fulfillmentMode == 1 ? Colors.white : AppColors.neutralDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Endereço de Entrega', style: AppTypography.heading2.copyWith(fontSize: 15)),
                ],
              ),
              TextButton(
                onPressed: _changeAddress,
                child: Text(
                  'Trocar',
                  style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedAddress['street']}, ${_selectedAddress['number']}${_selectedAddress['complement'] != null && _selectedAddress['complement'].toString().isNotEmpty ? ' - ${_selectedAddress['complement']}' : ''}',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.neutralDark),
          ),
          Text(
            '${_selectedAddress['neighborhood']} - ${_selectedAddress['city']}',
            style: AppTypography.caption.copyWith(color: AppColors.neutralMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Balcão de Retirada (Clique & Retire)', style: AppTypography.heading2.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Queiroz Atacadão - Matriz Centro',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.neutralDark),
          ),
          Text(
            'Av. Coronel José Inácio, 450 - Centro, Iguatu - CE',
            style: AppTypography.caption.copyWith(color: AppColors.neutralMedium),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Taxa de Entrega: R\$ 0,00 (Grátis)',
              style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _fulfillmentMode == 0 ? 'Janela de Entrega (operationTimes)' : 'Janela de Retirada',
                style: AppTypography.heading2.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Hoje', 'Amanhã'].map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withAlpha(40),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.neutralDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDay = day);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSlot,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neutralMedium),
                items: _slotDetails.map((s) {
                  final String slot = s['slot'] as String;
                  final int rem = s['remainingOrders'] as int;
                  return DropdownMenuItem(
                    value: slot,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Horário: $slot', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rem <= 3 ? AppColors.warningLight : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$rem vagas restantes',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rem <= 3 ? AppColors.warning : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSlot = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItemCard(CartController cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Se faltar produto na loja:', style: AppTypography.heading2.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          _buildPolicyOption(
            cart,
            'substitute',
            'Substituir por similar',
            'O separador escolhe marca similar de mesmo valor sem custo extra',
          ),
          _buildPolicyOption(
            cart,
            'call',
            'Avisar no WhatsApp',
            'Entramos em contato para você escolher ou aprovar a troca',
          ),
          _buildPolicyOption(
            cart,
            'cancel',
            'Apenas cancelar e estornar',
            'Remove o item faltante e devolve o valor correspondente',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyOption(CartController cart, String key, String title, String subtitle) {
    final isSelected = cart.missingItemPolicy == key;
    return InkWell(
      onTap: () => cart.setMissingItemPolicy(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: key,
              groupValue: cart.missingItemPolicy,
              activeColor: AppColors.primary,
              onChanged: (val) => cart.setMissingItemPolicy(val!),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.neutralDark,
                    ),
                  ),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.neutralMedium, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    CartController cart,
    AppStateController appState,
    double finalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Forma de Pagamento', style: AppTypography.heading2.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Pix Instantâneo
          _buildPaymentTile(
            key: 'pix',
            title: 'Pix Instantâneo (Aprovação Imediata)',
            subtitle: 'Economize 2% no valor final do pedido',
            icon: Icons.qr_code_2_rounded,
            badge: '2% OFF',
          ),
          if (_paymentMethod == 'pix') _buildPixDetails(),

          const Divider(height: 16),

          // 2. Cartão de Crédito Online (ClientCardsPage + storeInstallments)
          _buildPaymentTile(
            key: 'credit_card',
            title: 'Cartão de Crédito Online',
            subtitle: 'Parcele em até 3x sem juros (ou 6x no Cartão Queiroz)',
            icon: Icons.credit_card_rounded,
          ),
          if (_paymentMethod == 'credit_card')
            _buildCreditCardDetails(appState, finalAmount),

          const Divider(height: 16),

          // 3. Cartão Alimentação / Benefício (FOOD_CARD)
          _buildPaymentTile(
            key: 'food_card',
            title: 'Vale-Alimentação / Benefício',
            subtitle: 'Alelo, Sodexo/Pluxee, Ticket, VR Benefícios',
            icon: Icons.restaurant_rounded,
          ),
          if (_paymentMethod == 'food_card') _buildFoodCardDetails(),

          const Divider(height: 16),

          // 4. Crediário / Caderninho Digital
          _buildPaymentTile(
            key: 'crediario',
            title: 'Caderninho Digital / Crediário do Mercado',
            subtitle: 'Compre a prazo no seu limite de confiança',
            icon: Icons.account_balance_wallet_rounded,
            badge: 'Limite R\$ 420',
          ),

          const Divider(height: 16),

          // 5. Pagamento na Entrega
          _buildPaymentTile(
            key: 'delivery_payment',
            title: 'Pagar na Entrega / Retirada',
            subtitle: 'Maquininha de cartão ou dinheiro em espécie',
            icon: Icons.delivery_dining_rounded,
          ),
          if (_paymentMethod == 'delivery_payment') _buildDeliveryPaymentDetails(),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _paymentMethod == key;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Radio<String>(
              value: key,
              groupValue: _paymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.neutralMedium, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.neutralDark,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.neutralMedium, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixDetails() {
    return Container(
      margin: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Validade do código: 15 minutos após confirmar',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Ao confirmar, o código Pix Copia e Cola será gerado na tela com chave de identificação do pedido.',
            style: TextStyle(fontSize: 11, color: AppColors.neutralMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardDetails(AppStateController appState, double finalAmount) {
    final mainCard = appState.mainClientCard;
    return Container(
      margin: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cartão selecionado:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientCardsPage(selectMode: true)),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Trocar / Novo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.credit_card, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mainCard != null
                      ? '${mainCard.brand} final ${mainCard.last4Digits} (${mainCard.holderName})'
                      : 'MasterCard final 4289',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Parcelamento (storeInstallments - mín. R\$ 30/parcela):',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          DropdownButton<int>(
            value: _installments,
            isExpanded: true,
            isDense: true,
            items: [1, 2, 3, 4, 5, 6].map((n) {
              final valPerInst = finalAmount / n;
              final interest = n > 3 ? ' (Cartão Queiroz s/ juros)' : ' sem juros';
              return DropdownMenuItem(
                value: n,
                child: Text(
                  '${n}x de ${CurrencyFormatter.format(valPerInst)}$interest',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _installments = val ?? 1),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCardDetails() {
    final brands = ['Alelo Alimentação', 'Pluxee / Sodexo', 'Ticket Alimentação', 'VR Alimentação'];
    return Container(
      margin: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecione a bandeira do seu benefício:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: brands.map((b) {
              final sel = _selectedFoodBrand == b;
              return ChoiceChip(
                label: Text(b, style: const TextStyle(fontSize: 11)),
                selected: sel,
                onSelected: (_) => setState(() => _selectedFoodBrand = b),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPaymentDetails() {
    return Container(
      margin: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: 'card_machine',
            groupValue: _deliveryPaymentSub,
            title: const Text('Maquininha de Cartão (Débito, Crédito ou Alimentação)', style: TextStyle(fontSize: 12)),
            onChanged: (val) => setState(() => _deliveryPaymentSub = val!),
          ),
          RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: 'cash',
            groupValue: _deliveryPaymentSub,
            title: const Text('Dinheiro em Espécie', style: TextStyle(fontSize: 12)),
            onChanged: (val) => setState(() => _deliveryPaymentSub = val!),
          ),
          if (_deliveryPaymentSub == 'cash') ...[
            const SizedBox(height: 4),
            TextField(
              controller: _cashChangeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Precisa de troco para quanto? (Ex: R\$ 100,00)',
                hintStyle: const TextStyle(fontSize: 11),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    CartController cart,
    double deliveryFee,
    double pixDiscount,
    double finalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumo de Valores', style: AppTypography.heading2.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal dos Itens (${cart.itemCount})', CurrencyFormatter.formatReal(cart.subtotal)),
          if (cart.totalSavings > 0)
            _buildSummaryRow(
              'Economia com Clube',
              '- ${CurrencyFormatter.formatReal(cart.totalSavings)}',
              valueColor: AppColors.secondary,
            ),
          if (cart.voucherDiscountApplied > 0)
            _buildSummaryRow(
              'Vale-Compras / Cashback aplicado',
              '- ${CurrencyFormatter.formatReal(cart.voucherDiscountApplied)}',
              valueColor: AppColors.primary,
            ),
          _buildSummaryRow('Taxa de Serviço / Separação', CurrencyFormatter.formatReal(cart.serviceFee)),
          _buildSummaryRow(
            'Taxa de Entrega',
            deliveryFee == 0 ? 'GRÁTIS' : CurrencyFormatter.formatReal(deliveryFee),
            valueColor: deliveryFee == 0 ? AppColors.success : AppColors.neutralDark,
          ),
          if (pixDiscount > 0)
            _buildSummaryRow(
              'Desconto Pix (2%)',
              '- ${CurrencyFormatter.formatReal(pixDiscount)}',
              valueColor: AppColors.success,
            ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Pagar', style: AppTypography.heading2),
              Text(
                CurrencyFormatter.formatReal(finalAmount),
                style: AppTypography.priceClub.copyWith(fontSize: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMedium)),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.neutralDark,
            ),
          ),
        ],
      ),
    );
  }
}
