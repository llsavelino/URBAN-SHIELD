# URBAN SHIELD

## System Specification

**Documento:** Especificação Geral do Sistema
**Versão:** 1.0
**Status:** Draft Controlado
**Projeto:** Urban Shield
**Fonte de verdade:** Requisitos e comportamento funcional

---

# 1. Objetivo

Este documento define o comportamento esperado do Urban Shield.

Ele transforma a visão do produto em:

* requisitos funcionais;
* requisitos não funcionais;
* regras de negócio;
* casos de uso;
* fluxos;
* estados;
* contratos conceituais;
* critérios de aceite.

---

# 2. Conceito Central

O sistema possui uma entidade principal:

```text
Incident
```

Uma `Incident` representa uma ocorrência urbana registrada no sistema.

---

# 3. Atores

## ATO-01 — Cidadão

Pode fornecer relatos.

## ATO-02 — Operador

Pode visualizar, filtrar e revisar ocorrências.

## ATO-03 — Sistema

Executa automaticamente:

* validação;
* análise de IA;
* geocodificação;
* persistência;
* exposição dos dados.

---

# 4. Requisitos Funcionais

## RF-01 — Criar ocorrência

O sistema deve permitir o envio de um relato em linguagem natural.

Entrada mínima:

```text
description
```

---

## RF-02 — Validar entrada

O sistema deve rejeitar:

* descrição vazia;
* descrição acima do limite configurado;
* payload inválido;
* campos desconhecidos quando o contrato não os permitir.

---

## RF-03 — Analisar relato

O sistema deve enviar o relato para o serviço de IA.

A análise deverá produzir:

```text
category
primaryOds
relatedOds
severity
summary
extractedAddress
recommendedAction
```

---

## RF-04 — Validar saída da IA

A resposta da IA deverá ser validada contra um contrato estruturado.

Resposta inválida deverá ser rejeitada.

---

## RF-05 — Resolver localização

Quando houver endereço utilizável, o sistema deverá executar geocodificação.

---

## RF-06 — Registrar resultado geográfico

O sistema deverá armazenar:

```text
address
formattedAddress
latitude
longitude
geocodingStatus
locationPrecision
```

quando disponíveis.

---

## RF-07 — Persistir ocorrência

Uma ocorrência processada com sucesso deverá ser persistida.

---

## RF-08 — Listar ocorrências

O sistema deverá permitir consulta paginada das ocorrências.

---

## RF-09 — Filtrar

A listagem deverá permitir filtros por:

```text
ODS
severity
category
status
```

---

## RF-10 — Consultar ocorrência

O sistema deverá permitir consulta de uma ocorrência por ID.

---

## RF-11 — Visualizar no mapa

Ocorrências com localização válida deverão ser apresentadas no mapa.

Ocorrências sem coordenadas não deverão ser plotadas.

---

## RF-12 — Consultar detalhes

O operador deverá visualizar:

* relato original;
* resumo;
* categoria;
* ODS;
* severidade;
* endereço;
* localização;
* recomendação;
* status;
* datas.

---

## RF-13 — Alterar status

O operador deverá poder alterar o status da ocorrência.

---

## RF-14 — Tratar falhas externas

O sistema deverá distinguir:

```text
erro interno
erro de IA
erro de geocodificação
erro de validação
erro de banco
```

---

# 5. Requisitos Não Funcionais

## RNF-01

Frontend e backend serão implementados em TypeScript.

## RNF-02

O frontend utilizará Angular.

## RNF-03

O backend utilizará NestJS.

## RNF-04

A comunicação será realizada por HTTP/REST.

## RNF-05

A API será versionada.

## RNF-06

Entradas serão validadas.

## RNF-07

Saídas da IA serão validadas.

## RNF-08

Serviços externos possuirão timeout.

## RNF-09

Erros internos não serão expostos ao cliente.

## RNF-10

Segredos não serão armazenados no código.

## RNF-11

A aplicação deverá possuir logs estruturados.

## RNF-12

A interface deverá funcionar em desktop e tablet.

---

# 6. Regras de Negócio

## RN-01 — Identificação

Toda ocorrência deverá possuir um ID único.

---

## RN-02 — Severidade

Valores válidos:

```text
LOW
MEDIUM
CRITICAL
```

Nenhum outro valor será aceito.

---

## RN-03 — ODS

`primaryOds` deverá conter uma das:

```text
ODS_6
ODS_13
```

`relatedOds` poderá conter zero ou uma ODS adicional.

A ODS principal não poderá aparecer duplicada em `relatedOds`.

