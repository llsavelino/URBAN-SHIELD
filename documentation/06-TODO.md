# URBAN SHIELD

## 06 — Backend Reliability, Security & Privacy Standard

**Versão:** 1.0
**Status:** Draft Técnico — Base para Implementação
**Projeto:** Urban Shield
**Escopo:** Backend e infraestrutura de suporte
**Stack:** Node.js, TypeScript, NestJS, PostgreSQL, Ollama e Google Maps Platform
**Documento relacionado:** `01-product-vision.md`, `02-system-specification.md`, `03-technical-design.md` e `04-authentication-access-control.md`

---

# 1. Objetivo

Este documento estabelece os requisitos técnicos e operacionais necessários para tornar o backend do Urban Shield mais confiável, seguro e responsável no tratamento de informações.

O escopo está dividido em três pilares:

1. **Disponibilidade:** manter o serviço observável, recuperar falhas e preservar os dados.
2. **Segurança:** impedir acessos indevidos, reduzir a superfície de ataque e proteger credenciais e infraestrutura.
3. **Privacidade:** limitar a coleta, o acesso, a utilização e a retenção de dados pessoais.

O cumprimento deste documento será parte dos critérios para autorizar um piloto operacional do Urban Shield.

A existência das implementações descritas não representa, por si só, uma certificação de segurança, disponibilidade ou conformidade legal.

# 2. Princípios Gerais

O backend deverá seguir os seguintes princípios:

- **Fail safely:** falhas não devem provocar exposição de dados ou decisões operacionais inseguras.
- **Least privilege:** cada usuário, processo e serviço terá somente as permissões necessárias.
- **Defense in depth:** a segurança não dependerá de um único mecanismo.
- **Observability by design:** falhas e degradações deverão ser identificáveis por sinais técnicos.
- **Data minimization:** serão coletados somente os dados necessários para a finalidade definida.
- **Secure defaults:** configurações inseguras não deverão ser utilizadas por padrão em produção.
- **Recovery tested:** backups somente serão considerados confiáveis após testes de restauração.
- **Human oversight:** o funcionamento técnico do sistema não transforma resultados da IA em decisões oficiais.

---

# PARTE I — DISPONIBILIDADE E RECUPERAÇÃO

# 3. Objetivo de Disponibilidade

O backend deverá possuir mecanismos para detectar falhas, informar sua condição operacional, limitar efeitos em cascata e permitir a recuperação controlada dos serviços.

O MVP deverá suportar, pelo menos:

- falha temporária da API;
- indisponibilidade do PostgreSQL;
- indisponibilidade do Ollama;
- falha de geocodificação;
- saturação por excesso de requisições;
- reinicialização do processo;
- restauração de dados a partir de backup.

## 3.1 SLO inicial

Para um piloto controlado, fica definida a seguinte meta inicial de disponibilidade:

**99,5% de disponibilidade mensal da API**, medida por verificações externas do endpoint de saúde e excluindo manutenções programadas previamente declaradas.

Essa meta é um objetivo de engenharia, não uma garantia de disponibilidade.

A medição deverá distinguir a disponibilidade HTTP da disponibilidade do fluxo completo, porque o processamento da IA e a geocodificação dependem de serviços adicionais.

A meta só deverá ser considerada validada após medição em um ambiente de implantação representativo.

## 3.2 Indicadores principais

O sistema deverá acompanhar:

| Indicador              | Finalidade                         |
| ---------------------- | ---------------------------------- |
| API Availability       | Medir disponibilidade HTTP         |
| HTTP 5xx Rate          | Identificar falhas internas        |
| Request Latency        | Medir tempo de resposta            |
| Database Availability  | Identificar falhas de persistência |
| AI Failure Rate        | Medir falhas do Ollama             |
| Geocoding Failure Rate | Identificar falhas geográficas     |
| Backup Success         | Verificar execução dos backups     |
| Recovery Test Result   | Verificar restauração efetiva      |

---

# 4. Health Checks

O backend deverá disponibilizar endpoints distintos para verificar a saúde do processo e sua capacidade de atender requisições.

## 4.1 Liveness

```http
GET /health/live
```

Indica se o processo está ativo e funcionando.

Critério de sucesso:

```text
Processo ativo → 200 OK
```

A verificação não deverá depender de chamadas à IA ou ao Google Geocoding.

Uma falha de dependência externa não deverá provocar reinicializações em cascata do backend.

## 4.2 Readiness

```http
GET /health/ready
```

Indica se a aplicação está pronta para atender requisições que dependem dos serviços obrigatórios.

Deverá considerar, pelo menos, a conexão com o banco de dados.

O Ollama e a geocodificação poderão ser reportados como dependências degradadas separadamente, pois suas falhas não devem necessariamente impedir consultas ou todas as operações da API.

Exemplo conceitual:

```json
{
  "status": "degraded",
  "dependencies": {
    "database": "up",
    "ollama": "down",
    "geocoding": "up"
  }
}
```

