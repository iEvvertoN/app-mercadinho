import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/picking_api_service.dart';
import '../data/seal_printer.dart';
import '../domain/picking_models.dart';
import '../domain/seal_label.dart';

enum PickingMode { live, demo }

/// Estado da separação.
///
/// Regra: a **regra** vive no `PickingTask` (domínio); o controller só orquestra,
/// persiste e avisa o ERP. Assim a operação continua funcionando com o ERP fora
/// do ar e a tela nunca decide regra de negócio.
class PickingController extends ChangeNotifier {
  PickingController({
    PickingApiService? api,
    SealPrinter? printer,
    SealNumberGenerator? sealNumbers,
  })  : _api = api ?? PickingApiService(),
        _printer = printer ?? SealPrinter(),
        _sealNumbers = sealNumbers ?? SealNumberGenerator();

  final PickingApiService _api;
  final SealPrinter _printer;
  final SealNumberGenerator _sealNumbers;

  static const String _assigneeKey = 'picking.assignee';

  String assignee = 'Separador';
  String verifier = 'Conferente';

  List<PickingTask> tasks = <PickingTask>[];
  PickingMode mode = PickingMode.live;
  bool loading = false;
  String? errorMessage;
  String? lastSyncWarning;

  bool _disposed = false;
  Timer? _pollTimer;

  List<PickingTask> get queue =>
      tasks.where((t) => t.status == PickingStatus.waiting).toList();

  List<PickingTask> get inProgress => tasks
      .where((t) => t.status == PickingStatus.inProgress || t.status == PickingStatus.packing)
      .toList();

  List<PickingTask> get done => tasks.where((t) => t.status.index >= PickingStatus.ready.index).toList();

