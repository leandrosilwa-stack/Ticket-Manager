# Roteador e Monitor de Chamados — Regras Implementadas

> **Versão:** `vYYYY.MM.DD-hhmm` dinâmica via `document.lastModified` (`index.html:1804` `updateVersionDisplay`)  
> **Stack:** HTML + Tailwind CDN + Supabase (`acessos`, `tickets`, `analysts`, `absences`, `slas`, `feriados`) + GitHub Pages  
> **Arquivo principal:** `Ticket Manager/index.html` + `supabase-schema.sql`

---

## 1. Navegação (Sidebar)

- **Menus (7):** `Gerenciamento de Chamados` (`tabContentChamados`), `Painel do Roteador` (`tabContentRoteador`), `Produtividade` (`tabContentProdutividade`), `Histórico de Produtividade` (`tabContentHistorico`), `Gerenciamento de Analistas` (`tabContentAnalistas`), `Painel do Líder` (`tabContentLider` — senha `lider@softplan`), `Administração` (`tabContentAdministracao` — senha `lider@softplan`)
- **Troca:** `switchTab(tabName)` (`index.html:1915`) com `activeClass`/`hidden` toggle + `sessionStorage` para senhas
- **Header:** `Supabase Online/Modo Local` (`updateSupabaseStatus`), data atual, versão

---

## 2. Gerenciamento de Chamados (`tabContentChamados`)

### 2.1. Chamados Roteados (ex-Histórico de Chamados em Atendimento)
- **Título:** `Chamados Roteados`
- **Colunas:** `todos (checkbox)` | `Chamado` | `Analista` (filtro `ticketAnalystFilter` abaixo do label) | `Status` (`Ag. atendimento` sky, `Em atendimento` emerald, `Ag. cliente` amber, `Concluído` slate, `Ações do Roteador` indigo) | `Abertura` | `Vencimento` | `Aging` (termômetro)
- **Filtro Analista:** abaixo do label (`flex-col`), `Todos (N)` + por analista; `handleAnalystFilterChange`
- **Aging:** `calculateThermometer(open, due, ticket)` (`index.html:3446`) com `getEffectiveElapsedMs` (desconta `totalPausedMs` e pausa `ag. cliente`), cores: `<50% emerald`, `50-85% amber`, `≥85% rose`, `>100% vencido rose-600`, `pausado slate`
- **Ordenação Aging:** `ticketSortSelect` (`THERMO_DESC/ASC`) + botão `toggleThermoSort`, `sortTicketsList` via `getTicketThermoPercent`
- **Dados ativos:** `allActiveTickets = status === 'em atendimento' || 'ag. atendimento'` (exclui `ag. cliente`/`ações do roteador` que vão para outros painéis)
- **Paginação:** 10/página, `ticketsPagination`
- **Toolbar:** `Tomar Posse` (emerald) → `em atendimento` com `posseAt`, `Atualizar Status` (sky) → modal `ag. cliente` (pausa) / `concluído` (só de `em atendimento`), `Concluir` (indigo, só `em atendimento` → `concluído`), `Atualizar Prazos` (slate, só re-render)
- **Prioridade:** checkbox `ticketPrioridade` ao lado de `Número do Chamado`; se marcado, `t.prioridade=true` e `text-red-600` + `fa-flag` no número

### 2.2. Chamados Ag. Cliente
- **Colunas:** `todos` | `Chamado` | `Analista` (com filtro `agClienteAnalystFilter` abaixo) | `Data Ag. Cliente` (`pausedAt` formatado)
- **Dados:** `status === 'ag. cliente'`, ordenado por `pausedAt` desc, filtrável por analista
- **Ação:** `Devolver chamado` → move para **Ações do Roteador** (`status='ações do roteador'`, estende `dueDate` por `pauseMs`, limpa `pausedAt`), via `confirmDevolvido()` + modal `devolvidoModal`

### 2.3. Dashboard de Atendimentos
- **Título:** `Dashboard de Atendimentos` (sem botão Zerar, movido para Administração)
- **Lista densa (sem Aging):** `table` com `thead sticky`, `# | Analista (avatar, Ativo/Ausente) | Recebidos (mês) | Média/dia | No Prazo | Fora`, ordenado por menor média (`getAnalystAverage`), `renderStats()` gera `tr`
- **Métricas por analista:** `getAnalystStats` com `monthReceived`, `average = monthTickets/dias úteis trabalhados`, `inProgress` inclui `em atendimento`/`ag. atendimento`/`ag. cliente`/`ações do roteador`, `onTime`/`late` via `checkTicketOnTime`

---

## 3. Painel do Roteador (`tabContentRoteador`)

Posicionado abaixo de `Gerenciamento de Chamados` na sidebar.

