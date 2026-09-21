# BLACKWOOD HEIST — Plano de Implantação

## Status desejado

Projeto: Jogo multiplayer original para Roblox (suporte escalável para até 16 jogadores simultâneos).

Fases concluídas: 1–15 

Estado atual: Construir experiência completa e funcional com arquitetura modular Rojo/Luau, mansão de 2 andares totalmente mobiliada e selada contra furos, subsolo com cofre principal, exterior detalhado com piscina voxel nadável e novo parquinho 3D da Loja do Criador, garagem com pé-direito elevado, galeria subterrânea física de esgoto, viaturas policiais com giroflex estroboscópico e sirenes 3D espaciais, IA tática de guardas e policiais (com regras de atuação estritamente externa, busca focada em saqueadores e rua como área neutra), cálculo autoritativo de peso e velocidade, mecânica de Drop Bag com bolsa física 3D, tentativa gradual de prisão (ArrestAttempt) e teleporte individual seguro em Busted, progressão por níveis e árvore de habilidades com 3 arquétipos (Ghost, Tech, Thief), persistência resiliente com esquema versionado (v2) e proteção Anti-Wipe, economia e monetização ética anti-P2W com Developer Products e GamePasses validados via ProcessReceipt idempotente, ciclo dia/tarde/noite desacelerado (12 min) iniciando às 09:30 da manhã e polimento visual cinematográfico.

Próxima etapa: Expansões de conteúdo pós-lançamento, balanceamento contínuo e playtests públicos com múltiplos jogadores humanos.

---

## 1. Objetivo

Construir **Blackwood Heist**, um jogo multiplayer original no Roblox em que jogadores infiltram uma propriedade de luxo, roubam objetos de valor e escapam antes da resposta policial.

O jogo combina:

- stealth;
- exploração;
- loot;
- risco versus recompensa;
- progressão;
- cooperação;
- competição indireta;
- guardas NPC;
- câmeras;
- alarmes;
- lockdown;
- extração;
- perseguição policial;
- rotas de fuga;
- upgrades;
- contratos;
- conteúdo social;
- monetização não pay-to-win.

Blackwood Estate deve possuir arquitetura, rotas e identidade próprias, sem copiar mapas existentes.

---

## 2. Filosofia de gameplay

O jogador deve decidir constantemente:

- por onde entrar;
- qual área vale o risco;
- quanto loot carregar;
- quando parar de roubar;
- se aceita perder valor para correr mais rápido;
- qual extração utilizar;
- qual rota emergencial usar após a chegada da polícia.

A tensão deve vir das decisões e da segurança sistêmica, não de punições arbitrárias.

---

## 3. Estrutura da partida

### Act I — Infiltrate

Entrar na propriedade, estudar rotas, localizar loot e abrir acessos. Predominância de stealth.

### Act II — Steal

Roubar loot, cumprir contratos, abrir cofres e buscar itens raros. Predominância de risco versus recompensa.

### Act III — Escape

O jogador pode extrair normalmente antes da polícia ou entrar em Police Escape quando o tempo termina.

---

## 4. Estados centrais da rodada

- Lobby
- Preparation
- Infiltration
- Heist
- Lockdown
- Extraction
- PoliceInbound
- PoliceResponse
- Escape
- Completed
- Failed

`RoundService` controla as transições.

Fluxo principal:

```text
Lobby → Preparation → Infiltration → Heist → Lockdown
→ Extraction → PoliceInbound → PoliceResponse → Escape
→ Completed / Failed
```

Valores de duração devem permanecer configuráveis. Meta: partidas de 10–18 minutos.

Valores de referência publicados:

- Preparation: 30–60 s;
- Infiltration + Heist: 6–10 min;
- Extraction: 90–180 s;
- Police Escape: 3–5 min.

---

## 5. Extração e resposta policial

Quando o objetivo principal é concluído ou a segurança chega ao nível crítico:

- iniciar `ExtractionTimer`;
- mostrar `POLICE RESPONSE INBOUND`;
- avisar em 60 s, 30 s e 15 s;
- usar sirene externa, luzes e música progressiva;
- nunca spawnar polícia instantaneamente ao lado do jogador.

Quando o timer chega a zero:

- tocar evento audiovisual;
- ativar sirenes;
- ativar iluminação policial;
- bloquear rotas específicas;
- desabilitar Front Gate e Van Extraction;
- habilitar Forest Escape, Sewer Escape e Rooftop Escape futuramente;
- ativar `EscapeService`.

---

## 6. Polícia

### Arquétipos

#### Patrol Officer

Persegue diretamente, com velocidade média e maior quantidade.

#### Interceptor

Prevê rota, corta caminho e usa rotas alternativas.

#### Searcher

Procura o jogador após perder contato em quartos, jardim, garagem, subsolo e esconderijos.

#### Commander

Lógica de coordenação que atribui funções, bloqueia áreas, define zonas de busca e reorganiza unidades.

### Estados de AI

- Idle
- Deploy
- Chase
- Intercept
- Investigate
- Search
- Block
- Return

### Blackboard policial

Manter no servidor:

- `LastKnownPlayerPosition`;
- `LastKnownPlayerTime`;
- `CurrentEscapeDirection`;
- `ActiveSearchZones`;
- `BlockedRoutes`;
- `AvailableExtractionRoutes`;
- `PlayerLootWeight`;
- `AlertLevel`.

Policiais devem utilizar FOV, distância, raycast e tempo de reconhecimento. Paredes bloqueiam visão.

Um policial isolado deve ser escapável. Dificuldade deve vir de cobertura, coordenação, interceptação e controle de rota, não apenas de velocidade.

Não formar uma fila única atrás do jogador. Dividir policiais entre múltiplos alvos.

---

## 7. Guardas privados

Guardas atuam antes da polícia.

Estados:

- Patrol
- Idle
- Suspicious
- Investigate
- Search
- Chase
- ReturnToPost

`GuardAI` deve permanecer separado de `PoliceAI`.

Guardas reagem a ruído, câmeras, portas arrombadas, vidro quebrado, alarmes e perda de loot.

---

## 8. Jogador, peso e prisão

Velocidade base: 16 studs/s.

### Peso

- 0–10 kg: 100%;
- 10–20 kg: 95%;
- 20–30 kg: 90%;
- 30–40 kg: 82%;
- carga grande: aproximadamente 70–80%.

### Drop Bag

- tecla `G`;
- remove o loot carregado do inventário;
- cria uma bolsa física no mundo;
- restaura a velocidade do jogador;
- outro jogador pode recolher a bolsa se tiver capacidade;
- servidor valida estado, distância, cooldown, peso e propriedade.

### ArrestAttempt

- inicia quando policial chega perto;
- dura aproximadamente 2–3 segundos;
- pode ser interrompida por distância, cobertura, obstáculo, ajuda ou ferramenta válida;
- não é captura instantânea;
- ao completar: `BUSTED`.

Consequências:

- perde loot não extraído;
- mantém XP parcial;
- mantém progressão permanente;
- mantém ferramentas, itens comprados e cosméticos;
- registra `TimesBusted`;
- retorna individualmente ao lobby;
- não interrompe a rodada dos demais jogadores.

---

## 9. Blackwood Estate

### Exterior

- Front Gate
- Driveway
- Front Garden
- Side Garden
- Pool
- Garage
- Guest House
- Service Yard
- Forest
- Drainage
- Roof Access
- Utility Area

### Térreo

- Main Hall
- Living Room
- Dining Room
- Kitchen
- Library
- TV Room
- Office
- Security Room
- Bathroom
- Service Hall
- Main Stairs
- Service Stairs

### Segundo andar

- Master Suite
- Bedroom 1
- Bedroom 2
- Bedroom 3
- Gallery
- Private Office
- Balcony
- Closet
- Secondary Safe

### Subsolo

- Wine Cellar
- Storage
- Machine Room
- Electrical Room
- Security Infrastructure
- Main Vault
- Hidden Tunnel

Cada área importante deve ter pelo menos duas entradas, rota alternativa, opção de stealth e possibilidade de fuga.

Rotas de infiltração:

- Front Gate;
- Side Wall;
- Garage;
- Window;
- Maintenance Tunnel;
- Rooftop.

Rotas emergenciais:

- Forest Escape;
- Sewer Escape;
- Rooftop Escape futuramente.

O mapa deve suportar até 16 jogadores e manter áreas amplas, navegáveis e detalhadas.

---

## 10. Loot e inventário

`ItemDefinitions` central deve conter:

- Id;
- Name;
- Category;
- BaseValue;
- Weight;
- Size;
- Rarity;
- NoiseLevel;
- CarryType;
- SpawnWeight;
- RequiredTool;
- ModelReference.

Categorias:

- Electronics
- Jewelry
- Art
- Documents
- Collectibles
- Cash
- Artifact

Raridades:

- Common
- Uncommon
- Rare
- Epic
- Legendary
- Artifact

