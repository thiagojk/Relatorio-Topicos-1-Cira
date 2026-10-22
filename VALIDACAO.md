# Validação da análise com a base real GOES-16

Validação realizada em 22 de outubro de 2026. Este registro descreve os resultados efetivamente executados com o arquivo real; a validação técnica artificial é separada.

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

## Execução e verificações

- `Rscript R/executar.R`: concluído com a base real, status 0.
- `Rscript testes/testar.R`: aprovado, status 0. Os testes artificiais ficam em pasta temporária e não alimentam o relatório real. Incluem código good_data não zero, máscaras compostas, dimensão sem coordenada, faixa válida e regressão da comparação aninhada.
- `quarto render relatorio.qmd`: concluído com a base real, status 0.
- HTML: `/workspace/Relatorio-Topicos-1-Cira/relatorio.html` (5767095 bytes).
- Chromium: 37 imagens incorporadas, 25 tabelas, 21 elementos MathML; nenhuma imagem quebrada, erro JavaScript ou tabela larga em viewport de 1440 px. Acesso externo foi bloqueado durante a inspeção.
- As 37 figuras foram inspecionadas visualmente em painéis, e título, tabelas de parâmetros, níveis de retorno e principais figuras foram também conferidos no HTML.
- Valores renderizados das tabelas de parâmetros e retornos foram confrontados com os CSVs, respeitando o arredondamento de apresentação. O MD5 da base aparece no HTML e coincide com o RDS.
- R 4.5.0; Quarto 1.7.32; versões dos pacotes em `referencias/pacotes_validados.tsv` e `resultados/sessionInfo.txt`.

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

## Problemas encontrados e correções

- Dimensão quad_diode sem variável coordenada: excluída da busca por unidade temporal; nenhuma origem temporal foi fixada manualmente.
- Flags compostas: interpretadas pelas máscaras declaradas; a frequência anterior à exclusão registra eclipse + interpolação corretamente.
- Avisos ncdf4 sobre atributos inteiros de oito bytes: preservados em `tabelas/avisos_metadados.csv`. Afetam algorithm_version e input_files_total; os valores efetivos são pequenos e representáveis em double. Não alteram tempo/fluxo/flags.
- Máximos locais numéricos e Hessiana sensível ao suporte: múltiplos inícios, Nelder–Mead, passo de diferenciação menor e conferência independente da log-densidade.
- Comparação aninhada: a extensão começa também na solução estacionária e não pode produzir LRT válido com verossimilhança pior.
- ACFs de recortes diferentes: adicionada comparação de pares adjacentes de toda a grade, sem remover lacunas.
- Sensibilidade de cobertura e retirada apenas diagnóstica de um/três maiores máximos: exportada em `tabelas/sensibilidade_ajustes.csv`; os valores elevados permanecem no ajuste principal.
- Episódios separados: ranking, data e horário são exportados. A regra de seis horas gera 161 episódios; janelas de uma e 24 horas permanecem como sensibilidades, não um catálogo físico de flares.
- Incerteza da extensão linear: IC delta no log-quantil quando positivo, sem truncar limites negativos arbitrariamente.
- A renderização final não registrou warnings não tratados. Os avisos científicos xi >= 1 e as limitações de calibração estão explicitamente expostos no relatório.

## Git e reprodução

O NetCDF não é versionado. HTML, figuras, CSVs, RDS e arquivos temporários de renderização também permanecem ignorados quando são produtos reproduzíveis. O projeto em ZIP disponibilizado separadamente inclui os resultados, sem a base de 241 MiB.

```bash
export PATH=/workspace/.tools/bin:$PATH
Rscript R/executar.R
Rscript testes/testar.R
quarto render relatorio.qmd
```

No RStudio, abra projeto.Rproj e use Render em relatorio.qmd. Ao clonar o GitHub, obtenha primeiro o arquivo original e coloque-o em Dados/. Este documento registra a validação desta base e execução; o QMD recalcula os valores dinamicamente em novas renderizações. A exportação PDF é opcional e não foi validada com a base real.
