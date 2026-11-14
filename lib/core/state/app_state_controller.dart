import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/orders/domain/models/order_model.dart';

class ClientCardRecord {
  final String id;
  final String brand;
  final String lastFour;
  final String first6Digits;
  final String holderName;
  final String expiry;
  final String label;
  final String billingAddress;
  final String billingZipCode;
  final String billingStreet;
  final String billingNumber;
  final bool isMain;

  const ClientCardRecord({
    required this.id,
    required this.brand,
    String? lastFour,
    String? last4Digits,
    this.first6Digits = '541275',
    required this.holderName,
    String? expiry,
    String? expirationDate,
    this.label = 'Cartão Principal',
    this.billingAddress = 'Av. Coronel José Inácio, 450 - Centro, Iguatu/CE',
    this.billingZipCode = '63500-000',
    this.billingStreet = 'Av. Coronel José Inácio',
    this.billingNumber = '450',
    bool? isMain,
    bool? main,
  })  : lastFour = lastFour ?? last4Digits ?? '4289',
        expiry = expiry ?? expirationDate ?? '12/29',
        isMain = isMain ?? main ?? false;

  String get last4Digits => lastFour;
  String get expirationDate => expiry;
  bool get main => isMain;

  ClientCardRecord copyWith({bool? isMain, String? label}) {
    return ClientCardRecord(
      id: id,
      brand: brand,
      lastFour: lastFour,
      first6Digits: first6Digits,
      holderName: holderName,
      expiry: expiry,
      label: label ?? this.label,
      billingAddress: billingAddress,
      billingZipCode: billingZipCode,
      billingStreet: billingStreet,
      billingNumber: billingNumber,
      isMain: isMain ?? this.isMain,
    );
  }
}

class AppStateController extends ChangeNotifier {
  // Perfil do Cliente & CRM (`query_me.graphql` / `user_data_aux`)
  String userName = 'Everton da Silva';
  String userCpf = '123.456.789-00';
  bool isCnpj = false;
  String userEmail = 'everton.silva@email.com';
  bool emailValidated = true;
  String userPhone = '(88) 99654-3210';
  String birthDate = '14/05/1992';
  String gender = 'Masculino';
  String friendCode = 'EVERTON2026';

  String get userDocument => userCpf;
  String get userBirthDate => birthDate;
  String get referralCode => friendCode;

  // Dados Socioeconômicos CRM (`mutation_updateUserDataAux.graphql`)
  String profession = 'Comerciante / Autônomo';
  String maritalStatus = 'Casado(a)';
  String educationLevel = 'Ensino Superior';
  String incomeRange = 'R\$ 4.500 a R\$ 8.000';
  String residentsCount = '3 a 4 pessoas';
  String childrenCount = '1 filho';
  int residentsNumber = 3;
  int childrenNumber = 1;

  // Contadores do Clube (`user_setting` / `app_home_counters_order`)
  double economyTotal = 482.90;
  double cashbackBalance = 61.30;
  int pointsBalance = 1450;
  double activeGiftCardBalance = 25.00;
  int raffleVouchersCount = 14;
  int sportsBetsAvailable = 5;
  bool isCheckedInStore = false;
  bool greenCouponEnabled = true;
  bool shopSurveyAnswered = false;

  double get economiometroTotal => economyTotal;
  double get voucherBalance => activeGiftCardBalance;
  int get raffleTicketsCount => raffleVouchersCount;
  bool get surveySubmitted => shopSurveyAnswered;

  // Loja e Endereço Ativos
  String selectedStoreId = 'loja-01';
  String selectedStoreName = 'Mercadinho Matriz - Centro';
  String selectedAddressSummary = 'Av. Coronel José Inácio, 450';