### 3.1. Novo Chamado Individual
- **Campos:** `Número do Chamado` (numérico, único via `isTicketExists`, erro `Número já cadastrado!`), `PRIORIDADE` checkbox ao lado, `Tipo de chamado` (`select#ticketTipo` populado de `slas` via `populateTicketTipoSelect`), `Data de Abertura` (`DD/MM/YY HH:MM:SS`)
- **Validação:** `validateForm()` exige `número+abertura+tipo+analista`, desabilita `Enviar` se inválido
- **Envio:** `handleFormSubmit()` pega `slaHoras = getSlaHoras(tipo)` (via `normalizeDescricao`), calcula `dueDate = addBusinessHours(openDate, slaHoras)` (8h/dia, 08-12/13-17, pula fds/feriados), cria `ticket` com `status='ag. atendimento'`, `tipo`/`descricao` = tipo, `prioridade`, `posseAt=null`, roteia para `analystsQueue[0]` (menor média)

### 3.2. Importar Chamados em Lote (CSV)
- **Botões:** `Arquivo CSV Em Atendimento` (`importBatchTickets`) e `Arquivo CSV Ag. Priorização` (`importBatchPriorizacao`)
- **Em Atendimento (6 colunas):** `ID do Avô, Descrição do status, Prazo Ajustado (vencimento ISO), Relatado Por, Proprietário, Descrição` — só `Proprietário vazio` entra, `abertura = now` (importação), `vencimento = Prazo Ajustado` convertido `isoToBr` (`dd/mm/yyyy hh:mm:ss`), ignora se `Proprietário` preenchido; exige cabeçalho com `Prazo Ajustado`, senão alerta para usar o outro botão
- **Ag. Priorização (3 colunas):** `Solicitação de Serviço, Descrição do status, Descrição` — `abertura = now`, `vencimento via SLA` (`getSlaHoras(descricao)` → `addBusinessHours`), `status='em atendimento'` + `posseAt=abertura`, roteio padrão; se `Prazo Ajustado` existir no header, alerta para usar Em Atendimento
- **Comum:** valida `isTicketExists`, roteia via `analystsQueue[0]`, `status` (`ag. atendimento` ou `em atendimento` para priorização), `showBatchResultModal` com importados/ignorados

### 3.3. Analistas (Fila)
- **Lista:** `analystListContainer` com `radio` por analista disponível (`analystsQueue` ordenado por `getAnalystAverage`), `Sugestão Ideal` no topo, `média diária` + `ativos`, badge `X disponíveis`
- **Regra fila:** `sortAnalystsQueue()` ordena disponíveis (`!isAnalystAbsent`) por `average` asc, desempate alfabético

### 3.4. Redistribuir chamados
- **Painel:** `Redistribuir chamados` com botões `Redistribuir` (manual) e `Redistribuir Ausentes`
- **Redistribuir (manual):** `openManualRedistributeModal()` lista **todos** os chamados ativos (`ag. atendimento`/`em atendimento`/`ag. cliente`/`ações do roteador`) ordenados por Aging, cada linha com `select` de analistas (`analystsQueue`, `Sugestão Ideal` sem pré-seleção, `Selecione` padrão); `confirmManualRedistribute()` só move onde `select` foi escolhido
- **Redistribuir Ausentes:** `openRedistributeModal()` filtra `tickets` onde `isAnalystAbsent(analyst)` e `status` ativo, `computeRedistributePlan` sugere destino por fila simulada, modal mostra `select` para escolher destino (lista `analystsQueue`), `confirmRedistribute()` usa valor escolhido

### 3.5. Ações do Roteador
- **Colunas:** `Chamado` | `Analista` (filtro) | `Status` (`Ações do Roteador`) | `Vencimento` | `Ação` (botão `devolver` por linha)
- **Dados:** `status === 'ações do roteador'`, filtrável, ordenado por `pausedAt`/`openDate` desc
- **Ação:** `devolverAcoesRoteador(number)` → `status='em atendimento'`, `posseAt = now`, volta para **Chamados Roteados**

### 3.6. Solicitações de Prioridades
- **Painel independente** abaixo de **Ações do Roteador**, dentro de `Painel do Roteador`
- **Dados:** todos `abertos` (`status !== 'concluído'`), ordenados por `openDate` asc
- **Colunas:** `todos` | `Chamado` (vermelho se `prioridade`) | `Analista` | `Status` | `Abertura` | `Ação` (`Priorizar`)
- **Ação:** `openPriorizarModal(number)` → `priorizarModal` com `Chamado/Analista/Status/Abertura`, `confirmPriorizar()` seta `prioridade=true` e número fica vermelho (`text-red-600` + `fa-flag`)

---

## 4. Produtividade (`tabContentProdutividade`)

