# URBAN SHIELD

## Technical Design Document

**Documento:** Technical Design
**Versão:** 1.0
**Status:** Draft Controlado
**Projeto:** Urban Shield
**Fonte de verdade:** Arquitetura e implementação

---

# 1. Objetivo

Este documento descreve como o Urban Shield será implementado.

Ele define:

* arquitetura;
* stack;
* módulos;
* responsabilidades;
* banco;
* APIs;
* integração com IA;
* integração geográfica;
* segurança;
* observabilidade;
* testes;
* configuração;
* estrutura de código;
* deployment inicial.

---

# 2. Decisões Técnicas

| Área           | Decisão               |
| -------------- | --------------------- |
| Frontend       | Angular               |
| Backend        | NestJS                |
| Linguagem      | TypeScript            |
| API            | REST                  |
| Banco          | PostgreSQL            |
| IA             | Ollama                |
| Mapas          | Google Maps Platform  |
| Geocoding      | Google Geocoding      |
| Arquitetura    | Monólito modular      |
| API Version    | `/api/v1`             |
| Contratos HTTP | JSON                  |
| Validação HTTP | class-validator       |
| Validação IA   | JSON Schema / AJV     |
| Testes         | Jest + testes E2E     |
| Configuração   | Environment Variables |

---

# 3. Princípio Arquitetural

O MVP utilizará um **monólito modular**.

Não serão utilizados microserviços.

Estrutura conceitual:

```text
Angular
   │
   ▼
NestJS
   │
   ├── Incident Module
   ├── AI Module
   ├── Geocoding Module
   └── Infrastructure
```

O objetivo é manter o sistema simples sem comprometer separação de responsabilidades.

---

# 4. Arquitetura em Camadas

```text
Presentation
      ↓
Application
      ↓
Domain
      ↑
Infrastructure
```

## Presentation

Responsável por:

* HTTP;
* controllers;
* DTOs;
* serialização;
* autenticação futura.

## Application

Responsável por:

* casos de uso;
* orquestração;
* comandos;
* queries;
* coordenação de serviços.

## Domain

Responsável por:

* entidades;
* enums;
* regras;
* interfaces de repositório;
* invariantes.

## Infrastructure

Responsável por:

* PostgreSQL;
* implementação de repositórios;
* Ollama;
* Google Geocoding;
* clientes HTTP;
* configurações.

---

# 5. Estrutura do Backend

```text
backend/
└── src/
    ├── app.module.ts
    ├── main.ts
    │
    ├── modules/
    │   └── incidents/
    │       ├── domain/
    │       │   ├── entities/
    │       │   │   └── incident.entity.ts
    │       │   ├── enums/
    │       │   │   ├── incident-status.enum.ts
    │       │   │   ├── severity.enum.ts
    │       │   │   ├── ods.enum.ts
    │       │   │   └── category.enum.ts
    │       │   └── repositories/
    │       │       └── incident.repository.ts
    │       │
    │       ├── application/
    │       │   ├── use-cases/
    │       │   │   ├── create-incident/
    │       │   │   ├── list-incidents/
    │       │   │   ├── get-incident/
    │       │   │   └── update-incident-status/
    │       │   └── services/
    │       │
    │       ├── infrastructure/
    │       │   ├── database/
    │       │   ├── ai/
    │       │   └── geocoding/
    │       │
    │       └── presentation/
    │           ├── controllers/
    │           └── dto/
    │
    ├── common/
    │   ├── errors/
    │   ├── filters/
    │   ├── pipes/
    │   ├── interceptors/
    │   └── logging/
    │
    └── config/
```

---

# 6. Módulo Incident

O módulo `Incident` representa o núcleo de negócio.

Responsabilidades:

* criar ocorrência;
* consultar;
* listar;
* filtrar;
* alterar status;
* aplicar regras de domínio.

Ele não deverá conhecer diretamente:

* Ollama;
* Google Maps;
* detalhes HTTP.

Essas dependências deverão entrar por abstrações.

---

# 7. Interface do Repositório

Conceitualmente:

```ts
interface IncidentRepository {
  create(incident: Incident): Promise<Incident>;
  findById(id: string): Promise<Incident | null>;
  findMany(filter: IncidentFilter): Promise<IncidentPage>;
  updateStatus(id: string, status: IncidentStatus): Promise<Incident>;
}
```

A aplicação dependerá dessa abstração.

A implementação PostgreSQL ficará na infraestrutura.

---

# 8. Serviço de IA

Abstração:

```ts
interface IncidentAnalysisProvider {
  analyze(
    description: string
  ): Promise<IncidentAnalysis>;
}
```

Implementação do MVP:

```text
OllamaIncidentAnalysisProvider
```

No futuro poderão existir:

```text
CloudIncidentAnalysisProvider
AnotherLocalProvider
MockIncidentAnalysisProvider
```

