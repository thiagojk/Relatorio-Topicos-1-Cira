# Validação da análise com a base real GOES-16

Validação original em 22 de outubro de 2026; comparação Skew-t executada em 23 de outubro de 2026; reestruturação didática e novas versões em 27 de outubro de 2026 (registro ao final). Este registro descreve os resultados efetivamente executados com o arquivo real; a validação técnica artificial é separada.

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
- HTML da versão GEV original: 5767095 bytes; a versão ampliada está registrada na validação Skew-t abaixo.
- Chromium da versão GEV original: 37 imagens incorporadas, 25 tabelas, 21 elementos MathML; nenhuma imagem quebrada, erro JavaScript ou tabela larga em viewport de 1440 px. Acesso externo foi bloqueado durante a inspeção.
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

## Acréscimo Skew-t — execução real de 23/10/2026

### Preservação e amostra

Antes da edição foram lidos README, este registro, QMD e os módulos R. A amostra é `block$blocos$mensal[elegivel == TRUE]`, a mesma armazenada reescalonada em `modelos$modelos$mensal$fit$data`. `amostra_mensal_comum()` compara quantidade, valores na ordem original e datas, além de finitude, positividade e ausência de duplicação. O objeto explícito é `skew_t$amostra_comum`.

| n | primeiro | ultimo | minimo | mediana | maximo | invalidos |
|---|---|---|---|---|---|---|
| 94 | 2017-03-01 | 2025-03-01 | 4.1009429e-08 | 1.8975044e-05 | 0.0014640847 | 0 |

A nova execução completa foi confrontada com o RDS anterior: todos os componentes previamente existentes, incluindo parâmetros GEV, bootstrap, retornos, calibração, comparação de blocos e extensão linear, foram preservados integralmente (`all.equal` em cada componente). O CSV dos parâmetros GEV também é idêntico byte a byte. Nenhum extremo foi removido do ajuste principal.

### Implementação e otimização

- Pacote `sn` 2.1.1; Skew-t univariada de Azzalini–Capitanio, parametrização direta DP `(xi, omega, alpha, nu)`.
- Localização xi_ST não é a forma xi_GEV; omega é escala, não desvio padrão; alpha é slant, não coeficiente de assimetria; nu são graus de liberdade.
- `sn::st.mple(penalty=NULL)`: sem penalização, 8 conjuntos iniciais e dois métodos (nlminb e Nelder–Mead), 16 tentativas por cenário. Densidade/CDF/quantis: `sn::dst/pst/qst`, sem implementação manual.
- Reescalonamento linear pela mesma mediana da GEV, sem log-transformar resposta, truncamento em zero ou limite arbitrário para alpha. A soma das log-densidades é conferida independentemente em W/m², com correção `-n*log(s)`.
- A solução selecionada termina numericamente, mas `sn` sinaliza fronteira: alpha diverge sem estimativa finita identificável. Não é um MLE interior regular validado. Não se publicam EP/IC Wald; traços/NA são informativos, não erros zero.
- Nu < 1 implica média indefinida no modelo ajustado; não se atribui essa propriedade à emissão solar.
- `otimizacao_skew_t.csv` registra inícios, métodos, códigos, mensagens e avisos de todas as tentativas e cenários. As mensagens e falhas de convergência também aparecem no relatório. Não se apagam warnings para apresentar estabilidade fictícia.

| parametro | estimativa | ep | inferior | superior | unidade |
|---|---|---|---|---|---|
| xi_ST (localização) | 4.1009428e-08 | — | — | — | W m^-2 |
| omega (escala) | 2.1814254e-06 | — | — | — | W m^-2 |
| alpha (slant) | 6.0071775e+14 | — | — | — | adimensional |
| nu (graus de liberdade) | 0.30886067 | — | — | — | adimensional |

O valor numérico enorme de alpha pode variar entre execuções/ambientes com pouca variação da verossimilhança: os dígitos não representam precisão inferencial. A fronteira é o resultado relevante. A Hessiana só produziria EP/IC numa solução interior, positiva definida e bem condicionada, com gradiente pequeno; a dependência ainda tornaria tais intervalos nominais.

