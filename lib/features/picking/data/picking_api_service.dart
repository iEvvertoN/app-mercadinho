import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../catalog/data/catalog_api_service.dart';
import '../domain/picking_models.dart';

class PickingApiResponse {
  const PickingApiResponse({
    required this.ok,
    this.data,
    this.error,
    this.unsupported = false,
  });

  final bool ok;
  final Map<String, dynamic>? data;
  final String? error;
  final bool unsupported;

  static PickingApiResponse success([Map<String, dynamic>? data]) =>
      PickingApiResponse(ok: true, data: data);

  static PickingApiResponse failure(String error, {bool unsupported = false}) =>
      PickingApiResponse(ok: false, error: error, unsupported: unsupported);
}

/// Cliente HTTP do picking. Mesmo host do catálogo/pedidos
/// (`/api/marketplace/{id}/...`), para os três softwares falarem o mesmo
/// contrato — ver `docs/integracao.md`.
class PickingApiService {
  PickingApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);

  String get _id => CatalogApiService.idIntegradora.toString();

  Uri _uri(String base, String path) => Uri.parse('$base/api/marketplace/$_id$path');

  /// Fila de separação do dia.
  Future<PickingApiResponse> fetchTasks({required String assignee}) async {
    for (final base in CatalogApiService.candidateUrls) {
      try {
        final response = await _client
            .get(_uri(base, '/picking/tasks?assignee=${Uri.encodeComponent(assignee)}'))
            .timeout(_timeout);

        if (response.statusCode == 404 || response.statusCode == 501) {
          return PickingApiResponse.failure('sem endpoints de picking', unsupported: true);
        }
        if (response.statusCode != 200) {
          return PickingApiResponse.failure('HTTP ${response.statusCode}');
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) return PickingApiResponse.failure('resposta inválida');
        CatalogApiService.baseUrl = base;
        return PickingApiResponse.success(Map<String, dynamic>.from(decoded));
      } catch (error) {
        debugPrint('[PickingApi] tasks falhou em $base: $error');
      }
    }
    return PickingApiResponse.failure('sem conexão com o ERP');
  }

  Future<PickingApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    for (final base in CatalogApiService.candidateUrls) {
      try {
        final response = await _client
            .post(
              _uri(base, path),
              headers: const {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(body ?? const {}),
            )
            .timeout(_timeout);

        if (response.statusCode == 404 || response.statusCode == 501) {
          return PickingApiResponse.failure('endpoint ausente', unsupported: true);
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return PickingApiResponse.failure('HTTP ${response.statusCode}');
        }
        CatalogApiService.isConnectedToErp = true;
        CatalogApiService.baseUrl = base;
        return PickingApiResponse.success();
      } catch (error) {
        debugPrint('[PickingApi] POST $path falhou em $base: $error');
      }
    }
    return PickingApiResponse.failure('sem conexão com o ERP');
  }

  // ------------------------------------------------------------------ ações

  Future<PickingApiResponse> start(String orderId, String assignee) =>
      post('/picking/$orderId/start', body: {'assignee': assignee});

  Future<PickingApiResponse> scan(String orderId, String itemId, String barcode, double qty) =>
      post('/picking/$orderId/items/$itemId/scan', body: {'barcode': barcode, 'qty': qty});

  Future<PickingApiResponse> weigh(String orderId, String itemId, double grams) =>
      post('/picking/$orderId/items/$itemId/weigh', body: {'grams': grams});

  Future<PickingApiResponse> missing(String orderId, String itemId, String reason) =>
      post('/picking/$orderId/items/$itemId/missing', body: {'reason': reason});

  Future<PickingApiResponse> substitution(
    String orderId,
    String itemId, {
    required String toProductId,
    required String toProductName,
    required double toPrice,
  }) =>
      post('/picking/$orderId/items/$itemId/substitution', body: {
        'toProductId': toProductId,
        'toProductName': toProductName,
        'toPrice': toPrice,
      });

  Future<PickingApiResponse> decideSubstitution(String orderId, String itemId, bool approved) =>
      post('/picking/$orderId/items/$itemId/substitution/decision', body: {'approved': approved});

  Future<PickingApiResponse> seal(
    String orderId, {
    required String bagId,
    required BagTemperature temperature,
    required List<String> itemIds,
    required String sealNumber,
  }) =>
      post('/picking/$orderId/bags', body: {
        'bagId': bagId,
        'temperature': temperature.name,
        'itemIds': itemIds,
        'sealNumber': sealNumber,
      });

  Future<PickingApiResponse> finish(String orderId) => post('/picking/$orderId/finish');

  Future<PickingApiResponse> verify(String orderId, {required String by, required int volumes}) =>
      post('/picking/$orderId/verify', body: {'by': by, 'volumes': volumes});

  Future<PickingApiResponse> handOff(
    String orderId, {
    required String courierId,
    required bool passwordChecked,
  }) =>
      post('/picking/$orderId/handoff', body: {
        'courierId': courierId,
        'passwordChecked': passwordChecked,
      });

  void dispose() => _client.close();
}
