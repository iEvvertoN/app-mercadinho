# Integração: mercadinho, picking e entrega

Os três apps são **clientes** de um mesmo dono de estado: o ERP (`clipp-server`).
Nenhum app guarda a verdade sozinho. O que garante a comunicação é um contrato
pequeno e um catálogo de eventos.

```
                    ┌──────────────────────────┐
                    │        ERP / clipp       │
                    │  estado + eventos + IDs  │
                    └────┬──────────┬──────────┘
        catálogo/pedido  │          │  rotas/provas        │ fila/tarefas
                         ▼          ▼                      ▼
              ┌──────────────┐  ┌──────────────┐   ┌──────────────────┐
              │ App cliente  │  │  Entregador  │   │ Picking (separador│
              │  (mercado)   │  │              │   │  + conferente)    │
              └──────────────┘  └──────────────┘   └──────────────────┘
```

## 1. Quem escreve o quê

| Ação | Quem escreve | Endpoint |
|---|---|---|
| Pedido criado | app cliente | `POST /orders` |
| Separação iniciada | picking | `POST /picking/{id}/start` |
| Item conferido / pesado / faltou | picking | `POST /picking/{id}/items/{item}/...` |
| Substituição proposta/decidida | picking (cliente decide) | `POST /picking/{id}/items/{item}/substitution[/decision]` |
| Sacola lacrada | picking | `POST /picking/{id}/bags` |
| Separação fechada | picking | `POST /picking/{id}/finish` |
| Conferência | picking (conferente) | `POST /picking/{id}/verify` |
| Handoff ao entregador | picking | `POST /picking/{id}/handoff` |
| Rota do dia | entregador (lê) | `GET /delivery/routes` |
| Status de rota, prova | entregador | `POST /orders/{id}/status`, `/proof` |

**Regra dura:** o app do cliente **não** muda status operacional (separação, rota);
ele só lê. Quem escreve etapa operacional é o app que executa a etapa.

## 2. Ciclo do pedido (eventos)

```
order.received
  → picking.queued
  → picking.started
  → item.checked | item.missing | item.weighed
  → substitution.proposed → approved | rejected | expired
  → bag.sealed (por sacola, com nº de lacre)
  → picking.finished
  → picking.verified (por outra pessoa, volumes contados)
  → handoff.confirmed (entregador, volumes, senha conferida)
  → route.started
  → delivery.proof (senha e/ou assinatura + geo + hora)
  → order.closed
```

`order.status` passa a ser **derivado** do último evento, não digitado. Isso elimina
o "status mentiroso" e permite reconstruir a linha do tempo de qualquer pedido.

## 3. Contrato de evento

Todo evento enviado segue a mesma forma, independente do app:

```json
{
  "eventId": "uuid-v4",
  "type": "item.checked",
  "orderId": "9001",
  "at": "2026-11-09T10:12:31-03:00",
  "actor": {"id": "separador-02", "role": "picker"},
  "deviceApp": "picking",
  "appVersion": "1.0.0",
  "lat": -6.3621,
  "lng": -39.2985,
  "payload": {"itemId": "i1", "barcode": "7891234567890", "qty": 2}
}
```

- `eventId` é **idempotência**: o servidor descarta duplicata com o mesmo id.
- `at` é hora do aparelho; o servidor grava também `receivedAt` e decide qual vale
  para SLA (nunca confie só no relógio do celular).
- `actor` + `deviceApp` dizem quem fez; `appVersion` ajuda a diagnosticar.

## 4. Sincronização por papel

| App | Como recebe novidade | Como envia |
|---|---|---|
| Cliente | push (status do pedido) | HTTP direto |
| Picking | polling da fila (10–15 s) | HTTP, com fila local se cair |
| Entregador | push + polling de fallback | HTTP com fila local (já implementado) |

Picking **não** precisa de push: o separador está dentro da loja, na rede local, e a
fila é pequena. Polling é mais simples e não gasta bateria.

## 5. Chaves e identificadores

| Chave | Formato | Observação |
|---|---|---|
| `orderId` | inteiro do ERP | imutável, usado em todas as chamadas |
| `code` | `#MERC-1042` | visível ao humano |
| `bagId` | `S1`, `S2` por pedido | sacola dentro do pedido |
| `sealNumber` | `0911-0001` | **sequencial por dia**, único |
| `courierId` | `entregador-01` | login/token entram depois |
| `eventId` | uuid v4 | idempotência |

O `sealNumber` é sequencial de propósito: lacre faltando na sequência do dia é
**detectável na conferência**.

## 6. O que cada app mostra (e não calcula)

| Dado | Quem calcula |
|---|---|
| Total do pedido | ERP (o app só exibe) |
| Valor da corrida | ERP |
| Fill rate, tempo de separação | ERP (derivado de eventos) |
| Lacre necessário | picking (proposta de sacola) + ERP valida unicidade |
| Status do pedido | ERP (derivado), todos os apps leem |

Duas regras de ouro contra divergência:
1. **Nenhum app recalcula dinheiro** — só exibe o que o ERP mandou.
2. **Nenhum app inventa status** — só registra evento; status é consequência.

## 7. Modo demonstração (enquanto o ERP não tem os endpoints)

- Picking: sem `/picking/tasks` → fila de exemplo local, aviso na tela.
- Entrega: sem `/delivery/routes` → rota de exemplo local, aviso na tela.

Assim os três apps podem ser homologados antes do backend. Nada de demo é enviado
ao ERP.

## 8. Ordem de implementação no backend (sugestão)

1. `POST /orders/{id}/status` + `GET /delivery/routes` — completa o ciclo de entrega.
2. `GET /picking/tasks` + `POST /picking/{id}/start|finish` — abre a operação.
3. `POST /picking/{id}/items/{item}/scan|weigh|missing` — conferência item a item.
4. `POST /picking/{id}/bags` (lacre) + `verify` + `handoff` — fecha o ciclo.
5. `POST /picking/{id}/items/{item}/substitution[/decision]` — substituição com
   aprovação por push no app do cliente.
6. Derivação de `order.status` a partir dos eventos + métricas (fill rate, tempos).

## 9. Riscos de integração

| Risco | Mitigação |
|---|---|
| Dois apps escrevendo o mesmo status | só o app que executa a etapa escreve; os outros leem |
| Evento duplicado (retry) | `eventId` idempotente |
| Relógio do celular errado | servidor grava `receivedAt` próprio |
| Lacre duplicado | unicidade no ERP + validação local |
| Pedido cancelado durante a separação | evento `order.canceled` lido pelo picking, que bloqueia o fechamento |
| Rede da loja cair | fila local no app + reenvio idempotente |
