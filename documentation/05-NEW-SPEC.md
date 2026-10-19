# URBAN SHIELD

## Specification 05 — Triagem, Revisão Humana e Avaliação da IA

**Documento:** Especificação 05
**Versão:** 1.0
**Status:** Draft Controlado
**Altera:** `02 System Specification` (RN-05, RN-07, RN-08, §13, §19, §22, §23) e `03 Technical Design` (§10, §14, §15, §16, §19, §43)
**Fonte de verdade:** fluxo cidadão → triagem → operador, e medição da confiabilidade da IA

---

# 1. Objetivo

Transformar o sistema em uma cadeia única e mensurável:

```text
Cidadão envia relato
      ↓
Sistema GUARDA primeiro, depois classifica e localiza (IA + geocodificação)
      ↓
Regras objetivas decidem se precisa de revisão humana
      ↓
Operador trabalha uma fila priorizada: confirma ou corrige
      ↓
As correções humanas são a base de medição da IA
```

O cidadão não precisa entender nada da arquitetura: informa o problema, informa o endereço ou marca um ponto no mapa e recebe um **código de acompanhamento**.

---

# 2. Princípio: o relato nunca se perde

Um relato válido **sempre** é persistido, mesmo que IA e/ou geocodificação falhem. Falhas externas rebaixam a qualidade da triagem, nunca a disponibilidade do relato.

---

# 3. Alterações em regras anteriores

| Regra | Antes | Agora |
| --- | --- | --- |
| **RN-07** (falha da IA) | Não criar ocorrência; 503 | Criar a ocorrência com `analysisStatus = FAILED`, sem classificação, `needsReview = true` (motivo `AI_FAILED`). Nunca preencher classificação por "valor padrão". |
| **RN-05** (coordenadas) | Só do geocodificador | Do geocodificador **ou** de um ponto escolhido pelo cidadão/operador. O sistema nunca inventa coordenadas. A origem fica em `locationSource`. |
| **RN-08** (status inicial) | `OPEN` | Mantido. `OPEN` é o estado operacional; a qualidade da triagem é um eixo separado (`needsReview`). |
| §19 Matriz de falhas | Ollama fora → 503 | Ollama fora / JSON inválido → **201** + `FAILED` + revisão obrigatória. Google fora → **201** sem coordenadas (já era). Banco fora → 500 (único caso em que o relato não pode ser guardado). |
| §13 Resposta do POST | Ocorrência completa | **Resposta pública mínima** (código, status, data). Classificação e recomendação de IA não vão ao cidadão (RN-12). |

Campos de classificação (`category`, `primaryOds`, `severity`, `summary`, `recommendedAction`) passam a ser **anuláveis**, e só são nulos quando `analysisStatus = FAILED` e ainda não houve verificação humana. Nulo ≠ valor inválido: RN-02/03/04 continuam valendo para todo valor presente.

---

# 4. Jornada do cidadão

## 4.1 Envio — `POST /api/v1/incidents` (público)

```json
{
  "description": "Está alagando na Rua X.",
  "address": "Rua X, 100",
  "location": { "latitude": -20.5, "longitude": -47.4 }
}
```

* `description` obrigatório (RF-02).
* `address` opcional. `location` opcional (ponto escolhido no mapa). Se nenhum dos dois vier, o sistema tenta o endereço extraído pela IA.
* Campos desconhecidos são rejeitados.

**Prioridade da localização** (estende Technical Design §14):

```text
location (ponto do cidadão)  >  address informado  >  endereço extraído pela IA
```

* Ponto do cidadão → `locationSource = CITIZEN_PIN`, `geocodingStatus = RESOLVED`, `locationPrecision = APPROXIMATE`.
* Se houver ponto **e** endereço (informado ou extraído), o endereço é geocodificado em segundo plano da requisição; se a distância ao ponto passar de **500 m**, registra-se o motivo `LOCATION_MISMATCH` (o ponto do cidadão é mantido).
* Sem ponto: geocodifica o endereço → `GEOCODED`; sem resultado → `NONE` (`NOT_FOUND`, sem coordenadas — RN-06).

**Resposta `201`:**

```json
{ "data": { "referenceCode": "US-7K3Q9-X2M4P", "status": "OPEN", "createdAt": "2026-10-19T12:00:00.000Z" } }
```

