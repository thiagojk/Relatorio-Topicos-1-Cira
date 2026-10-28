# Validação da análise GOES-16

Atualização em 27 de outubro de 2026. Os dados são solares, não financeiros. Os valores abaixo foram obtidos da base real e dos objetos existentes; a aplicação atual conserva a GEV e sua extensão temporal.

## Base utilizada

- Arquivo: `sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc`.
- Origem: arquivo fornecido pelo usuário no [Google Drive](https://drive.google.com/file/d/12OXm9-VJg8EdJA3ulyxTtnWHNax1EDHg/view).
- Local: `Dados/sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc` (ignorado pelo Git).
- Tamanho: 252483840 bytes.
- MD5: `d3d777aab1fea86f1f3771749a320c71`.
- SHA256: `2b5dded7d1a6e1f55cffb4d049664dfd52b4082245ae7d8abe05bbff63a3daa0`.
- Registros totais: 4294080; válidos: 4172834; removidos: 121246.
- Percentual válido: 97.1764%.
- Período dos inícios de médias: 2017-02-07T00:00:00Z a 2025-04-07T23:59:00Z (UTC).
- Unidade: W/m2; cadência mediana: 60 segundos.
- Tempo: `seconds since 2000-01-01 12:00:00 UTC`, conforme os metadados; a convenção do produto despreza segundos intercalares.
- `good_data`: 0; flags encontradas: 0 | 1 | 2 | 4 | 5. As máscaras permitem decodificar `5` como eclipse + interpolação. A seleção conserva somente good_data puro, sem interpolação.
- Fill values, valores não finitos, positividade e valid_min/valid_max foram verificados. A tabela completa é `tabelas/validacao_base.csv`.

## Escolha dos blocos

| Bloco | Total | Elegíveis | Correlação de pares adjacentes | xi |
|---|---:|---:|---:|---:|
| diario | 2982 | 2905 | 0.910795 | 2.81342 |
| semanal | 427 | 409 | 0.815902 | 3.04357 |
| mensal | 99 | 94 | 0.79521 | 2.77199 |

O bloco de referência histórico escolhido foi **mensal**, com 94 máximos elegíveis entre 99 intervalos. Cobertura mínima: 90% do mês civil completo. A correlação entre pares adjacentes foi 0.79521 em 91 pares.

A comparação usa toda a grade e não colapsa lacunas. ACF/PACF/Ljung–Box usam os maiores trechos contíguos, documentados separadamente; essa distinção evita comparar apenas recortes pertencentes a fases diferentes. Convergência, suporte, erros padrão, pelo menos 50 máximos e região regular são requisitos prévios. AIC entre blocos e valores p não selecionam o tamanho. A dependência residual permanece alta; a escolha não certifica independência.

## Parâmetros da GEV estacionária de referência

| Parâmetro | Estimativa | Erro padrão | IC Wald 95% inferior | Superior |
|---|---:|---:|---:|---:|
| mu | 2.97857e-06 | 9.42419e-07 | 1.13143e-06 | 4.82571e-06 |
| sigma | 8.20798e-06 | 2.79428e-06 | 2.73118e-06 | 1.36848e-05 |
| xi | 2.77199 | 0.262937 | 2.25663 | 3.28734 |

Mu e sigma estão em W m⁻²; xi é adimensional. O IC bootstrap da forma é [1.2426, 3.45654]; foram 399 replicações completas em 399 tentativas. A forma é compatível com Fréchet **dentro do ajuste agregado**, mas isso não estabelece uma família física invariável para a série solar.

**Limitação decisiva:** a forma elevada, o QQ e a calibração dos níveis mostram que a GEV estacionária global não oferece extrapolações prospectivas confiáveis. Xi >= 1 implica média infinita no modelo ajustado; essa propriedade não foi demonstrada para o processo solar. O relatório não apresenta o ajuste como uma boa descrição da cauda.

## Níveis formais de retorno

**Não são previsões solares recomendadas.** Os números abaixo documentam o resultado e a falha de calibração do modelo agregado. Unidade: W m⁻²; IC percentil nominal de 95%, bootstrap de blocos móveis.

| Anos | Blocos mensais | Estimativa | IC inferior | Superior |
|---:|---:|---:|---:|---:|
| 1 | 12 | 0.0025759 | 0.000420807 | 0.00981475 |
| 2 | 24 | 0.0187002 | 0.001222 | 0.101939 |
| 5 | 60 | 0.245671 | 0.00405731 | 2.55551 |
| 10 | 120 | 1.69775 | 0.00971153 | 26.5104 |

O nível formal de um ano não foi excedido, embora a distribuição constante esperasse aproximadamente 7.83333 excedências na amostra. O nível de dez anos é 1159.6 vezes o maior fluxo observado. Níveis acima de valid_max também não têm validação instrumental neste produto; valid_max não é interpretado como limite físico solar.

## Comparação de estacionariedade

- AIC estacionário: 397.761; log-verossimilhança na escala numérica do ajuste: -195.881.
- AIC de localização linear: 399.095; log-verossimilhança: -195.547.
- Razão de verossimilhanças, um grau de liberdade: valor p nominal 0.414196. A extensão linear não foi favorecida pelos critérios conjuntos.
- Isso não demonstra estacionariedade. Medianas e quantis anuais mudam fortemente; o teste exploratório por permutação de segmentos indicou p = 0.002. A localização linear com escala fixa é restritiva e não resolveu o padrão do PIT no tempo.
- LRT/Hessiana são aproximações sob independência; o bootstrap móvel preserva dependência local, mas não corrige heterogeneidade de longo prazo. Os intervalos são condicionais e nominais.


## Escopo da atualização

Foi retirado o modelo alternativo solicitado pelo usuário, incluindo módulo exclusivo, dependências, referências, testes exclusivos e saídas locais obsoletas. O histórico permanece no Git. O relatório atual não contém menções, tabelas, gráficos ou conclusões desse modelo.

Normal permanece como referência gráfica QQ; não havia ajustes Alfa-Estável, VaR, mínimos financeiros, PWM ou dados de BrasilAgro/Boa Safra no código solar. Esses itens pertencem ao PDF de Carolyne, que permanece em `referencias/`. Não foram inventados nem transplantados resultados financeiros.

Resultados foi reorganizada em: análise descritiva do fluxo; distribuição/QQ Normal; dependência e blocos; série mensal; parâmetros e diagnósticos GEV; níveis de retorno; comportamento temporal; síntese. A descrição e as respectivas interpretações ficam na mesma sequência de resultados. O apêndice mantém qualidade, dependência, incerteza, calibração e sensibilidade GEV.

O módulo `R/08_apresentacao.R` agora utiliza diretamente `block$blocos$mensal[elegivel == TRUE]`. Não há dependência de um objeto do modelo removido para desenhar os 94 máximos ou apresentar o diagnóstico GEV. Os módulos estatísticos `01` a `06`, amostra, cobertura, semente e bootstrap são preservados.

## Publicação GitHub Pages

Causa dos downloads quebrados: a publicação é `main` + `/docs`; o PDF e o DOCX existiam somente na raiz, fora da pasta publicada. Não há workflow próprio de deploy em `.github/workflows/`; não é necessário criar um para publicar arquivos estáticos já gerados.

O QMD inclui botões HTML com `href="relatorio.pdf"` e `href="relatorio.docx"`. Após gerar os três formatos, `python3 scripts/publicar_pages.py` prepara:

- `docs/index.html`;
- `docs/relatorio.pdf`;
- `docs/relatorio.docx`;
- `docs/manifesto.json`, com tamanhos e SHA256;
- `.nojekyll` preservado.

O script recusa saídas ausentes, com assinatura de formato inválida ou mais antigas que os fontes. Nomes e maiúsculas coincidem com os arquivos. `.gitignore` permite versionar os dois downloads. Links relativos independem do domínio e não apontam para a raiz local nem para páginas de visualização do GitHub. HTML padrão, PDF/DOCX na raiz e estrutura `/docs` são preservados.

## Validação anterior — reorganização e downloads

- `Rscript testes/testar.R`: status 0; fixture isolada em `/tmp/goes_TESTE_ARTIFICIAL_3133458d55947`.
- `quarto render relatorio.qmd --to html`, `--to pdf` e `--to docx`: todos concluídos com a base real, sem erros.
- O RDS atual foi confrontado com o anterior por `all.equal`, retirando apenas o campo da comparação removida: todos os componentes GEV, blocos, bootstrap, retornos, calibração e extensão temporal são idênticos.
- Chromium: 11 imagens incorporadas, 15 tabelas, 17 expressões MathML; nenhuma imagem quebrada, referência interna não resolvida, erro JavaScript, placeholder ou transbordamento da página no celular. Seis tabelas principais foram conferidas com os CSVs.
- PDF: 25 páginas A4, 11 figuras e 15 tabelas. Rasterização de todas as páginas e inspeção visual de Resultados, parâmetros, diagnósticos, retornos e apêndice. Nenhum texto/imagem fora dos limites úteis; tabelas longas continuam com cabeçalhos repetidos. Uma auditoria de duas passagens XeLaTeX registrou 13 Underfull e um Overfull de 0,885 pt no parágrafo da conclusão, inspecionado sem corte; zero caracteres ausentes ou referências indefinidas.
- Word: os títulos estruturais correspondem ao HTML. A prévia LibreOffice tem 19 páginas, com blocos de texto dentro da página. A paginação pode variar no Microsoft Word, não executado no ambiente; atualizar o sumário automático ao abrir.
- 173 valores numéricos distintos das tabelas HTML foram encontrados no PDF e no XML Word. A tabela descritiva formatada foi conferida integralmente com o CSV no HTML.
- Busca no QMD, nos fontes ativos e no texto extraído de HTML/PDF/DOCX confirmou ausência de conteúdo do modelo retirado e de sua referência exclusiva. Dependências exclusivas foram removidas dos instaladores e de `R/utils.R`.
- `python3 scripts/publicar_pages.py`: concluído; as cópias de HTML/PDF/DOCX em `docs/` são byte a byte iguais às da raiz. Teste isolado confirmou que uma saída antiga é rejeitada antes de copiar arquivos.
- Teste Chromium dos dois botões em servidor local com prefixo `/Relatorio-Topicos-1-Cira/`: downloads efetivos concluídos, resposta HTTP 200 para ambos; tipos `application/pdf` e `application/vnd.openxmlformats-officedocument.wordprocessingml.document`; bytes baixados iguais aos originais. Isso valida a estrutura final do Pages, sem depender de caminhos locais ou da visualização `blob` do GitHub.
- `bash -n` aprovou os scripts de instalação e geração/publicação. O novo `scripts/renderizar_publicar.sh` executa as três renderizações sequencialmente e só então prepara `docs/`, interrompendo em falhas.

### Arquivos publicados na atualização anterior


- `docs/index.html`: 2801499 bytes; SHA256 `c33c46f1933e70a2ddeb9c1bcc1810cb3a779b302952bb2e8f745ed05f54b860`.

- `docs/relatorio.pdf`: 1427204 bytes; SHA256 `1888a425f87d286b19d0fd4070229ffe2ec74f512d21bf683e88ee3a7314d822`.

- `docs/relatorio.docx`: 1140264 bytes; SHA256 `277ff7a1e9f8a88fe25e4d192a4fbc317cf23685382bd08fa213bcaad703c630`.

O NetCDF não é versionado. A implantação remota depende da execução padrão do Pages após o push; os testes HTTP descritos foram executados localmente sobre a pasta final publicada.

## Tabela resumida de níveis de retorno — 27/10/2026

A tabela já existente `tbl-retornos` foi revisada, sem duplicação, na seção **4.6 — Níveis de retorno**, dentro de Resultados e antes do gráfico. A apresentação tem três colunas: período, estimativa em W/m² e IC 95% `(inferior; superior)`, em notação científica com quatro algarismos significativos e vírgula decimal. O resumo vem diretamente de `retornos$tabela`, por `R/08_apresentacao.R`, com o helper `mostrar()` já existente. Exporta-se também `retornos_resumo_relatorio.csv`; os CSVs numéricos anteriores são preservados.

| Período | Estimativa (W/m²) | IC 95% (W/m²) |
|---|---:|---|
| 1 ano | 2,576e-03 | (4,208e-04; 9,815e-03) |
| 2 anos | 1,870e-02 | (1,222e-03; 1,019e-01) |
| 5 anos | 2,457e-01 | (4,057e-03; 2,556e+00) |
| 10 anos | 1,698e+00 | (9,712e-03; 2,651e+01) |

Os horizontes existentes são 1, 2, 5 e 10 anos, equivalentes a 12, 24, 60 e 120 blocos mensais, com probabilidade de não excedência `1 - 1/(12T)`. Não foram criados horizontes de 20/50 anos. Os IC principais continuam sendo percentis de 2,5% e 97,5% do **bootstrap circular de blocos móveis**, com 399 replicações válidas, segmentos de cinco meses e lacunas preservadas. Nenhum IC da Hessiana os substituiu.

### Conferências e preservação

- Revisados QMD, módulos `05`, `06`, `08`, README e esta validação antes da edição. Não houve alteração em `R/05_gev.R`, `R/06_niveis_retorno.R`, seleção de blocos, cobertura, semente ou método de bootstrap.
- Auditoria independente com os parâmetros GEV na unidade original reproduziu as quatro estimativas. Os limites coincidem com os percentis das colunas T1/T2/T5/T10 de `bootstrap_blocos_moveis.csv`. Todos são finitos, ordenados e contêm a respectiva estimativa; a unidade é W/m² e os níveis crescem com o período. **Não foi encontrada inconsistência numérica nos cálculos existentes.**
- `all.equal` confirmou que o RDS científico completo permanece idêntico ao anterior. Hashes confirmaram preservação dos módulos `01`–`06`, de todos os CSVs numéricos anteriores e de todos os PNGs, inclusive `niveis_retorno.png`.
- `Rscript testes/testar.R`: aprovado em fixture temporária isolada. Uma conferência adicional avaliou diretamente os dados do gráfico produzido pelo módulo: curva e faixa reproduzem os quantis do mesmo ajuste e os percentis das mesmas replicações bootstrap em todos os nós da grade gráfica. Os horizontes da tabela não precisam coincidir com todos os nós da grade logarítmica do gráfico; a função e as replicações são as mesmas.
- `bash scripts/renderizar_publicar.sh`: concluído com a base real, gerando HTML, PDF e DOCX e preparando `docs/`.
- HTML: uma única tabela de retorno, quatro linhas, igualdade com o CSV de apresentação e concordância numérica com os valores completos dentro do arredondamento. Sem imagens quebradas ou referências internas não resolvidas; inspecionada em 1440 px e 390 px, sem transbordamento da página.
- PDF: 25 páginas; tabela completa na página 14, inspecionada visualmente, com seus 12 valores numéricos presentes. Sem corte de linhas/colunas na tabela. Nota bootstrap e interpretação acompanham a tabela antes do gráfico.
- Word: uma única tabela nativa com as quatro linhas e os mesmos textos do HTML. Prévia LibreOffice com 19 páginas; tabela e gráfico na página 11, inspecionados visualmente. A paginação no Microsoft Word pode variar.
- A nota identifica o bootstrap e a conversão temporal. O parágrafo interpretativo explicita crescimento dos quantis e cauda excessivamente pesada: os níveis são formais, **não previsões solares confiáveis**. A conclusão científica foi preservada.
- As cópias em `docs/` são idênticas às saídas da raiz. Os botões PDF/Word foram novamente exercitados em servidor local com o prefixo do projeto, com downloads corretos e resposta HTTP 200.

### Arquivos atuais

- `docs/index.html`: 2802164 bytes; SHA256 `8b836ea0e1544f6e33ee170699d576b328e4c3d39d1680f3be3edb157dc013ba`.

- `docs/relatorio.pdf`: 1428090 bytes; SHA256 `7cce3a5e5a4e815e824649f7091eb08e204d1228f8c9b6a10a6790bae4ef0233`.

- `docs/relatorio.docx`: 1140553 bytes; SHA256 `2dd6193c969d4a1b1b66e9c93dcd5edccf273c7078ddbcc13e69a22a4dbfe01c`.

## Interpretação didática dos níveis de retorno — 27/10/2026

A seção **4.6 — Níveis de retorno** mantém a Tabela 4 e os horizontes de **1, 2, 5 e 10 anos**, sem duplicá-la nem modificar seus números. Foram acrescentados **oito parágrafos interpretativos imediatamente após a tabela**, antes do gráfico, tomando a referência de Carolyne somente como inspiração de apresentação. Não foram copiados textos ou exemplos financeiros.

A interpretação aborda, em sequência: conteúdo e leitura das colunas; probabilidade de excedência mensal e conversão para blocos; exemplo de um ano; exemplo de dez anos; crescimento dos níveis e amplitudes dos IC; significado frequentista de cobertura; contexto do canal XRS-B e confronto com a amostra; limitações da GEV global e da extrapolação.

### Exemplos vinculados aos objetos R

- **1 ano:** 12 blocos, estimativa 2,576e-03 W/m², IC de 4,208e-04 a 9,815e-03 W/m², probabilidade de excedência de aproximadamente 8,33% por mês.
- **10 anos:** 120 blocos, estimativa 1,698e+00 W/m², IC de 9,712e-03 a 2,651e+01 W/m², probabilidade de excedência de aproximadamente 0,83% por mês.
- **Contraste curto/longo:** razão dos níveis aproximadamente 659,1; amplitude dos IC de 9,394e-03 a 2,650e+01 W/m². A razão usa os valores completos, antes do arredondamento da tabela.
- **Calibração:** o nível de um ano é 1,76 vezes o maior fluxo observado, com zero excedências contra cerca de 7,8 esperadas pelo modelo constante; o nível de dez anos é cerca de 1.159,6 vezes o máximo observado.

Os objetos auxiliares `rt_curto` e `rt_longo` selecionam as linhas de menor/maior período de `retornos$tabela`. Todas as estimativas, limites, probabilidades, razões, amplitudes, forma, contagens, quantidade de máximos e parâmetros do bootstrap são interpolados dinamicamente no QMD. Não são resultados escritos manualmente. As funções de formatação são de apresentação e mantêm os quatro algarismos significativos da tabela.

A interpretação de período de retorno é probabilística por bloco: `1/(12T)` nesta aplicação mensal, sem ocorrência obrigatória a cada T anos. A leitura de espera média é condicionada à estabilidade e à independência aproximada, ressalvadas explicitamente. O IC de 95% é explicado por repetição hipotética do procedimento: sob hipóteses adequadas, cerca de 95% dos intervalos conteriam o nível populacional correspondente. Não se atribui 95% de probabilidade ao parâmetro fixo neste intervalo, nem se confunde o IC com a faixa que conteria 95% dos fluxos.

A cobertura é tratada como **nominal** diante da dependência, heterogeneidade e má especificação. A narrativa relaciona a forma elevada à extrapolação, distingue intensidade registrada de identificação/classificação física de flares e integra a falha da cauda superior à discussão numérica. O limite instrumental valid_max permanece explicitamente distinto de uma barreira física solar. Não se autoriza previsão operacional com esses níveis.

### Conferências desta atualização

- Revistos QMD, módulos `05`, `06` e `08`, README, validação e tabela numérica antes da edição. Somente apresentação textual foi modificada; todos os scripts R, CSVs anteriores e PNGs permanecem byte a byte idênticos. `all.equal` confirmou preservação integral do RDS científico.
- Os quatro níveis têm estimativas dentro de seus respectivos IC, limites ordenados e unidades W/m². As amplitudes aumentam nos quatro horizontes, como afirmado na interpretação.
- Conferência do HTML identificou exatamente oito parágrafos interpretativos e validou 13 expressões numéricas extraídas das linhas originais e de seus cálculos derivados. Sem imagens quebradas, erros JavaScript, referências internas não resolvidas ou transbordamento da página em 390 px.
- `bash scripts/renderizar_publicar.sh`: execução final concluída com a base real, renderizando HTML, PDF e DOCX e preparando as cópias em `docs/`. A geração foi repetida após explicitar o significado frequentista de cobertura para manter o mesmo texto nos três formatos.
- PDF: **26 páginas**; tabela na página 14 e interpretação nas páginas 14–16, junto do gráfico. Os exemplos numéricos e a frase que define a cobertura de 95% foram encontrados no texto extraído. Inspeção visual das páginas da seção; nenhum bloco de texto fora das margens úteis.
- Word: XML contém os mesmos exemplos e a explicação de cobertura. Prévia LibreOffice com **20 páginas**, com interpretação iniciada na página 11 e continuação nas seguintes; paginação pode variar no Microsoft Word. O sumário automático deve ser atualizado ao abrir.
- As três cópias do Pages são idênticas aos artefatos da raiz. Downloads PDF e DOCX exercitados novamente em servidor local com prefixo do projeto: HTTP 200 e arquivos baixados iguais aos originais.

### Artefatos desta interpretação

- `docs/index.html`: 2807006 bytes; SHA256 `dec6475d8fbd7b70b4881b1c62da38f3b734d54f8ad86de86375fb68c22fa11d`.

- `docs/relatorio.pdf`: 1432388 bytes; SHA256 `e928d79fc2a03d6c3fee175decd34b6400e24e2351b7f39ad9e6af73cac0c245`.

- `docs/relatorio.docx`: 1141937 bytes; SHA256 `5e47e77d74159d539ed4f6b92801f914c1a93c5c3729edd6e8ca14e71455bd3b`.

## Histograma dos máximos mensais — 27/10/2026

Foi acrescentada a figura `fig-histograma-mensal`, após a série dos máximos mensais e antes do ajuste GEV, na seção Resultados. A numeração continua automática pelo Quarto. O texto imediatamente posterior descreve a assimetria à direita e ressalva que sua presença visual não demonstra adequação de uma GEV de cauda muito pesada.

O módulo `R/08_apresentacao.R` usa diretamente `mensal`, derivado de `block$blocos$mensal[elegivel == TRUE, .(inicio,fim,maximo,cobertura)]`. A seleção de valores é idêntica à de `R/05_gev.R`: `block$blocos$mensal[elegivel == TRUE,maximo]`. Não há nova base, mudança de cobertura, reamostragem, transformação ou retirada de extremos. O critério permanece cobertura mínima de 90% do mês civil completo.

Conferência com a base real: **94 máximos**, mínimo `4,100943e-08`, mediana `1,897504e-05` e máximo `1,464085e-03` W/m². A regra de Sturges define **oito classes de largura igual**, com limites entre o mínimo e o máximo observados. As frequências são **79, 10, 2, 0, 2, 0, 0 e 1**, somando 94. Os limites incluem os dois extremos. O eixo X permanece na escala original (transformação identidade); o eixo Y é frequência absoluta, não densidade. Não foi acrescentada uma versão logarítmica.

A auditoria executou as próprias expressões do módulo responsáveis pela amostra e pelo gráfico, verificou igualdade dos valores e das datas com a seleção da GEV, tamanho amostral, finitude, contagens das barras pelo `ggplot_build` e inclusão dos extremos (com tolerância de arredondamento de máquina nos limites gráficos). O resumo científico anterior foi preservado integralmente (`all.equal`). A renderização normal recalcula a rotina existente; nenhum ajuste, critério ou resultado GEV foi modificado.

### Renderização e preservação desta figura

- `bash scripts/renderizar_publicar.sh`: concluído com a base real nos três formatos, seguido da preparação de `docs/`. Houve uma interrupção temporária do acesso ao ambiente, mas o processo continuou e terminou com sucesso.
- HTML: Figura 7, após a série mensal e antes da seção 4.5 (GEV); parágrafo interpretativo imediatamente após a figura. Todas as imagens carregam; sem transbordamento da página em 390 px. Todas as figuras e tabelas anteriores foram preservadas.
- PDF: 27 páginas, histograma completo na página 12, inspecionado visualmente, sem corte do título, eixos ou legenda. Texto interpretativo continua na página seguinte, antes do ajuste.
- Word: DOCX gerado, contendo a nova figura e o mesmo parágrafo interpretativo. As cópias HTML/PDF/DOCX em `docs/` são idênticas aos originais da raiz.
- Hashes dos CSVs e PNGs anteriores permaneceram idênticos. Entre os scripts R, somente o módulo de apresentação `08` mudou. O novo PNG é um produto reproduzível, ignorado pelo Git. Não foi alterado o NetCDF nem incluída a base no versionamento.
- Verificação específica do gráfico aprovada. A suíte estatística não foi repetida nesta alteração de apresentação; o resumo científico integral e todos os produtos numéricos anteriores foram conferidos contra a execução anterior.
- Revisão final de largura: a nova figura usa `out-width: "95%"` no Quarto, evitando corte do último rótulo do eixo na saída Word. Os três formatos foram renderizados novamente e revalidados após esse ajuste. PDF final com 27 páginas (figura na página 12); prévia LibreOffice do Word com 21 páginas (figura na página 9), inspecionada com título, eixos e legenda completos. A paginação pode variar no Microsoft Word.

## Densidade mensal, remoção do PP gráfico e probabilidades — 27/10/2026

A Figura 7 mantém os mesmos 94 máximos mensais elegíveis da GEV, em escala original, incluindo todos os extremos. O eixo Y passou a densidade: `after_stat(density)` no histograma, com as oito classes anteriores de Sturges. Sobrepôs-se uma KDE gaussiana por `geom_density`, com largura automática `nrd0` e cor contrastante. `trim=TRUE` restringe somente o desenho da curva ao intervalo observado, sem retirar observações de sua estimação. O kernel pode ter viés de fronteira; o texto identifica a KDE como não paramétrica e não a utiliza para justificar Fréchet, suporte físico ou adequação da cauda GEV.

A antiga Figura 9 era o **PP-plot da GEV mensal**, `fig-pp-gev-principal`. Seu bloco e parágrafo específico foram retirados do QMD; em `R/05_gev.R`, somente a geração desse gráfico mensal deixou de ser executada. Os PP gráficos diário/semanal, QQs, métricas RMSE PP, PIT e demais cálculos/diagnósticos permanecem. O PNG mensal obsoleto, ignorado pelo Git, foi removido. O Quarto renumera automaticamente as figuras posteriores.

A Tabela 4 conserva suas colunas anteriores, com valores inalterados, e acrescenta **Prob. de excedência mensal**, calculada em `R/08_apresentacao.R` por `100/(12*retornos$tabela$anos)` e formatada com duas casas: **8,33%, 4,17%, 1,67% e 0,83%**. Os CSVs numéricos originais permanecem; só o CSV de resumo ganha a coluna formatada. O texto vincula a nova coluna à fórmula e aos exemplos dinâmicos de um e dez anos, sem prometer ocorrência anual obrigatória.

A auditoria específica verificou igualdade dos valores e datas da amostra com a seleção da GEV, 94 contribuições às barras, área do histograma igual a um, eixo X identidade, KDE finita/não negativa e largura/kernel especificados. Conferiu também as quatro probabilidades calculadas programaticamente e preservação integral do resumo científico anterior (`all.equal`). Não houve mudança de qualidade, cobertura, estimação GEV, parâmetros, níveis ou bootstrap.

### Verificações e renderização desta atualização

- `bash scripts/renderizar_publicar.sh`: concluído sem erros, com a base real, gerando HTML, PDF e DOCX e atualizando `docs/`.
- HTML: histograma + KDE visíveis na Figura 7; Tabela 4 com quatro colunas e probabilidades corretas. Todas as imagens carregam, sem transbordamento da página em 390 px. Inspeção visual do gráfico e da tabela.
- A única figura retirada foi `fig-pp-gev-principal`. Permanecem todas as demais figuras e tabelas; as figuras agora vão de 1 a 11. O gráfico de níveis de retorno passou de Figura 10 a Figura 9. Não há destinos de referências internas ausentes. A Tabela 4 mantém a mesma numeração e seus valores anteriores foram comparados célula a célula.
- PDF: 27 páginas; Figura 7 na página 12 e Tabela 4 na página 14, inspecionadas, com eixos, curva, colunas e valores completos.
- Word: arquivo gerado e conferido no XML; prévia LibreOffice com 20 páginas, Figura 7 na página 9 e Tabela 4 na página 11, inspecionadas sem corte do novo conteúdo. A paginação no Microsoft Word pode variar.
- O resumo científico completo permanece idêntico ao anterior. Hashes confirmaram preservação de todos os CSVs e PNGs anteriores, exceto os dois produtos de apresentação solicitados (histograma e tabela resumida) e o PP mensal removido. O módulo `05` mudou somente na geração gráfica do PP mensal; `08` somente na apresentação da KDE/probabilidade.
- Auditoria específica dos novos elementos aprovada; a suíte estatística não foi repetida para esta alteração de apresentação. Não houve alteração dos testes existentes. As três cópias do Pages são idênticas aos artefatos da raiz, e o NetCDF permanece fora do Git.
