# AI Roblox Lab — Blackwood Heist 🏦🕵️‍♂️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Roblox](https://img.shields.io/badge/Platform-Roblox%20Studio-00A2FF?logo=roblox&logoColor=white)](https://www.roblox.com)
[![Luau](https://img.shields.io/badge/Language-Luau%20--!strict-00A2FF)](https://luau-lang.org/)
[![Rojo](https://img.shields.io/badge/Tool-Rojo-E74C3C)](https://rojo.space/)
[![YouTube](https://img.shields.io/badge/YouTube-Assistir%20ao%20V%C3%ADdeo-FF0000?logo=youtube&logoColor=white)](https://youtu.be/POzYDoPPEII)
[![AI Architecture](https://img.shields.io/badge/AI%20Stack-GPT%20%7C%20Gemini%20%7C%20Codex-brightgreen)](https://github.com/dgurgel-info/ai-roblox-lab)

> **Projeto experimental de desenvolvimento de jogos com Inteligência Artificial no Roblox Studio**, combinando grandes modelos de linguagem (**GPT**, **Gemini**, **Codex**) e uma esteira de **múltiplos agentes autônomos em execução paralela** para planejar, codificar, auditar e testar uma experiência multiplayer completa do zero até o polimento cinematográfico.

---

## 📺 Vídeo Oficial no YouTube

Assista ao processo completo de criação, bastidores, erros e lições aprendidas no vídeo:

**[▶️ Como fazer um jogo VIRAL no Roblox com IA (E o resultado me surpreendeu...) 🤖🎮](https://youtu.be/POzYDoPPEII)**  

---

## 🤖 O Processo de Criação com IA (Multi-Agentes)

A grande inovação metodológica demonstrada no projeto é a **orquestração de múltiplos agentes autônomos com papéis bem delineados**, evitando o erro comum de pedir um jogo inteiro em um único prompt monolítico.

```text
       ┌────────────────────────────────────────────────────────┐
       │                 HUMAN OPERATOR / DESIGN                │
       │   (Visão de Jogo, Restrições & Feedback do Playtest)   │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │              AGENTE 1: ARQUITETO (GPT)                 │
       │   - Estruturação macro de requisitos e game design     │
       │   - Definição da máquina de estados de rodada          │
       │   - Decomposição em 15 fases técnicas sequenciais      │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │        AGENTE 2: ENGENHEIRO DE CÓDIGO (GEMINI/CODEX)   │
       │   - Geração de código Luau estrito (--!strict)         │
       │   - Serviços autoritativos (ServerScriptService)       │
       │   - Controllers de input e UI (StarterPlayerScripts)   │
       │   - Matemática vetorial 3D e cálculo de raycasting     │
       └──────────────┬───────────────────────────▲─────────────┘
                      │                           │
            Código    │                   Correção│ e
            Gerado    ▼                   Refinamento
       ┌──────────────────────────────────────────┴─────────────┐
       │             AGENTE 3: REVISOR / AUDITOR (GEMINI)       │
       │   - Auditoria estrita de concorrência (Single-Claim)   │
       │   - Verificação de exploits e vulnerabilidades de rede │
       │   - Checagem de linha de visão sem "wall-hack"         │
       │   - Validação de idempotência e resiliência (DataStore)│
       └───────────────────────────┬────────────────────────────┘
                                   │
                         Validação │ Aprovada
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │        AGENTE 4: INTEGRAÇÃO & AMBIENTE (MCP / ROJO)     │
       │   - Sincronização via Rojo com o Roblox Studio         │
       │   - Inspeção de hierarquia e injeção de testes         │
       │   - Ajuste fino de Terrain Voxel, iluminação e física  │
       └────────────────────────────────────────────────────────┘
```

### Divisão de Responsabilidades:

1. **GPT / Codex (Estrutura e Arquitetura)**:
   - Responsável pelo blueprint das mecânicas, fluxos de jogo, regras de balanceamento e pelo detalhamento exaustivo das 15 fases do plano de implantação ([`Plan.md`](Plan.md)).
2. **Gemini (Raciocínio Profundo, Luau Estrito e Geometria 3D)**:
   - Implementação especializada do código Luau (`--!strict`), resolução de equações vetoriais de produto escalar ($\vec{v} \cdot \vec{d} \ge \cos(55^\circ)$) para os cones de visão dos guardas, cálculo de trajetórias preditivas de interceptação policial e rebaixamento físico da galeria de esgoto.
3. **Múltiplos Agentes Autônomos em Revisão**:
   - Cada fase técnica passava por uma checagem cruzada: um agente propunha o código e outro analisava falhas de segurança autoritativa (ex.: garantir que o cliente nunca dite o valor de loot, velocidade física ou resultado de extração).
4. **Superação de Limitações (A Falha das Referências Visuais)**:
   - Conforme demonstrado no vídeo, sem referências visuais a IA tende a gerar blocos sem proporção humana ou fendas nas paredes. Ao introduzir plantas de referência, medições em studs e modelos 3D de apoio (armazenados na pasta [`assets/`](assets/)), a fidelidade espacial subiu drasticamente.

---

## 🎮 Sobre o Jogo: Mansão Heist

**Mansão Heist** é uma experiência multiplayer cooperativa/competitiva de assalto tático no Roblox. Os jogadores infiltram a suntuosa mansão, burlam a segurança privada, roubam itens valiosos do cofre principal e devem escapar antes que o cerco policial seja concluído.

### Filosofia Central:
- **Tensão de Decisão**: A dificuldade não vem de punições arbitrárias, mas de escolhas: *por onde entrar, quanto loot carregar, aceitar perder velocidade pelo valor do saque, ou largar a bolsa física para correr mais rápido*.
- **Estrutura em 3 Atos**:
  - **Ato I — Infiltrate**: Furtividade, estudo de rotas e abertura de acessos silenciosos.
  - **Ato II — Steal**: Coleta de loot, arrombamento de cofres e cumprimento de contratos sob risco crescente.
  - **Ato III — Escape**: Corrida contra o tempo. Se a polícia chegar, as rotas normais são bloqueadas e os jogadores precisam usar rotas de emergência (como a galeria subterrânea do esgoto).
- **Sem Pay-to-Win**: Toda vantagem é cosmética ou conquistada através do gameplay. Compras são estritamente bloqueadas durante perseguições.

---

## 🏆 As 15 Fases de Implantação

O desenvolvimento foi segmentado e auditado fase por fase diretamente no Roblox Studio via Rojo. Abaixo está o resumo técnico das 15 fases:

| Fase | Título | Módulos Principais | Mecânicas e Entregáveis |
| :---: | :--- | :--- | :--- |
| **01** | **Fundação** | `RoundService`, `PlayerDataService`, `GameConfig`, `Enums` | Suporte a até 16 jogadores simultâneos. FSM de 11 estados de rodada autoritativos. Replicação de rede e HUD adaptativo pt-BR. |
| **02** | **Map Blockout & Arquitetura** | `MapBuilder`, `MapDetailsService` | Mansão em 2 pavimentos + subsolo com cofre. Vedação completa sem furos na alvenaria, lajes sólidas, garagem com 12 studs de pé-direito e portas animadas em 90° via `TweenService`. |
| **03** | **Interaction + Loot** | `ItemDefinitions`, `LootService`, `InventoryService` | Catálogo de 7 categorias e 6 raridades. Bloqueio atômico de concorrência (*Single-Claim Lock*) impedindo duplicação de itens. Inventário de 3 níveis com peso acumulado e feedback visual (`Highlight`). |
| **04** | **Extraction** | `ExtractionService` | Pontos de extração convencionais (`FrontGate` e `VanExtraction`) com validação de proximidade física ($\le 15$ studs) e persistência autoritativa de recompensa. |
| **05** | **Security & Stealth** | `SecurityService` | 6 níveis dinâmicos de alerta (0 a 5). Câmeras robotizadas com cone de visão cônico e `DetectionMeter`. Sistema de propagação sonora (passos, corrida, arrombamento e vidro quebrado). |
| **06** | **Guard AI** | `GuardService` | Segurança privada autônoma com 7 estados (`Patrol`, `Investigate`, `Chase`, etc.). Linha de visão fisiológica autêntica via produto escalar ($\cos(55^\circ)$) e raycasts sem wall-hack. |
| **07** | **Police Inbound** | `RoundService`, `PoliceService` | Contagem regressiva com avisos de rádio em 60s, 30s e 15s. Bloqueio automático das saídas convencionais e ativação de giroflex e sirenes nas viaturas da rua ($Z = -132$). |
| **08** | **Police AI & Táticas** | `PoliceAIService`, `PoliceService` | 3 arquétipos táticos (`PatrolOfficer`, `Interceptor` com rota preditiva vetorial, `Searcher`). **Regras táticas**: não entram na casa, caçam apenas quem tem saque e a rua externa é zona neutra. |
| **09** | **Escape Mode & Esgoto** | `EscapeService` | Rotas de emergência (`Forest`, `Rooftop`, `Sewer`). Galeria subterrânea física rebaixada para $Y = -12.60$, vão livre de 10 studs (sem corte de câmera), túnel de 148 studs e escadarias completas. |
| **10** | **Weight + Drop Bag** | `InventoryService`, `DropBagService` | Curva de penalidade física de velocidade em 5 faixas. Mecânica de Drop Bag via **tecla `G`** restaurando velocidade instantaneamente e gerando bolsa física 3D recolhível no mundo. |
| **11** | **Mecânica de Prisão** | `ArrestService`, `PoliceAIService` | Iniciação gradual de captura (`ArrestAttempt`) de 2.5 segundos reais a $\le 5$ studs. Evasão atlética por distância ou cobertura. Captura individual (`Busted`) sem interromper os colegas de equipe. |
| **12** | **Progressão & Skills** | `PlayerDataService`, `HUDClient` | Sistema de níveis e XP. Árvore de habilidades com 9 perks em 3 ramos (**Ghost**, **Tech**, **Thief**). Catálogo de ferramentas com desbloqueio gradual por nível e contratos secundários. |
| **13** | **Persistência Resiliente** | `PlayerDataService` | DataStore versionado (`v2`) com migração automática. Resiliência de rede com até 3 retries e *exponential backoff*. Proteção estrita **Anti-Wipe** bloqueando salvamento caso a carga inicial falhe. |
| **14** | **Economia Anti-P2W** | `EconomyService`, `PurchaseService` | Developer Products e GamePasses validados via callback `ProcessReceipt` idempotente. Bloqueio total de compras durante perseguições ou tentativas de prisão. Zero vantagens desleais. |
| **15** | **Polimento Cinematográfico** | `MapDetailsService`, `LightingDetailsService`, `PolishService` | Piscina Voxel com água volumétrica do Terrain e nado nativo (`Swimming`). Novo playground 3D da Loja do Criador (Asset `9377320356`). Ciclo diurno desacelerado (12 min) iniciando às 09:30. Skyline otimizado a 60 FPS estáveis. |

---

## 📁 Estrutura do Repositório

```text
ai-roblox-lab/
├── assets/                          # Pasta dedicada para imagens de referência, plantas e modelos 3D
├── Plan.md                          # Plano de implantação completo (15 fases), prompts e auditoria técnica
├── LICENSE                          # Licença MIT
└── README.md                        # Documentação do projeto, bastidores e metodologia multi-agente
```

---

## 🚀 Como Utilizar Este Laboratório

1. **Estudo de Metodologia e Prompts**:
   - Consulte o [`Plan.md`](Plan.md) para ver a decomposição das 15 fases, regras táticas de IA, fórmulas matemáticas e auditoria completa de cada sistema.
   - Utilize a metodologia de múltiplos agentes (Arquiteto, Engenheiro, Auditor e Integrador) para construir ou evoluir seus próprios jogos no Roblox Studio.

2. **Assets e Referências Visuais**:
   - Acesse a pasta [`assets/`](assets/) para consultar ou adicionar as imagens conceituais, plantas baixas e modelos de referência utilizados nos prompts de IA.

---

## 🎨 Como Utilizar a Pasta `assets/`

A pasta [`assets/`](assets/) é o local reservado para receber os materiais multimídia e referências utilizados durante o desenvolvimento com IA e apresentados no vídeo:
- Imagens conceituais, plantas baixas e referências de iluminação;
- Modelos 3D de apoio (`.obj`, `.fbx`, `.rbxm`) que serviram de referência espacial;
- Prompts estruturados e capturas do Roblox Studio.

---

## 📄 Licença

Este projeto é disponibilizado sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👤 Autor

Desenvolvido por **Daniel de Morais Gurgel** ([@dgurgel-info](https://github.com/dgurgel-info)).

- **YouTube**: [@dgurgel-info](https://www.youtube.com/@dgurgel-info)
- **GitHub**: [dgurgel-info](https://github.com/dgurgel-info)

Se este projeto ou o vídeo te ajudou a entender como utilizar Inteligência Artificial para criar experiências no Roblox, deixe uma estrela ⭐ no repositório e se inscreva no canal!
