import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import 'mock_catalog_data.dart';

class ErpBannerItem {
  final String id;
  final String titulo;
  final String subtitulo;
  final String tag;
  final String? categoriaAlvo;

  const ErpBannerItem({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.tag,
    this.categoriaAlvo,
  });

  factory ErpBannerItem.fromJson(Map<String, dynamic> json) {
    return ErpBannerItem(
      id: (json['id'] ?? 'banner').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      subtitulo: (json['subtitulo'] ?? '').toString(),
      tag: (json['tag'] ?? 'OFERTA').toString(),
      categoriaAlvo: (json['categoriaAlvo'] ?? json['categoria_alvo'])?.toString(),
    );
  }
}

class ErpHomeCatalogPayload {
  final String storeName;
  final int totalActiveProducts;
  final int totalAllProducts;
  final List<ErpBannerItem> banners;
  final List<CategoryModel> categories;
  final List<ProductModel> clubOffers;
  final List<ProductModel> weighableHighlights;
  final List<ProductModel> featuredProducts;

  const ErpHomeCatalogPayload({
    required this.storeName,
    required this.totalActiveProducts,
    required this.totalAllProducts,
    required this.banners,
    required this.categories,
    required this.clubOffers,
    required this.weighableHighlights,
    required this.featuredProducts,
  });
}