  PickingTask? taskByOrderId(String orderId) {
    for (final task in tasks) {
      if (task.orderId == orderId) return task;
    }
    return null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    assignee = prefs.getString(_assigneeKey) ?? 'Separador';
    verifier = prefs.getString('picking.verifier') ?? 'Conferente';
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_disposed && !loading) {
        refresh(silent: true);
      }
    });
  }

  Future<void> setAssignee(String value) async {
    assignee = value.trim().isEmpty ? 'Separador' : value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assigneeKey, assignee);
    _notify();
  }

  Future<void> setVerifier(String value) async {
    verifier = value.trim().isEmpty ? 'Conferente' : value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picking.verifier', verifier);
    _notify();
  }

  Future<void> refresh({bool silent = false}) async {
    if (loading) return;
    if (!silent) {
      loading = true;
      _notify();
    }

    final response = await _api.fetchTasks(assignee: assignee);
    if (response.ok && response.data != null) {
      final raw = (response.data!['tasks'] as List?) ?? const [];
      final parsed = raw
          .whereType<Map>()
          .map((m) => _taskFromJson(Map<String, dynamic>.from(m)))
          .whereType<PickingTask>()
          .toList();
      if (parsed.isNotEmpty) {
        tasks = parsed;
        mode = PickingMode.live;
        errorMessage = null;
      } else if (!silent && tasks.isEmpty) {
        tasks = _demoTasks();
        mode = PickingMode.demo;
      }
    } else if (response.unsupported) {
      tasks = _demoTasks();
      mode = PickingMode.demo;
      errorMessage = null;
    } else if (!silent) {
      errorMessage = 'Sem conexão com o ERP. A fila abaixo é local.';
      if (tasks.isEmpty) tasks = _demoTasks();
    }

    loading = false;
    _notify();
  }

  /// Executa uma ação do domínio e devolve o resultado para a tela mostrar.
  /// Avisa o ERP em seguida; falha de rede não desfaz a ação local.
  Future<PickingResult> run(
    PickingTask task,
    PickingResult Function() action, {
    String? path,
    Map<String, dynamic>? body,
  }) async {
    final result = action();
    if (!result.ok) return result;

    if (path != null) {
      final response = await _api.post(path, body: body);
      lastSyncWarning = response.ok ? null : 'Ação registrada localmente; ERP não respondeu.';
    }
    _notify();
    return result;
  }

  Future<PickingResult> startTask(PickingTask task) => run(
        task,
        () => task.start(assignee),
        path: '/picking/${task.orderId}/start',
        body: {'assignee': assignee},
      );

  Future<PickingResult> scan(PickingTask task, String itemId, String barcode, {double? qty}) => run(
        task,
        () => task.scan(itemId, barcode: barcode, quantity: qty),
        path: '/picking/${task.orderId}/items/$itemId/scan',
        body: {'barcode': barcode, if (qty != null) 'qty': qty},
      );

  Future<PickingResult> weigh(PickingTask task, String itemId, double grams) => run(
        task,
        () => task.weigh(itemId, grams: grams),
        path: '/picking/${task.orderId}/items/$itemId/weigh',
        body: {'grams': grams},
      );

  Future<PickingResult> markMissing(PickingTask task, String itemId, String reason) => run(
        task,
        () => task.markMissing(itemId, reason: reason),
        path: '/picking/${task.orderId}/items/$itemId/missing',
        body: {'reason': reason},
      );

  Future<PickingResult> proposeSubstitution(
    PickingTask task,
    String itemId, {
    required String toProductId,
    required String toProductName,
    required double toPrice,
  }) =>
      run(
        task,
        () => task.proposeSubstitution(
          itemId,
          toProductId: toProductId,
          toProductName: toProductName,
          toPrice: toPrice,
        ),
        path: '/picking/${task.orderId}/items/$itemId/substitution',
        body: {'toProductId': toProductId, 'toProductName': toProductName, 'toPrice': toPrice},
      );

  Future<PickingResult> decideSubstitution(PickingTask task, String itemId, bool approved) => run(
        task,
        () => task.decideSubstitution(itemId, approved: approved),
        path: '/picking/${task.orderId}/items/$itemId/substitution/decision',
        body: {'approved': approved},
      );

  /// Fecha a separação criando as sacolas e lacres propostos.
  Future<({PickingResult result, List<SealLabel> labels})> sealAndFinish(
    PickingTask task, {
    DateTime? now,
  }) async {
    if (task.hasPendingItems) {
      return (
        result: const PickingResult.fail('Ainda há itens pendentes.'),
        labels: const <SealLabel>[],
      );
    }

    final labels = <SealLabel>[];
    final proposals = proposeBags(task);

    for (final proposal in proposals) {
      final seal = await _sealNumbers.next(now: now);
      final sealResult = task.addBag(
        bagId: proposal.bagId,
        temperature: proposal.temperature,
        itemIds: proposal.itemIds,
      );
      if (!sealResult.ok) {
        return (result: sealResult, labels: labels);
      }
      final sealed = task.sealBag(proposal.bagId, sealNumber: seal);
      if (!sealed.ok) return (result: sealed, labels: labels);

      final label = SealLabel(
        sealNumber: seal,
        orderId: task.orderId,
        orderCode: task.code,
        bagId: proposal.bagId,
        temperature: proposal.temperature,
        itemCount: proposal.itemIds.length,
        createdAt: now ?? DateTime.now(),
      );
      labels.add(label);

      await _api.seal(
        task.orderId,
        bagId: proposal.bagId,
        temperature: proposal.temperature,
        itemIds: proposal.itemIds,
        sealNumber: seal,
      );
    }

    final finish = task.finish();
    if (!finish.ok) return (result: finish, labels: labels);

    final response = await _api.finish(task.orderId);
    lastSyncWarning = response.ok ? null : 'Separação fechada localmente; ERP não respondeu.';
    _notify();
    return (result: const PickingResult.ok(), labels: labels);
  }

  Future<PrinterResult> printLabel(SealLabel label) => _printer.print(label);

  Future<PrinterConfig> printerConfig() => _printer.config();

  Future<void> configurePrinter(String host, int port) =>
      _printer.configure(PrinterConfig(host: host, port: port));

  String previewLabel(SealLabel label) => _printer.preview(label);

  Future<PickingResult> verifyTask(PickingTask task, {required int volumes}) async {
    final result = task.verify(by: verifier, volumesCounted: volumes);
    if (!result.ok) return result;
    await _api.verify(task.orderId, by: verifier, volumes: volumes);
    _notify();
    return result;
  }

  Future<PickingResult> handOff(PickingTask task, {required String courierId, required bool passwordChecked}) async {
    final result = task.handOff(courierId: courierId, passwordChecked: passwordChecked);
    if (!result.ok) return result;
    await _api.handOff(task.orderId, courierId: courierId, passwordChecked: passwordChecked);
    _notify();
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ demo

  /// Reconstrói a tarefa a partir do ERP, **preservando o que já foi feito**:
  /// separador pode fechar o app e voltar que o progresso continua lá.
  PickingTask? _taskFromJson(Map<String, dynamic> json) {
    final items = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) {
          final map = Map<String, dynamic>.from(m);
          final pick = map['pick'] is Map
              ? Map<String, dynamic>.from(map['pick'] as Map)
              : const <String, dynamic>{};

          final item = PickingItem(
            id: (map['id'] ?? map['itemId'] ?? '').toString(),
            productId: (map['productId'] ?? '').toString(),
            name: (map['name'] ?? 'Produto').toString(),
            barcode: (map['barcode'] ?? '').toString(),
            requestedQty: (map['requestedQty'] as num?)?.toDouble() ?? 1,
            unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
            weighable: map['weighable'] == true,
            unit: (map['unit'] ?? 'UN').toString(),
            aisle: map['aisle']?.toString(),
            isCold: map['isCold'] == true,
          );

          item.status = _itemStatusFromWire(pick['status']);
          item.foundQty = (pick['foundQty'] as num?)?.toDouble() ?? 0;
          item.weightGrams = (pick['weightGrams'] as num?)?.toDouble();
          if (pick['missingReason'] != null) {
            item.missingReason = pick['missingReason'].toString();
          }
          final substitution = pick['substitution'];
          if (substitution is Map) {
            final data = Map<String, dynamic>.from(substitution);
            final proposed = PickingSubstitution(
              fromProductId: item.productId,
              fromProductName: item.name,
              fromPrice: item.unitPrice,
              toProductId: (data['toProductId'] ?? '').toString(),
              toProductName: (data['toProductName'] ?? '').toString(),
              toPrice: (data['toPrice'] as num?)?.toDouble() ?? item.unitPrice,
            );
            proposed.approval = _approvalFromWire(data['approval']);
            item.substitution = proposed;
          }
          return item;
        })
        .toList();

    if (items.isEmpty) return null;

    final task = PickingTask(
      orderId: (json['orderId'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      items: items,
      assigneeId: json['assignee']?.toString(),
      verifiedBy: json['verifiedBy']?.toString(),
      volumesCounted: (json['volumesCounted'] as num?)?.toInt(),
      courierId: json['courierId']?.toString(),
      passwordChecked: json['passwordChecked'] == true,
      status: _taskStatusFromWire(json['status'], json['pickingStatus'], items),
    );

    final bags = json['bags'];
    if (bags is List) {
      for (final raw in bags.whereType<Map>()) {
        final bag = Map<String, dynamic>.from(raw);
        task.bags.add(
          PickingBag(
            id: (bag['bagId'] ?? '').toString(),
            temperature: bag['temperature'] == 'cold' ? BagTemperature.cold : BagTemperature.dry,
            itemIds: ((bag['itemIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
            sealNumber: bag['sealNumber']?.toString(),
            sealedAt: DateTime.tryParse((bag['sealedAt'] ?? '').toString()),
          ),
        );
      }
    }
    return task;
  }

  PickingStatus _taskStatusFromWire(
    Object? wire,
    Object? pickingStatusWire,
    List<PickingItem> items,
  ) {
    switch (pickingStatusWire?.toString()) {
      case 'handed_off':
        return PickingStatus.handedOff;
      case 'verified':
        return PickingStatus.verified;
      case 'ready':
        return PickingStatus.ready;
    }
    switch (wire?.toString()) {
      case 'picking':
        return PickingStatus.inProgress;
      case 'ready_to_invoice':
        return PickingStatus.ready;
      case 'invoiced':
      case 'delivering':
      case 'completed':
        return PickingStatus.handedOff;
      case 'canceled':
      case 'cancelled':
        return PickingStatus.canceled;
      case 'received':
        return PickingStatus.waiting;
    }
    return items.any((item) => item.isResolved) ? PickingStatus.inProgress : PickingStatus.waiting;
  }

  ItemPickStatus _itemStatusFromWire(Object? wire) {
    switch (wire?.toString()) {
      case 'found':
        return ItemPickStatus.found;
      case 'missing':
        return ItemPickStatus.missing;
      case 'substituted':
        return ItemPickStatus.substituted;
      case 'given_up':
        return ItemPickStatus.givenUp;
    }
    return ItemPickStatus.pending;
  }

  SubstitutionApproval _approvalFromWire(Object? wire) {
    switch (wire?.toString()) {
      case 'approved':
        return SubstitutionApproval.approved;
      case 'rejected':
        return SubstitutionApproval.rejected;
      case 'expired':
        return SubstitutionApproval.expired;
      case 'pending':
        return SubstitutionApproval.pending;
    }
    return SubstitutionApproval.notRequired;
  }

  List<PickingTask> _demoTasks() => [
        PickingTask(
          orderId: '9001',
          code: '1042',
          assigneeId: assignee,
          items: [
            PickingItem(
              id: 'i1',
              productId: 'p1',
              name: 'Arroz Branco 5kg',
              barcode: '7891234567890',
              requestedQty: 2,
              unitPrice: 24.90,
              aisle: 'A3',
            ),
            PickingItem(
              id: 'i2',
              productId: 'p2',
              name: 'Leite Integral 1L',
              barcode: '7891000315507',
              requestedQty: 3,
              unitPrice: 4.39,
              aisle: 'A5',
              isCold: true,
            ),
            PickingItem(
              id: 'i3',
              productId: 'p3',
              name: 'Tomate (kg)',
              barcode: '2000000000017',
              requestedQty: 0.5,
              unitPrice: 7.99,
              weighable: true,
              unit: 'kg',
              aisle: 'B1',
              isCold: true,
            ),
          ],
        ),
        PickingTask(
          orderId: '9002',
          code: '1043',
          items: [
            PickingItem(
              id: 'j1',
              productId: 'p4',
              name: 'Café Pilão 500g',
              barcode: '7896006711010',
              requestedQty: 2,
              unitPrice: 16.99,
              aisle: 'A2',
            ),
            PickingItem(
              id: 'j2',
              productId: 'p5',
              name: 'Pão Francês (kg)',
              barcode: '2000000000024',
              requestedQty: 0.6,
              unitPrice: 14.90,
              weighable: true,
              unit: 'kg',
              aisle: 'C1',
            ),
          ],
        ),
      ];
}
