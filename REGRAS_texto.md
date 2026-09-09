# Roteador e Monitor de Chamados — Como funciona

Este documento explica, de forma simples, como a aplicação funciona no dia a dia da equipe. Está organizado por **menu** e, dentro de cada menu, por **painel**.

---

## Visão geral

O sistema distribui chamados entre analistas de forma equilibrada, controla prazos e mostra produtividade. Ele funciona no navegador e sincroniza os dados com o Supabase, por isso todos veem as mesmas informações no GitHub Pages. A versão no rodapé (`v2026.09.08-1430`, por exemplo) mostra quando o arquivo foi salvo pela última vez.

---

## 1. Gerenciamento de Chamados

É a porta de entrada dos chamados que ainda precisam ser trabalhados.

### Chamados Roteados
É a lista principal. Mostra todos os chamados que estão aguardando atendimento ou em atendimento, com o número, o analista responsável, o status, as datas de abertura e vencimento e uma barra de progresso (Aging) que indica quanto do prazo já foi consumido. Dá para filtrar por analista e ordenar pelos mais críticos. A lista é paginada de 10 em 10.

Quando um chamado é criado, ele já entra aqui. Se for colocado em “Ag. cliente”, ele sai daqui e vai para o painel **Chamados Ag. Cliente**. Quando volta, retorna para cá.

Na parte de cima há quatro ações: **Tomar Posse**, **Atualizar Status**, **Concluir** e **Atualizar Prazos**. Tomar Posse registra quem pegou o chamado; Atualizar Status permite pausar o prazo (Ag. cliente); Concluir só funciona se o chamado estiver em atendimento; Atualizar Prazos apenas recalcula a barra sem mudar o status. Números marcados como prioridade aparecem em vermelho.

### Chamados Ag. Cliente
Aqui ficam apenas os chamados pausados porque estão aguardando o cliente. Enquanto estão aqui, o relógio do vencimento fica parado. Mostra o chamado, o analista e a data em que foi pausado, com filtro por analista. O botão **Devolver chamado** manda o chamado para o painel **Ações do Roteador**, onde o prazo volta a contar (o vencimento é estendido pelo tempo que ficou pausado).

### Dashboard de Atendimentos
É uma lista simples, uma linha por analista, ordenada da menor para a maior média diária. Analistas disponíveis vêm primeiro; os ausentes ficam sempre no final da lista, também ordenados entre si. Cada linha mostra quantos chamados o analista recebeu no mês, a média por dia útil, quantos foram entregues no prazo e quantos ficaram fora do prazo.

---

## 2. Painel do Roteador

Fica logo abaixo de Gerenciamento de Chamados e concentra as ações de quem distribui o trabalho.

### Novo Chamado Individual
Para cadastrar um chamado na mão. Pede o número (não pode repetir), o tipo (que vem da tabela de SLAs cadastrada em Administração) e a data de abertura. O vencimento é calculado automaticamente: pega as horas do SLA escolhido (por exemplo, 8h ou 30h) e soma dias úteis a partir da abertura, pulando fins de semana e feriados, dentro do expediente 08:00-12:00 e 13:00-17:00. Há uma opção de marcar como **Prioridade**, que deixa o número vermelho nas listas.

### Importar Chamados em Lote
São dois botões:

*   **Arquivo CSV Em Atendimento** — espera um arquivo com `ID do Avô, Prazo Ajustado (vencimento)` e outras colunas. Só entram linhas com `Proprietário` vazio. A abertura vira a data da importação e o vencimento vem do `Prazo Ajustado` do arquivo (convertido de `2026-09-04T14:31:11-03:00` para `04/09/2026 14:31:11`). Se o arquivo não tiver a coluna `Prazo Ajustado`, avisa para usar o outro botão.

*   **Arquivo CSV Ag. Priorização** — para arquivos com `Solicitação de Serviço, Descrição do status, Descrição`. A abertura também é a data da importação, o vencimento é calculado pelo SLA da descrição (busca na tabela de SLAs) e o chamado já entra como **Em atendimento** com posse registrada. Se o arquivo vier com `Prazo Ajustado`, avisa para usar o botão de Em Atendimento.

