# Padronização do processo operacional + picking

Base: o que está **codificado hoje** no app (não o que se pretende) + o padrão proposto.
Onde eu estou propondo, está marcado como **proposta**.

---

## 1. O processo como está hoje (extraído do código)

| Etapa | Status no sistema | O que o app realmente faz | Situação |
|---|---|---|---|
| Pedido criado | `received` | `POST /orders` → ERP devolve `orderId`, `orderCode`, `passwordNumber` | ✅ funciona |
| Separação | `picking` | **nada** — nenhuma tela operada | ⚠️ só o status existe |
| Separado | `ready_to_invoice` | nada | ⚠️ rótulo bonito, sem operação |
| Faturado | `invoiced` | nada no app | ⚠️ vem do ERP |
| Em rota | `delivering` | módulo de entregas (novo) | ✅ construído |
| Entregue | `completed` | prova (senha/assinatura) | ✅ construído |
| Cancelado | `canceled` | `cancelOrder()` local | ⚠️ não fala com ERP |

**O achado central:** o picking está **modelado mas não operado**.

O `OrderModel` já tem os campos certos — `requestQuantity`, `foundQuantity`, `notFound`,
`giveUp`, `lateAdded`, `substitutedBy`, `observation`, `weighable`, `dryVolumes`,
`coldVolumes`, `separatorName`, `needsClientApproval`, `clientApprovedChanges` — mas
**nenhuma tela escreve neles**. `separatorName` nasce com valor fixo
(`'Maria Fernanda (Separadora #04)'`) e `needsClientApproval` nasce `false`.

Ou seja: o domínio está pronto; o processo não existe. É exatamente onde o
iFood não serve de referência — lá o pedido chega fechado para o entregador.

---

## 2. Atores e responsabilidades (proposta)

| Etapa | Executa | Confere | Decide |
|---|---|---|---|
| Triagem do pedido | sistema | — | gestor (exceção) |
| Separação | separador | **outro** separador ou o caixa | separador (substituição) + cliente (aprovação) |
| Embalagem/lacre | separador | conferente | separador |
| Faturamento | caixa | — | caixa |
| Handoff | conferente | entregador (contagem) | conferente |
| Rota/entrega | entregador | — | entregador (falha) |
| Fechamento | gestor | — | gestor |

Regra de ouro: **quem separa não confere o próprio pedido**. Em mercadinho pequeno,
o caixa faz a conferência — é o mesmo posto que já existe.

---

## 3. O padrão proposto — S0 a S9

| # | Etapa | Entrada | Ações obrigatórias | Registro | SLA alvo |
|---|---|---|---|---|---|
| S0 | Pedido recebido | pedido pago/confirmado | validação de estoque e janela | `order.received` | automático |
| S1 | Triagem | pedido na fila | aceitar ou recusar com motivo | `picking.queued` | 2 min |
| S2 | Separação | tarefa atribuída | **scan por item** + quantidade real | `item.checked`, `item.missing` | 8 min / 20 itens |
| S3 | Substituição | item indisponível | sugerir, pedir aprovação, registrar decisão | `substitution.*` | 2 min p/ cliente |
| S4 | Embalagem | todos os itens resolvidos | separar seco/gelado, etiquetar, **lacrar** | `bag.sealed` | 3 min |
| S5 | Conferência | sacolas fechadas | contagem de volumes vs esperado | `picking.verified` | 3 min |
| S6 | Faturamento | conferido | emitir no caixa | `invoice.issued` | 2 min |
| S7 | Handoff | faturado | **contagem dupla** + senha/QR do entregador | `handoff.confirmed` | 1 min |
| S8 | Rota | rota atribuída | eventos geo-carimbados | `route.*`, `delivery.proof` | janela |
| S9 | Fechamento | rota concluída | conciliar volumes, tratar ocorrências | `order.closed` | 1×/dia |

Cada etapa só começa quando a anterior registrou o evento. **O status do pedido passa a
ser derivado dos eventos**, não digitado — é isso que impede o "status mentiroso".

---

## 4. Regras de exceção (o que fazer quando dá errado)