A resposta de produção não poderá expor endereços internos, credenciais, stack traces ou configurações sensíveis. Detalhes técnicos deverão ficar restritos aos logs e ao monitoramento interno.

## 4.3 Verificações periódicas

A infraestrutura de monitoramento deverá consultar os endpoints periodicamente e alertar quando houver falha persistente.

As verificações não deverão executar inferências completas na LLM ou chamadas geográficas pagas a cada ciclo.

---

# 5. Monitoramento, Métricas e Logs

## 5.1 Logs estruturados

Os logs deverão ser estruturados em JSON e incluir, conforme aplicável:

```text
timestamp
level
requestId
service
environment
route
method
statusCode
durationMs
errorCode
```

Quando houver um usuário autenticado, o sistema poderá registrar um identificador interno para auditoria, desde que necessário e adequadamente protegido.

Os logs não deverão conter:

- senhas;
- access tokens;
- refresh tokens;
- cabeçalhos de autorização;
- API keys;
- hashes de senha;
- descrição completa de relatos por padrão;
- informações pessoais desnecessárias.

O conteúdo dos relatos deverá permanecer fora dos logs técnicos. Quando for necessário investigar um incidente, o acesso ao registro original deverá ocorrer por meio do sistema autorizado, com rastreabilidade.

## 5.2 Métricas HTTP

Implementar métricas equivalentes a:

```text
http_requests_total
http_request_duration_seconds
http_errors_total
http_active_requests
```

As métricas deverão permitir analisar volume, latência e taxa de falhas por rota, sem criar identificadores de alta cardinalidade a partir de IDs individuais de ocorrências.

## 5.3 Métricas de dependências

Implementar:

```text
database_connection_failures_total
ai_request_duration_seconds
ai_failures_total
geocoding_request_duration_seconds
geocoding_failures_total
```

A coleta de métricas deverá usar tempos, contagens e códigos de falha, evitando incluir o texto dos relatos.

## 5.4 Correlação

Cada requisição deverá possuir um `requestId`.

Esse identificador deverá ser propagado entre controller, caso de uso e integrações internas para permitir a investigação de falhas.

O sistema deverá gerar ou validar o identificador no backend, sem confiar cegamente em valores arbitrários recebidos do cliente.

## 5.5 Monitoramento de infraestrutura

O ambiente deverá monitorar, pelo menos:

- uso de CPU;
- uso de memória;
- disponibilidade do processo;
- conexões com PostgreSQL;
- espaço disponível em disco;
- duração das consultas;
- falhas de backup;
- reinicializações inesperadas.

Como o Ollama pode consumir recursos significativos, o uso de memória e CPU da LLM deverá ser observado separadamente quando possível.

---

# 6. Alertas Operacionais

Os alertas deverão informar condições que exigem investigação ou intervenção.

## 6.1 Condições de alerta

O sistema deverá gerar alertas para:

- API indisponível em verificações consecutivas;
- aumento anormal de respostas HTTP 5xx;
- banco de dados indisponível;
- ausência de backup esperado;
- falha de restauração em testes;
- consumo de disco próximo do limite;
- falhas consecutivas de autenticação acima do padrão esperado;
- indisponibilidade prolongada do Ollama;
- aumento anormal de falhas de geocodificação;
- suspeita de acesso não autorizado ou vazamento de dados.

Os limiares deverão ser configuráveis e ajustados após a observação do ambiente real.

## 6.2 Severidade dos alertas

```text
P1 — Crítico
Indisponibilidade ampla ou incidente de segurança relevante.

P2 — Alto
Degradação relevante ou falha de dependência que afeta
uma funcionalidade importante.

P3 — Moderado
Erro localizado ou degradação sem interrupção ampla.

P4 — Informativo
Evento operacional que não exige resposta imediata.
```

## 6.3 Canais

Os alertas deverão chegar aos responsáveis técnicos por um canal definido pela equipe do projeto.

Os alertas não deverão conter relatos completos, senhas, tokens ou dados pessoais desnecessários.

A integração com um canal externo de notificações poderá ser adicionada após a definição do ambiente de implantação.

---

# 7. Recuperação de Falhas

## 7.1 PostgreSQL indisponível

Comportamento esperado:

1. identificar a falha de conexão;
2. registrar o erro técnico;
3. retornar erro controlado ao cliente;
4. não confirmar uma gravação que não foi concluída;
5. recuperar a conexão quando o banco voltar;
6. verificar se não existem gravações parciais ou inconsistentes.

Se o cliente não souber se uma criação foi concluída, não deverá repetir indiscriminadamente a operação sem uma estratégia contra duplicidade.

## 7.2 Ollama indisponível

O backend deverá:

1. aplicar timeout à chamada;
2. registrar a falha sem incluir dados sensíveis;
3. evitar chamadas repetidas e ilimitadas;
4. preservar as ocorrências já armazenadas;
5. permitir que operações independentes da IA continuem funcionando.