### Comparação na unidade original W/m²

| modelo | n | k | logLik | AIC | BIC |
|---|---|---|---|---|---|
| GEV | 94 | 3 | 826.12354 | -1646.2471 | -1638.6172 |
| Skew-t | 94 | 4 | 816.67238 | -1625.3448 | -1615.1716 |

Os números absolutos diferem do AIC de estacionariedade registrado acima porque aquela comparação usa os fluxos numericamente reescalonados. Não houve mudança de ajuste GEV: aqui ambos os modelos incluem o mesmo Jacobiano para W/m². Critérios Skew-t são nominais na fronteira; dependência e heterogeneidade limitam a interpretação clássica para ambas as famílias. Não se usa LRT entre GEV e Skew-t.

| modelo | rmse_pp | erro_log_cauda | quantil_maior_ponto |
|---|---|---|---|
| GEV | 0.075865653 | 1.7567828 | 5.9179623 |
| Skew-t | 0.097114462 | 1.8117653 | 15.515886 |

Menor é melhor para RMSE PP e erro médio absoluto log10(teórico/observado), nos pontos QQ com p >= 0,90. A GEV é relativamente menos discrepante; ambas excedem drasticamente os maiores valores. As curvas de densidade visualizadas em log10 usam o Jacobiano correto `x*log(10)`. Não se interpreta o aparente ajuste central como validação dos extremos.

### Quantis da cauda e equivalentes

| probabilidade | n_esperado_acima | empirico | GEV | Skew_t | erro_rel_GEV | erro_rel_Skew_t |
|---|---|---|---|---|---|---|
| 0.9 | 9.4 | 0.00021901725 | 0.0015155639 | 0.0011626358 | 5.919838 | 4.3084214 |
| 0.95 | 4.7 | 0.00037364204 | 0.011146563 | 0.010966716 | 28.832198 | 28.350862 |
| 0.975 | 2.35 | 0.0007472419 | 0.078909127 | 0.10344791 | 104.60051 | 137.43966 |
| 0.99 | 0.94 | 0.00093421097 | 1.0218203 | 2.0097086 | 1092.779 | 2150.2364 |

Quantis empíricos usam interpolação tipo 7. Erros relativos são frações, não porcentagens. P95 já tem menos de 5 observações esperadas acima; P99 tem menos de uma. São diagnósticos exploratórios, com grande incerteza e informação efetiva menor sob dependência. A Skew-t aproxima relativamente melhor P90/P95, mas piora P97,5/P99 e o erro agregado do QQ superior.

| anos | probabilidade | GEV | Skew_t | razao_Skew_t_maximo |
|---|---|---|---|---|
| 1 | 0.91666667 | 0.0025759025 | 0.0020979854 | 1.4329672 |
| 2 | 0.95833333 | 0.018700191 | 0.019789802 | 13.516842 |
| 5 | 0.98333333 | 0.24567146 | 0.3844619 | 262.59539 |
| 10 | 0.99166667 | 1.6977544 | 3.6265962 | 2477.0398 |

São **quantis equivalentes da Skew-t**, não níveis de retorno TVE validados. Não substituem os níveis GEV e seus IC. As extrapolações de ambas as famílias são excessivas; a Skew-t não recebe intervalos artificiais de precisão numa solução de fronteira.

### Influência dos maiores máximos

| cenario | modelo | n | localizacao | escala | xi_GEV | alpha_ST | nu_ST | logLik | AIC | BIC |
|---|---|---|---|---|---|---|---|---|---|---|
| completa | GEV | 94 | 2.9785681e-06 | 8.2079783e-06 | 2.771987 | — | — | 826.12354 | -1646.2471 | -1638.6172 |
| completa | Skew-t | 94 | 4.1009428e-08 | 2.1814254e-06 | — | 6.0071775e+14 | 0.30886067 | 816.67238 | -1625.3448 | -1615.1716 |
| sem_1_maior | GEV | 93 | 2.8755738e-06 | 7.8462533e-06 | 2.7446907 | — | — | 822.97181 | -1639.9436 | -1632.3458 |
| sem_1_maior | Skew-t | 93 | 4.1009428e-08 | 2.1786356e-06 | — | 3.2687844e+14 | 0.31418332 | 813.70489 | -1619.4098 | -1609.2794 |
| sem_3_maiores | GEV | 91 | 2.6847053e-06 | 7.1995205e-06 | 2.6977256 | — | — | 815.38397 | -1624.7679 | -1617.2354 |
| sem_3_maiores | Skew-t | 91 | 4.1009428e-08 | 2.1471002e-06 | — | 1.1068877e+15 | 0.32327913 | 806.49289 | -1604.9858 | -1594.9424 |