Loot pequeno inclui smartphone, tablet, laptop, câmera, relógio, colar, anel, dinheiro, escultura pequena, documento e chave rara.

Loot grande inclui TV, pintura, escultura, servidor, antiguidades, instrumento musical e peças de exposição.

Capacidades planejadas:

- Starter Bag: 6 slots / 15 kg;
- Professional Bag: 10 slots / 25 kg;
- Master Bag: 14 slots / 35 kg.

Capacidade máxima relevante deve ser obtível jogando.

---

## 11. Segurança e stealth

### Security Level

- 0 Normal
- 1 Suspicious
- 2 Searching
- 3 Alert
- 4 Lockdown
- 5 Critical

Eventos de segurança:

- câmera detecta jogador;
- vidro quebra;
- porta arrombada;
- guarda encontra loot faltando;
- sensor dispara;
- cofre abre;
- alarme manual.

### Câmeras

Usar cone de visão, raycast, DetectionMeter, hacking e estado desabilitado.

Fluxo:

```text
camera detecta → meter sobe → jogador sai → meter reduz
→ 100% → alert
```

### Ruído

Valores iniciais:

- walk: 2;
- run: 7;
- door: 5;
- glass: 18;
- crowbar: 10.

### Stealth

Implementar crouch, escuridão, esconderijos, closets, espaços sob camas, distrações, interruptores de luz e movimento silencioso.

### Lockdown

Ativa sirene, luzes de emergência, travas, mudança de comportamento dos guardas e timer de extração.

---

## 12. Contratos, XP e progressão

Contratos:

- roubar determinado valor;
- roubar pintura específica;
- abrir o Main Vault;
- roubar sem alarme;
- extrair pelo esgoto;
- completar dentro do tempo;
- encontrar documento secreto.

`Perfect Heist` exige objetivo completo, nenhum alarme e extração antes da polícia.

Recompensas:

- Cash bonus;
- XP bonus;
- estatísticas;
- achievements.

XP por:

- loot;
- objetivos;
- stealth;
- descoberta;
- contratos;
- extração;
- ações de equipe;
- Police Escape.

Skill tree:

- Ghost: stealth;
- Tech: segurança e hacking;
- Thief: loot e capacidade de carga.

Ferramentas:

- Lockpick;
- Flashlight;
- Basic Bag;
- Glass Cutter;
- Signal Jammer;
- Camera Loop;
- Safe Drill;
- Scanner;
- Decoy;
- Smoke Device ou distraction gadget futuramente.

Evitar armas letais como sistema principal.

---

## 13. Eventos, contratos diários e coleção

Eventos aleatórios:

- Owner At Home;
- Extra Guards;
- Security Upgrade;
- Power Failure;
- Rare Artifact;
- Hidden Safe;
- Storm;
- Private Party.

Randomizar loot, códigos, variantes de cofre, rotas de guarda, chaves e objetivos, sem randomizar totalmente o mapa.

Daily challenges:

- roubar eletrônicos;
- concluir contratos;
- extrair determinado valor;
- abrir cofres;
- escapar sem detecção.

Weekly challenges podem conter objetivos maiores. Não exigir login diário obrigatório.

Collection Book:

- Blackwood Art;
- Rare Watches;
- Historic Items;
- Artifacts.

Recompensas: badges, títulos e cosméticos.

Hideout pós-MVP: troféus, loot raro, artefatos, achievements, decorações e visita de amigos.

---

## 14. Economia e monetização

Cash é obtido jogando e usado para ferramentas, equipamentos, upgrades e cosméticos básicos.

Robux deve ser usado preferencialmente para:

- cosméticos;
- passes;
- bundles;
- conveniência.

Nunca bloquear o core gameplay atrás de pagamento.

### Game Passes

- Extra Loadout Slots;
- Hideout Designer;
- Elite Cosmetics Pack;
- Supporter Pack.

### Developer Products

- Cash Packs;
- XP Boost;
- Contract Reroll;
- Cosmetic Tokens.

Não vender fuga automática da polícia.

### Master Thief Bundle — 499 Robux

Conteúdo possível:

- premium bag skin;
- animated mask;
- tool skin;
- extraction effect;
- title;
- emote;
- hideout decoration;
- quantidade moderada de Cash.

Evitar fake discounts, compras forçadas, pay-to-win e popups durante perseguições.

---

## 15. UI, áudio e iluminação

HUD:

- Loot Value;
- Weight;
- Movement Speed;
- Security Level;
- Objective;
- Extraction Timer;
- Police State;
- Escape Route;
- feedback de prisão e Drop Bag.

Durante perseguição, reduzir elementos secundários e destacar rota, distância e estado policial.

Áudio:

- stealth: baixo e tenso;
- alert: intensificação;
- extraction: urgente;
- PoliceResponse: percussão e sirenes;
- escape: música dinâmica.

Iluminação:

- normal: interior quente e exterior frio;
- lockdown: luzes de emergência;
- PoliceResponse: luzes vermelhas/azuis, holofotes e reflexos moderados.

---

## 16. Arquitetura Roblox

```text
ReplicatedStorage
└── Blackwood
    ├── Shared
    │   ├── ItemDefinitions
    │   ├── ToolDefinitions
    │   ├── GameConfig
    │   ├── Enums
    │   ├── Types
    │   └── Utility
    ├── Remotes
    └── Assets

ServerScriptService
└── Services
    ├── RoundService
    ├── LootService
    ├── InventoryService
    ├── InteractionService
    ├── SecurityService
    ├── GuardService
    ├── ExtractionService
    ├── EscapeService
    ├── PoliceService
    ├── PoliceAIService
    ├── ArrestService
    ├── ContractService
    ├── EconomyService
    ├── PlayerDataService
    ├── PurchaseService
    ├── AnalyticsService
    └── AntiExploitService

StarterPlayer
└── StarterPlayerScripts
    └── Controllers
        ├── InteractionController
        ├── InventoryController
        ├── StealthController
        ├── CameraController
        ├── UIController
        ├── SoundController
        ├── EscapeController
        └── DropBagController

StarterGui
├── MainHUD
├── InventoryUI
├── ShopUI
├── ContractUI
├── ExtractionUI
└── PoliceUI

Workspace
└── BlackwoodEstate
    ├── Map
    ├── LootSpawns
    ├── GuardPaths
    ├── PoliceSpawns
    ├── PoliceRoutes
    ├── PoliceUnits
    ├── SecurityDevices
    ├── ExtractionPoints
    ├── EmergencyExtractionPoints
    ├── DroppedBags
    └── Interactables
```

---

## 17. Configuração central

Nada crítico deve ficar hardcoded.

`GameConfig` deve controlar:

- duração de rodada;
- tempo de extração;
- aviso policial;
- duração do Police Escape;
- quantidade máxima de polícia;
- intervalo de spawn;
- velocidade base;
- peso máximo;
- thresholds de segurança;
- velocidade por faixa de peso;
- duração e distância da prisão;
- cooldowns de interação.

---

## 18. Autoridade e segurança

O servidor controla:

- loot;
- dinheiro;
- XP;
- inventário;
- peso;
- velocidade carregando loot;
- segurança;
- polícia;
- prisão;
- extração;
- resultado da rodada;
- compras.

O cliente controla apenas input, UI, animações e efeitos locais.

Validar em todo RemoteEvent:

- tipo;
- distância;
- cooldown;
- estado;
- propriedade;
- estado da rodada.

Nunca confiar em dinheiro, loot, resultado de extração, peso ou estado policial enviados pelo cliente.

---

## 19. Persistência

`PlayerData`:

- Version;
- Cash;
- XP;
- Level;
- OwnedTools;
- OwnedCosmetics;
- Loadouts;
- Statistics;
- Collections;
- Settings;
- SeasonProgress.

Estatísticas:

- SuccessfulHeists;
- PerfectHeists;
- PoliceEscapes;
- TimesBusted;
- HighestLoot.

Testar disconnect, rejoin, shutdown, retries e falhas de DataStore.

---

## 20. Analytics

Registrar:

- TutorialStarted;
- TutorialCompleted;
- HeistStarted;
- VaultOpened;
- LockdownStarted;
- ExtractionStarted;
- PoliceInbound;
- PoliceArrived;
- PoliceChaseStarted;
- PoliceEscaped;
- PlayerBusted;
- LootDropped;
- ExtractionCompleted;
- HeistCompleted;
- PurchaseCompleted.

Métricas de balanceamento:

- tempo médio até alarme;
- taxa de extração normal;
- taxa de chegada policial;
- sucesso do Police Escape;
- valor médio de loot;
- loot descartado na perseguição;
- taxa de prisão;
- duração média da perseguição.

Metas iniciais:

- extração normal: 60–70%;
- Police Escape: 35–50% para jogador médio;
- jogador experiente: 70%+.

---

## 21. Performance