---

## RN-04 — Categoria

Somente categorias pertencentes ao catálogo oficial poderão ser persistidas.

---

## RN-05 — Geolocalização

Coordenadas só poderão ser persistidas quando vierem de uma resposta válida do serviço de geocodificação.

O sistema nunca deverá gerar coordenadas arbitrariamente.

---

## RN-06 — Falha de geocodificação

A ocorrência poderá existir sem coordenadas.

Nesse caso:

```text
geocodingStatus = NOT_FOUND
latitude = null
longitude = null
```

---

## RN-07 — Falha da IA

No MVP, se a análise da IA não puder ser concluída ou validada:

```text
não criar ocorrência processada
retornar erro controlado
```

---

## RN-08 — Status inicial

Toda nova ocorrência será criada com:

```text
OPEN
```

---

## RN-09 — Status

Valores permitidos:

```text
OPEN
IN_REVIEW
RESOLVED
DISMISSED
```

---

## RN-10 — Operador

Somente o operador deverá alterar o status operacional.

---

## RN-11 — IA

A IA não poderá modificar diretamente o banco.

---

## RN-12 — Recomendação

`recommendedAction` deverá ser tratada como recomendação preliminar gerada por IA.

---

# 7. Estado da Ocorrência

```text
OPEN
  │
  ▼
IN_REVIEW
  │
  ├──────► RESOLVED
  │
  └──────► DISMISSED
```

O sistema deverá manter os timestamps das transições relevantes.

---

# 8. Caso de Uso — Criar Ocorrência

### Pré-condição

O cliente possui um relato válido.

### Fluxo

```text
1. Cliente envia descrição.
2. API valida payload.
3. Aplicação solicita análise ao serviço de IA.
4. Resposta da IA é validada.
5. Endereço é normalizado.
6. Serviço de geocodificação é executado.
7. Ocorrência é construída.
8. Ocorrência é persistida.
9. API retorna a ocorrência.
```

### Pós-condição

Uma nova ocorrência existe no banco.

---

# 9. Caso de Uso — Listar Ocorrências

### Entrada

Filtros opcionais:

```text
ods
severity
category
status
page
limit
```

### Saída

```text
items
page
limit
total
totalPages
```

A paginação será utilizada somente em endpoints de consulta.

---

# 10. Caso de Uso — Consultar Ocorrência

Entrada:

```text
incidentId
```

Saída:

```text
Incident
```

Caso não exista:

```text
404
```

---

# 11. Caso de Uso — Alterar Status

Entrada:

```json
{
  "status": "IN_REVIEW"
}
```

O backend deverá validar o valor e a transição permitida.

---

# 12. Modelo Conceitual de Incident

```text
Incident
│
├── id
├── description
├── summary
├── category
├── primaryOds
├── relatedOds
├── severity
├── address
├── formattedAddress
├── latitude
├── longitude
├── geocodingStatus
├── locationPrecision
├── recommendedAction
├── status
├── createdAt
└── updatedAt
```

---

# 13. Contrato Conceitual de Criação

### Request

```json
{
  "description": "O bueiro da Rua X está transbordando."
}
```

### Success

```json
{
  "data": {
    "id": "uuid",
    "description": "O bueiro da Rua X está transbordando.",
    "summary": "Bueiro com transbordamento.",
    "category": "URBAN_DRAINAGE",
    "primaryOds": "ODS_6",
    "relatedOds": [],
    "severity": "MEDIUM",
    "address": "Rua X",
    "formattedAddress": "Rua X, Cidade - SP",
    "latitude": -20.000000,
    "longitude": -47.000000,
    "geocodingStatus": "RESOLVED",
    "locationPrecision": "APPROXIMATE",
    "recommendedAction": "Verificar a condição do sistema de drenagem.",
    "status": "OPEN",
    "createdAt": "2026-10-07T00:00:00Z",
    "updatedAt": "2026-10-07T00:00:00Z"
  }
}
```

---

# 14. Contrato de Erro

