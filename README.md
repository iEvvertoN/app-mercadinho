# app-mercadinho

App Flutter do mercadinho — e-commerce, clube de vantagens, **separação (picking)** e
**entregas**, todos no mesmo projeto e no mesmo contrato de ERP.

## Três entradas

| Entrada | Papel | Comando |
|---|---|---|
| `lib/main.dart` | cliente (catálogo, carrinho, pedidos, clube) | `flutter run` |
| `lib/main_picking.dart` | separador/conferente (fila, itens, lacre, handoff) | `flutter run -t lib/main_picking.dart` |
| `lib/main_delivery.dart` | entregador (turno, rota, prova de entrega) | `flutter run -t lib/main_delivery.dart` |
| `lib/main_dispatch.dart` | despacho (atribuir pedidos, ver sequência calculada) | `flutter run -t lib/main_dispatch.dart` |

Mesma base de código, mesmo contrato (`/api/marketplace/{idIntegradora}/...`), mesmo tema.
Quando existir login por papel, a entrada passa a ser escolhida pelo perfil.

## Documentação

- [`docs/processo-operacional.md`](docs/processo-operacional.md) — padronização do processo
  (S0–S9), regras de exceção, métricas e **picking enriquecido**.
- [`docs/integracao.md`](docs/integracao.md) — como os três apps se comunicam: eventos,
  idempotência, quem escreve o quê, ordem de implementação no backend.
- [`docs/entregas.md`](docs/entregas.md) — módulo de entregas: fluxo, contrato de API,
  regras de offline, segurança e checklist de produção.

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
```

## Backend

O app fala com o `clipp-server` em `/api/marketplace/{idIntegradora}/...`
(catálogo, pedidos, rotas/prova de entrega e fila de separação). A descoberta de host
fica em `lib/features/catalog/data/catalog_api_service.dart` e é reaproveitada pelos
módulos de picking e entregas.