- **Filtros:** `Período` (`month`/`all`)
- **KPIs:** `Recebidos`, `Resolvidos` (`concluído`), `Em Atendimento` (`em atendimento`/`ag. atendimento`/`ag. cliente`/`ações do roteador`), `I.E. SLA` (`No Prazo ÷ Resolvidos`), `I.E. Qtd` (`Resolvidos ÷ Recebidos`) com anéis e tendência vs mês anterior
- **Tabela por analista:** `Recebidos`, `Resolvidos`, `Em Atendimento`, `Cumprimento SLA` (`No Prazo/Fora`), `I.E. SLA`/`I.E. Qtd` com barras e badges, ordenada por `I.E. Qtd` desc

---

## 5. Histórico de Produtividade (`tabContentHistorico`)

- **Filtros obrigatórios:** `Analista` (Todos/nome) + `Status` (`Todos`/`Em andamento` (`em atendimento`+`ag. atendimento`+`ag. cliente`+`ações do roteador`)/`Concluídos` (`concluído`)), `Período` opcional `Início`/`Fim` (mês/ano, filtra por `openDate`)
- **Resultados:** agrupados por analista, expansível, tabela `Nº Chamado` | `Status` (`Concluído`/`Ag. atendimento`/`Ag. cliente`/`Em atendimento`) | `Abertura` | `Conclusão` (`resolvedAt` via `formatResolvedDisplay`, sem `Tempo de Resolução` — removido)

---

## 6. Gerenciamento de Analistas (`tabContentAnalistas`)

- **Cadastrar Novo Analista:** `handleNewAnalystSubmit` com unicidade case-insensitive, `sort` alfabético
- **Indicar Ausência:** `handleAbsenceSubmit` com `analista`+`Início`+`Dias`, valida sobreposição por analista (`isAnalystAbsentOnDate`), salva em `absences`
- **Equipe Cadastrada:** tabela `Nome` | `Status Fila` (`Disponível`/`Ausente`) | `Excluir` (modal `deleteModal`, mínimo 1 analista)
- **Ausentes/Afastados:** tabela `Analista` | `Início` | `Dias` | `Término Previsto` | `Remover`, badge `Ausente Agora` se `now` entre `start` e `end`

---

## 7. Painel do Líder (`tabContentLider` — senha `lider@softplan`)

- **Cópia do Histórico** com 8 colunas: `Nº Chamado` | `Status` | `Abertura` | `Posse` | `Tempo de reação` | `Conclusão` | `Líquido de resolução` | `Bruto de resolução`
- **Filtros:** mesmos do Histórico, funções `handleLiderSearch`/`clearLiderSearch` com `liderAnalystSelect` etc.
- **Cálculos (horas úteis, fds/feriados descontados, `totalPausedMs` descontado):**
  - `Tempo de reação` = `abertura → posse` (`formatBusinessHoursOnly`)
  - `Líquido` = `posse → conclusão`
  - `Bruto` = `abertura → conclusão` (todos via `getBusinessMsBetween` + `formatBusinessHoursOnly` → só `h m`, ex: `2d 1h 54m` → `17h 54m` com `8h/dia`)
- **Posse:** coluna `Posse` (`posseAt` em `dd/mm/yyyy hh:mm:ss`, `—` se null)

---

## 8. Administração (`tabContentAdministracao` — senha `lider@softplan`)

### 8.1. SLAs por Descrição (primeiro painel)
- **Tabela:** `Descrição` | `Prazo (h)` (úteis), `selectAll`, `renderSlaTable`, `populateTicketTipoSelect` para `Tipo de chamado`
- **Ações:** `Incluir` (`handleSlaAdd` com unicidade), `Excluir selecionados`, `Recarregar`, edição inline `handleSlaEdit` (Enter), `saveSlAs`/`loadSlAs` (Supabase `slas` + `localStorage`)

### 8.2. Feriados (dia/mês)
- **Tabela:** `Dia` | `Mês` | `Descrição`, sem ano (`feriados: []` com `dia/mes/descricao`), `isFeriado(date)` compara `dia/mês` com ano corrente
- **Ações:** `Incluir` (`handleFeriadoAdd` valida `1-31`/`1-12` e unicidade `dia/mês`), `Excluir selecionados`, `Editar` (modal `feriadoEditModal` com `Carnaval`/`Paixão de Cristo`/`Corpus Christi` editáveis, `confirmFeriadoEdit` valida e evita duplicidade), `saveFeriados`/`loadFeriados`
- **Uso:** `addBusinessDays`/`getWorkingDaysWorked`/`getBusinessMsBetween` pulam `isFeriado` além de fds; `dueDate` ajustado se cair em feriado

