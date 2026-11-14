import 'package:app_mercadinho/features/picking/data/seal_printer.dart';
import 'package:app_mercadinho/features/picking/domain/picking_models.dart';
import 'package:app_mercadinho/features/picking/domain/seal_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PickingItem item(String id, {bool cold = false}) => PickingItem(
      id: id,
      productId: 'p$id',
      name: 'Produto $id',
      barcode: '789$id',
      requestedQty: 1,
      unitPrice: 10,
      isCold: cold,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('numeração de lacre é sequencial no mesmo dia', () async {
    final generator = SealNumberGenerator();
    final day = DateTime(2026, 11, 9, 10);

    expect(await generator.next(now: day), '1109-0001');
    expect(await generator.next(now: day), '1109-0002');
    expect(await generator.next(now: day), '1109-0003');
    expect(await generator.peek(now: day), 3);
  });

  test('numeração reinicia no dia seguinte', () async {
    final generator = SealNumberGenerator();
    expect(await generator.next(now: DateTime(2026, 11, 9, 23, 59)), '1109-0001');
    expect(await generator.next(now: DateTime(2026, 11, 10, 0, 1)), '1110-0001');
  });

  test('proposta de sacolas separa seco e gelado', () {
    final task = PickingTask(
      orderId: '1',
      code: '1042',
      items: [item('a'), item('b'), item('c', cold: true)],
    );

    final proposals = proposeBags(task);
    expect(proposals.length, 2);
    expect(proposals[0].temperature, BagTemperature.dry);
    expect(proposals[0].itemIds, ['a', 'b']);
    expect(proposals[1].temperature, BagTemperature.cold);
    expect(proposals[1].itemIds, ['c']);
  });

  test('pedido só com gelados usa uma sacola', () {
    final task = PickingTask(
      orderId: '1',
      code: '1042',
      items: [item('a', cold: true), item('b', cold: true)],
    );

    final proposals = proposeBags(task);
    expect(proposals.length, 1);
    expect(proposals.single.bagId, 'S1');
    expect(proposals.single.temperature, BagTemperature.cold);
  });

  test('rótulo carrega pedido, sacola e lacre, sem dado pessoal', () {
    final label = SealLabel(
      sealNumber: '1109-0007',
      orderId: '9001',
      orderCode: '1042',
      bagId: 'S2',
      temperature: BagTemperature.cold,
      itemCount: 3,
      createdAt: DateTime(2026, 11, 9, 10, 30),
    );

    expect(label.qrPayload, 'IFD1|9001|S2|1109-0007|cold|20261109');
    expect(label.qrPayload.toLowerCase(), isNot(contains('senha')));
    expect(label.temperatureLabel, 'GELADO');
  });

  test('reimpressão é marcada no rótulo', () {
    final label = SealLabel(
      sealNumber: '1109-0001',
      orderId: '1',
      orderCode: '1042',
      bagId: 'S1',
      temperature: BagTemperature.dry,
      itemCount: 2,
      createdAt: DateTime(2026, 11, 9),
    );

    expect(label.reprinted().reprintCount, 1);
    expect(label.reprinted().reprinted().reprintCount, 2);
  });

  test('ESC/POS inicia com ESC @ e contém o QR e o número do lacre', () {
    final label = SealLabel(
      sealNumber: '1109-0009',
      orderId: '9001',
      orderCode: '1042',
      bagId: 'S1',
      temperature: BagTemperature.dry,
      itemCount: 4,
      createdAt: DateTime(2026, 11, 9),
    );

    final bytes = EscPosBuilder().build(label);

    expect(bytes.take(2).toList(), [0x1B, 0x40]);
    final asText = String.fromCharCodes(bytes);
    expect(asText, contains('1109-0009'));
    expect(asText, contains('PEDIDO 1042'));
    // Comando ESC/POS de impressão de QR: GS ( k ...
    expect(bytes.length, greaterThan(100));
    expect(bytes.contains(0x1D), isTrue);
  });

  test('preview mostra o conteúdo legível do rótulo', () {
    final label = SealLabel(
      sealNumber: '1109-0003',
      orderId: '1',
      orderCode: '1043',
      bagId: 'S1',
      temperature: BagTemperature.dry,
      itemCount: 2,
      createdAt: DateTime(2026, 11, 9),
    );

    final preview = EscPosBuilder().buildPreview(label);
    expect(preview, contains('LACRE 1109-0003'));
    expect(preview, contains('PEDIDO 1043'));
  });
}