Para submissões de novos relatos, o fluxo deverá priorizar a persistência inicial do registro e o seu protocolo. A análise poderá permanecer pendente para processamento ou revisão posterior.

A indisponibilidade da IA não deverá tornar os registros já recebidos inacessíveis.

## 7.3 Geocoding indisponível

O sistema deverá preservar o relato e marcar a localização como pendente ou não resolvida, conforme o estado adotado pelo modelo de dados.

A falha de geocodificação não deverá criar coordenadas artificiais.

O registro deverá continuar disponível por consulta em lista, mesmo que não possa ser plotado no mapa.

## 7.4 Reinicialização da API

A aplicação deverá implementar encerramento gracioso:

- parar de aceitar novas requisições conforme a estratégia do servidor;
- aguardar operações em andamento até o limite configurado;
- fechar conexões e recursos;
- encerrar sem corromper o estado persistido.

O backend deverá ser capaz de iniciar novamente a partir da configuração válida e do estado persistido no banco.

---

# 8. Backup e Recuperação de Dados

## 8.1 Política inicial para o piloto

A proposta inicial é:

- backup diário do PostgreSQL;
- retenção de 30 dias para cópias de backup;
- armazenamento protegido e separado do processo principal;
- criptografia dos backups;
- registro do resultado de cada execução;
- teste mensal de restauração em ambiente isolado.

Esses valores deverão ser ajustados conforme o volume, o custo e as necessidades operacionais.

## 8.2 RPO e RTO

Para o piloto, ficam estabelecidos objetivos iniciais:

```text
RPO máximo pretendido: 24 horas
RTO máximo pretendido: 4 horas
```

**RPO** representa a quantidade máxima de dados que a organização aceita perder, medida em tempo.

**RTO** representa o tempo máximo desejado para recuperar o serviço.

Esses valores só serão considerados alcançáveis após testes de backup, restauração e recuperação do ambiente. Se a operação exigir menor perda de dados, deverá ser adotada uma estratégia de backup mais frequente ou recuperação contínua apropriada.

## 8.3 Teste de restauração

O procedimento deverá verificar:

1. integridade da cópia;
2. restauração em banco isolado;
3. execução das migrações necessárias;
4. integridade das ocorrências;
5. funcionamento de consultas;
6. consistência dos estados;
7. possibilidade de iniciar a API;
8. registro dos resultados do teste.

Um backup sem teste de restauração não será considerado evidência suficiente de capacidade de recuperação.

## 8.4 Runbook de recuperação

A equipe deverá documentar:

- responsável pela recuperação;
- localização das cópias;
- procedimento de restauração;
- configuração de acesso;
- validações posteriores;
- procedimento de retorno ao ambiente principal;
- critérios para declarar o serviço recuperado.

---

# PARTE II — SEGURANÇA

# 9. Modelo de Segurança

O backend deverá considerar os seguintes ativos:

```text
Credenciais de usuários
Tokens de sessão
Dados dos relatos
Localizações geográficas
Banco de dados
Chaves externas
Configurações
Logs
Backups
```

A proteção deverá abranger confidencialidade, integridade, disponibilidade e rastreabilidade.

---

# 10. HTTPS e Transporte Seguro

## 10.1 Produção

Todo acesso público deverá utilizar HTTPS.

O tráfego HTTP deverá ser redirecionado para HTTPS na camada de entrada ou rejeitado, conforme a arquitetura adotada.

A configuração TLS deverá seguir as recomendações vigentes do ambiente de implantação.

## 10.2 Proxy reverso

Se houver um proxy reverso ou balanceador:

- a terminação TLS deverá ser configurada corretamente;
- o tráfego interno deverá ser protegido de acordo com o modelo de ameaça;
- cabeçalhos encaminhados deverão ser confiáveis somente quando enviados por proxies conhecidos;
- a configuração de IP original deverá impedir falsificação por clientes externos.

O backend não deverá confiar indiscriminadamente em `X-Forwarded-For` ou cabeçalhos semelhantes.

## 10.3 Desenvolvimento local

A comunicação local poderá utilizar HTTP quando os serviços estiverem limitados à máquina ou à rede isolada de desenvolvimento.

Essa exceção não deverá ser transportada automaticamente para a produção.

---

# 11. Gestão de Segredos

Credenciais e chaves de integração deverão ser mantidas fora do código-fonte.

Variáveis possíveis:

```text
DATABASE_URL
JWT_ACCESS_SECRET
OLLAMA_BASE_URL
OLLAMA_MODEL
GOOGLE_MAPS_API_KEY
```

As configurações efetivamente usadas pelo projeto deverão ser documentadas no arquivo de exemplo de ambiente, sem valores reais.

## 11.1 Regras obrigatórias