sem alterar o domínio.

---

# 9. Serviço de Geocoding

Abstração:

```ts
interface GeocodingProvider {
  geocode(
    address: string
  ): Promise<GeocodingResult>;
}
```

Implementação:

```text
GoogleGeocodingProvider
```

---

# 10. Fluxo de Criação

```text
POST /api/v1/incidents
             │
             ▼
      CreateIncidentController
             │
             ▼
      CreateIncidentUseCase
             │
       ┌─────┴──────┐
       ▼            ▼
   AI Provider   Geocoding
       │            │
       └─────┬──────┘
             ▼
       Domain Entity
             │
             ▼
      IncidentRepository
             │
             ▼
         PostgreSQL
```

---

# 11. Contrato de IA

A IA deverá retornar somente o objeto definido pelo schema.

Schema conceitual:

```json
{
  "type": "object",
  "required": [
    "category",
    "primaryOds",
    "relatedOds",
    "severity",
    "summary",
    "extractedAddress",
    "recommendedAction"
  ]
}
```

Enums:

```text
category:
FLOODING
URBAN_DRAINAGE
SEWAGE
WATER_SUPPLY
STORM
LANDSLIDE
OTHER
```

```text
primaryOds:
ODS_6
ODS_13
```

```text
severity:
LOW
MEDIUM
CRITICAL
```

---

# 12. Prompt da IA

O prompt deverá ser tratado como artefato versionado.

Exemplo conceitual:

```text
SYSTEM

Você é um classificador de ocorrências urbanas.

Sua função é extrair informações do relato.

Você deve:
- classificar a categoria;
- identificar ODS;
- classificar severidade;
- resumir o relato;
- extrair endereço somente quando houver evidência;
- gerar recomendação preliminar.

Não invente:
- endereços;
- coordenadas;
- nomes;
- eventos não presentes no relato.

Responda exclusivamente no schema definido.
```

O prompt deverá possuir versão.

Exemplo:

```text
incident-analysis-v1
```

---

# 13. Regra Contra Alucinação

A IA nunca poderá receber instrução para completar informações ausentes por inferência arbitrária.

Exemplo:

Entrada:

```text
"Tem água acumulada aqui."
```

Resultado aceitável:

```json
{
  "extractedAddress": null
}
```

Resultado inválido:

```json
{
  "extractedAddress": "Rua Principal, Franca - SP"
}
```

---

# 14. Geocoding

Fluxo:

```text
extractedAddress
       ↓
Google Geocoding
       ↓
normalização
       ↓
latitude/longitude
       ↓
persistência
```

Caso o cidadão tenha informado endereço explicitamente, esse endereço terá prioridade sobre um endereço inferido pela IA.

Ordem:

```text
providedAddress
      >
extractedAddress
```

---

# 15. Modelo de Localização

```ts
type GeocodingStatus =
  | 'RESOLVED'
  | 'PARTIAL'
  | 'NOT_FOUND';

type LocationPrecision =
  | 'EXACT'
  | 'APPROXIMATE';
```

Modelo:

```ts
interface GeocodingResult {
  formattedAddress: string | null;
  latitude: number | null;
  longitude: number | null;
  placeId: string | null;
  status: GeocodingStatus;
  precision: LocationPrecision | null;
}
```

---

# 16. Banco de Dados

PostgreSQL será o banco principal.

Tabela inicial:

```sql
incident
```

Campos:

```text
id UUID PK
description TEXT NOT NULL
summary TEXT NOT NULL
category VARCHAR NOT NULL
primary_ods VARCHAR NOT NULL
related_ods JSONB NOT NULL
severity VARCHAR NOT NULL
address TEXT NULL
formatted_address TEXT NULL
latitude DOUBLE PRECISION NULL
longitude DOUBLE PRECISION NULL
place_id TEXT NULL
geocoding_status VARCHAR NOT NULL
location_precision VARCHAR NULL
recommended_action TEXT NOT NULL
status VARCHAR NOT NULL
created_at TIMESTAMP NOT NULL
updated_at TIMESTAMP NOT NULL
```

---

# 17. Índices

Índices iniciais:

```text
id
status
severity
category
primary_ods
created_at
(latitude, longitude)
```

O índice geográfico avançado poderá ser considerado posteriormente.

---

# 18. Identidade

O ID deverá ser UUID.

Exemplo:

```text
550e8400-e29b-41d4-a716-446655440000
```

O cliente não deverá controlar o ID de criação.

---

# 19. API

## Criar

```http
POST /api/v1/incidents
```

## Listar

```http
GET /api/v1/incidents
```

## Consultar

```http
GET /api/v1/incidents/:id
```

## Alterar status

```http
PATCH /api/v1/incidents/:id/status
```

---

# 20. Paginação

Endpoint:

```http
GET /api/v1/incidents?page=1&limit=20
```

Response:

```json
{
  "data": {
    "items": [],
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

# 21. Filtros

Exemplo:

```http
GET /api/v1/incidents?severity=CRITICAL&ods=ODS_13&status=OPEN
```

Filtros aceitos:

```text
severity
category
ods
status
page
limit
```

---

# 22. Error Handling

Será utilizado um tratamento centralizado.

Arquitetura:

```text
Exception
   ↓
Global Exception Filter
   ↓
Application Error
   ↓
API Error
```

Resposta externa:

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Internal server error."
  }
}
```

O servidor deverá registrar os detalhes internamente.

---

# 23. Timeouts

Integrações externas deverão possuir timeout.

Exemplo conceitual:

```text
Ollama
timeout = configurável

Google Geocoding
timeout = configurável
```

Nenhuma chamada externa deverá aguardar indefinidamente.

---

# 24. Configuração

Variáveis:

```text
NODE_ENV
PORT
DATABASE_URL

OLLAMA_BASE_URL
OLLAMA_MODEL
OLLAMA_TIMEOUT_MS

GOOGLE_MAPS_API_KEY
GOOGLE_GEOCODING_TIMEOUT_MS
```

---

# 25. Segurança

Implementações mínimas:

```text
validation pipe
CORS
security headers
body size limit
rate limit
request timeout
secret management
sanitização de logs
```

A chave da Google Maps Platform nunca deverá chegar ao repositório.

---

# 26. Observabilidade

Cada requisição deverá possuir um `requestId`.

Logs deverão permitir correlacionar:

```text
HTTP request
→ use case
→ Ollama
→ Geocoding
→ Database
```

Exemplo:

```text
request_id=abc123
event=incident.create
ai_duration_ms=1200
geocoding_duration_ms=320
database_duration_ms=25
total_duration_ms=1570
status=201
```

---

# 27. Métricas

Métricas iniciais:

```text
http_request_duration_ms
ai_request_duration_ms
geocoding_request_duration_ms
incident_create_success_total
incident_create_failure_total
ai_failure_total
geocoding_failure_total
```

---

# 28. Frontend

Estrutura:

```text
frontend/
└── src/
    └── app/
        ├── core/
        │   ├── services/
        │   ├── interceptors/
        │   └── models/
        │
        ├── features/
        │   ├── dashboard/
        │   └── incidents/
        │
        └── shared/
            ├── components/
            ├── pipes/
            └── directives/
```

---

# 29. Feature Dashboard

Responsabilidades:

* carregar ocorrências;
* aplicar filtros;
* apresentar mapa;
* abrir detalhes;
* mostrar indicadores.

---

# 30. Feature Incidents

Componentes:

```text
incident-create
incident-list
incident-detail
incident-filters
incident-map
```

Serviços:

```text
IncidentApiService
IncidentStateService
```

---

# 31. Mapa

O mapa consumirá somente ocorrências com:

```text
latitude != null
longitude != null
```

Cada marcador deverá representar uma ocorrência.

A aparência do marcador deverá refletir:

```text
LOW
MEDIUM
CRITICAL
```

---

# 32. Contrato Frontend ↔ Backend

O frontend deverá consumir os contratos HTTP do backend.

Não haverá regra duplicada de classificação no Angular.

Exemplo:

```text
Backend:
severity = CRITICAL
           ↓
Frontend:
renderização crítica
```

O frontend não deverá recalcular a severidade.

---

# 33. Estado Frontend

Cada consulta deverá possuir estados:

```text
IDLE
LOADING
SUCCESS
EMPTY
ERROR
```

---

# 34. Integração Angular + API

Exemplo conceitual:

```ts
createIncident(
  request: CreateIncidentRequest
): Observable<IncidentResponse>;
```

Os tipos TypeScript deverão acompanhar os contratos da API.

---

# 35. Testes de Backend

## Unit

Testar:

* regras de domínio;
* casos de uso;
* validação;
* mapeadores.

## Integration

Testar:

* banco;
* repositórios;
* providers.

## E2E

Testar:

```text
POST /incidents
GET /incidents
GET /incidents/:id
PATCH /incidents/:id/status
```

---

# 36. Testes da IA

A integração com Ollama deverá possuir:

```text
real integration tests
mock tests
schema tests
failure tests
```

Os testes determinísticos não deverão depender da LLM real.

---

# 37. Testes do Geocoding

Deverão existir mocks para:

```text
RESOLVED
PARTIAL
NOT_FOUND
TIMEOUT
PROVIDER_ERROR
```

---

# 38. Testes do Frontend

Prioridades:

```text
Create Incident
Dashboard
Filters
Map
Incident Detail
Error States
```

---

# 39. Docker

Ambiente local recomendado:

```text
docker-compose
```