| Exceção | Regra proposta | Efeito |
|---|---|---|
| Item não encontrado | marcar `notFound` + motivo; se for essencial, oferecer substituição | cliente aprova ou recebe reembolso |
| Item avariado/vencido | tratar como não encontrado e **registrar ocorrência** | entra no indicador de perdas |
| Peso divergente | pesar, registrar peso real; diferença > 10% pede aprovação | ajuste de valor transparente |
| Substituição | mesma subcategoria, preço até **+20%** do original, estoque > 0 | acima disso, exige aprovação explícita |
| Cliente não responde em 2 min | fallback: reembolso do item | pedido não trava |
| Item adicionado tarde (`lateAdded`) | permitido até o lacre | após lacre, vira novo pedido |
| Desistência (`giveUp`) | reembolso automático | registra motivo |
| Cancelamento durante separação | parar tarefa, devolver itens às gôndolas | `order.canceled` + motivo |
| Cliente ausente na entrega | 1 tentativa de contato + 5 min de espera | falha com motivo (já implementado) |
| Devolução | retorna ao mercadinho, reentra em estoque | `order.returned` |

---

## 5. Checkpoints de qualidade (o que não pode falhar)

1. **Scan obrigatório** em item não pesável — é o que impede troca de produto.
2. **Peso real** em item pesável — sem isso não há como provar quantidade.
3. **Contagem de volumes** no handoff, feita por duas pessoas.
4. **Lacre numerado** por sacola — prova de que ninguém abriu.
5. **Senha do cliente** só no momento da entrega, nunca impressa na etiqueta.

---

## 6. Métricas e SLAs

| Indicador | Fórmula | Meta inicial |
|---|---|---|
| Tempo de separação | `picking.finished - picking.started` (mediana e p90) | ≤ 8 min / 20 itens |
| Fill rate | itens encontrados / itens pedidos | ≥ 95% |
| Taxa de substituição | itens substituídos / itens pedidos | ≤ 5% |
| Aceite de substituição | aprovadas / propostas | ≥ 70% |
| Acurácia de separação | pedidos sem reclamação / pedidos | ≥ 99% |
| OTIF | pedidos completos e no prazo / total | ≥ 95% |
| Tempo de handoff | `handoff.confirmed - invoice.issued` | ≤ 1 min |
| Ocorrências | ocorrências / 100 pedidos | ≤ 2 |

Sem esses números, "melhorar o processo" é opinião. Eles saem direto dos eventos.

---

## 7. Modelo de dados que falta

```
picking_task(id, order_id, assignee_id, status, started_at, finished_at, verified_by)
picking_check(id, task_id, order_item_id, method[SCAN|WEIGHT|MANUAL],
              found_qty, weight_g, at, by)
substitution(id, task_id, order_item_id, from_product_id, to_product_id,
             price_delta, approval[PENDING|APPROVED|REJECTED|EXPIRED], decided_at)
bag(id, task_id, temperature[DRY|COLD], seal_number, sealed_at)
handoff(id, task_id, courier_id, volumes_declared, volumes_counted, password_checked, at)
occurrence(id, order_id, kind[MISSING|DAMAGED|WEIGHT|LATE|RETURN], note, at)
```

Eventos: `order.received`, `picking.queued`, `picking.started`, `item.checked`,
`item.missing`, `substitution.proposed|approved|rejected`, `bag.sealed`,
`picking.finished`, `picking.verified`, `invoice.issued`, `handoff.confirmed`,
`route.started`, `delivery.proof`, `occurrence.opened`, `order.closed`.

---

## 8. Picking enriquecido (o coração do pedido)

**Modo de operação**
- **Pedido único por separador** — recomendado no início: menos erro, mais simples de auditar.
- **Onda (wave)** de 2–4 pedidos por carrinho só quando passar de ~30 pedidos/dia e a
  separação virar gargalo. Aí entra carrinho com baias numeradas e conferência por baia.

**Ordem de coleta**
- Ordenar por **corredor/prateleira**. Hoje o `ProductModel` **não tem** `aisle`/
  `shelf` — é o gap mais barato de resolver e o que mais reduz tempo de caminhada.
- Fallback enquanto não houver: ordenar por `categoryId`/`subcategoryId`.

