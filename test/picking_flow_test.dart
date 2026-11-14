import 'package:app_mercadinho/features/picking/domain/picking_models.dart';
import 'package:flutter_test/flutter_test.dart';

PickingTask buildTask() {
  return PickingTask(
    orderId: '9001',
    code: '1042',
    items: [
      PickingItem(
        id: 'i1',
        productId: 'p1',
        name: 'Arroz 5kg',
        barcode: '7891234567890',
        requestedQty: 2,
        unitPrice: 24.90,
        aisle: 'A3',
      ),
      PickingItem(
        id: 'i2',
        productId: 'p2',
        name: 'Tomate',
        barcode: '7890000000017',
        requestedQty: 0.5,
        unitPrice: 7.99,
        weighable: true,
        unit: 'kg',
        aisle: 'B1',
      ),
    ],
  );
}

void main() {
  test('fluxo completo: separar, lacrar, conferir e entregar', () {
    final task = buildTask();

    expect(task.start(' Ana ').ok, isTrue);
    expect(task.assigneeId, 'Ana');
    expect(task.status, PickingStatus.inProgress);

    expect(task.scan('i1', barcode: '7891234567890').ok, isTrue);
    expect(task.weigh('i2', grams: 480).ok, isTrue);
    expect(task.hasPendingItems, isFalse);
    expect(task.fillRate, 1.0);

    // Peso 480 g contra 500 g pedidos: dentro de 10%, não é divergência.
    expect(task.itemById('i2')!.billedQty, closeTo(0.48, 0.001));
    expect(task.itemById('i2')!.hasWeightDivergence, isFalse);

    expect(task.addBag(bagId: 'S1', temperature: BagTemperature.cold, itemIds: ['i2']).ok, isTrue);
    expect(task.addBag(bagId: 'S2', temperature: BagTemperature.dry, itemIds: ['i1']).ok, isTrue);

    // Sem lacre, não fecha.
    expect(task.finish().ok, isFalse);

    expect(task.sealBag('S1', sealNumber: '0001').ok, isTrue);
    expect(task.sealBag('S2', sealNumber: '0002').ok, isTrue);
    expect(task.finish().ok, isTrue);
    expect(task.status, PickingStatus.ready);

    // Contagem errada bloqueia.
    expect(task.verify(by: 'Caixa', volumesCounted: 3).ok, isFalse);
    expect(task.verify(by: 'Caixa', volumesCounted: 2).ok, isTrue);

    expect(task.handOff(courierId: 'entregador-01', passwordChecked: true).ok, isTrue);
    expect(task.status, PickingStatus.handedOff);
  });

  test('não fecha com item pendente', () {
    final task = buildTask();
    task.start('Ana');
    task.scan('i1', barcode: '7891234567890');

    expect(task.hasPendingItems, isTrue);
    expect(task.finish().error, contains('pendentes'));
  });

  test('código de barras divergente é recusado', () {
    final task = buildTask();
    task.start('Ana');

    final result = task.scan('i1', barcode: '0000000000000');
    expect(result.ok, isFalse);
    expect(result.error, contains('não confere'));
    expect(task.itemById('i1')!.status, ItemPickStatus.pending);
  });

  test('substituição acima de 20% exige aprovação e bloqueia o fechamento', () {
    final task = buildTask();
    task.start('Ana');
    task.markMissing('i1', reason: 'Sem estoque');

    // 32,00 contra 24,90 = +28,5%
    final proposed = task.proposeSubstitution(
      'i1',
      toProductId: 'p9',
      toProductName: 'Arroz 5kg marca X',
      toPrice: 32.00,
    );
    expect(proposed.ok, isTrue);
    expect(task.itemById('i1')!.status, ItemPickStatus.pending);
    expect(task.hasBlockedSubstitution, isTrue);

    expect(task.decideSubstitution('i1', approved: true).ok, isTrue);
    expect(task.itemById('i1')!.status, ItemPickStatus.substituted);
    expect(task.hasBlockedSubstitution, isFalse);
  });

  test('substituição dentro da tolerância não pede aprovação', () {
    final task = buildTask();
    task.start('Ana');
    task.markMissing('i1', reason: 'Sem estoque');

    // 26,00 contra 24,90 = +4,4%
    task.proposeSubstitution(
      'i1',
      toProductId: 'p8',
      toProductName: 'Arroz 5kg marca Y',
      toPrice: 26.00,
    );

    final item = task.itemById('i1')!;
    expect(item.status, ItemPickStatus.substituted);
    expect(item.substitution!.requiresApproval, isFalse);
    expect(task.hasBlockedSubstitution, isFalse);
  });

  test('substituição recusada vira item faltante', () {
    final task = buildTask();
    task.start('Ana');
    task.markMissing('i1', reason: 'Sem estoque');
    task.proposeSubstitution('i1', toProductId: 'p9', toProductName: 'Outro', toPrice: 40);

    task.decideSubstitution('i1', approved: false);
    expect(task.itemById('i1')!.status, ItemPickStatus.missing);
    expect(task.itemById('i1')!.missingReason, contains('recusada'));
  });

  test('lacre duplicado é recusado', () {
    final task = buildTask();
    task.start('Ana');
    task.scan('i1', barcode: '7891234567890');
    task.weigh('i2', grams: 500);
    task.addBag(bagId: 'S1', temperature: BagTemperature.dry, itemIds: ['i1']);
    task.addBag(bagId: 'S2', temperature: BagTemperature.cold, itemIds: ['i2']);

    expect(task.sealBag('S1', sealNumber: '0042').ok, isTrue);
    final duplicated = task.sealBag('S2', sealNumber: '0042');
    expect(duplicated.ok, isFalse);
    expect(duplicated.error, contains('já usado'));
  });

  test('não cancela pedido que já saiu com o entregador', () {
    final task = buildTask();
    task.start('Ana');
    task.scan('i1', barcode: '7891234567890');
    task.weigh('i2', grams: 500);
    task.addBag(bagId: 'S1', temperature: BagTemperature.dry, itemIds: ['i1', 'i2']);
    task.sealBag('S1', sealNumber: '0043');
    task.finish();
    task.verify(by: 'Caixa', volumesCounted: 1);
    task.handOff(courierId: 'entregador-01', passwordChecked: true);

    final result = task.cancel(reason: 'Cliente desistiu');
    expect(result.ok, isFalse);
    expect(result.error, contains('entregador'));
  });

  test('ordem de caminhada respeita corredor', () {
    final task = buildTask();
    final ordered = task.itemsInWalkOrder;
    expect(ordered.first.aisle, 'A3');
    expect(ordered.last.aisle, 'B1');
  });
}