- nunca versionar arquivos `.env` com segredos;
- manter `.env.example` sem credenciais reais;
- não imprimir configurações sensíveis no startup;
- usar credenciais distintas por ambiente;
- restringir o acesso às configurações;
- rotacionar segredos quando houver suspeita de exposição;
- evitar reutilizar credenciais de desenvolvimento em produção.

O segredo JWT deverá possuir entropia suficiente e ser diferente da chave da API do Google.

## 11.2 Google Maps Platform

As chaves deverão possuir restrições compatíveis com o serviço utilizado.

Uma chave destinada ao frontend não deverá ser reutilizada indiscriminadamente no backend.

As credenciais do backend deverão ser protegidas por controles disponíveis na plataforma, restrições de API e limites de utilização sempre que suportados.

---

# 12. Rate Limiting

Os endpoints deverão possuir limites de requisição conforme risco e custo.

## 12.1 Valores iniciais propostos

| Endpoint                      | Limite inicial proposto               |
| ----------------------------- | ------------------------------------- |
| Login                         | 5 tentativas por minuto por IP        |
| Criação pública de ocorrência | 10 requisições por minuto por IP      |
| Consulta de dados privados    | 60 requisições por minuto por usuário |
| Renovação de sessão           | Limite específico por sessão e origem |
| Endpoints administrativos     | Limite por usuário autenticado        |

Esses valores são parâmetros de partida. Deverão ser avaliados por meio de testes e ajustados para não bloquear indevidamente usuários legítimos.

## 12.2 Requisitos

- resposta `429 Too Many Requests` quando o limite for excedido;
- cabeçalhos de rate limiting quando aplicáveis;
- limites independentes por tipo de operação;
- proteção contra tentativas repetitivas de login;
- controle confiável da origem quando houver proxy;
- configuração de limites por ambiente.

Em múltiplas instâncias, os limites deverão utilizar armazenamento compartilhado ou outro mecanismo consistente. Um contador apenas em memória pode não ser suficiente nesse cenário.

No MVP executado em instância única, uma implementação local pode ser aceita temporariamente, desde que essa limitação esteja documentada.

---

# 13. Autenticação e Autorização

O backend deverá aplicar os controles definidos no documento `04-authentication-access-control.md`.

Requisitos:

- JWT validado no servidor;
- expiração verificada;
- autorização independente da interface;
- controle de acesso por perfil;
- revogação de sessões;
- proteção contra reutilização de refresh tokens;
- desativação efetiva de usuários;
- auditoria de operações administrativas.

Endpoints privados deverão exigir autenticação por padrão.

Endpoints públicos deverão ser declarados explicitamente como públicos.

O perfil enviado pelo cliente nunca deverá ser utilizado como fonte confiável de autorização.

---

# 14. Controle de Acesso ao Banco

## 14.1 Princípio do menor privilégio

A conta utilizada pela aplicação deverá possuir somente as permissões necessárias às operações normais.

A conta usada para migrações e manutenção deverá ser separada da conta utilizada em tempo de execução quando viável.

A aplicação não deverá operar normalmente com privilégios de superusuário do PostgreSQL.

## 14.2 Consultas

O backend deverá:

- utilizar consultas parametrizadas;
- validar os parâmetros;
- limitar resultados;
- proteger operações de escrita;
- evitar construir consultas SQL diretamente a partir de entrada não confiável.

## 14.3 Integridade

As regras essenciais deverão ser protegidas pela aplicação e, quando apropriado, por constraints do banco de dados.

Os registros operacionais não deverão ser alterados por caminhos que ignorem a validação de domínio.

---

# 15. Validação de Entrada

Todos os endpoints deverão validar:

- formato;
- tipo;
- tamanho;
- campos permitidos;
- enums;
- identificadores;
- paginação;
- transições de estado;
- permissões.

O backend deverá rejeitar campos não permitidos quando o contrato exigir um DTO estrito.

As entradas não deverão ser consideradas confiáveis por terem sido enviadas pelo Angular.

## 15.1 Relatos

As descrições deverão possuir um tamanho máximo configurado e razoável.

O sistema não deverá interpretar o conteúdo de um relato como instrução confiável para alterar regras de negócio, executar comandos ou acessar recursos protegidos.

O conteúdo encaminhado à IA deverá ser tratado como dado não confiável.

---

# 16. Dependências e Atualizações

O repositório deverá possuir:

- lockfile versionado;
- versões de dependências controladas;
- revisão periódica de vulnerabilidades;
- atualização de dependências vulneráveis;
- verificações automáticas no CI;
- processo de revisão antes de atualizações de alto impacto.

O pipeline deverá incluir, pelo menos:

```text
Install
   ↓
Lint
   ↓
Typecheck
   ↓
Tests
   ↓
Build
   ↓
Dependency Audit
```

O resultado da auditoria deverá ser avaliado. Não se deverá ignorar uma vulnerabilidade apenas para manter o pipeline verde.

---