Em ambos os casos, o sistema escolhe automaticamente o analista ideal (o da fila com menor média) e coloca o chamado como `Ag. atendimento`.

### Analistas
Mostra a fila de quem está disponível, ordenada da menor média para a maior. Quem está no topo é a sugestão ideal para manter a equipe equilibrada. Indica quantos analistas estão disponíveis e a média de cada um.

### Redistribuir chamados
Tem dois botões:

*   **Redistribuir** — abre uma janela com **todos** os chamados ativos, o analista atual e uma lista para escolher um novo responsável (ordenada pela média). Só redistribui os que você selecionar.
*   **Redistribuir Ausentes** — lista apenas os chamados de analistas que estão ausentes no período e sugere um destino, mas agora também deixa você escolher outro analista da lista.

### Ações do Roteador
Recebe os chamados que foram devolvidos do painel **Ag. Cliente**. Mostra o chamado, analista, status e vencimento, com filtro por analista. Cada linha tem um botão **devolver** que manda o chamado de volta para **Chamados Roteados**, já como **Em atendimento** e com nova data de posse.

### Solicitações de Prioridades
Lista **todos os chamados abertos** (qualquer status exceto concluído) para priorização. Dá para selecionar e clicar em **Priorizar**, que abre uma confirmação com número, analista, status e abertura. Ao confirmar, o número fica vermelho em todas as listas.

---

## 3. Produtividade

Mostra um resumo do mês atual (ou de todo o histórico, se selecionar) com quatro números grandes: quantos chamados entraram, quantos foram resolvidos (com detalhe de quantos no prazo e fora), quantos ainda estão em atendimento e dois índices em círculo — **I.E. SLA** (quantos resolvidos foram no prazo) e **I.E. Qtd** (quantos recebidos viraram resolvidos) — com setinha de tendência em relação ao mês anterior.

Abaixo, uma tabela detalha por analista: recebidos, resolvidos, em atendimento, cumprimento de SLA e as duas barras de I.E., ordenada por quem tem maior índice.

---

## 4. Histórico de Produtividade

Serve para pesquisar o passado. Exige escolher um analista (ou Todos) e um status (Todos, Em andamento ou Concluídos) e, se quiser, um intervalo de meses. Os resultados vêm agrupados por analista, cada grupo pode ser expandido ou recolhido, e mostra para cada chamado o número, o status, a abertura e a conclusão. A coluna de tempo de resolução foi retirada para deixar a consulta mais direta.

---

## 5. Gerenciamento de Analistas

*   **Cadastrar Novo Analista** — digita o nome e adiciona à equipe (ordem alfabética).
*   **Indicar Ausência** — escolhe o analista, a data de início e quantos dias ficará fora. O sistema não deixa cadastrar períodos sobrepostos para a mesma pessoa.
*   **Equipe Cadastrada** — lista todos com selo **Disponível** ou **Ausente** e botão **Excluir** (pede confirmação, mantém pelo menos um).
*   **Analistas Ausentes/Afastados** — tabela com início, dias e término previsto, com selo **Ausente Agora** quando o período inclui hoje, e botão para remover.

Essas ausências influenciam a fila de distribuição e o cálculo da média diária (dias afastados não contam como dias trabalhados) e também o cálculo de vencimentos (feriados e fins de semana são pulados).

---

## 6. Painel do Líder

É uma cópia do Histórico, mas com senha (`lider@softplan`) e foco gerencial. Tem os mesmos filtros, mas os resultados trazem mais colunas: **Nº Chamado, Status, Abertura, Posse, Tempo de reação, Conclusão, Líquido de resolução, Bruto de resolução**.

*   **Posse** é a data/hora em que alguém clicou em **Tomar Posse**.
*   **Tempo de reação** é o tempo útil entre a abertura e a posse.
*   **Líquido** é o tempo útil entre a posse e a conclusão.
*   **Bruto** é o tempo útil total entre a abertura e a conclusão.

Todos os tempos são em horas úteis (8h por dia útil, pulando fins de semana, feriados e pausas de Ag. cliente), mostrados só em horas e minutos (ex: `2d 1h` vira `17h 54m` porque `1d = 8h`).