- StreamingEnabled;
- limitar NPCs;
- não chamar PathfindingService todo frame;
- recalcular caminhos apenas quando necessário;
- pooling de NPCs quando fizer sentido;
- distribuir raycasts no tempo;
- evitar loops globais excessivos.

---

## 22. MVP completo

- 1 mapa;
- até 16 jogadores;
- 20–30 itens de loot;
- 1 vault;
- 4 guards;
- 4 câmeras;
- 2 rotas de infiltração;
- 2 extrações normais;
- SecurityLevel;
- ExtractionTimer;
- 4–6 NPCs policiais;
- PoliceAI básica;
- Forest Escape;
- Sewer Escape;
- inventário;
- peso;
- Drop Bag;
- prisão;
- Cash;
- XP;
- DataStore;
- loja básica;
- tutorial.

---

## 23. Fases de implantação

### Fase 1 — Fundação — CONCLUÍDA

- **Módulos**: `Bootstrap.server.lua`, `GameConfig.lua`, `Enums.lua`, pasta de Remotes (`ReplicatedStorage.Blackwood.Remotes`), `PlayerDataService.lua`, `RoundService.lua`, `HUDClient.client.lua`.
- **Mecânicas**: Máquina de estados finita autoritativa com 11 estados de rodada (`Lobby`, `Preparation`, `Infiltration`, `Heist`, `Lockdown`, `Extraction`, `PoliceInbound`, `PoliceResponse`, `Escape`, `Completed`, `Failed`). Suporte a até 16 jogadores simultâneos com arquitetura cliente-servidor desacoplada. Replicação de estado para clientes via RemoteEvents e ValueObjects. Ocultação automática de marcações 3D de depuração durante o gameplay.
- **Acceptance**: Estados transicionam de forma confiável e autoritativa; HUD recebe e reflete estados em tempo real; zero erros no console do Studio.

### Fase 2 — Map Blockout & Arquitetura — CONCLUÍDA

- **Módulos**: `MapBuilder.lua`, `MapDetailsService.lua`.
- **Mecânicas**: Mansão de luxo em 2 pavimentos (Térreo e 1º Andar) + Subsolo/Adega estrutural. Lajes perimetrais sólidas (`EastLedgeSolidRoof`, `WestLedgeSolidRoof`), parapeitos de sacadas e vedação de alvenaria eliminando 100% dos vãos na fachada. Portas interativas com animação fluida de 90° via `TweenService` e `ProximityPrompt` ("Abrir Porta" / "Fechar Porta") com batentes ajustados. Garagem lateral oeste com pé-direito de 12 studs e vão livre de entrada de 9.5 studs. Terreno hermético (`GardenGrounds`) com 12 lajes de grama/concreto em $Y = 0$, muros perimetrais altos e portões de ferro forjado.
- **Acceptance**: Rotas de circulação fluidas e desimpedidas, zero vãos ou quedas no vazio, avatar transita ereto na garagem sem cortes de câmera.

### Fase 3 — Interaction + Loot — CONCLUÍDA

- **Módulos**: `ItemDefinitions.lua`, `LootService.lua`, `InventoryService.lua`, `InteractionService.lua`.
- **Mecânicas**: Catálogo completo de itens categorizados por raridade (Bronze, Silver, Gold, Diamond, Art, SecretDocument, Cash). Bloqueio autoritativo de concorrência (*single-claim lock*) impedindo duplicação de itens entre múltiplos jogadores. Inventário com slots limitados e cálculo cumulativo de peso (Starter Bag: 6 slots / 15 kg; Professional Bag: 10 slots / 25 kg; Master Bag: 14 slots / 35 kg). Feedback visual no mundo via `Highlight` suave e etiqueta 3D (`BillboardGui`) exibindo valor e peso em studs.
- **Acceptance**: Coleta única e autoritativa; cálculo imediato de peso no inventário; zero duplicações em coletas simultâneas concorrentes.

### Fase 4 — Extraction — CONCLUÍDA

- **Módulos**: `ExtractionService.lua`, `RoundService.lua`.
- **Mecânicas**: Zonas de extração convencionais na calçada e rua (`FrontGateExtraction` em $Z \approx -115$ e `VanExtraction` em $Z \approx -140$). Validação autoritativa de raio físico ($\le 15$ studs do pad de extração) e tempo de permanência. Crédito de Cash e XP no perfil do jogador concedido apenas após extração bem-sucedida com a rodada em estado válido; zero pagamento em desconexões forçadas ou derrotas.
- **Acceptance**: Extração normal executada com sucesso; Cash creditado com integridade no servidor; bloqueio estrito de concessões antes do término da rodada.

### Fase 5 — Security & Stealth — CONCLUÍDA

- **Módulos**: `SecurityService.lua`.
- **Mecânicas**: Escala dinâmica de nível de alerta (0 = Normal a 5 = Crítico). Câmeras de segurança robotizadas com rotação contínua, detecção por raycast físico e barra gradual (`DetectionMeter`). Sistema de propagação de ruído calibrado por tipo de ação física (caminhar: 2, correr: 7, arrombar porta: 5, pé-de-cabra: 10, quebrar vidro: 18 studs). Disparo de Lockdown com sirenes de emergência perimétricas e luzes estroboscópicas vermelhas.
- **Acceptance**: Ações suspeitas elevam o nível de segurança; detecção visual acumula e dispara alertas; Lockdown inicia o timer de evacuação.

### Fase 6 — Guard AI (Segurança Privada) — CONCLUÍDA

- **Módulos**: `GuardService.lua`.
- **Mecânicas**: NPCs de segurança privada operando com 7 estados (`Patrol`, `Idle`, `Suspicious`, `Investigate`, `Search`, `Chase`, `ReturnToPost`). Linha de visão autêntica via produto escalar (`LookVector:Dot` $\ge \cos(55^\circ)$) e raycast físico contra paredes e mobílias (sem wall-hack). Reação a ruídos suspeitos e verificação de salas com itens roubados. Perseguição com velocidade equilibrada e retorno disciplinado ao posto.
- **Acceptance**: Guardas patrulham em rotas definidas, detectam apenas em linha de visão real e retornam aos seus postos quando o jogador quebra o contato.

### Fase 7 — Police Inbound — CONCLUÍDA

- **Módulos**: `RoundService.lua`, `PoliceService.lua`.
- **Mecânicas**: Contagem regressiva para cerco policial após roubo do cofre ou término da extração regular. Transmissão progressiva de rádio e avisos visuais no HUD em 60 s, 30 s e 15 s. Ativação antecipada de sirenes espaciais 3D e giroflex estroboscópico wig-wag nas viaturas policiais da rua ($Z = -132$). Bloqueio automático das extrações convencionais (`FrontGate` e `VanExtraction`) e transição imediata para `PoliceResponse`.
- **Acceptance**: Cronômetro regressivo operacional; alertas sincronizados em todos os clientes; transição perfeita para o cerco com viaturas ativas.

### Fase 8 — Police AI & Regras Táticas — CONCLUÍDA

- **Módulos**: `PoliceService.lua`, `PoliceAIService.lua`.
- **Mecânicas**: 3 arquétipos táticos (`PatrolOfficer` a 14.5 studs/s, `Interceptor` a 15.5 studs/s com cálculo preditivo `velocity * 1.5`, `Searcher` a 14.0 studs/s com varredura em leque). Blackboard tático no servidor (`LastKnownPlayerPosition`, `LastKnownPlayerTime`, `CurrentEscapeDirection`). Algoritmo de balanceamento de alvos para evitar filas únicas (*conga lines*). Uniformes táticos `PoliceAvatarStyleV2`.
- **Regras Táticas Especiais**:
  1. Policiais permanecem estritamente fora da mansão (`isInsideMansion` bloqueia a entrada deles na casa);
  2. Policiais só perseguem e buscam jogadores que tenham loot coletado no inventário (`LootValue > 0` e `#Loot > 0`);
  3. A rua além dos portões ($Z \le -118$) é área livre/neutra onde não ocorrem prisões e perseguições ativas são canceladas.
- **Acceptance**: Policiais perseguem e interceptam com inteligência, respeitam barreiras de paredes, não entram na mansão, ignoram jogadores sem saque e não prendem na rua.

### Fase 9 — Escape Mode & Galeria do Esgoto — CONCLUÍDA

- **Módulos**: `EscapeService.lua`.
- **Mecânicas**: Ativação de rotas de fuga alternativas pós-bloqueio com pads neon lilás `(200, 100, 255)` e ProximityPrompts: `ForestEscape`, `RooftopEscape` e `SewerEscape`.
- **Galeria Subterrânea do Esgoto Física e Rebaixada**: cota rebaixada para $Y = -12.60$ com vão livre vertical generoso de 10 studs (teto em $Y = -2.60$), garantindo passagem ereta e confortável do avatar sem cortes de câmera. Duas escadarias completas de alvenaria com 16 studs de desnível e parapeitos de contenção nos fundos da casa ($Z = 45$) e na calçada da rua ($Z = -163$). Túnel selado de 148 studs com passarelas laterais elevadas e canal central impermeável.
- **Bônus de extração policial autoritativo**: +300 XP e registro em estatísticas (`PoliceEscapes`).
- **Acceptance**: Rotas de fuga operacionais; descida, travessia subterrânea desimpedida e subida física no esgoto funcionando 100%; vitória possível no pós-bloqueio.