| cenario | delta_AIC | delta_BIC | rmse_pp_GEV | rmse_pp_ST | P99_GEV | P99_ST |
|---|---|---|---|---|---|---|
| completa | 20.902337 | 23.445632 | 0.075865653 | 0.097114462 | 1.0218203 | 2.0097086 |
| sem_1_maior | 20.533837 | 23.066436 | 0.076946695 | 0.09767407 | 0.8700922 | 1.5747933 |
| sem_3_maiores | 19.782141 | 22.293001 | 0.078485352 | 0.098331251 | 0.65444703 | 1.0448669 |

Diferenças são Skew-t menos GEV, sempre dentro da mesma amostra do cenário. A preferência dos critérios pela GEV persiste sem um e sem três maiores. Nu varia e a escala das extrapolações muda, mas alpha permanece na fronteira e os problemas de cauda não desaparecem. Não se compara AIC absoluto entre cenários com n diferente nem se excluem dados do ajuste principal por esse motivo.

### Conclusão empírica

**A Skew-t apresentou evidência de ajuste empírico melhor que a GEV para os máximos mensais? Não.** AIC/BIC nominais e PP favorecem a GEV; a Skew-t melhora alguns quantis menos extremos, mas piora a cauda mais alta e tem assimetria não identificável como parâmetro finito. A GEV também falha na calibração superior. Nenhuma família global investigada autoriza previsão segura; dependência, mistura de fases solares, n mensal pequeno e incerteza estrutural permanecem.

A referência Azzalini e Capitanio (2003) e a citação de `sn` foram verificadas na documentação instalada (`help("st.mple", package="sn")` e `citation("sn")`), sem inventar bibliografia. O relatório reproduz a citação do pacote e registra versões.

### Testes e renderização da extensão

- `Rscript testes/testar.R`: aprovado, status 0; fixture somente em `/tmp/goes_TESTE_ARTIFICIAL_*`.
- Novos testes: identidade da amostra e rejeição de divergência, ajuste e parâmetros válidos, densidade normalizada/caso Student simétrico conhecido, inversão CDF/quantil, fórmulas AIC/BIC, Jacobiano, diagnósticos finitos, cenários comuns e incerteza indisponível em fronteira. Testes anteriores preservados.
- `Rscript R/executar.R`: concluído, status 0, base real original.
- `quarto render relatorio.qmd`: concluído, status 0, base real; recalcula integralmente, sem reutilizar resultados artificiais.
- `bash scripts/preparar_nuvem.sh`: concluído, status 0; instaladores incluem sn e numDeriv.

- Chromium da versão ampliada: 42 imagens incorporadas, 37 tabelas e 49 elementos MathML; zero imagens quebradas/externas, erros JavaScript ou tabelas largas no viewport de 1440 px.
- As cinco novas figuras foram inspecionadas visualmente, assim como capturas do HTML nas seções de critérios e sensibilidade. As cinco tabelas de parâmetros Skew-t, critérios, cauda, sensibilidade dos critérios e quantis equivalentes foram conferidas numericamente contra os CSVs, com tolerância de arredondamento.
- Nenhum placeholder nem resultado artificial no HTML. O MD5 da base confere; os logs da execução/renderização não apresentam warnings não tratados. As falhas de convergência e a não regularidade científica são expostas nas tabelas/texto, não ocultadas.
- HTML ampliado: 6339913 bytes; SHA256 `dbb0c10e7a238d086e59732262b62113130b77673bbf81fc582c692876861f5d`. `docs/index.html` recebe cópia idêntica para preservar a estrutura Pages existente.

