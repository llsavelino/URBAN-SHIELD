# URBAN SHIELD
## 04 — Authentication & Access Control Specification

**Versão:** 1.0  
**Status:** Draft Controlado  
**Projeto:** Urban Shield  
**Documento relacionado:** `01-product-vision.md`, `02-system-specification.md` e `03-technical-design.md`  
**Stack:** Angular, NestJS, TypeScript e PostgreSQL  
**Fonte de verdade:** Autenticação, sessões e controle de acesso

---

# 1. Objetivo

Este documento define os requisitos funcionais, as regras de segurança e os contratos técnicos responsáveis pela autenticação e pelo controle de acesso do Urban Shield.

O módulo deverá garantir que usuários administrativos sejam identificados antes de acessar dados operacionais ou executar ações restritas.

O sistema deverá distinguir três situações:

- usuário não autenticado;
- usuário autenticado sem permissão para determinada operação;
- usuário autenticado e autorizado.

A autenticação confirma a identidade associada à sessão. A autorização determina quais operações essa identidade pode executar.

# 2. Escopo

## 2.1 Funcionalidades incluídas no MVP

- Login com e-mail e senha.
- Emissão e validação de access tokens JWT.
- Renovação da sessão por refresh token.
- Logout com revogação da sessão.
- Consulta dos dados do usuário autenticado.
- Cadastro administrativo de operadores.
- Gerenciamento básico de usuários.
- Proteção de endpoints privados.
- Controle de tentativas de login.
- Hash seguro de senhas.
- Revogação de sessões.
- Tratamento padronizado de erros de autenticação.

## 2.2 Funcionalidades fora do MVP

- Login com Google ou outros provedores OAuth.
- Autenticação multifator (MFA).
- Login por biometria.
- Cadastro público de operadores.
- Login social.
- Integração com provedores corporativos de identidade.
- Recuperação de senha por e-mail.
- Permissões personalizadas por usuário.
- Estrutura complexa de RBAC.

A recuperação de senha poderá ser adicionada posteriormente. Até lá, um administrador autorizado poderá realizar a redefinição por um procedimento administrativo seguro.

# 3. Perfis de Acesso

O sistema utilizará dois perfis no MVP.

## 3.1 ADMIN

Representa o administrador da aplicação.

Permissões:

- acessar o painel operacional;
- listar e consultar ocorrências;
- alterar o status das ocorrências;
- cadastrar usuários;
- consultar usuários;
- ativar e desativar contas;
- redefinir senhas de operadores;
- revogar sessões de usuários.

O administrador não poderá consultar ou exportar senhas em texto puro, hashes de senha ou refresh tokens.

## 3.2 OPERATOR

Representa o operador responsável pela análise das ocorrências.

Permissões:

- acessar o painel operacional;
- listar ocorrências;
- consultar detalhes;
- alterar o status operacional;
- encerrar ou descartar ocorrências conforme as regras de negócio.

Não poderá criar administradores, gerenciar usuários ou executar operações administrativas de autenticação.

## 3.3 Regra de autorização

Toda autorização deverá ser executada pelo backend.

Ocultar um botão no Angular não constitui controle de acesso.

O cliente não poderá escolher seu perfil, alterar suas permissões ou atribuir privilégios por meio de um payload HTTP.

# 4. Usuários e Identidade

A entidade `User` deverá possuir, no mínimo:

| Campo | Tipo conceitual | Regra |
|---|---|---|
| `id` | UUID | Identificador único |
| `name` | String | Nome de exibição |
| `email` | String | Único e normalizado |
| `passwordHash` | String | Hash da senha |
| `role` | Enum | `ADMIN` ou `OPERATOR` |
| `status` | Enum | `ACTIVE` ou `INACTIVE` |
| `createdAt` | Timestamp | Data de criação |
| `updatedAt` | Timestamp | Última atualização |

O e-mail deverá ser normalizado antes das operações de criação e login, com espaços externos removidos e letras convertidas para minúsculas.