# 17. Tratamento de Erros

Erros internos deverão ser registrados com contexto técnico seguro e convertidos em respostas controladas.

Exemplo:

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Internal server error."
  }
}
```

Nunca retornar ao cliente:

- stack traces;
- queries SQL;
- caminhos internos;
- credenciais;
- tokens;
- configurações sensíveis;
- detalhes que facilitem exploração.

Mensagens de erro deverão ajudar o cliente a identificar o problema sem expor detalhes desnecessários da infraestrutura.

---

# 18. Auditoria de Segurança

O sistema deverá registrar operações relevantes:

```text
LOGIN_SUCCESS
LOGIN_FAILURE
LOGOUT
SESSION_REVOKED
USER_CREATED
USER_DISABLED
USER_ROLE_CHANGED
INCIDENT_STATUS_CHANGED
ACCESS_DENIED
CONFIGURATION_CHANGE
```

Os eventos deverão registrar, quando aplicável:

```text
timestamp
requestId
actorUserId
targetResourceId
action
result
```

O registro de auditoria deverá ser protegido contra acesso indevido e alterações não autorizadas.

Não se deverá registrar conteúdo sensível somente por conveniência de depuração.

---

# PARTE III — PRIVACIDADE E PROTEÇÃO DE DADOS

# 19. Objetivo de Privacidade

O Urban Shield deverá tratar dados pessoais com finalidade definida, acesso controlado, retenção limitada e proteção compatível com os riscos envolvidos.

O desenvolvimento deverá considerar a Lei Geral de Proteção de Dados Pessoais (LGPD), especialmente seus princípios e requisitos de segurança, prevenção e tratamento de incidentes.

Referências oficiais:

- Lei nº 13.709/2018 — LGPD: [https://www.planalto.gov.br/ccivil_03/\_ato2015-2018/2018/lei/l13709.htm](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- Guia de Segurança da Informação da ANPD: [https://www.gov.br/anpd/pt-br/centrais-de-conteudo/materiais-educativos-e-publicacoes/guia-orientativo-sobre-seguranca-da-informacao-para-agentes-de-tratamento-de-pequeno-porte](https://www.gov.br/anpd/pt-br/centrais-de-conteudo/materiais-educativos-e-publicacoes/guia-orientativo-sobre-seguranca-da-informacao-para-agentes-de-tratamento-de-pequeno-porte)
- Guia da ANPD sobre tratamento de dados pessoais pelo Poder Público: [https://www.gov.br/anpd/pt-br/centrais-de-conteudo/materiais-educativos-e-publicacoes/guia_orientativo_tratamento_de_dados_pessoais_pelo_poder_publico](https://www.gov.br/anpd/pt-br/centrais-de-conteudo/materiais-educativos-e-publicacoes/guia_orientativo_tratamento_de_dados_pessoais_pelo_poder_publico)

O uso institucional deverá definir formalmente quem é o controlador, quem atua como operador e quais são as responsabilidades de cada parte.

---

# 20. Mapeamento dos Dados

Antes da implantação, a equipe deverá manter um inventário dos dados tratados.

| Dado                             | Finalidade                 | Acesso                           |
| -------------------------------- | -------------------------- | -------------------------------- |
| Descrição do relato              | Registrar a ocorrência     | Operadores autorizados           |
| Endereço                         | Localizar a ocorrência     | Conforme necessidade operacional |
| Coordenadas                      | Posicionar no mapa         | Conforme necessidade operacional |
| Categoria e severidade           | Triagem                    | Operadores autorizados           |
| Recomendação da IA               | Apoio à análise            | Operadores autorizados           |
| E-mail do usuário administrativo | Autenticação               | Módulo de autenticação           |
| Hash de senha                    | Verificação de credenciais | Backend autorizado               |
| Metadados de sessão              | Controle e revogação       | Módulo de autenticação           |
| Logs técnicos                    | Diagnóstico                | Equipe técnica autorizada        |
| Logs de auditoria                | Rastreabilidade            | Responsáveis autorizados         |

A descrição de uma ocorrência poderá conter dados pessoais mesmo que o formulário não solicite nome, telefone ou e-mail.

O sistema deverá considerar essa possibilidade no desenho de acesso, logging e retenção.

---

# 21. Minimização de Dados

O formulário público deverá solicitar somente os dados necessários para receber e localizar a ocorrência.

Não deverá exigir por padrão:

```text
CPF
documento de identidade
data de nascimento
telefone
email
nome completo
```

Caso seja necessária a identificação do cidadão para uma funcionalidade futura, a necessidade deverá ser justificada e a coleta documentada antes da implementação.

Os dados pessoais encontrados acidentalmente no relato não deverão ser replicados automaticamente em logs, notificações ou respostas públicas.

---

# 22. Finalidade do Tratamento

As finalidades inicialmente previstas são:

1. receber e registrar relatos urbanos;
2. organizar e classificar ocorrências;
3. determinar a localização quando possível;
4. disponibilizar informações a operadores autorizados;
5. apoiar a triagem operacional;
6. investigar falhas, abuso e incidentes de segurança;
7. manter evidências operacionais necessárias durante o período autorizado.

Cada finalidade deverá corresponder a uma necessidade concreta.

A base legal aplicável não deverá ser presumida pelo desenvolvedor. Antes de um piloto institucional, o responsável pelo tratamento deverá documentar a base legal, a finalidade, os destinatários e os prazos de conservação pertinentes.

---

# 23. Política de Privacidade

O serviço deverá disponibilizar um aviso de privacidade acessível ao cidadão.

No mínimo, esse aviso deverá explicar:

- quem é responsável pelo tratamento;
- quais dados são coletados;
- para quais finalidades são utilizados;
- como a IA participa do processamento;
- quais dados são encaminhados a provedores externos;
- como funciona a geocodificação;
- quem pode consultar as informações;
- por quanto tempo os dados são conservados;
- como o titular pode exercer seus direitos;
- como entrar em contato com o responsável pela privacidade.

A política publicada deverá refletir o comportamento real da aplicação.

Não deverá afirmar, por exemplo, que nenhum dado sai do ambiente local se o endereço for encaminhado ao Google Geocoding.

---

# 24. Fluxo de Dados e Terceiros

O fluxo previsto é:

```text
Cidadão
   |
   v
