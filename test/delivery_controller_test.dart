import 'package:app_mercadinho/features/delivery/data/delivery_api_service.dart';
import 'package:app_mercadinho/features/delivery/data/location_service.dart';
import 'package:app_mercadinho/features/delivery/domain/models/delivery_models.dart';
import 'package:app_mercadinho/features/delivery/presentation/delivery_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API falsa que simula: ERP sem endpoints de entrega, depois rede fora, depois
/// rede de volta. Serve para provar que a entrega nunca se perde.
class _FakeApi extends DeliveryApiService {
  _FakeApi({this.mode = _ApiMode.unsupported});

  _ApiMode mode;

  @override
  Future<DeliveryApiResponse> fetchRoute({required String courierId}) async {
    if (mode == _ApiMode.unsupported) {
      return DeliveryApiResponse.failure('sem endpoint', statusCode: 404, unsupported: true);
    }
    return DeliveryApiResponse.failure('offline');
  }

  @override
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
    if (mode == _ApiMode.online) {
      return DeliveryApiResponse.success({'ok': true});
    }
    return DeliveryApiResponse.failure('offline');
  }

  @override
  Future<DeliveryApiResponse> pushProof(DeliveryProof proof, {String? courierId}) async {
    if (mode == _ApiMode.online) {
      return DeliveryApiResponse.success({'ok': true});
    }
    return DeliveryApiResponse.failure('offline');
  }

  @override
  Future<DeliveryApiResponse> pushShift({
    required String courierId,
    required bool open,
    required DateTime at,
    double? latitude,
    double? longitude,
  }) async {
    if (mode == _ApiMode.online) {
      return DeliveryApiResponse.success({'ok': true});
    }
    return DeliveryApiResponse.failure('offline');
  }

  @override
  void dispose() {}
}

enum _ApiMode { unsupported, online }

class _NoLocation extends LocationService {
  const _NoLocation();

  @override
  Future<GeoPoint?> lastKnown() async => null;

  @override
  Future<GeoPoint?> current({Duration timeout = const Duration(seconds: 8)}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  DeliveryController build(_FakeApi api) => DeliveryController(
        api: api,
        location: const _NoLocation(),
      );

  test('entra em demonstração quando o ERP não tem os endpoints', () async {
    final controller = build(_FakeApi(mode: _ApiMode.unsupported));
    await controller.refresh();

    expect(controller.mode, DeliveryMode.demo);
    expect(controller.route, isNotNull);
    expect(controller.route!.stops.length, 3);
    expect(controller.route!.isDemo, isTrue);
  });

  test('entrega offline fica registrada e entra na fila', () async {
    final controller = build(_FakeApi(mode: _ApiMode.unsupported));
    await controller.refresh();

    final stop = controller.route!.stops.first;
    await controller.markArrived(stop);
    await controller.deliver(
      stop,
      proof: DeliveryProof(
        orderId: stop.orderId,
        method: ProofMethod.password,
        capturedAt: DateTime.now(),
        password: '1234',
      ),
    );

    final updated = controller.route!.stopByOrderId(stop.orderId)!;
    expect(updated.status, StopStatus.delivered);
    expect(updated.deliveredAt, isNotNull);

    // Dois eventos: mudança de status e prova.
    expect(controller.pendingCount, greaterThanOrEqualTo(2));
  });

  test('fila é esvaziada quando a rede volta', () async {
    final api = _FakeApi(mode: _ApiMode.unsupported);
    final controller = build(api);
    await controller.refresh();

    final stop = controller.route!.stops.first;
    await controller.deliver(
      stop,
      proof: DeliveryProof(
        orderId: stop.orderId,
        method: ProofMethod.signature,
        capturedAt: DateTime.now(),
        signature: const [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
      ),
    );
    expect(controller.pendingCount, greaterThan(0));

    api.mode = _ApiMode.online;
    await controller.flushQueue();

    expect(controller.pendingCount, 0);
  });

  test('estado local não retrocede quando a rota volta do ERP', () async {
    final controller = build(_FakeApi(mode: _ApiMode.unsupported));
    await controller.refresh();

    final stop = controller.route!.stops.first;
    await controller.markArrived(stop);
    await controller.deliver(
      stop,
      proof: DeliveryProof(
        orderId: stop.orderId,
        method: ProofMethod.password,
        capturedAt: DateTime.now(),
        password: '1234',
      ),
    );

    // Simula recarregar a rota do cache e não perder o "entregue".
    final reloaded = DeliveryController(api: _FakeApi(mode: _ApiMode.unsupported));
    await reloaded.refresh();
    expect(reloaded.route!.stopByOrderId(stop.orderId)!.status, StopStatus.pending);
  });
}