A unicidade do e-mail deverá ser garantida pelo banco de dados, além da validação da aplicação.

Usuários inativos não poderão iniciar sessões ou renovar sessões existentes.

# 5. Sessões e Tokens

O sistema utilizará dois tipos de credencial.

## 5.1 Access Token

O access token será um JWT de curta duração, utilizado para autorizar chamadas à API.

Configuração inicial:

- validade: 15 minutos;
- algoritmo explicitamente configurado;
- validação obrigatória de assinatura, expiração, emissor e audiência;
- transporte no cabeçalho `Authorization: Bearer <token>`.

Claims recomendados:

```json
{
  "sub": "uuid-do-usuario",
  "role": "OPERATOR",
  "iss": "urban-shield",
  "aud": "urban-shield-api",
  "iat": 1792000000,
  "exp": 1792000900,
  "jti": "uuid-do-token"
}
```

O payload não deverá conter senha, hash, refresh token ou dados pessoais desnecessários.

O backend deverá obter novamente o estado atual do usuário, ou aplicar uma estratégia equivalente de revogação, quando necessário para impedir que usuários desativados continuem utilizando credenciais válidas.

## 5.2 Refresh Token

O refresh token permitirá renovar o access token sem solicitar novamente as credenciais do usuário.

Configuração inicial:

- validade máxima: 7 dias;
- armazenado no navegador em cookie `HttpOnly`;
- cookie `Secure` em produção;
- política `SameSite` restritiva compatível com a implantação;
- rotação a cada renovação;
- revogação no logout;
- armazenamento no banco somente como hash ou representação não reutilizável.

O refresh token não deverá ser disponibilizado ao código JavaScript da aplicação.

O endpoint de renovação deverá validar a sessão no servidor, verificar o estado do usuário e invalidar a credencial anterior ao emitir a próxima.

A reutilização de um refresh token já rotacionado deverá ser tratada como possível comprometimento da sessão e poderá ocasionar a revogação da família de tokens correspondente.

As operações autenticadas por cookie deverão possuir proteção contra CSRF, incluindo validação de origem e os controles adicionais definidos na implementação.

# 6. Persistência das Sessões

O backend deverá possuir uma entidade ou tabela equivalente a `AuthSession`.

Campos conceituais:

```text
id
userId
refreshTokenHash
expiresAt
revokedAt
createdAt
lastUsedAt
```

A sessão deverá estar vinculada a um usuário existente.

O banco não deverá armazenar o refresh token original.

Uma sessão será considerada inválida quando:

- estiver expirada;
- estiver revogada;
- pertencer a um usuário inativo;
- apresentar inconsistência na validação da credencial.

O logout deverá revogar a sessão no servidor e remover o cookie do navegador.

# 7. Regras de Senha

As senhas deverão ser armazenadas exclusivamente por meio de hash adaptativo seguro.

Requisitos:

- utilizar Argon2id, preferencialmente;
- utilizar salt individual gerado pela biblioteca;
- não implementar algoritmos de hash manualmente;
- nunca armazenar ou registrar senhas em texto puro;
- nunca devolver o hash em respostas HTTP;
- não registrar senhas em logs, métricas ou mensagens de erro.

A política inicial exigirá uma senha com pelo menos 12 caracteres e aceitará senhas longas, respeitando um limite máximo de entrada documentado.

Não será obrigatório impor regras artificiais como exigir simultaneamente letras maiúsculas, números e símbolos, desde que a política de senha e os controles contra tentativas automatizadas sejam adequados.

# 8. Cadastro Administrativo

Não haverá endpoint público de registro de usuários.

O primeiro administrador deverá ser criado por um comando de bootstrap ou procedimento administrativo seguro, com credenciais fornecidas por configuração protegida.

O comando de bootstrap deverá:

1. validar a configuração;
2. verificar se a conta administrativa já existe;
3. impedir duplicidade;
4. gerar o hash da senha;
5. persistir o usuário;
6. nunca imprimir a senha nos logs.