  // Favoritos (`query_list_favorites.graphql`)
  final Set<String> _favoriteProductIds = {'prod_001', 'prod_006', 'prod_008'};
  Set<String> get favoriteProductIds => _favoriteProductIds;
  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();
  }

  // Carteira de Cartões (`query_clientUserCards.graphql`)
  final List<ClientCardRecord> _clientCards = [
    const ClientCardRecord(
      id: 'card_01',
      brand: 'Mastercard',
      lastFour: '4289',
      holderName: 'EVERTON S SILVA',
      expiry: '08/2029',
      label: 'Nubank Principal',
      billingAddress: 'Av. Coronel José Inácio, 450 - Centro, Iguatu/CE',
      isMain: true,
    ),
    const ClientCardRecord(
      id: 'card_02',
      brand: 'Visa',
      lastFour: '9012',
      holderName: 'EVERTON S SILVA',
      expiry: '11/2028',
      label: 'Cartão Corporativo',
      billingAddress: 'Rua Floriano Peixoto, 1120 - Planalto, Iguatu/CE',
      isMain: false,
    ),
  ];

  List<ClientCardRecord> get clientCards => List.unmodifiable(_clientCards);
  ClientCardRecord? get mainCard =>
      _clientCards.isEmpty ? null : _clientCards.firstWhere((c) => c.isMain, orElse: () => _clientCards.first);
  ClientCardRecord? get mainClientCard => mainCard;

  static String identifyBrandByBin(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith('5')) return 'Mastercard';
    if (clean.startsWith('6') || clean.startsWith('50')) return 'Elo';
    if (clean.startsWith('3')) return 'Amex';
    return 'Mastercard';
  }

  void addClientCard(ClientCardRecord card) {
    if (card.isMain) {
      for (int i = 0; i < _clientCards.length; i++) {
        _clientCards[i] = _clientCards[i].copyWith(isMain: false);
      }
    }
    _clientCards.add(card);
    notifyListeners();
  }

  void setMainClientCard(String id) {
    for (int i = 0; i < _clientCards.length; i++) {
      _clientCards[i] = _clientCards[i].copyWith(isMain: _clientCards[i].id == id);
    }
    notifyListeners();
  }

  void deleteClientCard(String id) {
    _clientCards.removeWhere((c) => c.id == id);
    if (_clientCards.isNotEmpty && !_clientCards.any((c) => c.isMain)) {
      _clientCards[0] = _clientCards[0].copyWith(isMain: true);
    }
    notifyListeners();
  }

  // Motivos Oficiais de Cancelamento (`query_orderCancelReasons.graphql`)
  final List<String> orderCancelReasons = const [
    'Esqueci de adicionar itens ao carrinho',
    'Quero alterar a forma de pagamento ou endereço',
    'Imprevisto no horário agendado de entrega',
    'Não concordo com a variação de pesagem / substituição',
    'Desisti da compra no momento',
  ];

  // Pedidos (`query_orders.graphql` & `query_order.graphql` com divergência real de pesagem!)
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ord_101',
      code: '8942',
      date: DateTime.now().subtract(const Duration(minutes: 28)),
      grossValue: 138.60,
      discountValue: 18.00,
      deliveryFee: 0.00,
      serviceFee: 2.50,
      purchaseVoucherValue: 0.00,
      totalAmount: 129.08,
      itemsCount: 3,
      status: 'picking',
      deliveryType: 'delivery',
      paymentMethod: 'PIX Instantâneo',
      timeSlot: 'Hoje, 14:00 - 16:00',
      deliveryAddressText: 'Av. Coronel José Inácio, 450 - Centro',
      observation: 'Tocar interfone 201. Carnes bem limpas por favor.',
      dryVolumes: 2,
      coldVolumes: 2,
      separatorName: 'Maria Fernanda (Separadora #04)',
      deliverymanName: 'Carlos Eduardo (Moto #12)',
      canCancel: true,
      needsClientApproval: true,
      clientApprovedChanges: false,
      items: [
        OrderItemRecord(
          productId: 'prod_001',
          productName: 'Picanha Bovina Resfriada Fatiada',
          imageUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=500&q=80',
          weighable: true,
          unitPrice: 54.90,
          requestQuantity: 1.000,
          foundQuantity: 1.120,
          observation: 'Cortar em bifes de 2 dedos',
        ),
        OrderItemRecord(
          productId: 'prod_002',
          productName: 'Banana Prata Selecionada',
          imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80',
          weighable: true,
          unitPrice: 4.49,
          requestQuantity: 1.500,
          foundQuantity: 1.420,
          observation: 'Mais verdes para durar a semana',
        ),
        OrderItemRecord(
          productId: 'prod_006',
          productName: 'Arroz Branco Parboilizado Tipo 1 5kg',
          imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
          weighable: false,
          unitPrice: 24.90,
          requestQuantity: 2.0,
          foundQuantity: 2.0,
        ),
      ],
      statesHistory: const [
        OrderStateHistoryRecord(
          name: 'Pedido Recebido',
          description: 'Recebemos seu pedido na filial Matriz - Centro.',
          date: 'Hoje às 08:50',
          status: 'done',
        ),
        OrderStateHistoryRecord(
          name: 'Em Separação e Pesagem',
          description: 'Maria Fernanda pesou seus itens de açougue/hortifrúti. Há pequena variação de balança (+R\$ 6,23).',
          date: 'Hoje às 09:05',
          status: 'current',
        ),
      ],
    ),
    OrderModel(
      id: 'ord_100',
      code: '7721',
      date: DateTime.now().subtract(const Duration(days: 4)),
      grossValue: 112.40,
      discountValue: 14.00,
      deliveryFee: 0.0,
      serviceFee: 0.0,
      totalAmount: 98.40,
      itemsCount: 5,
      status: 'completed',
      deliveryType: 'delivery',
      paymentMethod: 'Cartão Mastercard •••• 4289 (2x)',
      timeSlot: '01/11, 17:00 - 19:00',
      deliveryAddressText: 'Av. Coronel José Inácio, 450 - Centro',
      dryVolumes: 3,
      coldVolumes: 1,
      separatorName: 'Lucas Andrade',
      deliverymanName: 'Roberto Motoboy',
      canCancel: false,
      items: [
        OrderItemRecord(
          productId: 'prod_006',
          productName: 'Arroz Branco Parboilizado Tipo 1 5kg',
          imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
          unitPrice: 24.90,
          requestQuantity: 2,
          foundQuantity: 2,
        ),
        OrderItemRecord(
          productId: 'prod_007',
          productName: 'Café Torrado e Moído Pilão 500g',
          imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500&q=80',
          unitPrice: 16.99,
          requestQuantity: 2,
          foundQuantity: 2,
        ),
        OrderItemRecord(
          productId: 'prod_005',
          productName: 'Leite Integral UHT Betânia 1 Litro',
          imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
          unitPrice: 4.39,
          requestQuantity: 3,
          foundQuantity: 3,
        ),
      ],
    ),
  ];

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get activeOrders =>
      _orders.where((o) => o.status != 'completed' && o.status != 'canceled' && o.status != 'cancelled').toList();
  List<OrderModel> get pastOrders =>
      _orders.where((o) => o.status == 'completed' || o.status == 'canceled' || o.status == 'cancelled').toList();
  bool get hasOrderInProgress => activeOrders.isNotEmpty;

  void addOrder(OrderModel newOrder) {
    _orders.insert(0, newOrder);
    pointsBalance += (newOrder.totalAmount * 2).round();
    raffleVouchersCount += (newOrder.totalAmount ~/ 50).clamp(1, 10);
    economyTotal += newOrder.discountValue;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final cleanCode = orderId.replaceAll(RegExp(r'\D'), '');
    final idx = _orders.indexWhere((o) =>
        o.id == orderId ||
        o.code == cleanCode ||
        (cleanCode.isNotEmpty && o.erpOrderId?.toString() == cleanCode));
    if (idx != -1) {
      if (_orders[idx].status != newStatus) {
        _orders[idx] = _orders[idx].copyWith(status: newStatus);
        notifyListeners();
      }
    }
  }

  OrderModel _parseErpOrder(Map<String, dynamic> data, {OrderModel? existing}) {
    final int? erpId = (data['id'] as num?)?.toInt() ?? existing?.erpOrderId;
    final String code = (data['orderCode'] ?? data['code'] ?? erpId?.toString() ?? existing?.code ?? '0000')
        .toString();
    final String id = existing?.id ?? 'ord_$code';
    final String status = (data['status'] ?? existing?.status ?? 'received').toString();
    final volumes = data['volumes'] is Map ? Map<String, dynamic>.from(data['volumes'] as Map) : const <String, dynamic>{};
    final int dryVol = (data['dryVolumes'] as num?)?.toInt() ??
        (volumes['dry'] as num?)?.toInt() ??
        existing?.dryVolumes ??
        1;
    final int coldVol = (data['coldVolumes'] as num?)?.toInt() ??
        (volumes['cold'] as num?)?.toInt() ??
        existing?.coldVolumes ??
        0;
    final String sepName = (data['separatorName'] ?? existing?.separatorName ?? 'Central Clipp ERP').toString();
    final String delivName = (data['deliverymanName'] ?? existing?.deliverymanName ?? 'Aguardando Despacho').toString();
    final String? pword = data['passwordNumber']?.toString() ?? existing?.passwordNumber;
    final double total = (data['billedTotal'] as num?)?.toDouble() ??
        (data['total'] as num?)?.toDouble() ??
        existing?.totalAmount ??
        0.0;
    final bool needsApproval = data['needsClientApproval'] == true;
    final bool clientApproved = data['clientApprovedChanges'] == true || (existing?.clientApprovedChanges ?? false);

    final rawItems = (data['items'] as List?) ?? const [];
    final List<OrderItemRecord> parsedItems = rawItems.whereType<Map>().map((m) {
      final map = Map<String, dynamic>.from(m);
      final reqQty = (map['requestQuantity'] as num?)?.toDouble() ??
          (map['quantity'] as num?)?.toDouble() ??
          (map['qty'] as num?)?.toDouble() ??
          1.0;
      final foundQty = (map['foundQuantity'] as num?)?.toDouble() ?? reqQty;
      final price = (map['unitPrice'] as num?)?.toDouble() ?? 0.0;
      return OrderItemRecord(
        id: (map['id'] ?? map['idProduto'] ?? 'item').toString(),
        productId: (map['idProduto'] ?? map['id'] ?? 'prod_001').toString(),
        productName: (map['name'] ?? 'Produto').toString(),
        weighable: map['weighable'] == true,
        unitPrice: price,
        requestQuantity: reqQty,
        foundQuantity: foundQty,
        notFound: map['notFound'] == true,
        substitutedBy: map['substitutedBy']?.toString(),
        observation: map['observation']?.toString(),
      );
    }).toList();

    if (existing != null) {
      return existing.copyWith(
        status: status,
        totalAmount: total > 0 ? total : existing.totalAmount,
        dryVolumes: dryVol,
        coldVolumes: coldVol,
        separatorName: sepName,
        deliverymanName: delivName,
        passwordNumber: pword,
        needsClientApproval: needsApproval,
        clientApprovedChanges: clientApproved,
        items: parsedItems.isNotEmpty ? parsedItems : existing.items,
      );
    }

    return OrderModel(
      id: id,
      code: code,
      erpOrderId: erpId,
      preSaleId: (data['preSaleId'] as num?)?.toInt() ?? erpId,
      date: DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime.now(),
      grossValue: (data['subtotal'] as num?)?.toDouble() ?? total,
      discountValue: (data['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      itemsCount: parsedItems.isNotEmpty ? parsedItems.length : 1,
      status: status,
      deliveryType: (data['fulfillmentMode'] ?? 'delivery').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'PIX').toString().toUpperCase(),
      timeSlot: (data['scheduledWindow'] ?? 'Hoje, 14:00 - 16:00').toString(),
      observation: data['observation']?.toString(),
      dryVolumes: dryVol,
      coldVolumes: coldVol,
      separatorName: sepName,
      deliverymanName: delivName,
      passwordNumber: pword,
      needsClientApproval: needsApproval,
      clientApprovedChanges: clientApproved,
      items: parsedItems,
    );
  }

  void syncOrderFromErp(Map<String, dynamic> data) {
    final String rawId = (data['id'] ?? data['orderCode'] ?? '').toString();
    final cleanCode = rawId.replaceAll(RegExp(r'\D'), '');
    final idx = _orders.indexWhere((o) =>
        o.id == rawId ||
        o.code == rawId ||
        (cleanCode.isNotEmpty &&
            (o.erpOrderId?.toString() == cleanCode ||
                o.code.replaceAll(RegExp(r'^0+'), '') == cleanCode.replaceAll(RegExp(r'^0+'), ''))));
    if (idx != -1) {
      _orders[idx] = _parseErpOrder(data, existing: _orders[idx]);
      notifyListeners();
    } else if (cleanCode.isNotEmpty) {
      _orders.insert(0, _parseErpOrder(data));
      notifyListeners();
    }
  }

  void syncOrdersListFromErp(List<Map<String, dynamic>> list) {
    var changed = false;
    for (final data in list.reversed) {
      final String rawId = (data['id'] ?? data['orderCode'] ?? '').toString();
      final cleanCode = rawId.replaceAll(RegExp(r'\D'), '');
      if (cleanCode.isEmpty) continue;
      final idx = _orders.indexWhere((o) =>
          o.id == rawId ||
          o.code == rawId ||
          o.erpOrderId?.toString() == cleanCode ||
          o.code.replaceAll(RegExp(r'^0+'), '') == cleanCode.replaceAll(RegExp(r'^0+'), ''));
      if (idx != -1) {
        _orders[idx] = _parseErpOrder(data, existing: _orders[idx]);
        changed = true;
      } else {
        _orders.insert(0, _parseErpOrder(data));
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void approveOrderChanges(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        clientApprovedChanges: true,
        needsClientApproval: false,
      );
      notifyListeners();
    }
  }

  void cancelOrder(String orderId, {required String reason, String? observation}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        status: 'canceled',
        canCancel: false,
        needsClientApproval: false,
        cancelReason: reason,
        cancelObservation: observation,
      );
      notifyListeners();
    }
  }

  // Check-in na Loja Física (`mutation_checkin.graphql`)
  void performStoreCheckIn() {
    if (!isCheckedInStore) {
      isCheckedInStore = true;
      pointsBalance += 50;
      raffleVouchersCount += 1;
      notifyListeners();
    }
  }

  // Cashback & Transferência (`mutation_transferBalance.graphql` / `mutation_exchangeBalance.graphql`)
  bool transferCashback({required String targetCpf, required double amount}) {
    if (amount <= 0 || amount > cashbackBalance) return false;
    cashbackBalance -= amount;
    notifyListeners();
    return true;
  }

  bool convertCashbackToGiftCard(double amount) {
    if (amount <= 0 || amount > cashbackBalance) return false;
    cashbackBalance -= amount;
    activeGiftCardBalance += amount;
    notifyListeners();
    return true;
  }

  bool redeemPointsForReward({required int pointsCost, double? cashbackAdded, double? voucherAdded}) {
    if (pointsCost > pointsBalance) return false;
    pointsBalance -= pointsCost;
    if (cashbackAdded != null) cashbackBalance += cashbackAdded;
    if (voucherAdded != null) activeGiftCardBalance += voucherAdded;
    notifyListeners();
    return true;
  }

  bool exchangePointsForSportsBets(int betsCount) {
    final int cost = betsCount * 100;
    if (pointsBalance < cost) return false;
    pointsBalance -= cost;
    sportsBetsAvailable += betsCount;
    notifyListeners();
    return true;
  }

  // Raspadinhas (`query_list_pending_scratches.graphql` & `query_list_used_scratches.graphql`)
  final List<Map<String, dynamic>> pendingScratches = [
    {
      'id': 'scr_101',
      'campaign': 'Festival de Aniversário do Mercadinho',
      'shopDate': 'Hoje • Cupom #048291 (R\$ 142,80)',
      'store': 'Mercadinho Matriz - Centro',
      'prizeTitle': 'VALE-COMPRA R\$ 15,00 + CUPOM AÇOUGUE',
      'prizeValue': 15.0,
      'isWinner': true,
    },
    {
      'id': 'scr_102',
      'campaign': 'Raspou Achou Fim de Semana',
      'shopDate': '02/11/2026 • Cupom #047102 (R\$ 98,40)',
      'store': 'Mercadinho Matriz - Centro',
      'prizeTitle': 'R\$ 5,00 DE CASHBACK NA CARTEIRA',
      'prizeValue': 5.0,
      'isWinner': true,
    },
  ];

  List<Map<String, dynamic>> get pendingScratchCards => pendingScratches;

  final List<Map<String, dynamic>> usedScratches = [
    {
      'id': 'scr_099',
      'campaign': 'Outubro Premiado Queira Mais',
      'shopDate': '24/10/2026 • Cupom #041820 (R\$ 215,10)',
      'scratchedAt': '24/10/2026 às 19:40',
      'store': 'Mercadinho Matriz - Centro',
      'prizeTitle': 'R\$ 10,00 DE CASHBACK RESGATADO',
      'prizeValue': 10.0,
      'isWinner': true,
    },
  ];

  void claimScratchPrize(String scratchId) {
    final index = pendingScratches.indexWhere((s) => s['id'] == scratchId);
    if (index != -1) {
      final item = Map<String, dynamic>.from(pendingScratches.removeAt(index));
      item['scratchedAt'] = 'Agora mesmo';
      usedScratches.insert(0, item);
      final double val = (item['prizeValue'] as num?)?.toDouble() ?? 0.0;
      cashbackBalance += val;
      economyTotal += val;
      notifyListeners();
    }
  }

  // Central de Notificações (`query_user_push_notifications.graphql`)
  final List<Map<String, dynamic>> pushNotificationItems = [
    {
      'id': 'notif_01',
      'title': '🗞️ Novo Jornal de Ofertas no Ar!',
      'body': 'Confira as ofertas de Fim de Semana com Picanha a R\$ 54,90/kg e Cerveja a R\$ 3,29.',
      'date': 'Hoje, 08:30',
      'read': false,
    },
    {
      'id': 'notif_02',
      'title': '⚖️ Pedido #8942 Pesado na Balança',
      'body': 'Sua separação foi concluída. Toque para revisar a pesagem de carnes e hortifrúti.',
      'date': 'Hoje, 09:05',
      'read': false,
    },
    {
      'id': 'notif_03',
      'title': '🎉 Você ganhou 1 Raspadinha e 2 Números da Sorte!',
      'body': 'Sua última compra gerou recompensas no Clube Queira Mais.',
      'date': 'Ontem, 19:15',
      'read': true,
    },
  ];

  int get unreadNotificationsCount =>
      pushNotificationItems.where((n) => n['read'] == false).length;

  void markAllNotificationsRead() {
    for (final n in pushNotificationItems) {
      n['read'] = true;
    }
    notifyListeners();
  }

  // Preferências de Notificações (`mutation_updateNotificationsSettings.graphql`)
  bool pushNotifications = true;
  bool whatsappNotifications = true;
  bool smsNotifications = false;
  bool emailNotifications = true;
  bool financialOptin = true;

  bool get optinPush => pushNotifications;
  bool get optinWhatsapp => whatsappNotifications;
  bool get optinSms => smsNotifications;
  bool get optinEmail => emailNotifications;

  void updateNotificationPrefs({
    bool? push,
    bool? whatsapp,
    bool? sms,
    bool? email,
    bool? financial,
  }) {
    if (push != null) pushNotifications = push;
    if (whatsapp != null) whatsappNotifications = whatsapp;
    if (sms != null) smsNotifications = sms;
    if (email != null) emailNotifications = email;
    if (financial != null) financialOptin = financial;
    notifyListeners();
  }

  void updateOptins({
    bool? push,
    bool? whatsapp,
    bool? sms,
    bool? email,
    bool? financial,
  }) {
    updateNotificationPrefs(
      push: push,
      whatsapp: whatsapp,
      sms: sms,
      email: email,
      financial: financial,
    );
  }

  void setGreenCoupon(bool enabled) {
    greenCouponEnabled = enabled;
    notifyListeners();
  }

  void confirmEmailValidation() {
    emailValidated = true;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? document,
    bool? isCnpj,
    String? email,
    String? phone,
    String? birthDate,
    String? profession,
    String? maritalStatus,
    String? educationLevel,
    String? incomeRange,
    int? residentsCount,
    int? childrenCount,
  }) {
    if (name != null) userName = name;
    if (document != null) userCpf = document;
    if (isCnpj != null) this.isCnpj = isCnpj;
    if (email != null) userEmail = email;
    if (phone != null) userPhone = phone;
    if (birthDate != null) this.birthDate = birthDate;
    if (profession != null) this.profession = profession;
    if (maritalStatus != null) this.maritalStatus = maritalStatus;
    if (educationLevel != null) this.educationLevel = educationLevel;
    if (incomeRange != null) this.incomeRange = incomeRange;
    if (residentsCount != null) {
      residentsNumber = residentsCount;
      this.residentsCount = '$residentsCount pessoas';
    }
    if (childrenCount != null) {
      childrenNumber = childrenCount;
      this.childrenCount = '$childrenCount filhos';
    }
    notifyListeners();
  }

  Future<void> saveProfileChanges({
    required String name,
    required String email,
    required String phone,
    required String birth,
    required String genderVal,
    required String job,
    required String marital,
    required String education,
    required String income,
    required String residents,
    required String children,
  }) async {
    userName = name;
    userEmail = email;
    userPhone = phone;
    birthDate = birth;
    gender = genderVal;
    profession = job;
    maritalStatus = marital;
    educationLevel = education;
    incomeRange = income;
    residentsCount = residents;
    childrenCount = children;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
  }
}