### Fase 10 — Weight + Drop Bag — CONCLUÍDA

- **Módulos**: `InventoryService.lua`, `DropBagService.lua`.
- **Mecânicas**: Redução física autoritativa de WalkSpeed baseada na carga carregada em 5 faixas (0–10 kg: 16.0 studs/s; 10–20 kg: 15.2 studs/s; 20–30 kg: 14.4 studs/s; 30–40 kg: 13.12 studs/s; >40 kg: 12.0 studs/s). Mecânica de Drop Bag via tecla `G` ou botão no HUD: esvaziamento imediato do inventário, restauração instantânea da velocidade para 16.0 studs/s (100%) e criação de bolsa física 3D no chão assentada via raycast (`DroppedBag` de lona bordô com Highlight e BillboardGui). Recolhimento validado por distância e capacidade de carga.
- **Acceptance**: Penalidade de peso precisa no Humanoid; descarte restaura velocidade instantaneamente; bolsa física transitável e recolhível por colegas.

### Fase 11 — Mecânica de Prisão (Arrest) — CONCLUÍDA

- **Módulos**: `PoliceAIService.lua`, `ArrestService`.
- **Mecânicas**: Iniciação de tentativa de prisão a curta distância ($\le 5.0$ studs). Duração gradual de 2.5 segundos em tempo real desacoplada de relógios acelerados. Barra de progresso visual `BeingArrested` com vinheta avermelhada e rádio policial. Interrupção imediata caso o jogador se afaste além de 8.5 studs, dobre esquinas, feche portas ou quebre a linha de visão. Estado `Busted` (100%): esvaziamento de loot, preservação de XP/ferramentas salvas, incremento de `TimesBusted` e teleporte individual seguro para o Lobby na rua (`(0, 3, -137)`), mantendo ativa a partida dos demais jogadores.
- **Acceptance**: Captura não instantânea; evasão por distância ou cobertura comprovada; teleporte e penalidades isolados por jogador.

### Fase 12 — Progressão & Skill Tree — CONCLUÍDA

- **Módulos**: `PlayerDataService.lua`, `HUDClient.client.lua`.
- **Mecânicas**: Sistema de XP e Níveis (1000 XP/nível com +1 SkillPoint por nível). Árvore de Habilidades com 9 perks em 3 ramos (Ghost: `SilentMovement`, `Darkness`, `FastHide`; Tech: `CameraLoop`, `SignalJammer`, `VaultCrack`; Thief: `HeavyCarry`, `BagSlots`, `ValueBoost`). Loja de ferramentas com bloqueio autoritativo por nível (requisitos do Nível 1 ao 10). Contratos secundários dinâmicos (`CashRun`, `SewerExit`, `SilentGallery`, `VaultJob`) e bônus de `Perfect Heist`. Modais interativos no HUD acionados por teclas `K` (Skills) e `B` (Shop).
- **Acceptance**: XP concedido server-side; árvore de habilidades funcional e persistente; compras bloqueadas se o nível for insuficiente e liberadas no nível correto.

### Fase 13 — Persistência Resiliente — CONCLUÍDA

- **Módulos**: `PlayerDataService.lua`.
- **Mecânicas**: Esquema de dados versionado (`BlackwoodHeist_PlayerData_v2`). Migração automática de versão v1 para v2 com concessão retroativa de pontos de habilidade. Mecanismo de resiliência com até 3 retries e backoff exponencial (0.2s, 0.4s, 0.8s) protegendo `GetAsync` e `UpdateAsync`. Camada de segurança Anti-Wipe (`DataLoadFailed`) que bloqueia salvamento se a carga inicial falhar, prevenindo sobrescrita acidental por perfis zerados. Salvamento paralelo e concorrente no `BindToClose` com timeout de 25 segundos. Mock DataStore determinístico para execução no Studio.
- **Acceptance**: Dados sobrevivem a disconnect/rejoin; retries recuperam falhas temporárias; proteção Anti-Wipe comprovada; salvamento concorrente validado no shutdown.

### Fase 14 — Economia & Monetização Ética — CONCLUÍDA

- **Módulos**: `EconomyService.lua`, `PurchaseService.lua`, `StreetShopService.lua`.
- **Mecânicas**: Catálogo de Developer Products (pacotes de Cash e XP Boost) e GamePasses (`ExtraLoadoutSlots`). Callback `ProcessReceipt` autoritativo, transacional e idempotente com registro de `PurchaseId` processados. Filosofia estrita Anti-Pay-to-Win: bloqueio total de compras e popups durante perseguição e prisão policial (`BeingArrested == true`); sem itens de vitória automática, teleporte para o cofre ou imunidade a dano. Interface de Loja com 3 abas ([EQUIPAMENTOS], [PASSES], [CONSUMÍVEIS]).
- **Acceptance**: Transações idempotentes sem duplicação de saldo; ausência total de vantagens desleais no core loop; interface clara com preços transparentes.

### Fase 15 — Polimento & Ambientação Visual Completa — CONCLUÍDA

- **Módulos**: `MapDetailsService.lua`, `LightingDetailsService.lua`, `PolishService.lua`.
- **Mecânicas**:
  1. Piscina Voxel com terreno de água volumétrica (`FillBlock`), deck de madeira em 4 segmentos perimetrais, nado físico nativo (`HumanoidStateType.Swimming`), escada de mármore e escada de inox com ProximityPrompt e som ambiente marinho (`WaterLapSound` `rbxassetid://9114223998`);
  2. Novo Parquinho 3D da Loja do Criador (Asset ID `9377320356`, `ScaleTo(0.65)`, 97 peças, base perfeitamente nivelada no gramado em $Y = 0.50$ em $X \approx 65, Z \approx 41.7$), com recuo das placas de horizonte distante;
  3. Portas interativas com animação de 90° via `TweenService` e fechamento de vãos na entrada principal;
  4. Frota de veículos alinhada ao asfalto em $Y = 0.35$ (2 viaturas em $Z = -132$ e van em $Z = -140$), com giroflex estroboscópico wig-wag de 8 Hz e sirenes de áudio espacial 3D (`rbxassetid://9119165131`);
  5. Garagem oeste com pé-direito de 12 studs e vão livre de 9.5 studs;
  6. Esgoto subterrâneo rebaixado para $Y = -12.60$, vão livre de 10 studs e escadas completas de 16 studs;
  7. Ciclo diurno desacelerado com início às 09:30 da manhã (`ClockTime = 9.5`) e duração total de 720 segundos (12 minutos);
  8. Regras táticas policiais ativas: atuação externa à mansão, perseguição focada em saqueadores e rua como área neutra;
  9. Cenário de horizonte com skyline urbano de neon ao Sul (171 peças), cinturão florestal (396 árvores) e montanhas (34 picos), otimizados para 60 FPS estáveis com até 16 jogadores;
  10. Tela de resumo de partida (*Round Summary Modal*) com telemetria detalhada de recompensas.
- **Acceptance**: Experiência estética cinematográfica, iluminação equilibrada, física aquática e de tráfego fluidas, e estabilidade de performance comprovada.

---

## 24. Playtests obrigatórios

Testar:

- partida sem alarme;
- alarme rápido;
- extração normal;
- timer expirando;
- polícia chegando;
- jogador escapando;
- jogador sendo preso;
- jogador soltando loot;
- jogador recolhendo bolsa;
- múltiplos jogadores perseguidos;
- um jogador extraindo enquanto outro permanece;
- todos capturados;
- Forest Escape;
- Sewer Escape;
- persistência após rejoin;
- compras e recompensas.

---

## 25. Regras de código

- usar Luau moderno;
- preferir `--!strict`;
- usar ModuleScripts;
- usar interfaces tipadas;
- centralizar configuração;
- usar `task.wait()`;
- separar services e controllers;
- evitar `wait()`;
- evitar scripts gigantes;
- evitar magic numbers;
- evitar duplicação;
- evitar estado global descontrolado.

Após cada fase:

1. fazer Play Test;
2. verificar Output;
3. corrigir erros;
4. testar multiplayer quando aplicável;
5. somente depois avançar.

Não avançar automaticamente para a próxima fase sem confirmação do usuário.

---

## 26. Exemplo de partida-alvo

Jogador entra pela garagem, desliga uma câmera, rouba laptop, encontra chave, abre o escritório, descobre o código e acessa o subsolo.

Abre o vault, carrega `$40.000`, o lockdown começa e o timer de extração inicia em 120 segundos.

