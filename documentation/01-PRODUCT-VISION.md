# URBAN SHIELD

## Product Vision Document

**Documento:** Product Vision
**Versão:** 1.0
**Status:** Draft Controlado
**Projeto:** Urban Shield
**Tipo:** Projeto Acadêmico / PI
**Fonte de verdade:** Visão e direção do produto

---

# 1. Objetivo do Documento

Este documento define a visão, propósito, problema, objetivos, público-alvo, escopo e direção do produto Urban Shield.

Ele responde principalmente às perguntas:

* Por que o produto existe?
* Qual problema resolve?
* Para quem?
* Qual valor entrega?
* O que faz parte do produto?
* O que não faz parte?
* Como o sucesso será medido?

Este documento não define detalhes de implementação.

---

# 2. Visão do Produto

O **Urban Shield** é uma plataforma web de apoio à triagem e visualização de ocorrências urbanas relacionadas a saneamento e eventos hidroclimáticos.

A plataforma recebe relatos em linguagem natural, estrutura essas informações por meio de inteligência artificial local, determina a localização da ocorrência por geocodificação e apresenta os resultados em um painel geográfico.

O objetivo é reduzir o tempo necessário para transformar uma informação textual não estruturada em uma ocorrência organizada, localizada e priorizada.

---

# 3. Missão

Transformar relatos urbanos desestruturados em informações operacionais úteis para análise rápida de riscos relacionados a saneamento e eventos climáticos.

---

# 4. Problema

Relatos de problemas urbanos normalmente chegam de maneira desestruturada.

Exemplo:

> "Tem muita água acumulada na rua perto da escola e está entrando nas casas."

Esse relato contém informações relevantes, mas não está estruturado para análise operacional.

É necessário identificar:

* tipo de ocorrência;
* gravidade;
* possível relação com saneamento;
* possível relação com evento climático;
* endereço;
* localização;
* resumo;
* recomendação preliminar.

Quando esse processo é realizado manualmente, a triagem tende a ser mais lenta e inconsistente.

---

# 5. Oportunidade

O Urban Shield combina:

```text
Linguagem natural
        +
IA local
        +
Geolocalização
        +
Visualização geográfica
```

para produzir uma representação estruturada da ocorrência.

A execução local do modelo de IA reduz a dependência de serviços externos de LLM para o processamento inicial dos relatos.

---

# 6. Proposta de Valor

O Urban Shield deverá permitir que um operador transforme rapidamente:

```text
RELATO HUMANO
      ↓
INFORMAÇÃO ESTRUTURADA
      ↓
LOCALIZAÇÃO
      ↓
PRIORIZAÇÃO
      ↓
VISUALIZAÇÃO
```

O valor principal não está apenas no mapa, mas na **redução do trabalho necessário para estruturar e interpretar o relato inicial**.

---

# 7. Público-Alvo

## 7.1 Operador

Usuário responsável pela análise das ocorrências.

### Necessidades

* visualizar ocorrências rapidamente;
* identificar criticidade;
* localizar incidentes;
* filtrar informações;
* analisar o relato original;
* consultar recomendações preliminares.

---

## 7.2 Cidadão

Usuário responsável pelo fornecimento da informação inicial.

### Necessidades

* informar um problema de maneira simples;
* utilizar linguagem natural;
* não precisar conhecer terminologia técnica;
* não precisar informar coordenadas manualmente.

---

# 8. Objetivos do Produto

## Objetivo principal

Criar um fluxo funcional capaz de transformar um relato textual em uma ocorrência urbana estruturada e geolocalizada.

## Objetivos secundários

* reduzir o esforço manual de triagem;
* padronizar a classificação;
* visualizar ocorrências em mapa;
* permitir filtragem por criticidade;
* demonstrar aplicação prática de IA local;
* relacionar ocorrências às ODS 6 e 13.

---

# 9. ODS

## ODS 6 — Água Potável e Saneamento

Abrange ocorrências como:

* problemas de saneamento;
* esgoto;
* drenagem;
* bueiros;
* abastecimento;
* refluxo de esgoto.

## ODS 13 — Ação Contra a Mudança Global do Clima

Abrange ocorrências como:

* alagamentos;
* enchentes;
* chuvas intensas;
* tempestades;
* eventos climáticos extremos;
* impactos urbanos associados.

Uma mesma ocorrência poderá possuir relação simultânea com as duas ODS.

---

# 10. Conceito de Ocorrência

A unidade central do produto é a **Incident / Ocorrência**.

Uma ocorrência representa um evento urbano reportado pelo usuário.

Ela contém:

```text
identificação
relato original
classificação
ODS
criticidade
resumo
localização
recomendação
status
datas
```