NestJS API
   |
   +----> PostgreSQL
   |
   +----> Ollama local
   |         |
   |         +---- análise do relato
   |
   +----> Google Geocoding
             |
             +---- endereço necessário à geocodificação
```

## 24.1 Ollama

O serviço deverá enviar à LLM somente o conteúdo necessário para a análise.

A execução local reduz o compartilhamento externo de dados do relato, mas não elimina os riscos de acesso indevido no próprio computador, nos logs, nos arquivos ou no processo que executa o modelo.

O comportamento de logging e armazenamento do ambiente Ollama deverá ser avaliado e configurado antes da produção.

## 24.2 Google Geocoding

O backend deverá encaminhar o endereço necessário à resolução geográfica, evitando transmitir a descrição completa do relato quando ela não for necessária.

A utilização deverá respeitar as condições aplicáveis ao provedor e ser refletida no aviso de privacidade.

## 24.3 Compartilhamento institucional

Caso haja parceria com prefeitura, Defesa Civil ou outro órgão, deverão ser definidos:

- finalidade do compartilhamento;
- dados disponibilizados;
- destinatários autorizados;
- responsabilidades das partes;
- mecanismos de acesso;
- prazo de conservação;
- regras de divulgação pública.

O simples fato de uma ocorrência estar em um mapa não autoriza automaticamente sua publicação irrestrita.

---

# 25. Controle de Acesso aos Relatos

As ocorrências deverão possuir regras de visibilidade claras.

## Acesso público

No MVP, o público poderá enviar relatos por meio do endpoint definido para essa finalidade.

A consulta irrestrita ao conjunto completo de ocorrências deverá permanecer desabilitada.

## Acesso operacional

Operadores autenticados poderão consultar os dados necessários à triagem, de acordo com suas permissões.

## Acesso administrativo

Administradores poderão executar operações administrativas autorizadas, sem receber acesso irrestrito a credenciais ou dados técnicos secretos.

## Acesso técnico

O acesso direto ao banco e aos ambientes de produção deverá ser restrito às pessoas responsáveis por manutenção e recuperação.

A equipe técnica não deverá consultar relatos identificáveis sem necessidade operacional justificada.

---

# 26. Publicação de Dados

Caso seja criado um mapa público, deverão ser avaliados:

- necessidade de mostrar o endereço exato;
- risco de identificar moradores;
- exposição de residências ou pessoas vulneráveis;
- divulgação de descrições sensíveis;
- risco de abuso ou assédio;
- possibilidade de agregação ou anonimização.

A visualização pública deverá priorizar dados necessários à utilidade pública, como categoria, região aproximada, data e status permitido.

Os dados operacionais detalhados deverão permanecer protegidos.

A anonimização deverá ser avaliada de forma efetiva. Remover apenas o nome não garante anonimização quando a localização e a descrição permitem identificar uma pessoa.

---

# 27. Política de Retenção

A retenção deverá ser definida por categoria de dados.

Os prazos abaixo são uma proposta inicial para avaliação durante o piloto, não prazos legais universais.

| Categoria                       | Proposta inicial                                      |
| ------------------------------- | ----------------------------------------------------- |
| Ocorrências encerradas          | Revisão para eliminação ou anonimização após 24 meses |
| Logs técnicos                   | 30 dias                                               |
| Logs de auditoria               | 180 dias                                              |
| Backups                         | 30 dias                                               |
| Sessões ativas                  | Conforme validade e revogação                         |
| Metadados de sessões encerradas | Período necessário à segurança e auditoria            |

Antes da ativação de exclusões automáticas, deverão ser aprovados os prazos aplicáveis pelo responsável pelo tratamento.

Registros sujeitos a obrigações legais, arquivísticas ou administrativas não deverão ser eliminados simplesmente porque expirou um prazo genérico de aplicação.

A eliminação deverá abranger os dados ativos e considerar o ciclo de expiração dos backups. Quando a remoção imediata de uma cópia de backup não for tecnicamente viável, o processo deverá estar documentado e impedir que os dados sejam reintroduzidos indevidamente durante a restauração.

---

# 28. Direitos dos Titulares

O sistema e seus responsáveis deverão possuir um procedimento para receber e encaminhar solicitações relativas aos direitos previstos na LGPD, conforme aplicáveis ao tratamento.

O procedimento deverá permitir:

- receber a solicitação;
- verificar a identidade quando necessário;
- localizar os dados relacionados;
- verificar a base legal e eventuais obrigações de conservação;
- executar a medida cabível;
- registrar o resultado;
- responder pelo canal definido.

A API interna não deverá expor uma rota pública que permita consultar ou excluir dados arbitrários sem verificação adequada.

---

# 29. Incidentes de Segurança e Privacidade

A equipe deverá manter um procedimento formal para incidentes que possam afetar disponibilidade, integridade ou confidencialidade.

Exemplos:

- exposição de credenciais;
- acesso não autorizado a relatos;
- vazamento de dados pessoais;
- alteração indevida de ocorrências;
- perda de dados;
- backups expostos;
- comprometimento do servidor.

## 29.1 Etapas de resposta

```text
Detectar
   |
   v
