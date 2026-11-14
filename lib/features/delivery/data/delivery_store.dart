import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/delivery_models.dart';

/// Persistência local do turno, da fila e da última rota.
///
/// Existe por um motivo específico: o entregador perde sinal no meio da rua e
/// o app não pode depender do ERP para lembrar em que pé estava a entrega.
class DeliveryStore {
  static const _courierKey = 'delivery.courier.v1';
  static const _shiftKey = 'delivery.shift.v1';
  static const _queueKey = 'delivery.queue.v1';
  static const _routeKey = 'delivery.route.v1';
  static const _lastSyncKey = 'delivery.lastSync.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, String>?> loadCourier() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_courierKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          'id': (decoded['id'] ?? '').toString(),
          'name': (decoded['name'] ?? '').toString(),
        };
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCourier({required String id, required String name}) async {
    final prefs = await _prefs;
    await prefs.setString(_courierKey, jsonEncode({'id': id, 'name': name}));
  }

  Future<({bool open, DateTime? startedAt})> loadShift() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_shiftKey);
    if (raw == null || raw.isEmpty) return (open: false, startedAt: null);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return (
          open: decoded['open'] == true,
          startedAt: DateTime.tryParse((decoded['startedAt'] ?? '').toString()),
        );
      }
    } catch (_) {}
    return (open: false, startedAt: null);
  }

  Future<void> saveShift({required bool open, DateTime? startedAt}) async {
    final prefs = await _prefs;
    await prefs.setString(
      _shiftKey,
      jsonEncode({'open': open, 'startedAt': startedAt?.toIso8601String()}),
    );
  }

  Future<List<PendingEvent>> loadQueue() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_queueKey) ?? const <String>[];
    final events = <PendingEvent>[];
    for (final item in raw) {
      final event = PendingEvent.decode(item);
      if (event != null) events.add(event);
    }
    return events;
  }

  Future<void> saveQueue(List<PendingEvent> events) async {
    final prefs = await _prefs;
    await prefs.setStringList(_queueKey, events.map((e) => e.encode()).toList());
  }

  Future<DeliveryRoute?> loadRoute() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_routeKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return DeliveryRoute.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveRoute(DeliveryRoute? route) async {
    final prefs = await _prefs;
    if (route == null) {
      await prefs.remove(_routeKey);
      return;
    }
    await prefs.setString(_routeKey, jsonEncode(route.toJson()));
  }

  Future<DateTime?> loadLastSync() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastSync(DateTime at) async {
    final prefs = await _prefs;
    await prefs.setString(_lastSyncKey, at.toIso8601String());
  }
}