Formato:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Dados inválidos."
  }
}
```

Códigos iniciais:

```text
INVALID_REQUEST
AI_UNAVAILABLE
AI_INVALID_RESPONSE
GEOCODING_ERROR
NOT_FOUND
INTERNAL_ERROR
```

Informações internas não deverão ser retornadas ao cliente.

---

# 15. Status HTTP

```text
201 Created
400 Bad Request
404 Not Found
422 Unprocessable Entity
500 Internal Server Error
503 Service Unavailable
```

---

# 16. API Inicial

## POST

```text
/api/v1/incidents
```

Cria ocorrência.

## GET

```text
/api/v1/incidents
```

Lista ocorrências.

## GET

```text
/api/v1/incidents/:id
```

Consulta ocorrência.

## PATCH

```text
/api/v1/incidents/:id/status
```

Altera status.

---

# 17. Contrato da IA

Entrada:

```json
{
  "description": "Está alagando na Rua X e a água está entrando nas casas."
}
```

Saída esperada:

```json
{
  "category": "FLOODING",
  "primaryOds": "ODS_13",
  "relatedOds": [
    "ODS_6"
  ],
  "severity": "CRITICAL",
  "summary": "Alagamento com entrada de água em residências.",
  "extractedAddress": "Rua X",
  "recommendedAction": "Avaliar imediatamente a área e verificar necessidade de isolamento preventivo."
}
```

---

# 18. Contrato de Geocodificação

Entrada:

```text
address
```

Saída normalizada:

```json
{
  "formattedAddress": "Rua X, Cidade - SP",
  "latitude": -20.000000,
  "longitude": -47.000000,
  "placeId": "provider-place-id",
  "status": "RESOLVED",
  "precision": "APPROXIMATE"
}
```

---

# 19. Matriz de Falhas

| Componente | Falha                   | Resultado                  |
| ---------- | ----------------------- | -------------------------- |
| Cliente    | JSON inválido           | 400                        |
| Cliente    | Campo inválido          | 400/422                    |
| Ollama     | indisponível            | 503                        |
| Ollama     | JSON inválido           | 503                        |
| Geocoding  | endereço não encontrado | ocorrência sem coordenadas |
| Banco      | indisponível            | 500                        |
| ID         | inexistente             | 404                        |

---

# 20. Critérios de Aceite

## CA-01

Dado um relato válido, o sistema deve criar uma ocorrência.

## CA-02

A saída da IA deve ser validada antes da persistência.

## CA-03

Uma resposta inválida da IA não pode ser persistida como análise válida.

## CA-04

Endereço não encontrado não deve impedir necessariamente a criação da ocorrência.

## CA-05

Ocorrências sem coordenadas não devem aparecer no mapa.

## CA-06

Filtros devem alterar corretamente o conjunto retornado.

## CA-07

A consulta por ID deve retornar a ocorrência correta.

## CA-08

Status inválido deve ser rejeitado.

## CA-09

Erro interno não deve expor detalhes internos.

## CA-10

Todas as respostas devem obedecer ao contrato definido.

---

# 21. Testes de Aceite

O sistema deverá ser testado com pelo menos:

* relato de alagamento;
* relato de bueiro;
* relato de esgoto;
* relato de tempestade;
* relato sem endereço;
* endereço inválido;
* texto ambíguo;
* saída inválida da IA;
* Ollama indisponível;
* Google indisponível.

---

# 22. Dataset de Avaliação

O projeto deverá manter uma base de relatos previamente classificados.

Cada registro deverá conter:

```text
id
description
expectedCategory
expectedPrimaryOds
expectedRelatedOds
expectedSeverity
expectedAddress
```

A IA será comparada contra esse conjunto.

---

# 23. Métricas

Serão avaliadas:

```text
Category Accuracy
ODS Accuracy
Severity Accuracy
Address Extraction Accuracy
End-to-End Success Rate
P50 Latency
P95 Latency
```

A meta mínima definida para o projeto é:

```text
≥ 85%
```

para a métrica principal de classificação definida no dataset.

---

# 24. Regra de Autoridade dos Dados

A prioridade dos dados será:

```text
Relato original
    ↓
Análise estruturada pela IA
    ↓
Validação de domínio
    ↓
Geocodificação externa
    ↓
Estado persistido
```

A IA não terá autoridade absoluta sobre dados externos.

---

# 25. Definition of Done

Uma funcionalidade estará concluída quando possuir:

```text
Implementação
Contrato
Validação
Tratamento de erros
Teste
Integração
Documentação mínima
```

---

# 26. Relação com o Product Vision

Este documento implementa a visão estabelecida no `01-PRODUCT-VISION.md`.

A entidade principal permanece:

```text
Incident
```

Os níveis de severidade permanecem:

```text
LOW
MEDIUM
CRITICAL
```

As ODS permanecem:

```text
ODS_6
ODS_13
```

Os status permanecem:

```text
OPEN
IN_REVIEW
RESOLVED
DISMISSED
```

Não deverão existir conceitos conflitantes entre os documentos.