Tenta a Van Extraction, fica preso na mansão e a polícia chega. A van é bloqueada. O jogador corre pelo jardim, um interceptor fecha a rota, ele retorna pela cozinha, desce ao subsolo, larga uma TV de `$12.000`, recupera velocidade, entra no Hidden Tunnel e escapa pelo Sewer Exit.

Resultado final: `$28.000` extraídos.

---

# 27. ATUALIZAÇÕES CONFIRMADAS NO STUDIO — ESPECIFICAÇÕES TÉCNICAS E AUDITORIA DETALHADA POR FASE

Esta seção documenta com rigor arquitetural, matemático e prático todas as 15 fases implementadas, configuradas e auditadas diretamente no Roblox Studio via Rojo e cliente MCP. Cada fase detalha seus componentes, algoritmos, coordenadas espaciais, modelos de dados e evidências de testes.

---

## Fase 1 — Fundação

- **Capacidade e Concorrência**: Configuração autoritativa de rede e servidor para suportar até **16 jogadores simultâneos** (`Config.MaxPlayers = 16`) em instâncias dedicadas.
- **Máquina de Estados de Rodada**: `RoundService` gerencia o ciclo de vida da partida com 11 estados sequenciais e determinísticos:
  ```text
  Lobby -> Preparation -> Infiltration -> Heist -> Lockdown
  -> Extraction -> PoliceInbound -> PoliceResponse -> Escape
  -> Completed / Failed
  ```
- **Sincronização de Rede e Remotes**:
  - `BlackwoodShared.Enums`: enumerações canônicas de estados, raridades, ferramentas e arquétipos;
  - `BlackwoodShared.GameConfig`: repositório centralizado de constantes físicas, durações e tabelas de balanceamento;
  - `BlackwoodRemotes`: RemoteEvents dedicados para replicação de estado de rodada, inventário, tentativas de prisão, compras, notificações e alertas visuais.
- **Interface e HUD**:
  - `HUDClient.client.lua`: interface adaptativa com telemetria em tempo real (estado da rodada, cronômetro regressivo, dinheiro, XP, peso e avisos policiais);
  - Mensagens e textos 100% localizados em português brasileiro (pt-BR);
  - Ocultação automática em runtime das legendas 3D de depuração de blocos do mapa, preservando a imersão.

---

## Fase 2 — Map Blockout & Arquitetura

- **Mansão Blackwood (Estrutura e Pavimentos)**:
  - Pavimento Térreo ($Y \in [0, 16]$): Sala de Estar, Sala de Jantar, Cozinha de Serviço, Biblioteca Clássica, Lavabo Social, Hall Principal e Acesso à Garagem;
  - Pavimento Superior ($Y \in [16, 32]$): Suíte Master, Galeria de Arte Privada, Quartos de Hóspedes, Banheiros e Varanda com Sacada Panorâmica;
  - Subsolo ($Y \in [-16, 0]$): Adega Climatizada, Sala de Máquinas, Infraestrutura Elétrica e Cofre Principal (*Main Vault*).
- **Vedação Estrutural e Arquitetural (Zero Furos)**:
  - Adicionadas 21 peças estruturais de alvenaria e lajes maciças (`EastLedgeSolidRoof`, `WestLedgeSolidRoof`) vedando os encontros de tetos e paredes das abas laterais;
  - Parapeitos selados em sacadas e varandas, eliminando 100% de vãos e passagens acidentais entre paredes;
  - Porta envidraçada instalada na varanda superior traseira com detector perimetral acusando 0 brechas.
- **Garagem Oeste Reconfigurada**:
  - Pé-direito interno ampliado para **12 studs de altura**;
  - Vão livre da entrada/portão elevado para **9.5 studs**, permitindo passagem desimpedida do avatar com armas ou bolsas sem clipping de câmera.
- **Portas Interativas com Abertura Realista**:
  - Sistema de tweening angular suave de 90° (`TweenService`) em dobradiças alinhadas, acionado por `ProximityPrompt` ("Abrir Porta" / "Fechar Porta");
  - Batentes ajustados na entrada principal da fachada, eliminando os antigos buracos e frestas abertas.
- **Fechamento Hermético do Terreno (`GardenGrounds`)**:
  - Reconstruído todo o solo da propriedade murada com 12 lajes sólidas de concreto e gramado cobrindo a área integral ($X \in [-125, 125]$, $Z \in [-118, 98]$) em $Y = 0$;
  - Auditoria com 378 pontos de raycast vertical confirmou 0 vazios e 0 quedas no infinito.
- **Remoção da Fonte e Paisagismo Frontal**:
  - Removida a fonte central desproporcional na frente da casa;
  - Substituída por canteiro paisagístico com passarela central de mármore e arbustos ornamentais integrados.

---

## Fase 3 — Interaction + Loot

- **Catálogo Centralizado (`ItemDefinitions.lua`)**:
  - 7 Categorias de itens: *Electronics, Jewelry, Art, Documents, Collectibles, Cash, Artifact*;
  - 6 Graus de raridade: *Common, Uncommon, Rare, Epic, Legendary, Artifact*;
  - Parâmetros individuais: `Id`, `Name`, `BaseValue`, `Weight`, `Size`, `NoiseLevel`, `SpawnWeight`, `CarryType`.
- **Controle de Concorrência e Bloqueio Atômico (*Single-Claim Lock*)**:
  - `LootService` utiliza trava atômica no servidor (`claimingPlayer`) ao processar a interação;
  - Se múltiplos jogadores pressionarem o prompt simultaneamente, apenas a primeira requisição validada pelo servidor captura o item; requisições concorrentes são rejeitadas, garantindo zero duplicação de itens.
- **Inventário e Mochilas**:
  - Starter Bag: 6 slots, capacidade máxima de 15 kg;
  - Professional Bag: 10 slots, capacidade máxima de 25 kg;
  - Master Bag: 14 slots, capacidade máxima de 35 kg;
  - Cálculo contínuo do peso total no servidor com atualização em tempo real para o cliente.
- **Feedback Visual de Saque**:
  - Efeito luminoso suave (`Highlight`) em itens interativos;
  - `BillboardGui` informativo flutuante exibindo nome, valor monetário (`$Valor`) e peso (`X.X kg`).

---

## Fase 4 — Extraction

- **Pontos de Extração Convencionais**:
  - `FrontGateExtraction` ($X \approx 0, Z \approx -115$): portão principal da propriedade;
  - `VanExtraction` ($X \approx -20, Z \approx -140$): furgão de fuga posicionado na rua externa.
- **Validação Física e Autoritativa**:
  - `ExtractionService` monitora a presença física do jogador a uma distância máxima de 15 studs do pad de extração;
  - Cronômetro de evacuação individual (3 segundos contínuos sobre o pad de extração para evitar ativações acidentais);
  - Validação estrita de estado da partida: extrações só são processadas nos estados `Extraction` ou `Escape`.
- **Garantia Transacional de Recompensa**:
  - Conversão do valor de saque acumulado no inventário em saldo permanente (`Cash`);
  - Aplicação de bônus de contratos ativos e multiplicador de `ValueBoost`;
  - Gravação autoritativa no perfil do jogador via `PlayerDataService`; zero concessão em caso de desconexão forçada ou captura policial.

---

## Fase 5 — Security & Stealth

- **Níveis de Segurança Progressivos**:
  - Nível 0 (Normal): vigilância de rotina, iluminação padrão;
  - Nível 1 (Suspeito): guardas investigam ruídos;
  - Nível 2 (Buscando): varredura ativa em salas;
  - Nível 3 (Alerta): segurança reforçada, tempos de reação reduzidos;
  - Nível 4 (Lockdown): sirenes de emergência acionadas, luzes estroboscópicas vermelhas, contagem de evacuação iniciada;
  - Nível 5 (Crítico): resposta tática policial chamada antecipadamente.
- **Câmeras Robotizadas com Cone de Visão**:
  - Movimento angular suave de varredura (pan de 90°);
  - Detecção volumétrica com cone de visão cônico e raycasting contínuo contra obstáculos físicos;
  - `DetectionMeter` progressivo: barra sobe gradualmente enquanto o jogador permanece no foco da câmera e decai ao quebrar a linha de visão; atingir 100% dispara alarme geral.
- **Sistema Físico de Propagação Sonora**:
  - Emissão de impulsos sonoros radiais baseados na ação do jogador:
    * Caminhada normal: raio de 2 studs;
    * Corrida (*Sprint*): raio de 7 studs;
    * Abertura forçada de porta: raio de 5 studs;
    * Uso de pé-de-cabra: raio de 10 studs;
    * Quebra de vidro: raio de 18 studs;
  - NPCs de guarda dentro do raio de alcance alteram seu estado para `Investigate` no local exato da origem do som.

---

## Fase 6 — Guard AI (Segurança Privada)

