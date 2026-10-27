# Valores extremos do fluxo solar GOES-16

Projeto em R e Quarto inspirado metodologicamente no trabalho de Carolyne Soares de Brito. A análise usa XRS-B, controles de qualidade do próprio NetCDF, máximos diários/semanais/mensais, GEV, extensão de localização linear no tempo, diagnósticos e níveis de retorno com bootstrap de blocos móveis. Compara também a GEV com a Skew-t de Azzalini–Capitanio (`sn`), usando exatamente os mesmos máximos mensais elegíveis.

## Versões do relatório

- **HTML:** [leitura no GitHub Pages](https://thiagojk.github.io/Relatorio-Topicos-1-Cira/); arquivo local `relatorio.html`.
- **Word:** [abrir ou baixar relatorio.docx](relatorio.docx), editável, com tabelas nativas e equações do Word.
- **PDF:** [abrir ou baixar relatorio.pdf](relatorio.pdf), na raiz do repositório. Versão acadêmica A4 com capa, sumário, páginas numeradas e o mesmo conteúdo científico.

## Relatório no GitHub Pages

A versão HTML completa da análise com dados reais está em `docs/index.html`, com gráficos, estilos e fórmulas incorporados. A publicação usa esses arquivos estáticos e não precisa baixar o NetCDF nem executar R no GitHub.

Para ativar, abra [Settings → Pages](https://github.com/thiagojk/Relatorio-Topicos-1-Cira/settings/pages), selecione **Deploy from a branch**, escolha **main** e **/docs**, e clique em **Save**. Após a implantação, o endereço será:

https://thiagojk.github.io/Relatorio-Topicos-1-Cira/

Para atualizar a versão publicada após alterar a análise, com a base real instalada:

```bash
quarto render relatorio.qmd
cp relatorio.html docs/index.html
git add docs/index.html
git commit -m "Atualiza relatório publicado"
git push origin HEAD:main
```

O Pages publica novamente após o envio. A cópia em `docs/` representa a análise já renderizada; alterações apenas no código R ou no QMD não a atualizam automaticamente.

## Estrutura didática do relatório

A versão reestruturada apresenta **Introdução → Referencial teórico → Dados e metodologia → Análise descritiva → Resultados → Discussão → Conclusão → Referências**. O corpo principal prioriza tabelas resumidas, gráficos selecionados e interpretação. Controle de qualidade detalhado, otimização Skew-t, sensibilidades e informações de sessão continuam disponíveis no apêndice, nos scripts e em `VALIDACAO.md`.

Do trabalho de Carolyne foram adaptadas a tabela descritiva, a combinação histograma/série histórica e a função dos diagnósticos por quantis. O repositório contém o PDF dela, sem código-fonte separado. Não foram transferidos log-retornos, VaR ou alfa-estável. A GEV e a Skew-t continuam ajustadas ao fluxo original, sem excluir os maiores máximos.

Novos produtos de apresentação, derivados dos resultados atuais, em `R/08_apresentacao.R`:

- tabela descritiva enxuta, comparação dos calendários, GEV com IC bootstrap, níveis de retorno e comparação conjunta GEV × Skew-t;
- série histórica com envelope mínimo–máximo e mediana por hora, usando todos os minutos válidos e conservando os picos; não é uma série minuto a minuto desenhada sem agregação;
- comparação temporal dos três calendários e gráfico da amostra mensal com os três maiores destacados.

As saídas anteriores continuam sendo calculadas e exportadas. `tabelas/*_relatorio.csv`, `serie_horaria_visual.csv` e os novos PNGs são reproduzíveis e permanecem ignorados pelo Git. A conversão dos critérios de estacionariedade para W/m² no relatório é apenas apresentação; preserva as diferenças de AIC e torna a unidade coerente com a comparação GEV × Skew-t.

## Estado atual

A análise foi executada com a **base real GOES-16**, disponível localmente em `Dados/`, e o relatório é gerado por Quarto. A validação e o registro dos resultados estão em `VALIDACAO.md`.

**Resultado científico central:** a GEV estacionária global produz uma cauda excessivamente pesada e não calibra a cauda superior observada. Seus níveis de retorno são resultados formais de um ajuste inadequado para previsão, não projeções solares recomendadas. A extensão simples de localização linear não resolveu a heterogeneidade temporal. O relatório mostra os resultados, os diagnósticos e essas limitações explicitamente.

O NetCDF de 252.483.840 bytes permanece ignorado pelo Git. A cópia fornecida pelo usuário está em [Google Drive](https://drive.google.com/file/d/12OXm9-VJg8EdJA3ulyxTtnWHNax1EDHg/view). Ao clonar este repositório, baixe o arquivo e coloque-o em `Dados/`; ele não acompanha o código. SHA256 da base analisada:

```text
2b5dded7d1a6e1f55cffb4d049664dfd52b4082245ae7d8abe05bbff63a3daa0
```

O HTML é autocontido e está em `relatorio.html` após a execução. `relatorio.html`, figuras, tabelas e RDS são produtos reproduzíveis ignorados pelo Git. A cópia estática `docs/index.html` é versionada para o GitHub Pages; atualize-a após renderizar.

## Gerar o relatório

1. Instale R (>= 4.4) e Quarto (testado: 1.7.32). No Linux, `ncdf4` pode exigir `libnetcdf-dev` e compiladores se instalado a partir de fontes.
2. Coloque a base em `Dados/sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc`.
3. Na pasta deste README, execute uma vez:

```bash
Rscript scripts/instalar_pacotes.R
```

4. Gere o formato desejado:

```bash
quarto render relatorio.qmd --to html
quarto render relatorio.qmd --to pdf
quarto render relatorio.qmd --to docx
```

Os arquivos são gravados na raiz: `relatorio.html`, `relatorio.pdf` e `relatorio.docx`. O comando sem `--to` continua produzindo HTML por padrão.

Abra `relatorio.html` no navegador. O HTML incorpora figuras e estilos; fórmulas usam MathML para evitar dependência de carregamento remoto. O suporte visual de MathML depende do navegador moderno.

**Nesta máquina em nuvem**, as ferramentas locais ficam em `/workspace/.tools/bin`. Antes dos comandos:

```bash
export PATH=/workspace/.tools/bin:$PATH
```

Para refazer a instalação local desta máquina Debian sem privilégios de administrador: `bash scripts/preparar_nuvem.sh`. O instalador mantém verificação de assinatura dos índices Debian e SHA256 do Quarto; os arquivos ficam fora do repositório, em `/workspace/.tools/`.

No **RStudio**, abra `projeto.Rproj`, execute `source('scripts/instalar_pacotes.R')` uma vez, abra `relatorio.qmd` e clique em **Render**. O HTML pode ser aberto pelo painel Viewer ou no navegador. Não é necessário um servidor.

### Dependências e apresentação do PDF

O PDF usa **XeLaTeX**. Nesta máquina já existe TeX Live 2025/Debian; não foi necessário substituir a instalação. Se não houver uma distribuição LaTeX no seu computador, uma alternativa é:

```bash
quarto install tinytex
```

Instale também as fontes **DejaVu Serif**, **DejaVu Sans**, **DejaVu Sans Mono** e **Latin Modern Math**, usadas na configuração. Os pacotes LaTeX de apresentação incluem `tcolorbox`, `fvextra`, `seqsplit`, `needspace`, `placeins`, `microtype`, `longtable` e `booktabs`; com TinyTeX, o Quarto pode instalar dependências faltantes conforme o acesso à rede.

A configuração PDF está em `relatorio.qmd`; os arquivos `formatos/pdf-*` e `formatos/tabelas_pdf.R` cuidam exclusivamente da impressão: capa, margens, tabelas com quebra de texto, cabeçalhos repetidos e reserva de espaço para tabelas curtas, quadro de advertência sem ícone e quebra de identificadores longos. Figuras mantêm os PNGs originais e suas proporções, em blocos independentes. Código permanece oculto. O HTML conserva seu tema e suas tabelas originais.

O PDF final é versionado; `.tex`, `.aux`, `.log`, `.toc` e demais intermediários de `relatorio` são ignorados. Sempre regenere `relatorio.pdf` após uma mudança científica no QMD ou nos scripts. Atualizar somente HTML não atualiza automaticamente o PDF.

### Versão Word

A saída DOCX usa `formatos/referencia-word.docx` para página A4, margens, estilos, títulos e numeração; `formatos/word-tabelas.lua` distribui as larguras das colunas. Não exige LaTeX nem Microsoft Word para gerar. As fontes são Liberation Serif/Sans e Latin Modern Math; substituições de fonte e versões do editor podem mudar a paginação.

Ao abrir no Word, atualize o sumário em **Referências → Atualizar Sumário → Atualizar o índice inteiro** (ou selecione tudo com Ctrl+A e pressione F9). O sumário é um campo automático, preenchido pelo editor.

O modelo já acompanha o repositório. Para recriá-lo opcionalmente, use `python scripts/criar_referencia_word.py` com Quarto no PATH e o pacote Python `python-docx` instalado. O DOCX final é versionado; regenere-o após mudanças científicas. HTML e PDF continuam com suas próprias configurações.

## Organização

- `R/config.R`: limiar de cobertura, bootstrap, semente, declustering e caminho relativo da base.
- `R/01_leitura_limpeza.R`: metadados CF, flags, preenchimentos, validações, `dados_xrs` e `dados_limpos`.
- `R/02_exploratoria.R`: estatísticas completas, cobertura, lacunas, gráficos e mudança anual exploratória.
- `R/03_dependencia.R`: ACF/PACF/Ljung–Box no maior trecho contíguo, sem colapsar lacunas.
- `R/04_block_maxima.R`: grades de calendário, cobertura e elegibilidade dos máximos.
- `R/05_gev.R`: múltiplos inícios de otimização, comparação de blocos e extensão temporal.
- `R/06_niveis_retorno.R`: IC por bootstrap móvel, níveis de retorno e episódios separados.
- `R/07_skew_t.R`: validação da amostra comum, estimação Skew-t, múltiplos inícios, comparação GEV × Skew-t, diagnósticos e influência dos maiores máximos.
- `R/08_apresentacao.R`: resumos e figuras didáticas derivados dos mesmos dados e ajustes, sem modificar a metodologia.
- `R/executar.R`: execução integral compartilhada com o relatório.
- `figuras/`, `tabelas/`, `resultados/`: saídas geradas, ignoradas no Git.
- `referencias/Carolyne.pdf`: referência fornecida, sem reprodução literal de seu texto.
- `testes/`: testes técnicos com uma base NetCDF artificial, exclusivamente em diretório temporário, sem resultados científicos.

Para executar primeiro a análise e conferir seus resultados:

```bash
Rscript R/executar.R
quarto render relatorio.qmd
```

Para executar só a análise: `Rscript R/executar.R`. Resultados resumidos ficam em `resultados/resumo.rds`; versões em `resultados/sessionInfo.txt`. A renderização sempre recalcula tudo. Reserve memória para milhões de registros; a leitura mantém a série original e a limpa e pode exigir alguns GB. O bootstrap pode demorar vários minutos; não é uma etapa de instalação.

## Escolhas e salvaguardas

- Datas são UTC e a origem é lida em `units`. Calendários não gregorianos, origem ambígua, coordenadas incompatíveis, duplicatas por minuto e unidades não reconhecidas interrompem a execução.
- `good_data` deve existir em `flag_meanings` com `flag_values` compatíveis. Máscaras são decodificadas quando declaradas; combinações como eclipse + interpolated são identificadas. A seleção é conservadora: código good_data puro, excluindo interpolação e demais condições. Ambiguidade impede a execução.
- `dados_xrs` mantém os registros organizados antes da seleção analítica; preenchimentos são representados por NA. O original permanece preservado no arquivo NetCDF.
- Cobertura padrão: 90% de cada bloco civil completo; sensibilidade em 80% e 95%. Bordas parciais não recebem denominadores reduzidos.
- Fluxos não positivos ou fora de valid_min/valid_max são excluídos com contagem explícita; valores positivos elevados não são retirados para melhorar ajustes.
- Estatísticas usam todos os dados válidos; apenas gráficos de distribuição/Normal são amostrados (semente fixa, até 20 mil pontos).
- Após exigir 50 máximos, suporte, convergência, erro de forma finito e xi > -0,5, a comparação prioriza a menor correlação absoluta dos pares adjacentes válidos de toda a grade (sem colapsar lacunas); diferenças de até 0,02 favorecem agregação maior. A escolha real foi mensal. ACF não prova independência nem garante bom ajuste: a má calibração global é explicitamente reportada. Sensibilidades variam a cobertura e retiram um/três maiores máximos somente para diagnóstico, sem alterar a análise principal.
- AIC é comparado para estacionariedade apenas na mesma amostra; não seleciona entre blocos.
- IC principais: 399 replicações bootstrap circular móvel, janela `ceiling(n^(1/3))` da grade regular, com lacunas preservadas; mínimo de 80% e 100 replicações válidas. Intervalos da Hessiana são apresentados como aproximação iid.
- Otimização usa múltiplos inícios, Nelder–Mead, validação independente da log-densidade e passo menor para a Hessiana; a extensão começa também na solução estacionária aninhada.
- Comparação não estacionária: localização linear, escala/forma constantes; AIC e LRT nominais são exploratórios sob dependência. Uma tendência não modela um ciclo inteiro.
- Declustering: excedências do P99,9 global, regra de intervalo entre excedências, 6 h como principal, 1/24 h para sensibilidade. Não constitui identificação física de flares.
- Níveis históricos estacionários de 1, 2, 5 e 10 anos são resumos condicionais às hipóteses. Sob mudança temporal, não são previsões. Quantis da extensão mantêm a covariável congelada e recebem ressalvas explícitas.
- Não se conclui independência com p > 0,05, nem cauda Fréchet apenas pelo sinal de xi ou desvio de normalidade.

## Comparação GEV × Skew-t

A comparação principal preserva os 94 máximos mensais elegíveis da GEV: asserções conferem quantidade, datas, valores e positividade contra os dados efetivamente usados no ajuste original. A Skew-t usa a parametrização direta de `sn`: localização xi_ST, escala omega, slant alpha e graus de liberdade nu. Localização/escala não são média/desvio padrão; xi_ST não é a forma da GEV. A estimação usa `st.mple(penalty=NULL)` com oito inícios e dois métodos, sem truncar em zero ou transformar a resposta em log.

**Resultado real:** a Skew-t não melhorou conjuntamente o ajuste. A GEV teve menor AIC/BIC nominal, menor discrepância PP e menor erro dos quantis mais altos do QQ. A Skew-t atingiu uma fronteira de assimetria extrema, sem alpha finito estável; por isso não são publicados EP/IC Wald para essa solução. Ambas extrapolam excessivamente a cauda. As exclusões apenas diagnósticas de um/três maiores máximos não inverteram a preferência dos critérios pela GEV; não justificam retirar dados do principal. Valores completos e verificações estão em `VALIDACAO.md` e no relatório.

As log-verossimilhanças comparativas são expressas na mesma escala W/m², com Jacobiano do reescalonamento numérico. AIC/BIC são nominais diante da dependência mensal, heterogeneidade temporal e solução Skew-t não regular. Não se usa LRT entre as famílias, nem se atribui à Skew-t a justificativa assintótica da GEV. Quantis equivalentes da Skew-t não substituem níveis de retorno GEV e não são previsões validadas.

Novas saídas reproduzíveis:

- `tabelas/amostra_comum_mensal.csv`: datas, máximos e cobertura da amostra compartilhada.
- `tabelas/parametros_skew_t.csv`, `comparacao_gev_skew_t.csv`, `quantis_cauda_gev_skew_t.csv`: parâmetros, critérios e cauda.
- `tabelas/otimizacao_skew_t.csv`: todos os inícios, métodos, códigos, mensagens e avisos nos três cenários.
- `tabelas/sensibilidade_gev_skew_t.csv`, `diagnosticos_sensibilidade_skew_t.csv`: influência dos maiores eventos.
- `tabelas/diagnosticos_gev_skew_t.csv`: valores ponto a ponto dos QQ/PP, sem NA.
- `resultados/comparacao_skew_t.rds`: objetos numéricos e conclusão gerada a partir dos resultados.
- `figuras/comparacao_*.png`: densidade visualizada em log10 com Jacobiano, QQ separados em limites comuns, PP e cauda superior.

## Testes técnicos

```bash
Rscript testes/testar.R
```

Os dados artificiais existem somente para testar contratos, conversões, rejeições e a execução dos módulos; nunca são gravados em `Dados/` real nem apresentados como observações solares. Para o teste de renderização em área temporária, consulte o procedimento em `VALIDACAO.md`.