## Versão PDF acadêmica — 23/10/2026

### Arquivos e renderização

- Fonte única: `relatorio.qmd`; nenhuma seção científica, cálculo ou conclusão foi alterada.
- Quarto **1.7.32**, R **4.5.0**.
- Mecanismo: **XeLaTeX**, XeTeX 3.141592653-2.6-0.999996, TeX Live 2025/dev/Debian já instalado. Não foi necessário instalar TinyTeX ou substituir a distribuição existente.
- `quarto render relatorio.qmd --to pdf`: concluído, status 0, com a base real.
- `quarto render relatorio.qmd --to html`: concluído novamente depois das correções PDF, status 0.
- PDF: [`relatorio.pdf`](relatorio.pdf), na raiz, **50 páginas A4**, **4442806 bytes** (aproximadamente 4.44 MB).
- SHA256 PDF: `be0fabed07f4e0bf9b68c77d9b05783f91aa0a86cc5b31db8412f14f61471049`.
- HTML local: `relatorio.html`. A cópia publicada `docs/index.html` foi preservada byte a byte.

### Adaptações exclusivas do PDF

- Classe `scrartcl`, margens de 24 mm, fonte de texto 11 pt e entrelinha 1,12. Fontes DejaVu Serif/Sans/Mono e Latin Modern Math.
- Capa com título, subtítulo e data já disponíveis, sem inventar autoria ou afiliação. Sumário com os títulos reais, seções e páginas numeradas; largura dos números do sumário ajustada para seções de dois dígitos.
- `formatos/pdf-cabecalho.tex`: capa, espaçamento, preservação dos títulos com o conteúdo seguinte, legendas e quebra de identificadores extensos. Saída de `sessionInfo()` com quebra de linhas, sem ultrapassar margens.
- `formatos/tabelas_pdf.R`: os mesmos valores formatados pelo HTML são apresentados em `longtable`, com colunas proporcionais e texto quebrável, fonte de 9,5 pt, cabeçalhos repetidos e reserva de altura para tabelas curtas. Nenhuma linha ou coluna foi removida.
- `formatos/pdf-callouts.lua`: o quadro de advertência conserva título e texto em uma caixa sóbria, sem ícone de interface. Também permite quebrar identificadores longos sem mudar seus caracteres.
- As 42 figuras usam os PNGs originais, sem recorte, mudanças nos dados ou reconstrução estética. O Quarto as apresenta individualmente, com proporções preservadas e legendas anexas; os QQ comparativos permanecem grandes e legíveis.
- O tema SCSS e o CSS HTML não foram modificados. Código continua oculto; equações são compostas pelo LaTeX, sem depender de MathML ou de recursos remotos.

### Inspeção visual e conferências

**Todas as 50 páginas foram rasterizadas e inspecionadas visualmente**, incluindo capa, sumário, texto, equações GEV/suporte/retorno/Skew-t, tabelas, gráficos, referências e informações da sessão. As páginas finais foram comparadas pixel a pixel com a diagramação inspecionada: nenhuma diferença visual.

- 42 figuras e 37 tabelas presentes. Nenhuma figura cortada, legenda de figura em página diferente, tabela ultrapassando a área útil, coluna ausente ou página em branco.
- Verificação das caixas delimitadoras de texto/imagens: nenhum conteúdo fora das margens úteis; a paginação no rodapé foi excluída desse teste intencionalmente.
- 436 valores numéricos distintos das tabelas HTML encontrados no texto extraído do PDF. Todas as demais células também foram localizadas, desconsiderando somente espaços e normalização Unicode.
- Tabelas pequenas, inclusive parâmetros GEV e Skew-t, foram conferidas inteiras; tabelas extensas podem continuar com os cabeçalhos repetidos.
- Nenhum código LaTeX literal de tabelas, símbolo de substituição de caractere ou placeholder foi encontrado.
- Auditoria adicional com duas passagens XeLaTeX sobre o `.tex` final: **zero `Overfull`**, zero caracteres ausentes, zero referências indefinidas ou demais `Warning`. Permanecem **16 avisos `Underfull \hbox`**, de espaçamento em parágrafos justificados. Os trechos foram inspecionados e não apresentam cortes ou sobreposições; esses avisos não foram tratados como erros científicos.