### 8.3. Importar Histórico
- **Botão:** `Selecionar Histórico CSV` (`historicoFile` → `importHistorico`) espera `chamado,analista,abertura,posse,conclusão,vencimento,categoria` (`dd/mm/yy hh:mm:ss`), valida `analista` existe, `categoria` tem SLA, `isTicketExists`, ordem `abertura ≤ posse ≤ conclusão`, cria `status='concluído'` com `posseAt`/`resolvedAt`/`dueDate`/`tipo`

### 8.4. Configuração Supabase
- **Campos:** `Project URL` + `anon public key` (`cfgSupabaseUrl`/`cfgSupabaseKey`), `Testar Conexão` (`testSupabaseConnection`), `Salvar e Recarregar` (`saveSupabaseConfig` salva em `localStorage` + reload), `Limpar`/`Migrar Dados Locais`
- **Status badge:** `supabaseStatus` (`Modo Local`/`Supabase Online`/`Sincronizando`/`Erro`)
- **Realtime:** `setupSupabaseRealtime` escuta `tickets`/`analysts`/`absences`/`slas`/`feriados`/`acessos` → `debouncedReload` (800ms) re-render

### 8.5. Acessos à Aplicação
- **Métricas:** `Total`/`Hoje`/`Últimos 7 dias` + tabela últimos 50 (`Data/Hora`/`Navegador`), `loadAcessos` com `count` (`head:true`) e `gte` por data, `logAcesso` insere `id/timestamp/user_agent/ip` (via `ipapi.co`) a cada load

### 8.6. Zerar Chamados e Indicadores
- **Botão:** `resetData()` em `Administração` (movido do Dashboard), `confirm` → `appState.tickets=[]` (preserva `absences`/`allAnalysts`/`slas`/`feriados`), `saveToStorage` (Supabase `DELETE FROM tickets` + re-insert vazio), `render*` + `renderSlaTable`/`renderFeriadoTable`, toast `Ausências, analistas e SLAs preservados`

---

## 9. Regras de Negócio Transversais

- **Vencimento:** `calculateDueDate` / `addBusinessHours` / `addBusinessDays` com `isFeriado` e `getWorkingDaysWorked`; `Prazo Ajustado` do CSV é `vencimento`; `abertura` dos lotes é data da importação (`dd/mm/yyyy hh:mm:ss`); `Tipo de chamado` manual usa `SLA` da descrição
- **Aging/Termômetro:** `calculateThermometer` com `getEffectiveElapsedMs` (desconta `totalPausedMs` e pausa `ag. cliente`)
- **Posse:** `Tomar Posse` (`posseModal`) de `ag. atendimento` → `em atendimento` com `posseAt = now` (`formatDateTime`)
- **Devolução:** `Ag. Cliente` → `Ações do Roteador` (estende `dueDate` por `pauseMs`) → `devolverAcoesRoteador` → `em atendimento` com `posseAt`
- **Prioridade:** `ticketPrioridade` checkbox → `t.prioridade=true` → número vermelho (`text-red-600` + `fa-flag`) em todas as tabelas; `Solicitações de Prioridades` lista `abertos` com botão `Priorizar` → `prioridade=true`
- **Média diária:** `getAnalystAverage = monthTickets / dias úteis trabalhados` (desconta `isFeriado` e `isAnalystAbsentOnDate`)
- **Validações:** `isTicketExists` (case-insensitive), `validateForm` exige `número+abertura+tipo+analista`, `handleAbsenceSubmit` evita sobreposição, `resetData` exige `confirm`
- **Filtros:** `ticketAnalystFilter` abaixo do label (`flex-col`), `agClienteAnalystFilter`/`acoesRoteadorAnalystFilter`/`ticketSortSelect` com `Todos (N)`
- **Versão:** `updateVersionDisplay` via `document.lastModified` → `vYYYY.MM.DD-hhmm`

---

## 10. Supabase (`supabase-schema.sql`)

- **Tabelas:** `analysts(name PK)`, `tickets(number PK, analyst, open_date, due_date, date_key, status check, resolved_at, paused_at, total_paused_ms, posse_at, tipo, descricao, prioridade)`, `absences(id PK, analyst, start_date, days)`, `slas(id PK, descricao unique, prazo_horas)`, `feriados(id PK, dia, mes, descricao unique(dia,mes))`, `acessos(id PK, timestamp, user_agent, ip)`
- **RLS:** `enable row level security` + `Allow all for anon` em todas
- **Realtime:** `alter publication supabase_realtime add table` para todas
- **Índices:** `idx_tickets_analyst/status`, `idx_absences_analyst`, `idx_slas_descricao`, `idx_feriados_dia_mes`, `idx_acessos_timestamp`
- **Migrations:** `add column if not exists` para `paused_at`/`total_paused_ms`/`posse_at`/`tipo`/`descricao`/`prioridade`/`feriados`/`slas`/`acessos`, `drop/add constraint tickets_status_check` para incluir `ag. atendimento`/`ag. cliente`/`ações do roteador`/`concluído`