Registrar o incidente
   |
   v
Conter o impacto
   |
   v
Investigar e preservar evidências
   |
   v
Avaliar o risco aos titulares
   |
   v
Acionar responsáveis legais e institucionais
   |
   v
Realizar notificações exigíveis
   |
   v
Recuperar o serviço
   |
   v
Documentar ações corretivas
```

## 29.2 Comunicação

O procedimento deverá identificar quem é responsável por avaliar e realizar comunicações à ANPD e aos titulares.

Segundo o regulamento de comunicação de incidentes da ANPD, incidentes que possam ocasionar risco ou dano relevante devem ser comunicados pelo controlador à ANPD e aos titulares afetados no prazo aplicável, em regra três dias úteis, ressalvadas as condições previstas no regulamento e em legislação específica.

Referência oficial: [https://www.gov.br/anpd/pt-br/canais_atendimento/agente-de-tratamento/comunicado-de-incidente-de-seguranca-cis](https://www.gov.br/anpd/pt-br/canais_atendimento/agente-de-tratamento/comunicado-de-incidente-de-seguranca-cis)

A equipe técnica deverá comunicar rapidamente o responsável pelo tratamento. A avaliação jurídica e a comunicação regulatória não deverão ficar sob responsabilidade exclusiva do desenvolvedor.

---

# PARTE IV — IMPLEMENTAÇÃO E VALIDAÇÃO

# 30. Organização Técnica

Os controles deverão ser integrados à arquitetura existente sem misturar responsabilidades de domínio com infraestrutura.

Áreas previstas:

```text
src/
├── common/
│   ├── filters/
│   ├── interceptors/
│   ├── logging/
│   ├── security/
│   └── monitoring/
│
├── config/
│   ├── environment/
│   ├── validation/
│   └── secrets/
│
└── modules/
    ├── auth/
    ├── users/
    └── incidents/