---

## 7. Administração

Precisa de senha (`lider@softplan`) e é onde ficam as configurações que afetam toda a equipe. O painel de **SLAs** aparece primeiro.

### SLAs por Descrição
Tabela com `Descrição` e `Prazo (horas úteis)`. Cada linha pode ser selecionada para excluir em lote ou ter o prazo editado direto na célula (Enter para salvar). O botão **Incluir** adiciona uma nova descrição com prazo. O **Tipo de chamado** do cadastro manual e a importação **Ag. Priorização** usam essa tabela quando o arquivo não traz vencimento: o sistema procura a descrição do chamado e calcula o vencimento somando as horas úteis a partir da abertura.

### Feriados (dia/mês)
Tabela com `Dia`, `Mês` e `Descrição`, sem ano — vale todo ano. Dá para incluir, excluir selecionados e **Editar** (botão ao lado) que abre uma janela só com **Carnaval, Paixão de Cristo e Corpus Christi** para ajustar dia e mês. Esses feriados são desconsiderados no cálculo de vencimento (se o vencimento cair neles, vai para o próximo dia útil) e na média diária.

### Importar Histórico
Botão **Selecionar Histórico CSV** que espera `chamado,analista,abertura,posse,conclusão,vencimento,categoria` (tudo em `dd/mm/yy hh:mm:ss`). Valida se o analista existe, se a categoria tem SLA, se o número já não existe e se as datas estão em ordem (`abertura ≤ posse ≤ conclusão`). Cria o chamado já como **Concluído**, alimentando diretamente as quantidades de atendidos, as médias e os históricos.

### Configuração Supabase
Campos para colar `Project URL` e `anon public key` do Supabase. Botões para **Testar Conexão**, **Salvar e Recarregar**, **Limpar** e **Migrar Dados Locais para Nuvem**. O selo no topo (`Supabase Online` verde, `Modo Local` cinza) indica se está sincronizando. Quando está online, qualquer alteração em chamados, analistas, ausências, SLAs ou feriados é espelhada na nuvem e aparece para todos via Realtime.

### Acessos à Aplicação
Três cartões com **Total de acessos**, **Hoje** e **Últimos 7 dias**, mais uma tabela com os últimos 50 acessos (`Data/Hora` e `Navegador`). Cada vez que alguém abre o app, grava um registro na tabela `acessos` do Supabase (com horário, navegador e IP quando possível). O botão **Atualizar** recarrega os números.

### Zerar Chamados e Indicadores
Botão vermelho com confirmação que apaga **todos os chamados** e zera os indicadores, mas **preserva** ausências, analistas, SLAs e feriados, tanto local quanto na nuvem.

---

## 8. Regras que valem para tudo

*   **Prazo e Aging:** toda data usa `DD/MM/YY HH:MM:SS` (ou `DD/MM/YYYY` na importação, convertido). O Aging mostra `X% consumido` ou `Vencido` e fica `pausado` (cinza) quando está em `Ag. cliente`.
*   **Posse:** só sai de `Ag. atendimento` para `Em atendimento` via **Tomar Posse**, que grava `posseAt` com data/hora atual.
*   **Devolução:** `Ag. Cliente` → **Ações do Roteador** (estende o vencimento pelo tempo pausado) → **devolver** → `Em atendimento` com nova posse.
*   **Prioridade:** checkbox `PRIORIDADE` no cadastro manual deixa o número vermelho em todas as listas; **Solicitações de Prioridades** permite priorizar qualquer aberto.
*   **Concluir:** só de `Em atendimento` para `Concluído` (com `conclusão` em `dd/mm/yy hh:mm:ss`); `Ag. cliente` e `Ag. atendimento` precisam voltar antes.
*   **Média diária:** `chamados do mês do analista ÷ dias úteis trabalhados no mês` (dias úteis = dias do mês sem fds/feriados e sem ausência do analista).
*   **Filtros:** sempre abaixo do nome da coluna, com `Todos (N)` e contagem por analista.
*   **Versão:** no rodapé, `vYYYY.MM.DD-hhmm` pega a data da última vez que o `index.html` foi salvo.