### Preservação do HTML e dos resultados

O texto integral de `main`, as **37 tabelas** e os dados incorporados das **42 imagens** do HTML renderizado novamente são idênticos aos da versão anterior à tarefa. A cópia do Pages não foi alterada. A inspeção Chromium continua verificando imagens, tabelas e erros JavaScript.

Hashes SHA256 confirmaram que todos os scripts em `R/`, CSVs científicos e PNGs são idênticos aos anteriores. Os objetos completos de `resultados/resumo.rds` e `resultados/comparacao_skew_t.rds` também foram comparados com `all.equal`: nenhuma mudança. Não se alteraram parâmetros GEV/Skew-t, ICs, níveis de retorno, amostra ou métodos. As iterações de diagramação utilizaram o LaTeX gerado para verificar ajustes de apresentação.

### Git e reprodução PDF

`relatorio.pdf` não é ignorado e é versionado com esta entrega. As regras adicionadas ao `.gitignore` restringem-se aos intermediários de `relatorio` (`.tex`, `.aux`, `.log`, `.toc`, `.out`, entre outros). O cabeçalho LaTeX em `formatos/` é código-fonte necessário, não um intermediário. O NetCDF continua ignorado e não é incluído no commit.

O README registra os dois comandos, dependências XeLaTeX/fontes e a alternativa `quarto install tinytex` para computadores sem uma distribuição LaTeX.

## Git e reprodução

O NetCDF não é versionado. `relatorio.html`, figuras, CSVs, RDS e arquivos temporários permanecem ignorados. A cópia autocontida em `docs/index.html` é versionada para o GitHub Pages. O projeto em ZIP disponibilizado separadamente inclui os resultados, sem a base de 241 MiB.

```bash
export PATH=/workspace/.tools/bin:$PATH
Rscript R/executar.R
Rscript testes/testar.R
quarto render relatorio.qmd
```

No RStudio, abra projeto.Rproj e use Render em relatorio.qmd. Ao clonar o GitHub, obtenha primeiro o arquivo original e coloque-o em Dados/. Este documento registra a validação desta base e execução; o QMD recalcula os valores dinamicamente em novas renderizações. A saída PDF também foi validada com a base real; veja a seção de validação PDF neste documento.

## Versão Word — 23/10/2026

Renderização `quarto render relatorio.qmd --to docx` concluída com Quarto 1.7.32 e a base real. Arquivo `relatorio.docx`: 3.571.946 bytes. O modelo A4 tem margens de 24 mm, estilos de títulos, numeração de páginas e campo de sumário automático (atualizar no Word ao abrir). A configuração DOCX é independente das saídas HTML e PDF.

Auditoria OOXML confirmou as 42 figuras científicas originais incorporadas sem alteração de bytes, além do ícone de advertência; 49 expressões matemáticas nativas editáveis; e todos os 436 valores numéricos distintos das 37 tabelas científicas iguais aos do HTML publicado. Tabelas e texto são editáveis, não capturas de tela. O arquivo contém também tabelas estruturais criadas pelo Quarto para legendas, figuras e o aviso.

Conversão de inspeção pelo LibreOfficeDev 26.8 produziu 43 páginas A4. Foram rasterizadas todas as páginas, verificadas as posições dos elementos e inspecionadas visualmente capa, tabelas, gráficos, fórmulas e conclusão. Não houve conteúdo fora da página; a paginação poderá variar no Microsoft Word, que não foi executado neste ambiente. O sumário depende da atualização de campos pelo editor e não está preenchido na prévia do LibreOffice. A prévia PDF foi criada apenas em `/tmp`, sem substituir o PDF acadêmico existente.

Hashes SHA256 antes/depois confirmaram preservação byte a byte de `relatorio.pdf`, `docs/index.html`, todos os scripts científicos em `R/`, CSVs e PNGs. O pipeline foi executado pela renderização; não houve alteração de métodos nem de resultados. Não foi necessário repetir testes estatísticos para esta mudança exclusivamente de formato. O NetCDF continua fora do Git.