```

A estrutura real poderá utilizar nomes diferentes, desde que os controles e suas responsabilidades permaneçam identificáveis.

---

# 31. Configuração por Ambiente

O projeto deverá distinguir:

```text
development
test
production
```

As políticas deverão ser adequadas a cada ambiente.

Produção deverá exigir:

- validação estrita das variáveis obrigatórias;
- segredos diferentes dos ambientes locais;
- HTTPS;
- controle de CORS;
- logging seguro;
- limite de requisições;
- backup;
- alertas;
- procedimento de recuperação.

A aplicação deverá falhar na inicialização se faltar uma configuração crítica, como segredo de autenticação ou conexão obrigatória com o banco.

Não deverá substituir um segredo ausente por um valor fraco padrão.

---

# 32. Estratégia de Testes

## Testes de disponibilidade

- API indisponível;
- banco indisponível;
- Ollama indisponível;
- timeout de geocodificação;
- reinicialização;
- interrupção durante uma operação;
- restauração do banco.

## Testes de segurança

- endpoint privado sem token;
- token expirado;
- usuário desativado;
- operador acessando função administrativa;
- abuso de requisições;
- payload excessivo;
- tentativa de injeção;
- segredo ausente;
- credencial inválida;
- verificação de logs para garantir que não há tokens ou senhas.

## Testes de privacidade

- descrição contendo dados pessoais;
- consultas sem autorização;
- tentativa de enumerar ocorrências;
- tentativa de consultar usuários;
- aplicação das regras de retenção;
- exclusão ou anonimização autorizada;
- ausência de dados sensíveis em logs;
- comportamento de restauração de backups.

Os testes deverão ser executados em ambiente controlado, sem utilizar dados pessoais reais desnecessários.

---

# 33. Critérios de Aceite

## Disponibilidade

- [ ] Health checks implementados.
- [ ] Logs estruturados habilitados.
- [ ] Métricas técnicas disponíveis.
- [ ] Alertas configurados.
- [ ] Falhas de banco tratadas.
- [ ] Falhas de Ollama tratadas.
- [ ] Falhas de geocodificação tratadas.
- [ ] Backup automatizado.
- [ ] Restauração testada.
- [ ] RPO e RTO avaliados em simulação.

## Segurança

- [ ] HTTPS configurado em produção.
- [ ] Rate limiting aplicado aos endpoints sensíveis.
- [ ] Segredos fora do repositório.
- [ ] JWT validado conforme a especificação de autenticação.
- [ ] Autorização aplicada pelo backend.
- [ ] Privilégios do banco revisados.
- [ ] Dependências avaliadas.
- [ ] Erros internos não expostos.
- [ ] Auditoria de operações sensíveis.
- [ ] Testes de acesso indevido aprovados.

## Privacidade

- [ ] Inventário de dados documentado.
- [ ] Finalidades definidas.
- [ ] Responsáveis pelo tratamento identificados.
- [ ] Aviso de privacidade aprovado.
- [ ] Dados enviados a provedores externos identificados.
- [ ] Visibilidade das ocorrências definida.
- [ ] Prazos de retenção aprovados.
- [ ] Procedimento de direitos dos titulares estabelecido.
- [ ] Processo de resposta a incidentes definido.
- [ ] Logs e backups avaliados quanto à exposição de dados.

---

# 34. Definition of Done

O trabalho não será considerado concluído apenas porque as configurações existem.

Cada controle deverá possuir evidência verificável, que poderá incluir:

- testes automatizados;
- registros de execução;
- configuração revisada;
- relatório de auditoria;
- evidência de backup;
- resultado de restauração;
- documentação de procedimento;
- teste de autorização;
- simulação de falha;
- aprovação da política de privacidade.

Um item sem implementação ou sem evidência deverá permanecer identificado como pendente.

---

# 35. Ordem de Implementação Recomendada

## Fase 1 — Observabilidade

1. Logs estruturados.
2. Correlation ID.
3. Health checks.
4. Métricas HTTP e de dependências.
5. Alertas.

## Fase 2 — Segurança

1. HTTPS.
2. Gestão de segredos.
3. Rate limiting.
4. Revisão dos guards e permissões.
5. Revisão dos privilégios do banco.
6. Auditoria de operações.
7. Verificação de dependências.

## Fase 3 — Recuperação

1. Backup automático.
2. Proteção dos backups.
3. Procedimento de restauração.
4. Teste de recuperação.
5. Simulação de indisponibilidade.
6. Runbooks.

## Fase 4 — Privacidade

1. Inventário de dados.
2. Mapeamento dos fluxos.
3. Definição de finalidades e bases legais.
4. Definição das permissões de leitura.
5. Aprovação da retenção.
6. Aviso de privacidade.
7. Procedimento de incidentes.
8. Testes de privacidade.

## Fase 5 — Validação operacional

1. Executar testes ponta a ponta.
2. Simular indisponibilidade das dependências.
3. Validar as rotinas de recuperação.
4. Corrigir falhas.
5. Registrar evidências.
6. Avaliar a prontidão para um piloto.

---

# 36. Critério Final de Prontidão

O backend estará tecnicamente preparado para avançar a um piloto quando os controles prioritários estiverem implementados, testados e documentados.

A liberação também dependerá da confirmação de que:

- os dados possuem finalidade e acesso definidos;
- existe capacidade demonstrada de recuperar o banco;
- as falhas geram alertas úteis;
- os endpoints possuem proteção adequada;
- os responsáveis sabem como responder a incidentes;
- os cidadãos recebem informações transparentes sobre o tratamento dos dados;
- existe um procedimento operacional para tratar os relatos recebidos.

A preparação técnica não equivale à autorização institucional para operar como serviço oficial. Essa etapa dependerá das condições de implantação e dos responsáveis competentes.

---

# 37. Controle de Versão

Toda alteração relevante deverá registrar:

```text
Versão
Data
Responsável
Descrição
Motivo
Impacto técnico
```

Mudanças que afetem retenção, acesso ou tratamento de dados pessoais deverão ser avaliadas antes de sua implementação.

**Documento de referência:** `docs/05-backend-reliability-security-privacy.md`

**Status esperado após aprovação:** requisito obrigatório para a preparação do backend para piloto operacional.