Serviços:

```text
postgres
ollama
backend
frontend
```

O desenvolvimento poderá executar Angular e NestJS diretamente no host enquanto PostgreSQL e Ollama ficam em containers, caso isso simplifique o ambiente.

---

# 40. CI

Pipeline inicial:

```text
install
→ lint
→ typecheck
→ unit tests
→ build
```

Posteriormente:

```text
integration tests
→ e2e
→ security scan
```

---

# 41. Deployment do MVP

O MVP poderá ser executado em uma máquina única:

```text
Browser
   ↓
Frontend
   ↓
Backend
   ├── PostgreSQL
   ├── Ollama
   └── Google API
```

Não haverá necessidade de infraestrutura distribuída no início.

---

# 42. Restrições Arquiteturais

O sistema não deverá:

* colocar regra de negócio no controller;
* permitir acesso direto ao banco pelos controllers;
* chamar Ollama diretamente do frontend;
* chamar Google Geocoding diretamente do frontend para o fluxo de processamento;
* confiar em JSON da LLM sem validação;
* gerar coordenadas artificialmente;
* expor segredos;
* duplicar contratos entre módulos sem necessidade.

---

# 43. Fluxo Técnico Completo

```text
Angular
   │
   │ POST /api/v1/incidents
   ▼
NestJS Controller
   │
   ▼
DTO Validation
   │
   ▼
CreateIncidentUseCase
   │
   ▼
IncidentAnalysisProvider
   │
   ▼
Ollama
   │
   ▼
JSON Schema Validation
   │
   ▼
Address Resolution
   │
   ▼
GeocodingProvider
   │
   ▼
Domain Validation
   │
   ▼
IncidentRepository
   │
   ▼
PostgreSQL
   │
   ▼
HTTP Response
   │
   ▼
Angular
   │
   ▼
Dashboard / Map
```

---

# 44. Vertical Slice Inicial

A primeira funcionalidade implementada deverá ser:

```text
POST /api/v1/incidents
```

Ela deverá funcionar completamente antes da construção avançada do dashboard.

Critério:

```text
HTTP
→ Validation
→ AI
→ Validation
→ Geocoding
→ Domain
→ Database
→ Response
```

---

# 45. Ordem de Implementação

```text
01. Repository
02. Backend bootstrap
03. Database
04. Domain model
05. DTOs
06. Error contract
07. Incident repository
08. CreateIncidentUseCase
09. Ollama provider
10. AI schema
11. Geocoding provider
12. POST /incidents
13. GET /incidents
14. GET /incidents/:id
15. PATCH /incidents/:id/status
16. Angular API client
17. Dashboard
18. Map
19. Filters
20. Tests
21. Docker
22. CI
```

---

# 46. Definition of Done Técnico

Uma entrega técnica somente será considerada pronta quando:

```text
Código compilando
+
TypeScript sem erros
+
Testes passando
+
Contrato validado
+
Tratamento de erros implementado
+
Logs adequados
+
Configuração documentada
```

---

# 47. Decisões Futuras

As seguintes decisões serão tomadas somente após o MVP:

* Redis;
* cache distribuído;
* filas;
* processamento assíncrono;
* notificações;
* autenticação;
* RBAC;
* observabilidade avançada;
* PostgreSQL/PostGIS;
* CQRS;
* Event Sourcing;
* microserviços.

Nenhuma delas é necessária para validar a proposta principal do Urban Shield.

---

# 48. Compatibilidade com os Outros Documentos

Este documento implementa:

```text
01 Product Vision
       ↓
02 System Specification
       ↓
03 Technical Design
```

Os três documentos devem manter os seguintes elementos idênticos:

### Entidade

```text
Incident
```

### ODS

```text
ODS_6
ODS_13
```

### Severity

```text
LOW
MEDIUM
CRITICAL
```

### Status

```text
OPEN
IN_REVIEW
RESOLVED
DISMISSED
```

### Categories

```text
FLOODING
URBAN_DRAINAGE
SEWAGE
WATER_SUPPLY
STORM
LANDSLIDE
OTHER
```

### Endpoint principal

```text
POST /api/v1/incidents
```

### Arquitetura

```text
Angular
   ↓
NestJS
   ↓
PostgreSQL
Ollama
Google Geocoding
```

---

# 49. Princípio Arquitetural Final

A arquitetura deverá seguir:

```text
Produto define
       ↓
Requisitos especificam
       ↓
Aplicação implementa
       ↓
Infraestrutura integra
```

Nenhuma tecnologia deverá ditar o comportamento do domínio.

O domínio do Urban Shield deve permanecer independente de:

* Angular;
* NestJS;
* Ollama;
* Google Maps;
* PostgreSQL.

Isso permitirá substituir componentes de infraestrutura no futuro sem reconstruir o núcleo do sistema.