**Check por item**
- Não pesável: **scan do EAN** (obrigatório) → quantidade.
- Pesável: etiqueta da balança → peso real → valor recalculado.
- Item não encontrado: botão único, 3 motivos (sem estoque, avariado, vencido).

**Substituição guiada**
- Sugestões: mesma `subcategoryId`, `stock > 0`, preço entre 80% e 120% do original.
- Acima de +20%: só com aprovação explícita.
- Aprovação: push no app do cliente (já existe infra de pedido) com timeout de 2 min →
  sem resposta = reembolso do item.
- Registrar **quem** decidiu e **quando** (auditoria).

**Embalagem**
- Sacola seca e sacola gelada separadas (os campos `dryVolumes`/`coldVolumes` já existem).
- Etiqueta por sacola: código do pedido + número do lacre + QR.
- Lacre obrigatório antes da conferência.

**Conferência e handoff**
- Contagem: volumes declarados × contados. Divergência **bloqueia** o handoff.
- Handoff registra: entregador, volumes, hora, quem conferiu, senha conferida (sim/não).

---

## 9. Telas do picking (proposta)

1. **Fila de separação** — colunas: `aguardando`, `separando`, `conferência`, `pronto`.
   Cada cartão mostra: pedido, janela, nº de itens, volumes previstos.
2. **Tarefa** — lista ordenada por corredor; cada linha: produto, quantidade pedida,
   botão de scan, campo de quantidade encontrada, ação "não encontrado".
3. **Substituição** — bottom sheet com 3 sugestões + preço + botão "pedir aprovação".
4. **Fechamento** — sacolas, lacres, contagem; bloqueia se faltar item pendente.
5. **Conferência/handoff** — checklist + contagem dupla + senha.

---

## 10. MVP do picking (o que implementar primeiro)

1. Fila + tarefa com scan e quantidade encontrada.
2. Marcar não encontrado com motivo.
3. Fechamento com volumes seco/gelado + lacre.
4. Handoff com contagem e senha.
5. Eventos gravados em cada passo (mesmo que só local no começo).

Fica para a segunda fase: onda/batch, sugestão automática de substituto, rota por
corredor (depende do campo `aisle`), foto de lacre.

---

## 11. Sobre engenharia reversa de um app de picking

**Minha recomendação: não é necessário — e provavelmente é o pior uso do seu tempo.**

Motivos concretos:

1. **O que falta não é código, é decisão de processo.** Batch ou pedido único,
   quem confere, quanto de substituição é aceitável — nenhum APK responde isso
   pelo seu mercadinho.
2. **O seu modelo já é mais rico que o de app de picking de marketplace** no que
   importa (quantidade pedida × encontrada, substituição, item tardio).
3. **O custo é alto e o retorno é de UI.** Apps de picking diferem em tela e
   fluxo, não em segredo técnico.

**Se ainda quiser uma referência, o melhor caminho é código aberto, não APK:**

| Fonte | Por que |
|---|---|
| **Odoo Inventory (Barcode app)** | picking em ondas, localização, regras de scan — código aberto, documentado, dá para ler |
| **ERPNext (Stock)** | pick list, putaway, transferência — fluxo completo e open source |
| **Instacart Shopper** (app fechado, EUA/Canadá) | melhor referência de *shopper*: substituição, peso, foto, checkout — só serve como UI, e é regional |
| **Cornershop Shopper** | mesma mecânica na América Latina; disponibilidade atual precisa ser verificada na loja |

Se você instalar um deles no emulador e me passar o APK, eu analiso o fluxo de picking
como fiz com o iFood. Mas eu começaria pelo **Odoo**: é gratuito, tem o processo
documentado e eu consigo apontar exatamente as regras que valem para você — sem
gastar dias decodificando uma tela.

---

## 12. Decisões que eu preciso de você

1. **Volume**: quantos pedidos por dia e quantos separadores? (define pedido único × onda)
2. **Substituição**: sempre pedir aprovação, ou autorizar até +20% automaticamente?
3. **Aprovação do cliente**: push no app, WhatsApp ou ligação?
4. **Quem confere**: outro separador ou o caixa?
5. **Lacre**: já existe etiqueta/lacre numerado na operação ou precisa entrar na impressão?