O cadastro de novos operadores exigirá um administrador autenticado.

A resposta de cadastro não deverá revelar o hash da senha.

# 9. Endpoints de Autenticação

Prefixo comum:

```text
/api/v1
```

## 9.1 Login

```http
POST /api/v1/auth/login
Content-Type: application/json
```

Request:

```json
{
  "email": "operador@urban-shield.local",
  "password": "senha-fornecida-pelo-usuario"
}
```

Sucesso: `200 OK`.

Resposta:

```json
{
  "data": {
    "accessToken": "jwt",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "user": {
      "id": "uuid",
      "name": "Operador",
      "email": "operador@urban-shield.local",
      "role": "OPERATOR"
    }
  }
}
```

O refresh token deverá ser enviado por cookie seguro, não incluído no JSON.

Credenciais incorretas deverão produzir uma resposta genérica, sem revelar se o e-mail está cadastrado ou se a senha está errada.

## 9.2 Renovação de sessão

```http
POST /api/v1/auth/refresh
```

O endpoint utilizará o refresh token do cookie.

Sucesso: `200 OK`.

Deverá emitir um novo access token e rotacionar o refresh token.

Refresh token ausente, inválido, expirado ou revogado deverá resultar em `401 Unauthorized`.

## 9.3 Logout

```http
POST /api/v1/auth/logout
```

O endpoint deverá revogar a sessão correspondente e remover o cookie de refresh.

Resposta esperada: `204 No Content`.

## 9.4 Usuário autenticado

```http
GET /api/v1/auth/me
Authorization: Bearer <access-token>
```

Retorna os dados do usuário atual, sem informações de credenciais.

Resposta:

```json
{
  "data": {
    "id": "uuid",
    "name": "Operador",
    "email": "operador@urban-shield.local",
    "role": "OPERATOR",
    "status": "ACTIVE"
  }
}
```

## 9.5 Logout de todas as sessões

```http
POST /api/v1/auth/logout-all
Authorization: Bearer <access-token>
```

Permissão: `ADMIN`, ou o próprio usuário quando a regra for explicitamente habilitada para ele.

O endpoint deverá revogar todas as sessões abrangidas pela operação e registrar um evento de auditoria sem incluir credenciais.

# 10. Gerenciamento de Usuários

Endpoints administrativos iniciais:

```http
POST   /api/v1/users
GET    /api/v1/users
GET    /api/v1/users/:id
PATCH  /api/v1/users/:id/status
PATCH  /api/v1/users/:id/password
```

Todos deverão exigir autenticação e autorização `ADMIN`.

## Criação

O administrador informa nome, e-mail e senha inicial, ou utiliza um fluxo seguro de definição inicial de senha quando implementado.

## Desativação

Ao desativar uma conta, o backend deverá:

- impedir novos logins;
- invalidar suas sessões de renovação;
- impedir operações protegidas;
- manter os registros operacionais históricos associados ao usuário.

## Redefinição de senha

A redefinição deverá gerar um novo hash e revogar todas as sessões existentes do usuário.

O procedimento deverá impedir que administradores leiam a senha definida.

# 11. Matriz de Acesso

| Operação | Público | OPERATOR | ADMIN |
|---|---:|---:|---:|
| Criar relato público | Sim | Sim | Sim |
| Login | Sim | Sim | Sim |
| Consultar o próprio perfil | Não | Sim | Sim |
| Listar ocorrências | Não | Sim | Sim |
| Consultar detalhes | Não | Sim | Sim |
| Alterar status | Não | Sim | Sim |
| Listar usuários | Não | Não | Sim |
| Criar usuário | Não | Não | Sim |
| Desativar usuário | Não | Não | Sim |
| Redefinir senha de outro usuário | Não | Não | Sim |

A listagem pública de ocorrências ficará desabilitada no MVP para evitar exposição indevida de informações operacionais.

O endpoint público de criação deverá possuir rate limiting, validação de entrada e limites de tamanho.