- **Máquina de Estados Autônoma**:
  - `Patrol`: caminhada cíclica entre waypoints predefinidos no mapa (`GuardPaths`);
  - `Idle`: pausa temporária para observação do ambiente;
  - `Suspicious`: rotação corporal na direção de estímulos sonoros;
  - `Investigate`: deslocamento até a origem de ruídos ou portas abertas;
  - `Search`: varredura local em leque por 6 segundos;
  - `Chase`: perseguição ativa em linha de visão direta com velocidade de 14 studs/s;
  - `ReturnToPost`: retorno disciplinado ao trajeto de patrulha original.
- **Linha de Visão Fisiológica Realista (Zero Wall-Hack)**:
  - Checagem baseada no produto escalar do vetor diretor:
    $$\vec{v}_{olhar} \cdot \frac{\vec{p}_{alvo} - \vec{p}_{guarda}}{\|\vec{p}_{alvo} - \vec{p}_{guarda}\|} \ge \cos(55^\circ)$$
  - Raycast físico confirmatório entre os olhos do guarda e o torso do jogador (`RaycastParams` ignorando outros NPCs);
  - Bloqueio completo da visão por portas fechadas, paredes, pilares e mobílias densas.

---

## Fase 7 — Police Inbound

- **Ativação da Resposta Policial**:
  - Disparado automaticamente ao término do `ExtractionTimer` ou quando o nível de segurança atinge o patamar crítico;
  - `RoundService` transiciona a partida para o estado `PoliceInbound`.
- **Avisos Progressivos e Comunicação Tática**:
  - Alertas sonoros de transmissão de rádio da polícia no HUD de todos os jogadores;
  - Contagem regressiva com avisos em 3 estágios: **60 segundos**, **30 segundos** e **15 segundos** para a invasão;
  - Notificações coloridas em amarelo, laranja e vermelho na tela dos jogadores.
- **Ativação Prévia dos Veículos na Rua**:
  - As viaturas policiais na entrada da rua ($Z = -132$) ativam seus giroflex estroboscópicos e sirenes de rádio 3D antes da chegada do comboio;
  - Bloqueio das saídas normais: pads de `FrontGate` e `VanExtraction` ficam vermelhos com aviso *"BLOQUEADO PELA POLÍCIA"*.
- **Preparação de Pontos de Spawn**:
  - 10 pontos de cerco configurados em `PoliceSpawns` com validação de distância mínima de segurança (mínimo de 35 studs de qualquer jogador, eliminando spawn colado).

---

## Fase 8 — Police AI & Novas Regras Táticas

- **Arquétipos Táticos Diferenciados**:
  - `PatrolOfficer` (Velocidade 14.5 studs/s): avanço direto em linha de visão (`Chase`) e busca no último local confirmado (`Investigate`);
  - `Interceptor` (Velocidade 15.5 studs/s): corte de caminho e bloqueio de rotas com cálculo preditivo vetorial da posição do fugitivo:
    $$\vec{p}_{alvo\_futuro} = \vec{p}_{jogador} + \vec{v}_{jogador} \times 1.5$$
  - `Searcher` (Velocidade 14.0 studs/s): varredura e cobertura tática em cômodos e esconderijos ao perder o contato visual.
- **Blackboard Tático Centralizado**:
  - Mantido no servidor compartilhando dados entre todas as unidades policiais:
    * `LastKnownPlayerPosition`
    * `LastKnownPlayerTime`
    * `CurrentEscapeDirection`
    * `ActiveSearchZones`
  - Se o jogador quebra a linha de visão virando uma esquina, os policiais se dirigem até o ponto exato da curva em vez de persegui-lo através de paredes sólidas.
- **Balanceamento de Alvos (Anti-Conga Line)**:
  - Algoritmo de ponderação (`findPoliceTarget`) penaliza jogadores que já possuem policiais designados, distribuindo o cerco entre múltiplos fugitivos.
- **Visual e Uniformes Oficiais**:
  - Bonecos Roblox estilizados com fardamento azul-marinho, colete balístico tático com inscrição *"POLÍCIA"*, distintivo dourado com estrela, rádio comunicador no ombro, gravata, cinto de utilidades e boné tático (`PoliceAvatarStyleV2`).
- **Regras Táticas Refinadas Aplicadas**:
  1. **Atuação Estritamente Externa**: Policiais não entram no interior da casa. O delimitador físico `isInsideMansion` ($|X| \le 44.5, |Z| \le 31.5, Y \in [-0.5, 30]$) bloqueia perseguição interna; os policiais cercam as portas, janelas e o perímetro externo do jardim.
  2. **Perseguição Exclusiva a Saqueadores**: Policiais só caçam e algemam jogadores que estejam carregando loot roubado (`LootValue > 0` e `#Loot > 0`); jogadores sem saque são ignorados pelas unidades policiais.
  3. **Rua como Área Livre / Zona Neutra**: A rua externa e a calçada além dos portões ($Z \le -118$) constituem zona neutra/segura. Policiais não iniciam tentativas de prisão na rua e qualquer perseguição em andamento é cancelada imediatamente quando o fugitivo alcança $Z \le -118$.

---

## Fase 9 — Escape Mode & Galeria do Esgoto

- **Rotas de Emergência Ativas**:
  - Ao transicionar para `Escape`, rotas convencionais permanecem bloqueadas e são liberadas as rotas de emergência:
    * `ForestEscape` ($X \approx -110, Z \approx 40$): fuga pela cerca rompida na mata oeste;
    * `RooftopEscape` ($X \approx 0, Z \approx 10, Y \approx 33$): tirolesa no telhado superior;
    * `SewerEscape` ($X \approx 48, Z \approx -163$): saída subterrânea pela galeria do esgoto.
  - Pads sinalizados com neon lilás vibrante `(200, 100, 255)` e letreiros 3D *"ROTA DE FUGA ATIVA!"*.
- **Galeria Subterrânea do Esgoto Física e Rebaixada (`SewerEscape`)**:
  - **Cota Rebaixada do Piso**: Piso rebaixado para $Y = -12.60$, com teto em $Y = -2.60$, oferecendo **vão livre vertical de 10 studs**. O avatar transita com postura ereta e câmera totalmente desobstruída, sem qualquer corte no personagem.
  - **Escadaria de Descida nos Fundos ($Z = 45$)**: Escada de alvenaria com 16 studs de desnível descendo de $Y = 0.50$ até a cota subterrânea $Y = -12.60$, com paredes de contenção de tijolo e parapeito de ferro fundido com placa *"ACESSO AO ESGOTO"*.
  - **Túnel Subterrâneo Contínuo de 148 Studs**: Extensão contínua passando por baixo da mansão e do jardim, com piso de concreto impermeável, canal central de escoamento de água suja (onde o jogador pode pisar sem cair no void), passarelas elevadas nas laterais, arcos de reforço estrutural com lâmpadas industriais e tubulações metálicas.
  - **Escadaria de Subida na Rua Externa ($Z = -163$)**: Escadaria de alvenaria com 16 studs de desnível subindo de $Y = -12.60$ até a calçada externa em $Y = 0.50$, emergindo ao lado do furgão de fuga e do pad `Sewer_Pad` ($Z = -163$).
- **Recompensas e Telemetria**:
  - Fuga bem-sucedida pelo modo Escape concede bônus de **+300 XP de Fuga Policial**;
  - Incremento persistente no contador de estatísticas `PoliceEscapes`.

---

## Fase 10 — Weight + Drop Bag

- **Escala de Penalidade de Peso Autoritativa**:
  - Velocidade base do jogador: 16.0 studs/s;
  - Tabela escalonada de penalidade por peso acumulado no inventário:
    * 0 a 10 kg: 100% de velocidade (16.0 studs/s);
    * 10 a 20 kg: 95% de velocidade (15.2 studs/s);
    * 20 a 30 kg: 90% de velocidade (14.4 studs/s);
    * 30 a 40 kg: 82% de velocidade (13.12 studs/s);
    * Superior a 40 kg (carga pesada): 75% de velocidade (12.0 studs/s).
- **Mecânica de Drop Bag (Tecla G e Botão Interativo)**:
  - Acionamento rápido por teclado (tecla `G`) ou botão virtual na interface gráfica (`"LARGAR BOLSA [G]"`), disponível em todas as fases ativas da partida;
  - Esvaziamento instantâneo do inventário de loot do jogador;
  - Restauração imediata da velocidade de caminhada para 16.0 studs/s (100%), permitindo arrancadas de sprint em momentos de perseguição;
  - Instanciação de bolsa física 3D no mundo (`DroppedBag`): assentada no solo via raycast (`Anchored = true`, `CanCollide = true`), modelada em lona bordô com tiras de couro, contorno `Highlight` dourado, `BillboardGui` informando valor total e peso, e `ProximityPrompt` ("Recuperar Bolsa").
- **Recolhimento Seguro e Cooperativo**:
  - Qualquer jogador pode recolher a bolsa caída, desde que possua espaço livre e capacidade de carga compatível na sua mochila;
  - Ao recolher, o loot é reintegrado ao inventário, a velocidade do jogador é recalculada e a bolsa no chão é destruída no servidor.

---

