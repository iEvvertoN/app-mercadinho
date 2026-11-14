# Módulo de entregas (papel entregador)

Módulo novo, dentro do mesmo projeto Flutter do mercadinho. Mesma base de código,
mesmo contrato de ERP, tema e modelos — muda o papel do usuário.

## Como rodar

```bash
flutter pub get
flutter run -t lib/main_delivery.dart
```

A entrada normal (`lib/main.dart`, app do cliente) continua intacta. Quando houver
login por papel, esta tela passa a ser escolhida pelo perfil, não por um alvo separado.

## Estrutura

```
lib/features/delivery/
├── domain/models/delivery_models.dart     rota, parada, prova, fila, enums
├── data/delivery_api_service.dart         HTTP do contrato de entrega
├── data/delivery_store.dart               persistência local (turno, fila, rota)
├── data/location_service.dart             posição no momento do evento
└── presentation/
    ├── delivery_controller.dart           estado + regras (fonte da verdade)
    ├── delivery_home_page.dart            turno, rota do dia, paradas
    ├── delivery_stop_page.dart            uma parada + ações
    ├── delivery_proof_sheet.dart          prova: senha e/ou assinatura
    └── widgets/
        ├── delivery_status_chip.dart
        └── signature_pad.dart
```

## Fluxo do entregador

```
Turno fechado
   ↓ abrir turno
Turno aberto  →  rota do dia (pendentes)
   ↓ "Iniciar rota"                 (pedido passa a "saiu para entrega")
Em rota
   ↓ "Cheguei no cliente"
No cliente
   ↓ senha e/ou assinatura
Entregue        ou        Não entregue (motivo)
```

No ERP, isso mapeia para o que já existe em `OrderModel.status`:

| Ação no app do entregador | Status do pedido |
|---|---|
| Iniciar rota | `delivering` |
| Entregue | `completed` |
| Não entregue | `delivering` + motivo de falha no evento |

## Contrato de API

Base: a mesma do app (`CatalogApiService.candidateUrls`), caminho
`/api/marketplace/{idIntegradora}/...`, com `idIntegradora = 2` hoje.

### 1. Rota do dia

```
GET /api/marketplace/{id}/delivery/routes?courierId={courierId}
```

```json
{
  "success": true,
  "route": {
    "id": "rota-2026-11-08-01",
    "courierId": "entregador-01",
    "date": "2026-11-08T00:00:00",
    "storeName": "Mercadinho Matriz - Centro",
    "version": 7,
    "stops": [
      {
        "orderId": "9001",
        "code": "1042",
        "customerName": "Ana Paula Ribeiro",
        "addressText": "Rua Santos Dumont, 210 - Centro",
        "timeSlot": "Hoje, 14:00 - 16:00",
        "dryVolumes": 2,
        "coldVolumes": 1,
        "itemsCount": 12,
        "totalAmount": 187.40,
        "phone": "(88) 99911-2233",
        "latitude": -6.3621,
        "longitude": -39.2985,
        "status": "pending",
        "sequence": 1
      }
    ]
  }
}
```

- `404`/`501` → o app entra em **modo demonstração** (rota de exemplo local).
- Qualquer falha de rede → mantém a última rota salva em `shared_preferences`.
- `version` serve para o app recusar estado velho; o merge preserva o que o
  entregador já fez offline (nunca retrocede uma entrega concluída).

### 2. Mudança de status (evento leve)

```
POST /api/marketplace/{id}/orders/{orderId}/status
```

```json
{
  "status": "on_route | arrived | delivered | failed",
  "at": "2026-11-08T14:22:31-03:00",
  "lat": -6.3621,
  "lng": -39.2985,
  "appVersion": "1.0.0",
  "source": "courier",
  "failureReason": "Cliente ausente"
}
```

Resposta esperada: `2xx`. Corpo é opcional.

### 3. Prova de entrega

```
POST /api/marketplace/{id}/orders/{orderId}/proof
```

```json
{
  "orderId": "9001",
  "method": "password | signature | password_and_signature",
  "password": "1234",
  "signature": [[0.12, 0.44], [0.15, 0.47]],
  "capturedAt": "2026-11-08T14:25:02-03:00",
  "lat": -6.3621,
  "lng": -39.2985,
  "appVersion": "1.0.0"
}
```

`signature` é uma lista de pontos normalizados (0..1) na ordem do traço. Não é
imagem: pesa pouco e pode ser redesenhada em qualquer resolução.

### 4. Turno

```
POST /api/marketplace/{id}/delivery/shift
{"courierId": "...", "open": true, "at": "...", "lat": ..., "lng": ...}
```

## Regras de offline

1. Toda ação é aplicada **primeiro no aparelho** e só depois enviada.
2. Falha de rede → o evento entra na fila (`PendingEvent`) e é reenviado em:
   abertura do app, botão "Sincronizar" e próxima ação bem-sucedida.
3. Falha de rede interrompe a rodada de envio (preserva ordem); não insiste em
   todos os eventos de uma vez.
4. `404`/`501` no envio marca o evento como `unsupported` — não existe endpoint,
   reenviar para sempre só geraria ruído. O evento **não é apagado**.
5. A rota fica em cache; sem rede o entregador continua trabalhando.

## Segurança — decisão importante

O endpoint do entregador **não deve devolver `passwordNumber`**. A senha é do
cliente; se vier no payload do entregador, a prova deixa de valer. A validação é
sempre no servidor: o app envia a senha digitada e recebe `2xx` ou erro.

Hoje o ERP entrega `passwordNumber` no `POST /orders` do app do cliente e ele é
exibido ao cliente — isso está correto. Só não pode vazar para o app do entregador.

## Modo demonstração

Quando o ERP ainda não tem `/delivery/routes`, o app mostra uma rota de exemplo
com 3 paradas, marcada com o aviso "Modo demonstração". Serve para validar o
fluxo inteiro (turno, rota, chegada, prova, falha) antes da integração. Nada é
enviado nesse modo, e a UI deixa isso explícito.

## Antes de produção — checklist

- [ ] **HTTPS + endpoint público**: hoje os hosts são LAN/Tailscale em HTTP puro;
      celular na rua não alcança e senha não pode trafegar sem TLS.
- [ ] **Autenticação do entregador**: hoje o `courierId` é local. Precisa de login
      e token por entregador (e o servidor decide qual rota ele vê).
- [ ] Endpoints 1–4 implementados no ERP (`clipp-server`).
- [ ] Teste em aparelho real de entrada (Xiaomi/Samsung/Motorola) em campo.
- [ ] LGPD: base legal, prazo de retenção e transparência para rastreio de
      funcionário.
- [ ] Opcional: foto da entrega (`image_picker`) e serviço em primeiro plano
      (`flutter_foreground_task`) se quiser rastreio com app minimizado.

## Decisões herdadas do estudo (e o que ficou de fora)

**Adotado como padrão**
- Evento leve (geo + hora + versão) e prova separada do evento.
- Estado de rota versionado, com merge que nunca retrocede.
- Fila local para evento que não sobe.

**Descartado de propósito**
- Oferta com faixa de preço, escada `WARNING → LAST_WARNING → LOST`, contador de
  recusa e penalidade: o entregador é contratado, a rota é atribuída.
- Beacon, prova de vida facial, RASP pesado: custo e complexidade sem retorno no
  modelo de mercadinho.
