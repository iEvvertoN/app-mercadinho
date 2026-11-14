import 'package:app_mercadinho/features/delivery/data/delivery_api_service.dart';
import 'package:app_mercadinho/features/delivery/data/location_service.dart';
import 'package:app_mercadinho/features/delivery/domain/models/delivery_models.dart';
import 'package:app_mercadinho/features/delivery/presentation/delivery_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineApi extends DeliveryApiService {
  @override
  Future<DeliveryApiResponse> fetchRoute({required String courierId}) async =>
      DeliveryApiResponse.failure('sem endpoint', unsupported: true);

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
  }) async =>
      DeliveryApiResponse.failure('offline');

  @override
  void dispose() {}
}

class _NoLocation extends LocationService {
  const _NoLocation();

  @override
  Future<GeoPoint?> lastKnown() async => null;

  @override
  Future<GeoPoint?> current({Duration timeout = const Duration(seconds: 8)}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  DeliveryController build() => DeliveryController(
        api: _OfflineApi(),
        location: const _NoLocation(),
      );

  test('liberar um pedido nao mexe nas outras paradas', () async {
    final controller = build();
    await controller.refresh();
    expect(controller.route!.stops.length, 3);

    final first = controller.route!.stops.first;
    await controller.startStop(first);

    expect(controller.route!.stopByOrderId(first.orderId)!.status, StopStatus.onRoute);
    final pendentes =
        controller.route!.stops.where((s) => s.status == StopStatus.pending).length;
    expect(pendentes, 2, reason: 'as outras duas continuam aguardando');
  });

  test('retirada em lote e explicita e libera todas', () async {
    final controller = build();
    await controller.refresh();

    await controller.startAllStops();

    expect(
      controller.route!.stops.every((s) => s.status == StopStatus.onRoute),
      isTrue,
    );
    expect(controller.route!.stops.where((s) => s.status == StopStatus.pending), isEmpty);
  });

  test('nao reabre pedido ja entregue ao liberar rota', () async {
    final controller = build();
    await controller.refresh();

    final first = controller.route!.stops.first;
    await controller.startStop(first);
    await controller.markArrived(first);
    await controller.deliver(
      first,
      proof: DeliveryProof(
        orderId: first.orderId,
        method: ProofMethod.password,
        capturedAt: DateTime.now(),
        password: '1234',
      ),
    );

    await controller.startAllStops();

    expect(controller.route!.stopByOrderId(first.orderId)!.status, StopStatus.delivered);
  });
}