## Fase 11 — Mecânica de Prisão (Arrest)

- **Iniciação Gradual de Tentativa de Prisão (`ArrestAttempt`)**:
  - A tentativa de prisão é iniciada por policiais ou guardas em perseguição a uma distância física de até **5.0 studs** (`Config.Police.ArrestDistance`);
  - Duração contínua calibrada em **2.5 segundos de tempo real** (desacoplada de relógios de rodada acelerados), oferecendo janela atlética e justa de reação para evasão;
  - Atributos sincronizados no personagem: `BeingArrested = true` e `ArrestProgress` (0% a 100%);
  - O policial desacelera e focaliza o fugitivo, emitindo aviso de voz e rádio.
- **Condições de Interrupção e Cancelamento**:
  - A tentativa é imediatamente cancelada caso:
    1. O jogador se afaste além de **8.5 studs** (`Config.Police.BreakArrestDistance`);
    2. O jogador dobre uma esquina, feche uma porta ou coloque mobília sólida na linha de visão (`Raycast`);
    3. O jogador cruze os portões em direção à rua ($Z \le -118$);
    4. O jogador utilize granada de fumaça (`SmokeCanister`).
  - Ao cancelar: `BeingArrested` torna-se `false`, a barra zera imediatamente e o HUD sinaliza em verde *"ESCAPOU DA PRISÃO!"*.
- **Interface e Feedback no HUD**:
  - Vinheta periférica avermelhada pulsante na tela;
  - Painel central com card de alerta *"TENTATIVA DE PRISÃO"*, barra de progresso em tempo real (0% a 100%) e orientação em destaque: *"AFASTE-SE OU QUEBRE A LINHA DE VISÃO!"*;
  - Tela modal imersiva de `BUSTED` (*"PRESO!"*) exibida ao atingir 100%.
- **Consequências do BUSTED e Teleporte Seguro**:
  - Perda do loot não extraído carregado na mochila e peso zerado;
  - Preservação integral do XP parcial (+50 XP de consolação), ferramentas permanentes e progresso salvo;
  - Incremento no contador de estatísticas persistente `TimesBusted`;
  - Teleporte individual seguro para o Spawn do Lobby na rua (`(0, 3, -137)`) com `ForceField` protetor;
  - **A partida dos demais membros da equipe continua ativa na mansão** sem interrupção.

---

## Fase 12 — Progressão & Skill Tree

- **Sistema de XP e Níveis**:
  - Fórmula linear progressiva: cada nível requer 1000 XP (`math.floor(XP / 1000) + 1`);
  - Ao subir de nível, o jogador recebe autoritativamente **+1 Ponto de Habilidade (`SkillPoints`)**;
  - Interface no HUD com barra de progresso contínua e notificação animada de celebração de Level Up.
- **Árvore de Habilidades com 3 Ramos Temáticos (`SkillTree`)**:
  - **Ramo Ghost (Furtividade)**:
    * `SilentMovement`: passos 100% silenciosos ao correr;
    * `Darkness`: camuflagem em áreas de sombra, reduzindo o cone de visão dos NPCs em 25%;
    * `FastHide`: velocidade de interação dobrada com esconderijos e armários.
  - **Ramo Tech (Tecnologia & Hacking)**:
    * `CameraLoop`: congelamento de sinal de câmeras de segurança prolongado por +10s;
    * `SignalJammer`: atraso adicional de 20s na chamada de reforços policiais via rádio;
    * `VaultCrack`: redução de 30% no tempo de abertura do cofre principal.
  - **Ramo Thief (Loot & Carga)**:
    * `HeavyCarry`: alívio de sobrepeso concedendo +10% de velocidade quando carregando mochilas pesadas;
    * `BagSlots`: +2 slots adicionais de inventário permanente;
    * `ValueBoost`: bônus passivo de +10% de Cash em todo o loot extraído com sucesso.
- **Loja de Ferramentas com Requisito de Nível (*Level Gate*)**:
  - Catálogo de ferramentas desbloqueadas progressivamente:
    * Nível 1: `Lockpick`, `Flashlight`, `BasicBag` (gratuitos/iniciais);
    * Nível 2: `GlassCutter` ($8.000);
    * Nível 3: `Decoy` ($6.000), `Scanner` ($7.000);
    * Nível 4: `SignalJammer` ($9.000);
    * Nível 5: `ProfessionalBag` ($12.000, 25 kg);
    * Nível 6: `CameraLoop` ($11.000);
    * Nível 7: `SafeDrill` ($14.000);
    * Nível 10: `MasterBag` ($25.000, 35 kg).
- **Contratos e Desafios Secundários**:
  - Validação autoritativa na extração para contratos ativos (`CashRun`, `SewerExit`, `SilentGallery`, `VaultJob`) com bônus de Cash (+$2.500 a +$5.000) e XP (+250 a +500 XP);
  - Recompensa de **Perfect Heist** (+500 XP) ao extrair sem acionar alarmes.
- **Navegação no HUD**:
  - Modal da Árvore de Habilidades acionado via tecla **`K`**;
  - Modal do Catálogo da Loja acionado via tecla **`B`**.

---

## Fase 13 — Persistência Resiliente

- **Esquema de Dados Versionado (`v2`)**:
  - Armazenamento em `BlackwoodHeist_PlayerData_v2` contendo campos estruturados:
    `Cash`, `XP`, `Level`, `SkillPoints`, `UnlockedSkills`, `OwnedTools`, `OwnedCosmetics`, `Loadouts`, `Statistics`, `Collections`, `Settings`, `SeasonProgress`.
- **Migração Automática de Esquema (`Migrate`)**:
  - Detecção automática de dados legados (< v2);
  - Conversão de esquema sem perda de dados históricos;
  - Concessão retroativa de pontos de habilidade faltantes com base no nível atingido e perícias já adquiridas:
    $$\text{expectedPoints} = (\text{Level} - 1) - \#(\text{UnlockedSkills})$$
- **Resiliência de Rede com Exponential Backoff**:
  - Rotina `retryAsync` protege chamadas de `GetAsync` e `UpdateAsync` com até 3 tentativas sucessivas com atrasos crescentes (0.2s, 0.4s, 0.8s), tolerando oscilações momentâneas nos servidores do Roblox.
- **Proteção Anti-Wipe**:
  - Se o carregamento inicial falhar criticamente, o perfil é marcado com o atributo `DataLoadFailed = true`;
  - Qualquer tentativa posterior de salvamento (`PlayerRemoving`, salvamento periódico ou shutdown) é **estritamente bloqueada**, impedindo que um perfil vazio sobrescreva os dados reais do jogador na nuvem.
- **Encerramento Seguro do Servidor (`BindToClose`)**:
  - Orquestração de salvamento paralelo de todos os jogadores conectados via `task.spawn` com timeout de 25 segundos antes do desligamento da instância.
- **Mock DataStore de Alta Fidelidade**:
  - Suporte automático no Roblox Studio com emulação local em memória quando APIs externas não estão ativadas, permitindo testes sem erros no console.

---

## Fase 14 — Economia & Monetização Ética

- **Developer Products (Consumíveis de Apoio)**:
  - `CashPackSmall`: concede +$5.000 de saldo bancário imediato;
  - `XPBoost`: concede +1.000 XP imediato, disparando cálculo de Level Up e pontos de habilidade;
  - Catálogo preparado para expansão com tokens cosméticos e reroll de contratos.
- **GamePasses (Conveniência e Expansão)**:
  - `ExtraLoadoutSlots`: concede autoritativamente +2 slots de inventário em runtime para transporte de ferramentas;
  - `SupporterPack` e cosméticos exclusivos preparados para lançamento público.
- **Garantia Transacional e Idempotência (`ProcessReceipt`)**:
  - O callback `MarketplaceService.ProcessReceipt` armazena a lista de `PurchaseId` processados no histórico permanente do jogador;
  - Se o Roblox retransmitir o mesmo `PurchaseId`, o servidor identifica a duplicidade e retorna imediatamente `Enum.ProductPurchaseDecision.PurchaseGranted` sem aplicar o saldo novamente, eliminando duplicações acidentais.
- **Diretriz Anti-Pay-to-Win Estrita**:
  - Bloqueio absoluto de compras e popups comerciais quando o jogador está em perseguição ativa ou sofrendo tentativa de prisão (`BeingArrested == true`);
  - Nenhum produto vende vitória automática, teleporte mágico para dentro do cofre, fuga instantânea da polícia ou invulnerabilidade;
  - Todo o núcleo de progressão, ferramentas e mochilas avançadas é plenamente conquistável jogando com Cash obtido nas partidas.
- **Interface da Loja (`ShopModal`)**:
  - Interface com 3 abas temáticas ([EQUIPAMENTOS], [PASSES & ROBUX], [CONSUMÍVEIS DE RUA]) com descrição explícita de itens e valores.

---

## Fase 15 — Polimento & Ambientação Visual Completa

