import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../catalog/data/catalog_api_service.dart';
import '../domain/models/delivery_models.dart';

/// Resultado de uma chamada de entrega.
///
/// `unsupported` existe para separar "o ERP ainda não tem essa rota" (404/501)
/// de "a rede caiu" — o primeiro leva ao modo demonstração, o segundo à fila
/// offline. Sem essa distinção, o app tentaria reenviar para sempre um endpoint
/// que não existe.
class DeliveryApiResponse {
  const DeliveryApiResponse({
    required this.ok,
    this.statusCode,
    this.data,
    this.error,
    this.unsupported = false,
  });

  final bool ok;
  final int? statusCode;
  final Map<String, dynamic>? data;
  final String? error;
  final bool unsupported;

  static DeliveryApiResponse success(Map<String, dynamic>? data) =>
      DeliveryApiResponse(ok: true, statusCode: 200, data: data);

  static DeliveryApiResponse failure(String error, {int? statusCode, bool unsupported = false}) =>
      DeliveryApiResponse(ok: false, error: error, statusCode: statusCode, unsupported: unsupported);

  bool get isOffline => !ok && !unsupported;
}

/// Cliente HTTP do módulo de entregas.
///
/// Fala o mesmo contrato do restante do app (`/api/marketplace/{id}/...`) e
/// reaproveita a descoberta de host do [CatalogApiService], para não existirem
/// duas listas de endereços divergindo com o tempo.
class DeliveryApiService {
  DeliveryApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _readTimeout = Duration(seconds: 12);

  String get _integrationId => CatalogApiService.idIntegradora.toString();

  List<String> get _candidates => CatalogApiService.candidateUrls;

  Uri _uri(String base, String path, [Map<String, String>? query]) =>
      Uri.parse('$base/api/marketplace/$_integrationId$path')
          .replace(queryParameters: query);

  /// Busca a rota do dia do entregador.
  Future<DeliveryApiResponse> fetchRoute({required String courierId}) async {
    for (final base in _candidates) {
      try {
        final response = await _client
            .get(_uri(base, '/delivery/routes', {'courierId': courierId}))
            .timeout(_readTimeout);

        if (response.statusCode == 404 || response.statusCode == 501) {
          return DeliveryApiResponse.failure(
            'Endpoint de rotas não disponível neste ERP',
            statusCode: response.statusCode,
            unsupported: true,
          );
        }
        if (response.statusCode != 200) {
          return DeliveryApiResponse.failure(
            'HTTP ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) {
          return DeliveryApiResponse.failure('Resposta de rota inválida');
        }
        final map = Map<String, dynamic>.from(decoded);

        // Aceita tanto `{success, route}` quanto a rota direta no corpo.
        final routeJson = map['route'] is Map ? Map<String, dynamic>.from(map['route'] as Map) : map;
        CatalogApiService.baseUrl = base;
        return DeliveryApiResponse.success(routeJson);
      } catch (error) {
        debugPrint('[DeliveryApi] fetchRoute falhou em $base: $error');
      }
    }
    return DeliveryApiResponse.failure('Sem conexão com o ERP');
  }

  /// Publica um evento de status do pedido (leve: geo + hora + versão).
  Future<DeliveryApiResponse> pushStatus({
    required String orderId,
    required StopStatus status,
    required DateTime at,
    double? latitude,
    double? longitude,
    String? failureReason,
    String appVersion = '1.0.0',
    String? courierId,
  }) async {
    final body = <String, dynamic>{
      'status': stopStatusToWire(status),
      'at': at.toIso8601String(),
      'lat': latitude,
      'lng': longitude,
      'appVersion': appVersion,
      'source': 'courier',
      if (courierId != null) 'courierId': courierId,
      if (failureReason != null) 'failureReason': failureReason,
    };
    return _post('/orders/$orderId/status', body);
  }

  /// Publica a prova de entrega (senha e/ou assinatura).
  Future<DeliveryApiResponse> pushProof(DeliveryProof proof, {String? courierId}) =>
      _post('/orders/${proof.orderId}/proof', {
        ...proof.toJson(),
        if (courierId != null) 'courierId': courierId,
      });

  /// Heartbeat do turno. Mantido barato de propósito: só sinaliza presença.
  Future<DeliveryApiResponse> pushShift({
    required String courierId,
    required bool open,
    required DateTime at,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'courierId': courierId,
      'open': open,
      'at': at.toIso8601String(),
      'lat': latitude,
      'lng': longitude,
      'source': 'courier',
    };
    return _post('/delivery/shift', body);
  }

  /// Pedidos faturados aguardando atribuição (tela de despacho).
  Future<DeliveryApiResponse> fetchDispatch() async {
    for (final base in _candidates) {
      try {
        final response = await _client
            .get(_uri(base, '/delivery/dispatch'))
            .timeout(_readTimeout);

        if (response.statusCode == 404 || response.statusCode == 501) {
          return DeliveryApiResponse.failure(
            'Despacho não disponível neste ERP',
            statusCode: response.statusCode,
            unsupported: true,
          );
        }
        if (response.statusCode != 200) {
          return DeliveryApiResponse.failure('HTTP ${response.statusCode}');
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) return DeliveryApiResponse.failure('resposta inválida');
        CatalogApiService.baseUrl = base;
        return DeliveryApiResponse.success(Map<String, dynamic>.from(decoded));
      } catch (error) {
        debugPrint('[DeliveryApi] fetchDispatch falhou em $base: $error');
      }
    }
    return DeliveryApiResponse.failure('Sem conexão com o ERP');
  }

  /// Atribui pedidos a um entregador; o servidor devolve a rota já ordenada.
  Future<DeliveryApiResponse> assignRoute({
    required String courierId,
    required List<String> orderIds,
  }) =>
      _post('/delivery/routes', {'courierId': courierId, 'orderIds': orderIds});

  Future<DeliveryApiResponse> _post(String path, Map<String, dynamic> body) async {
    for (final base in _candidates) {
      try {
        final response = await _client
            .post(
              _uri(base, path),
              headers: const {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_readTimeout);

        if (response.statusCode == 404 || response.statusCode == 501) {
          return DeliveryApiResponse.failure(
            'Endpoint não disponível neste ERP',
            statusCode: response.statusCode,
            unsupported: true,
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          String errMessage = 'HTTP ${response.statusCode}';
          if (response.bodyBytes.isNotEmpty) {
            try {
              final decoded = jsonDecode(utf8.decode(response.bodyBytes));
              if (decoded is Map && decoded['error'] != null) {
                errMessage = decoded['error'].toString();
              }
            } catch (_) {}
          }
          return DeliveryApiResponse.failure(
            errMessage,
            statusCode: response.statusCode,
          );
        }

        CatalogApiService.isConnectedToErp = true;
        CatalogApiService.baseUrl = base;
        Map<String, dynamic>? payload;
        if (response.bodyBytes.isNotEmpty) {
          try {
            final decoded = jsonDecode(utf8.decode(response.bodyBytes));
            if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
          } catch (_) {
            // Sucesso sem corpo JSON é aceitável para eventos.
          }
        }
        return DeliveryApiResponse.success(payload);
      } catch (error) {
        debugPrint('[DeliveryApi] POST $path falhou em $base: $error');
      }
    }
    return DeliveryApiResponse.failure('Sem conexão com o ERP');
  }

  void dispose() => _client.close();
}