---

# 11. Escopo do MVP

O MVP deverá possuir:

* cadastro de ocorrência;
* processamento do relato com IA;
* classificação;
* associação às ODS;
* classificação de severidade;
* extração de endereço;
* geocodificação;
* persistência;
* mapa;
* filtros;
* consulta de detalhes;
* recomendação preliminar.

---

# 12. Fora do Escopo do MVP

Não fazem parte da primeira versão:

* aplicativo mobile nativo;
* sensores físicos;
* pluviômetros;
* previsão meteorológica;
* integração com sistemas governamentais;
* despacho automático de equipes;
* tomada de decisão automática;
* reconhecimento de imagens;
* processamento de vídeo;
* processamento de áudio;
* RBAC governamental;
* microserviços;
* Event Sourcing;
* CQRS;
* Kubernetes;
* integração com LLM pago.

---

# 13. Princípio de Human-in-the-Loop

A IA será um mecanismo de **triagem e apoio**.

Ela não será responsável pela decisão operacional final.

O sistema deverá deixar clara a distinção entre:

```text
Informação fornecida pelo cidadão
Informação estruturada pela IA
Informação geográfica confirmada pelo serviço de mapas
Decisão do operador
```

---

# 14. Classificação de Severidade

O produto utilizará três níveis:

### LOW

Ocorrência sem indicação de risco imediato significativo.

### MEDIUM

Ocorrência relevante que exige acompanhamento.

### CRITICAL

Ocorrência com indícios de risco significativo à população ou infraestrutura.

A severidade é uma classificação de triagem e não representa um diagnóstico técnico ou avaliação oficial de risco.

---

# 15. Categorias Iniciais

O MVP trabalhará com categorias controladas:

```text
FLOODING
URBAN_DRAINAGE
SEWAGE
WATER_SUPPLY
STORM
LANDSLIDE
OTHER
```

Categorias adicionais poderão ser incluídas posteriormente.

---

# 16. Jornada Principal do Produto

```text
Cidadão/Operador
      ↓
Envia relato
      ↓
Sistema interpreta
      ↓
Sistema classifica
      ↓
Sistema resolve localização
      ↓
Ocorrência é registrada
      ↓
Operador visualiza
      ↓
Operador analisa
```

---

# 17. Experiência Esperada

O produto deve privilegiar:

* simplicidade;
* leitura rápida;
* baixa quantidade de cliques;
* destaque para criticidade;
* visualização geográfica;
* clareza sobre informações geradas por IA.

---

# 18. Métricas de Sucesso

## Qualidade da IA

Meta inicial:

**≥ 85% de acerto** no conjunto de avaliação definido pelo projeto.

A avaliação deverá considerar separadamente:

* categoria;
* ODS;
* severidade;
* extração de endereço.

---

## Performance

Meta inicial:

**P50 ≤ 3 segundos** para o fluxo completo em ambiente controlado.

Fluxo:

```text
envio
→ IA
→ geocodificação
→ persistência
→ resposta
```

A medição deverá registrar os tempos de cada etapa.

---

## Qualidade do sistema

O MVP deverá:

* processar relatos válidos;
* tratar falhas da IA;
* tratar falhas da geocodificação;
* manter contratos consistentes;
* apresentar erros de forma controlada.

---

# 19. Premissas

O produto assume:

* disponibilidade do ambiente local;
* Ollama executável;
* banco de dados disponível;
* acesso à Google Maps Platform;
* relatos suficientemente compreensíveis para avaliação;
* hardware capaz de executar o modelo escolhido.

---

# 20. Limitações

O Urban Shield não deve ser interpretado como:

* sistema oficial de emergência;
* sistema oficial de Defesa Civil;
* sistema de previsão meteorológica;
* mecanismo de diagnóstico de infraestrutura;
* mecanismo de decisão automática;
* substituto de profissionais especializados.

---

# 21. Critério de Sucesso do Produto

O Urban Shield será considerado bem-sucedido quando demonstrar um fluxo completo:

```text
Relato
  ↓
Classificação
  ↓
ODS
  ↓
Severidade
  ↓
Endereço
  ↓
Geocodificação
  ↓
Persistência
  ↓
Mapa
  ↓
Apoio à análise
```

com desempenho e qualidade compatíveis com as metas definidas.

---

# 22. Evolução Futura

Possíveis extensões:

* integração meteorológica;
* imagens de ocorrências;
* análise de séries temporais;
* sensores;
* notificações;
* autenticação;
* RBAC;
* integração com sistemas municipais;
* priorização baseada em múltiplas ocorrências;
* análises históricas.

Esses itens não fazem parte do compromisso do MVP.