## 4.2 Código de acompanhamento

* Formato `US-XXXXX-XXXXX`, 10 caracteres de um alfabeto de 30 símbolos sem ambiguidade (sem `0 1 I L O U`), gerados por CSPRNG (~49 bits). **Não sequencial** — não permite enumerar relatos.
* Único (índice UNIQUE). A entrada é normalizada (maiúsculas, sem espaços).

## 4.3 Acompanhamento — `GET /api/v1/reports/:referenceCode` (público, limite de taxa próprio)

```json
{ "data": { "referenceCode": "US-7K3Q9-X2M4P", "stage": "RECEIVED", "createdAt": "…", "updatedAt": "…" } }
```

| `status` interno | `stage` público |
| --- | --- |
| `OPEN` | `RECEIVED` |
| `IN_REVIEW` | `IN_REVIEW` |
| `RESOLVED` | `RESOLVED` |
| `DISMISSED` | `CLOSED` |

Não expõe descrição, endereço, coordenadas, classificação nem dados do operador. Código malformado ou inexistente → o mesmo `404 NOT_FOUND`.

---

# 5. Triagem e necessidade de revisão

A decisão é por **regras objetivas**, não pela "confiança" informada pelo modelo (não calibrada). `needsReview = true` quando houver ao menos um motivo:

| Motivo | Quando |
| --- | --- |
| `AI_FAILED` | IA indisponível, timeout ou saída inválida |
| `SEVERITY_CRITICAL` | IA classificou como `CRITICAL` (sempre confirmado por humano) |
| `LOCATION_NOT_FOUND` | Sem coordenadas |
| `LOCATION_PARTIAL` | Geocodificação parcial |
| `LOCATION_MISMATCH` | Ponto do cidadão a mais de 500 m do endereço geocodificado |

Os motivos ficam gravados (`reviewReasons`) mesmo depois da revisão. `needsReview` volta a `false` quando um humano verifica.

---

# 6. Operador

## 6.1 Fila priorizada — `GET /api/v1/incidents?sort=priority`

Novos parâmetros: `sort` (`recent` — padrão, comportamento anterior — ou `priority`) e `needsReview` (`true`/`false`).

Ordem de `priority`:

```text
1º  severidade: CRITICAL → NÃO CLASSIFICADA → MEDIUM → LOW
2º  needsReview = true antes de false
3º  mais antigo primeiro
```

Relato **sem classificação** vale mais que `MEDIUM` e menos que `CRITICAL`: sem saber a gravidade, não pode ficar atrás de casos leves (fail-safe).

## 6.2 Revisão — `PATCH /api/v1/incidents/:id/review` (OPERATOR ou ADMIN)

```json
{ "decision": "CORRECT",
  "corrections": { "severity": "CRITICAL", "category": "FLOODING", "address": "Rua Y, 20" } }
```

* `decision = CONFIRM`: o operador valida o registro como está. Exige classificação completa e **não aceita** `corrections`.
* `decision = CORRECT`: exige ao menos uma alteração efetiva. Para relato com `analysisStatus = FAILED`, a classificação completa precisa ser informada.
* `corrections.address` → nova geocodificação (`GEOCODED`); falha do geocodificador → `503 GEOCODING_ERROR` (o operador espera um resultado). `corrections.location` → ponto do operador (`locationSource = OPERATOR`).
* Só relatos `OPEN` ou `IN_REVIEW` podem ser revisados. Concorrência otimista: se o registro mudou no meio, `409`.
* Resultado: `verification = CONFIRMED | CORRECTED`, `verifiedAt`, `verifiedBy`, `needsReview = false`, `locationVerdict`:
  * localização alterada → `CORRECTED`;
  * localização com coordenadas e não alterada → `CONFIRMED`;
  * sem coordenadas e não alterada → `null`.
* Cada revisão grava um registro de histórico (`incident_review`: quem, decisão, campos alterados com valor anterior e novo).

## 6.3 O que nunca se perde: o snapshot da IA

No momento da criação grava-se `triageSnapshot` — **imutável**: saída original da IA (ou `null`), resultado original da localização, modelo e versão do prompt. As correções alteram os campos "atuais", jamais o snapshot. É a comparação *snapshot × valor final humano* que mede a IA.

---

# 7. Avaliação da IA