## Reestruturação didática — 27/10/2026

### Leitura prévia e adaptação da referência

Foram examinados o PDF `referencias/Carolyne.pdf`, o QMD anterior, README, este registro, todos os módulos R e os CSVs/RDS já produzidos, antes das alterações. Não há código-fonte separado da Carolyne no checkout: a análise da referência se limita ao PDF disponível, sem atribuir a ele uma implementação não acessível.

- **Tabela 2:** adaptada a ideia de um resumo descritivo antes da modelagem, incluindo quartis, dispersão, CV, assimetria e curtose do fluxo válido. Esses valores já existiam em `exploratoria$descritiva`; não foram inventados nem calculados em uma amostra visual.
- **Figura 2:** adaptada a sequência histograma + série histórica. Histograma mantém a amostra visual determinística de 20 mil minutos. A série usa um envelope mínimo–máximo e mediana por hora sobre todos os minutos válidos, com horas vazias na grade. O total de contribuições e a preservação do maior/menor fluxo são verificados.
- **Figura 8:** sua função é diagnosticar caudas por quantis teóricos de Gumbel. Aqui priorizou-se o QQ da GEV efetivamente ajustada e o PP, sem classificar automaticamente o domínio pela curvatura contra Gumbel.
- **Não transferidos:** Figura 3/log-retornos, VaR, preços, alfa-estável e interpretações financeiras. O objeto continua sendo magnitude do fluxo XRS-B, sem identificar fisicamente flares.

### Estrutura e produtos de apresentação

O corpo principal agora tem Introdução, Referencial teórico, Dados e metodologia, Análise descritiva, Resultados (seis subseções), Discussão, Conclusão e Referências. Contém **sete tabelas e onze figuras** selecionadas; com o apêndice, são **23 tabelas e 14 figuras**, em vez de 37 e 42 anteriormente.

Otimização, contabilidade de flags, dependência detalhada, incerteza complementar, quantis condicionais/equivalentes e sensibilidades ficaram no apêndice ou nos arquivos de resultados. Reduziram-se repetições, múltiplos histogramas/boxplots equivalentes, QQ Normal e diagnósticos de todas as agregações no texto. Esses produtos continuam a ser calculados e exportados, sem retirar análise do pipeline.

`R/08_apresentacao.R`, integrado a `R/executar.R`, deriva seis tabelas: descritiva limpa, comparação de blocos, GEV com IC bootstrap, níveis de retorno, comparação conjunta GEV × Skew-t e comparação temporal em W/m². Exporta os CSVs `descritiva_relatorio`, `blocos_relatorio`, `gev_relatorio`, `retornos_relatorio`, `comparacao_relatorio` e `estacionariedade_relatorio`. Não realiza novos ajustes nem sorteios.

Três novas figuras: `serie_fluxo_horaria.png`, `maximos_comparados.png` e `mensais_destaque.png`. O último gráfico usa exatamente os 94 máximos da amostra comum, destaca os três maiores e identifica seus meses, não datas de erupções físicas. O envelope horário é um resumo visual de todos os minutos; não se afirma que é uma curva desenhada na resolução original de um minuto. A grade conserva horas/blocos ausentes, sem aproximá-los como períodos adjacentes.

A comparação temporal é reconvertida somente na apresentação para W/m², aplicando o mesmo Jacobiano aos dois modelos. Os critérios originais permanecem no CSV anterior. As diferenças de AIC, o ajuste e o teste não se alteram. A tabela principal de parâmetros GEV usa os IC bootstrap já calculados; erros padrão e IC de Wald permanecem no apêndice.

### Preservação científica

Antes das alterações foram guardados hashes dos 100 arquivos R/CSV/PNG anteriores e cópias dos dois RDS científicos. Após as renderizações reais:

- `all.equal` confirmou igualdade integral de `resultados/resumo.rds` e `resultados/comparacao_skew_t.rds` com o estado anterior;
- todos os CSVs e PNGs anteriores são idênticos byte a byte;
- módulos estatísticos `R/01_*` a `R/07_*`, `R/config.R` e `R/utils.R` não foram alterados; somente o executor recebeu o módulo de apresentação;
- amostra, forma GEV 2,771987, bootstrap, níveis de retorno, logLik/AIC/BIC, solução Skew-t de fronteira e conclusões são os mesmos;
- nenhuma exclusão adicional de extremos, transformação em log-retorno ou resultado artificial entrou no relatório.

A conclusão foi reescrita sem mudar seu sentido: GEV relativamente melhor que a Skew-t considerada, mas ambas mal calibradas na cauda superior; a localização linear não resolve a heterogeneidade; extrapolação prospectiva não foi validada. As referências acadêmicas do projeto foram mantidas e citadas no texto. Não se acrescentou bibliografia externa não verificada.

### Execução e inspeção das versões

- `Rscript testes/testar.R`: status 0. Fixture em `/tmp/goes_TESTE_ARTIFICIAL_2e7464e1d18e`, isolada da base real. Novas asserções verificam conservação de contagem/extremos pelo envelope, identidade mensal, níveis de retorno e invariância dos critérios após mudança de unidade.
- `quarto render relatorio.qmd --to html`: status 0 com a base real; última execução após o ajuste de CSS para telas estreitas.
- `quarto render relatorio.qmd --to pdf`: status 0 com a base real. A inspeção identificou duas figuras que ultrapassavam o rodapé; `fig-pos: H` foi adotado no formato PDF. A composição final foi validada por duas passagens XeLaTeX no LaTeX gerado, sem refazer cálculos nas iterações de diagramação.
- `quarto render relatorio.qmd --to docx`: status 0 com a base real. Word atualizado para acompanhar a mesma reestruturação.
- Chromium: 14 imagens incorporadas, 23 tabelas, 32 elementos MathML; zero imagens quebradas, erros JavaScript, links internos sem destino, referências não resolvidas ou placeholders. Dez tabelas foram confrontadas numericamente com os CSVs. Viewport de 1440 px sem tabelas excessivamente largas; viewport de 390 px sem transbordamento da página (tabelas largas e equação têm rolagem própria).
- PDF: **30 páginas A4**, com 14 figuras e 23 tabelas numeradas. Todas as páginas foram rasterizadas e inspecionadas em painéis; conferidas capa, sumário, equações, tabelas, gráficos, conclusão e apêndice. Nenhum texto/imagem fora das margens úteis e nenhum corte de legenda. Zero `Overfull`, caracteres ausentes, referências indefinidas ou `Warning`; permanecem 18 avisos `Underfull` de espaçamento, sem cortes ou sobreposições.
- 230 valores numéricos distintos das tabelas HTML foram encontrados no texto PDF e no XML Word; a tabela descritiva formatada também foi confrontada integralmente com seu CSV no HTML.
- Word: 14 imagens e 32 equações nativas. A prévia LibreOfficeDev 26.8 tem 25 páginas, com texto dentro da página. A paginação pode variar no Microsoft Word, não executado nesta máquina; o sumário automático deve ser atualizado ao abrir. A prévia foi criada em `/tmp` e não substitui o PDF acadêmico.
- `docs/index.html` recebeu cópia byte a byte do HTML final. A estrutura Pages `main` + `/docs` permanece a mesma; HTML continua sendo o formato padrão.

### Artefatos desta versão

- `docs/index.html`: 3180647 bytes; SHA256 `855321ed49a67033957af69bd998e4daff7bb196e42af154a328ba29c4fea168`.
- `relatorio.pdf`: 1689726 bytes; SHA256 `fd06bc67c9461e6df76ae11edff48d09a831ac2f2e3b17c98a9061e30daff9b6`.
- `relatorio.docx`: 1390526 bytes; SHA256 `f247a9f113bbf40bb6987108d34ced1b08c53cb3f4803f8ca818edcafcdbb02c`.

O NetCDF continua ignorado e não é incluído no Git. Os registros de 22/23 de outubro acima são históricos; contagens e tamanhos desta seção descrevem a versão reestruturada atual.
