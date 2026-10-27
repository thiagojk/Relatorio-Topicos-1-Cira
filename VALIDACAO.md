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

## Validação da execução atual

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

### Arquivos publicados


- `docs/index.html`: 2801499 bytes; SHA256 `c33c46f1933e70a2ddeb9c1bcc1810cb3a779b302952bb2e8f745ed05f54b860`.

- `docs/relatorio.pdf`: 1427204 bytes; SHA256 `1888a425f87d286b19d0fd4070229ffe2ec74f512d21bf683e88ee3a7314d822`.

- `docs/relatorio.docx`: 1140264 bytes; SHA256 `277ff7a1e9f8a88fe25e4d192a4fbc317cf23685382bd08fa213bcaad703c630`.

O NetCDF não é versionado. A implantação remota depende da execução padrão do Pages após o push; os testes HTTP descritos foram executados localmente sobre a pasta final publicada.