85% de acerto global não é critério suficiente para uso operacional (classes desbalanceadas escondem erros graves). A confiabilidade é medida por duas fontes.

## 7.1 Dataset de avaliação (offline) — estende a Specification 02 §22

Cada registro:

```text
id, description, providedAddress?, expectedCategory, expectedPrimaryOds, expectedRelatedOds,
expectedSeverity, expectedAddress?, expectedLatitude?, expectedLongitude?,
labels: [{ labeler, category, severity, … }]    # ≥ 2 rotuladores humanos independentes
```

Regras do dataset:
* rótulos feitos por humanos — **nunca** gerados pela própria IA avaliada;
* conjunto de teste separado do usado para ajustar o prompt;
* concordância entre rotuladores medida (kappa de Cohen) e divergências resolvidas por um terceiro;
* amostra mínima sugerida: 30–50 casos `CRITICAL`; sem isso o recall de críticos não é estatisticamente defensável (o relatório mostra o tamanho `n` de cada classe e o intervalo de confiança).

## 7.2 Métricas

| # | Métrica | Definição |
| --- | --- | --- |
| M1 | Classificação | Precisão, recall e F1 **por categoria** e **por severidade** (matriz de confusão), mais macro-F1 e acurácia global (apenas informativa) |
| M2 | Casos críticos | `criticalToLow` = gold `CRITICAL` previsto `LOW`; `criticalToMedium`; `criticalMissRate`; e a taxa de relatos críticos **sem classificação** (IA falhou) |
| M3 | Localização | `resolvedRate` (endereços que resultaram em coordenadas), `correctRate` (coordenadas a ≤ **200 m** do gold, ou veredito humano `CONFIRMED`), `extractionAccuracy` do endereço |
| M4 | Revisão humana | `correctionRate = CORRECTED / verificados`, por campo (categoria, severidade, ODS, localização), e `reviewLoad = needsReview / total` |
| M5 | Resiliência | Com Ollama e/ou Google derrubados: `persistedRate = relatos acessíveis / relatos enviados` (meta 100%), contagem `FAILED`/sem coordenadas e tempo de recuperação |
| M6 | Operação | Latência P50/P95 ponta a ponta; sucesso fim a fim |

## 7.3 Portões de qualidade (valores definidos pelo projeto, configuráveis)

O relatório compara cada métrica a um limite configurável e marca `PASS`/`FAIL`. Os limites iniciais são **decisão do projeto** e ficam em arquivo de configuração versionado (ex.: recall de `CRITICAL`, `criticalToLow` máximo, `persistedRate = 100%`). Enquanto algum portão falhar, a IA permanece **assistiva**: nada é descartado ou fechado automaticamente por ela.

## 7.4 Fontes

* **Offline:** `npm run eval -- <dataset.json>` roda o dataset contra a IA e o geocodificador reais, e um modo de injeção de falhas para M5.
* **Produção:** as mesmas métricas M1/M3/M4 calculadas sobre `triageSnapshot × valor final` dos relatos verificados. Como só relatos sinalizados passam por humano, **uma amostra aleatória dos não sinalizados também é encaminhada à revisão** (auditoria por amostragem) para evitar viés de seleção.

---

# 8. Critérios de aceite

* **CA-11** Com Ollama indisponível, `POST /incidents` válido retorna `201`, o relato é persistido com `analysisStatus = FAILED` e `needsReview = true`.
* **CA-12** Com Google indisponível, o relato é persistido sem coordenadas e sinalizado.
* **CA-13** A resposta do POST contém apenas `referenceCode`, `status`, `createdAt`.
* **CA-14** O acompanhamento por código não expõe dados internos e responde igual para código inexistente e malformado.
* **CA-15** A fila `sort=priority` ordena `CRITICAL`, não classificadas, `MEDIUM`, `LOW`.
* **CA-16** Revisão preserva o `triageSnapshot` e registra os campos alterados.
* **CA-17** `CONFIRM` com `corrections`, ou `CORRECT` sem mudança efetiva, é rejeitado (400).
* **CA-18** O relatório de avaliação calcula M1–M6 e aponta `PASS`/`FAIL` por portão.
* **CA-19** Coordenadas nunca são geradas pelo sistema: vêm do geocodificador, do cidadão ou do operador.