# 12. Comportamento de Autenticação

O fluxo de login deverá seguir:

```text
Cliente Angular
      |
      v
POST /auth/login
      |
      v
Validação do payload
      |
      v
Busca do usuário
      |
      v
Verificação do status
      |
      v
Verificação do hash da senha
      |
      v
Criação da sessão
      |
      +----> Access Token JWT
      |
      +----> Refresh Token em cookie seguro
      |
      v
Cliente autenticado
```

A falha em qualquer etapa deverá impedir a criação de uma sessão válida.

# 13. Proteção de Endpoints

O backend deverá implementar componentes equivalentes a:

- `JwtAuthGuard`: valida o access token;
- `RolesGuard`: verifica a autorização;
- estratégia JWT: valida a assinatura e as claims;
- decorators de autorização: declaram os perfis permitidos.

Endpoints privados deverão ser protegidos por padrão ou receber proteção explícita e verificável.

O backend não deverá confiar em um `role` enviado pelo cliente.

A identidade e as permissões deverão ser validadas no servidor.

# 14. Proteção Contra Tentativas Automatizadas

O login deverá possuir:

- rate limiting por origem e identificador de conta;
- mensagens genéricas para credenciais inválidas;
- registro de falhas sem registrar a senha;
- atrasos ou bloqueios progressivos quando apropriados;
- limitação de tentativas de renovação de sessão.

Os limites deverão ser configuráveis.

Não deverá existir um bloqueio permanente de conta acionado exclusivamente por requisições públicas, pois isso permitiria ataques de negação de serviço direcionados.

# 15. Segurança da Aplicação

Requisitos obrigatórios:

- HTTPS em ambientes expostos à rede;
- segredo JWT forte, aleatório e protegido;
- validação de `iss`, `aud`, `exp` e assinatura;
- algoritmo JWT explicitamente permitido;
- CORS restritivo;
- cookies configurados conforme o ambiente;
- proteção contra CSRF nas rotas que utilizam cookies;
- validação dos DTOs;
- limites de payload;
- logs sem senhas e tokens;
- respostas de erro sem detalhes internos;
- gestão segura das variáveis de ambiente.

A aplicação Angular não deverá armazenar access ou refresh tokens em `localStorage`.

O access token deverá permanecer em memória durante a sessão da aplicação. Ao recarregar a página, o cliente poderá solicitar um novo token por meio do endpoint de renovação.

# 16. Auditoria

Eventos relevantes deverão ser registrados:

```text
AUTH_LOGIN_SUCCESS
AUTH_LOGIN_FAILURE
AUTH_LOGOUT
AUTH_SESSION_REVOKED
USER_CREATED
USER_DISABLED
USER_PASSWORD_RESET
```

Cada evento deverá incluir, quando disponível:

```text
timestamp
requestId
actorUserId
targetUserId
eventType
result
```

Não registrar:

- senha;
- hash da senha;
- JWT completo;
- refresh token;
- cabeçalhos de autenticação;
- segredos de configuração.

# 17. Erros HTTP

| Situação | Status |
|---|---:|
| Payload inválido | 400 |
| Credenciais inválidas | 401 |
| Token ausente ou inválido | 401 |
| Usuário sem autorização | 403 |
| Recurso inexistente | 404 |
| E-mail já cadastrado | 409 |
| Limite de tentativas excedido | 429 |
| Serviço de autenticação indisponível | 503 |

Contrato de erro:

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Não foi possível autenticar com as credenciais fornecidas."
  }
}
```

O contrato não deverá revelar se determinado e-mail existe.

# 18. Configuração

Variáveis de ambiente esperadas:

```text
JWT_ACCESS_SECRET
JWT_ACCESS_TTL
JWT_ISSUER
JWT_AUDIENCE

AUTH_REFRESH_TTL
AUTH_COOKIE_NAME
AUTH_COOKIE_SECURE
AUTH_COOKIE_SAME_SITE