/// Serviço de comunicação direta entre o `app_mercadinho` (Flutter) e o `clipp-server` (`/api/marketplace/catalog`)
class CatalogApiService {
  static String get initialBaseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        // Se estiver rodando via mobile_proxy.cjs (8088, 8443, 80, 443), Cloudflare Tunnel ou porta 3333,
        // o próprio origin faz proxy de /api/* para 127.0.0.1:3333.
        if (origin.isNotEmpty && origin != 'null' && Uri.base.port != 8080) {
          return origin;
        }
      } catch (_) {}
    }
    return 'http://127.0.0.1:3333';
  }

  static String baseUrl = initialBaseUrl;

  static String? customBaseUrl;

  static List<String> get candidateUrls {
    final list = <String>[];
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      list.add(customBaseUrl!.trim());
    }
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null' && Uri.base.port != 8080 && !list.contains(origin)) {
          list.add(origin);
        }
      } catch (_) {}
    }
    const fallbacks = [
      'http://192.168.101.72:3333',
      'http://127.0.0.1:3333',
      'http://100.75.105.40:3333',
      'http://192.168.101.51:3333',
      'http://192.168.101.6:3333',
    ];
    for (final f in fallbacks) {
      if (!list.contains(f)) list.add(f);
    }
    return list;
  }

  static int idIntegradora = 2;
  static bool isConnectedToErp = false;
  static int totalErpProductsCount = 0;

  /// Carrega os dados da Home e o catálogo completo do ERP (`CLIPP.FDB`)
  static Future<ErpHomeCatalogPayload?> syncWithErp({bool includeInactive = false}) async {
    for (final candidate in candidateUrls) {
      try {
        debugPrint('[CatalogApiService] Tentando sincronizar com ERP em: $candidate');
        final homeUri = Uri.parse(
          '$candidate/api/marketplace/$idIntegradora/catalog/home?limit=30&includeInactive=$includeInactive',
        );
        final catalogUri = Uri.parse(
          '$candidate/api/marketplace/$idIntegradora/catalog?limit=9000&includeInactive=$includeInactive',
        );

        final responses = await Future.wait([
          http.get(homeUri).timeout(const Duration(seconds: 10)),
          http.get(catalogUri).timeout(const Duration(seconds: 15)),
        ]);

        final homeRes = responses[0];
        final catalogRes = responses[1];

        if (homeRes.statusCode == 200 && catalogRes.statusCode == 200) {
          baseUrl = candidate;
          final Map<String, dynamic> homeJson = jsonDecode(utf8.decode(homeRes.bodyBytes));
          final Map<String, dynamic> catalogJson = jsonDecode(utf8.decode(catalogRes.bodyBytes));

          final List<CategoryModel> categories = ((homeJson['categories'] as List?) ?? const [])
              .whereType<Map>()
              .map((c) => CategoryModel.fromErpJson(Map<String, dynamic>.from(c)))
              .toList();

          final List<ProductModel> allProducts = ((catalogJson['products'] as List?) ?? const [])
              .whereType<Map>()
              .map((p) => ProductModel.fromErpJson(Map<String, dynamic>.from(p), baseUrl: baseUrl))
              .toList();

          final List<ProductModel> clubOffers = ((homeJson['clubOffers'] ?? homeJson['club_offers']) as List? ?? const [])
              .whereType<Map>()
              .map((p) => ProductModel.fromErpJson(Map<String, dynamic>.from(p), baseUrl: baseUrl))
              .toList();

          final List<ProductModel> weighableHighlights =
              ((homeJson['weighableHighlights'] ?? homeJson['weighable_highlights']) as List? ?? const [])
                  .whereType<Map>()
                  .map((p) => ProductModel.fromErpJson(Map<String, dynamic>.from(p), baseUrl: baseUrl))
                  .toList();

          final List<ProductModel> featuredProducts =
              ((homeJson['featuredProducts'] ?? homeJson['featured_products']) as List? ?? const [])
                  .whereType<Map>()
                  .map((p) => ProductModel.fromErpJson(Map<String, dynamic>.from(p), baseUrl: baseUrl))
                  .toList();

          final List<ErpBannerItem> banners = ((homeJson['banners'] as List?) ?? const [])
              .whereType<Map>()
              .map((b) => ErpBannerItem.fromJson(Map<String, dynamic>.from(b)))
              .toList();

          final int totalActive =
              ((homeJson['totalActiveProducts'] ?? homeJson['total_active_products'] ?? allProducts.length) as num)
                  .toInt();
          final int totalAll =
              ((homeJson['totalAllProducts'] ?? homeJson['total_all_products'] ?? allProducts.length) as num).toInt();

          if (allProducts.isNotEmpty) {
            MockCatalogData.setLiveErpData(
              erpProducts: allProducts,
              erpCategories: categories.isNotEmpty ? categories : null,
              erpClubOffers: clubOffers,
              erpWeighable: weighableHighlights,
            );
            isConnectedToErp = true;
            totalErpProductsCount = totalActive;
          }

          debugPrint('[CatalogApiService] Conectado com sucesso ao ERP! Total de produtos: $totalActive');
          return ErpHomeCatalogPayload(
            storeName: (homeJson['storeName'] ?? homeJson['store_name'] ?? 'Mercadinho Casa de Vó').toString(),
            totalActiveProducts: totalActive,
            totalAllProducts: totalAll,
            banners: banners,
            categories: categories,
            clubOffers: clubOffers,
            weighableHighlights: weighableHighlights,
            featuredProducts: featuredProducts,
          );
        } else {
          debugPrint('[CatalogApiService] Resposta não-200 de $candidate: home=${homeRes.statusCode}, catalog=${catalogRes.statusCode}');
        }
      } catch (e) {
        debugPrint('[CatalogApiService] Erro conectando a $candidate: $e');
      }
    }
    isConnectedToErp = false;
    return null;
  }

  /// Busca textual e filtrada em tempo real direto no endpoint `/api/marketplace/catalog`
  static Future<List<ProductModel>?> searchInErp({
    String? query,
    String? categoryId,
    String? subcategoryId,
    bool onlyOffers = false,
    bool onlyWeighable = false,
    String? sortBy,
    int limit = 200,
  }) async {
    try {
      final activeBase = baseUrl.isNotEmpty ? baseUrl : initialBaseUrl;
      final Map<String, String> params = {
        'limit': limit.toString(),
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (subcategoryId != null && subcategoryId.isNotEmpty) 'subcategoryId': subcategoryId,
        if (onlyOffers) 'onlyOffers': 'true',
        if (onlyWeighable) 'onlyWeighable': 'true',
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      };

      final uri = Uri.parse('$activeBase/api/marketplace/$idIntegradora/catalog').replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final List raw = (data['products'] as List?) ?? const [];
        isConnectedToErp = true;
        return raw
            .whereType<Map>()
            .map((p) => ProductModel.fromErpJson(Map<String, dynamic>.from(p), baseUrl: activeBase))
            .toList();
      }
    } catch (e) {
      debugPrint('[CatalogApiService] searchInErp erro: $e');
    }
    return null;
  }

  /// Consulta instantânea de código de barras na gôndola (`/api/marketplace/catalog/barcode/:code`)
  static Future<ProductModel?> lookupBarcodeInErp(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;
    try {
      final activeBase = baseUrl.isNotEmpty ? baseUrl : initialBaseUrl;
      final uri = Uri.parse(
        '$activeBase/api/marketplace/$idIntegradora/catalog/barcode/${Uri.encodeComponent(clean)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['found'] == true && data['product'] is Map) {
          isConnectedToErp = true;
          return ProductModel.fromErpJson(
            Map<String, dynamic>.from(data['product'] as Map),
            baseUrl: activeBase,
          );
        }
      }
    } catch (e) {
      debugPrint('[CatalogApiService] lookupBarcodeInErp erro: $e');
    }
    return MockCatalogData.findByBarcode(clean);
  }

  /// Gravação atômica do pedido de compra no ERP (TB_PEDIDO_VENDA + TB_PREVENDA / F10 no PDV)
  static Future<Map<String, dynamic>?> submitOrder(Map<String, dynamic> orderPayload) async {
    for (final candidate in candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/api/marketplace/$idIntegradora/orders');
        debugPrint('[CatalogApiService] Enviando pedido para: $uri');
        final res = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(orderPayload),
            )
            .timeout(const Duration(seconds: 14));

        if (res.statusCode == 200 || res.statusCode == 201) {
          baseUrl = candidate;
          isConnectedToErp = true;
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          debugPrint('[CatalogApiService] Pedido gravado no ERP com sucesso! orderId=${data['orderId']}, senha=${data['passwordNumber']}');
          return data;
        } else {
          debugPrint('[CatalogApiService] submitOrder status=${res.statusCode} de $candidate: ${res.body}');
        }
      } catch (e) {
        debugPrint('[CatalogApiService] submitOrder falha em $candidate: $e');
      }
    }
    return null;
  }

  /// Consulta em tempo real o status atualizado do pedido no ERP
  static Future<Map<String, dynamic>?> fetchOrderStatus(int orderId) async {
    for (final candidate in candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/api/marketplace/$idIntegradora/orders/$orderId');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data['success'] == true && data['order'] is Map) {
            return Map<String, dynamic>.from(data['order'] as Map);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Lista todos os pedidos recentes do ERP / Store unificado
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    for (final candidate in candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/api/marketplace/$idIntegradora/orders');
        final res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data['success'] == true && data['orders'] is List) {
            return (data['orders'] as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList();
          }
        }
      } catch (_) {}
    }
    return const [];
  }

  /// Aprova ou recusa alterações de pesagem / substituição (>20%) do pedido no servidor
  static Future<bool> approveOrderChanges(int orderId, {bool approved = true}) async {
    for (final candidate in candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/api/marketplace/$idIntegradora/orders/$orderId/approve');
        final res = await http
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode({'approved': approved}),
            )
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }
}