- **Piscina Voxel com Nado Físico Nativo**:
  - Remoção da cobertura de madeira suspensa e do vidro estático original;
  - Construção de deck de madeira perimetral em 4 segmentos contornando as margens da piscina (`DeckWest`, `DeckEast`, `DeckSouth`, `DeckNorth`);
  - Bacia preenchida com água volumétrica Voxel do terreno via:
    ```lua
    workspace.Terrain:FillBlock(
        CFrame.new(-72, -1.75, 5),
        Vector3.new(20.4, 3.5, 34.4),
        Enum.Material.Water
    )
    ```
  - Propriedades de água translúcida configuradas no Terrain (`WaterColor = Color3.fromRGB(30, 160, 215)`, `WaterTransparency = 0.40`, `WaterWaveSize = 0.15`);
  - Nado nativo automático ao submergir (`Enum.HumanoidStateType.Swimming = true`);
  - Escadaria submersa de mármore transitável na extremidade sul e escada vertical de aço inox com `ProximityPrompt` de saída rápida na borda norte gerida pelo `PoolLadderService`;
  - Áudio ambiente marinho suave em loop contínuo (`WaterLapSound` - `rbxassetid://9114223998`).
- **Novo Parquinho 3D da Loja do Criador (Asset ID `9377320356`)**:
  - Inserção do modelo oficial de playground da Loja do Criador (`parquinho stark`), composto por 97 peças detalhadas (escorregadores curvos e retos em espiral, torres com telhados cônicos coloridos, pontes suspensas de madeira e estrutura de balanços);
  - Escalonamento proporcional via método oficial `ScaleTo(0.65)`;
  - Posicionamento perfeito no gramado leste ($X \approx 65, Z \approx 41.7$) com a base nivelada em $Y = 0.50$;
  - Recuo das placas de horizonte distante leste e sul (`DistantLandscapeBaseEast` para $X \ge 125$ e `DistantLandscapeBaseSouth` para $Z \le -165$), eliminando interferências visuais no playground.
- **Portas Interativas e Fechamento da Fachada**:
  - Portas da mansão operando com abertura e fechamento angular de 90° acionadas por `TweenService` e `ProximityPrompt`;
  - Alinhamento dos batentes da porta principal da fachada, fechando vãos e buracos que existiam na alvenaria.
- **Frota de Veículos Alinhada ao Asfalto e Sirenes Espaciais 3D**:
  - Duas viaturas policiais modulares (`PoliceCruiser_West` e `PoliceCruiser_East`) posicionadas na entrada da rua ($Z = -132$) e van de fuga dos assaltantes (`GetawayVan`) posicionada em $Z = -140$;
  - Pneus e chassis nivelados perfeitamente com a superfície do asfalto em $Y = 0.35$, eliminando o afundamento dos veículos no chão;
  - Giroflex estroboscópico wig-wag com alternância realista em frequência de 8 Hz entre vermelho neon e azul neon com fontes de luz `PointLight` dinâmicas;
  - Sirene policial espacial 3D em alta fidelidade (`rbxassetid://9119165131`), com atenuação física por distância e RollOff acústico linear.
- **Garagem Oeste e Galeria do Esgoto com Pé-Direito Ampliado**:
  - Garagem oeste com teto elevado para 12 studs e vão livre do portão para 9.5 studs, sem clipping de avatar;
  - Galeria subterrânea do esgoto rebaixada para $Y = -12.60$, com vão livre vertical de 10 studs e escadarias completas de alvenaria com 16 studs de desnível em $Z = 45$ e $Z = -163$.
- **Ciclo Diurno e Passagem de Tempo Desacelerada**:
  - O jogo inicia sob a luz do dia ensolarado às **09:30 da manhã** (`ClockTime = 9.5`);
  - Duração do ciclo de 24 horas desacelerada para **720 segundos (12 minutos)** (`TimeCycleDuration = 720`), proporcionando transições graduais e cinematográficas entre manhã, tarde e noite sem mudanças bruscas de iluminação.
- **Cenário de Horizonte Imersivo & Otimização de Performance**:
  - Skyline urbano iluminado ao Sul com 171 peças de arranha-céus, janelas iluminadas e antenas de neon;
  - Cinturão florestal denso com 396 árvores ao redor dos muros da propriedade e 34 picos de montanhas poligonais ao Norte, Leste e Oeste;
  - Otimização rigorosa para até 16 jogadores: peças do horizonte com `CanCollide = false` e `CastShadow = false`, garantindo estabilidade de 60 FPS.
- **Tela de Resumo de Fim de Partida (`Round Summary Modal`)**:
  - Modal integrado ao HUD exibido ao final da rodada com telemetria detalhada de desempenho:
    * Status da missão: Sucesso na Extração ou Capturado pela Polícia (*Busted*);
    * Valor monetário total roubado e convertido em saldo;
    * Bônus adicionais de contratos concluídos e multiplicador de perícia;
    * Ganho de XP total e progresso para o próximo nível;
    * Saldo bancário atualizado pós-partida.

---

## Validações e Testes Concluídos no Roblox Studio

- **Auditoria de Arquitetura e Estrutura**: Mansão com 13 cômodos, 98 paredes e portas interativas, 151 peças de mobília, garagem com vão livre de 9.5 studs e lajes superiores 100% vedadas com 0 furos no detector perimetral.
- **Física Aquática e Nado**: Bacia da piscina preenchida com água Voxel, entrada e saída física fluida, transição automática para o estado de nado `Swimming` e escada de inox com prompt interativo de saída validada no `PoolLadderService`.
- **Playground 3D da Loja do Criador**: Asset oficial `9377320356` carregado com 97 peças, escalado proporcionalmente a 0.65, com base perfeitamente nivelada no gramado leste em $Y = 0.50$ sem invasão das placas distantes de horizonte.
- **Veículos e Sinalização**: 2 viaturas e furgão alinhados ao asfalto em $Y = 0.35$, giroflex wig-wag estroboscópico duplo funcional e sirene de áudio 3D (`rbxassetid://9119165131`) com resposta acústica espacial.
- **Galeria do Esgoto**: Descida a pé no jardim traseiro ($Z = 45$), travessia dos 148 studs de extensão em cota rebaixada $Y = -12.60$ com vão de 10 studs (sem corte de avatar), e subida na calçada da rua ($Z = -163$) com ativação da rota de fuga de emergência.
- **IA Policial Tática**: Policiais respeitam a regra de não entrar na mansão, priorizam apenas alvos que possuem loot roubado e não efetuam prisões na rua ($Z \le -118$).
- **Mecânica de Prisão (Arrest)**: Iniciação gradual de 2.5 segundos em tempo real, cancelamento comprovado ao afastar-se além de 8.5 studs ou dobrar esquinas, e conclusão com captura individual para o Spawn do Lobby sem prejudicar colegas de equipe.
- **Física de Peso e Drop Bag**: Comprovada a curva de 5 faixas de velocidade (16.0 a 12.0 studs/s) e restauração instantânea da velocidade ao largar a bolsa física de assalto com a tecla `G`.
- **Progressão e Loja com Level Gate**: Concessão de XP e pontos de habilidade, desbloqueio de perks na Skill Tree, bloqueio de compra por nível insuficiente e liberação autoritativa no nível correto.
- **Persistência Anti-Wipe**: Testes determinísticos de salvamento, reconexão (disconnect/rejoin), proteção contra corrupção com retenção de 100% dos atributos e salvamento paralelo em `BindToClose`.
- **Monetização Idempotente**: Entrega de Developer Products e GamePasses com garantia transacional via `ProcessReceipt` idempotente e bloqueio estrito durante perseguições policiais.
- **Ciclo de Tempo Diurno**: Avanço suave do relógio com início às 09:30 da manhã e ciclo de 720 segundos verificado via `TimeOfDayService`.

---

## Diretrizes para Futuras Implantações e Expansões

1. **Testes de Concorrência Massiva em Servidores Públicos**:
   - Conduzir testes com 16 jogadores simultâneos reais nos servidores da nuvem do Roblox para avaliar a latência de replicação dos estados policiais e distribuição de alvos em rede de alta latência.
2. **Adição de Novos Mapas e Contratos**:
   - A arquitetura modular desenvolvida (`RoundService`, `MapBuilder`, `SecurityService`, `PoliceAIService`) permite a criação de novas propriedades (ex: Museu Histórico, Cobertura de Luxo) reutilizando 100% da lógica central de assalto, segurança e fuga.
3. **Expansão de Ferramentas e Gadgets**:
   - Implementação de novos dispositivos situacionais (ex: grampo magnético para câmeras, fumaça holográfica, cortador a laser) respeitando as restrições éticas sem pay-to-win.
4. **Modo Competitivo Indireto / Tabela de Líderes**:
   - Criação de leaderboards globais baseados nas estatísticas persistidas no DataStore (`SuccessfulHeists`, `PerfectHeists`, `PoliceEscapes`, `HighestLoot`).