AUTH_ALLOWED_ORIGINS
AUTH_RATE_LIMIT_MAX
AUTH_RATE_LIMIT_WINDOW_MS
```

As variáveis adicionais de banco de dados e servidor serão definidas no documento técnico geral.

Os valores de produção deverão ser fornecidos por um gerenciador de segredos ou ambiente protegido, nunca versionados no repositório.

# 19. Testes Obrigatórios

## Login

- login válido;
- senha incorreta;
- e-mail inexistente;
- usuário inativo;
- payload inválido;
- tentativas excedidas.

## JWT

- token válido;
- token expirado;
- assinatura inválida;
- emissor incorreto;
- audiência incorreta;
- token ausente.

## Refresh e logout

- renovação válida;
- refresh token expirado;
- refresh token revogado;
- reutilização de token rotacionado;
- logout;
- logout após expiração;
- usuário desativado com sessão ativa.

## Autorização

- operador tentando criar usuário;
- operador tentando desativar usuário;
- administrador acessando operações administrativas;
- usuário não autenticado acessando endpoint privado;
- tentativa de alterar o perfil no payload.

# 20. Critérios de Aceite

O módulo estará aceito quando:

1. Usuários válidos conseguirem realizar login.
2. Credenciais inválidas forem rejeitadas.
3. Os tokens expirarem conforme configuração.
4. O refresh token for rotacionado e armazenado de forma segura.
5. O logout revogar a sessão no servidor.
6. Usuários inativos não conseguirem iniciar ou renovar sessões.
7. Os endpoints privados exigirem autenticação.
8. A autorização for verificada no backend.
9. Apenas administradores puderem gerenciar usuários.
10. Senhas e tokens nunca forem expostos nas respostas ou logs.
11. A aplicação aplicar limites de tentativas.
12. Os testes automatizados de autenticação e autorização passarem.

# 21. Estrutura Técnica Prevista

```text
src/
├── modules/
│   ├── auth/
│   │   ├── domain/
│   │   ├── application/
│   │   │   ├── use-cases/
│   │   │   └── services/
│   │   ├── infrastructure/
│   │   │   ├── jwt/
│   │   │   └── sessions/
│   │   └── presentation/
│   │       ├── controllers/
│   │       ├── dto/
│   │       ├── guards/
│   │       └── strategies/
│   │
│   └── users/
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       └── presentation/
│
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── logging/
│
└── config/
```

A estrutura representa a separação de responsabilidades e poderá ser adaptada à implementação concreta, sem alterar os contratos definidos neste documento.

# 22. Alinhamento com a Documentação Geral

Este módulo deverá respeitar os princípios do Urban Shield:

- frontend Angular;
- backend NestJS com TypeScript;
- PostgreSQL;
- API REST versionada;
- monólito modular;
- validação de entrada;
- erros padronizados;
- regras de negócio no backend;
- ausência de cadastro público de operadores.

O módulo de autenticação não será responsável pela classificação de ocorrências, integração com Ollama ou geocodificação. Ele fornecerá identidade e controle de acesso aos demais módulos.

# 23. Decisões Congeladas para o MVP

```text
Autenticação       = JWT
Access Token      = 15 minutos
Refresh Token     = máximo de 7 dias
Senha             = Argon2id
Perfis            = ADMIN / OPERATOR
Persistência      = PostgreSQL
Cadastro público  = Desabilitado
Login social      = Fora do MVP
MFA               = Fora do MVP
Recuperação email = Fora do MVP
```

Os períodos de validade são valores iniciais de configuração, não constantes imutáveis.

# 24. Definition of Done

A autenticação será considerada pronta quando:

```text
Login funcionando
+
JWT validado
+
Refresh seguro
+
Logout com revogação
+
Permissões verificadas
+
Senhas protegidas
+
Tratamento de erros
+
Auditoria
+
Testes automatizados
```

O módulo deverá ser integrado ao backend antes de liberar o dashboard operacional para uso real.
