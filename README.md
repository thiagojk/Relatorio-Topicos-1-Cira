# Valores extremos do fluxo solar GOES-16

Projeto em R e Quarto inspirado metodologicamente no trabalho de Carolyne Soares de Brito. A análise usa XRS-B, controles de qualidade do próprio NetCDF, máximos diários/semanais/mensais, GEV, extensão de localização linear no tempo, diagnósticos e níveis de retorno com bootstrap de blocos móveis.

## Situação desta entrega

O anexo NetCDF excede o limite de transferência de **32 MiB** da ferramenta. A análise científica só pode ser executada após colocar a **base real** em `Dados/`. Nenhum resultado solar foi inventado. O relatório não produz valores substitutos quando a base falta: interrompe com uma mensagem clara. Consulte `VALIDACAO.md` para o que foi realmente testado.

## Gerar o relatório

1. Instale R (>= 4.4) e Quarto (testado: 1.7.32). No Linux, `ncdf4` pode exigir `libnetcdf-dev` e compiladores se instalado a partir de fontes.
2. Coloque a base em `Dados/sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc`.
3. Na pasta deste README, execute uma vez:

```bash
Rscript scripts/instalar_pacotes.R
```

4. Gere o relatório:

```bash
quarto render relatorio.qmd
```

Abra `relatorio.html` no navegador. O HTML incorpora figuras e estilos; fórmulas usam MathML para evitar dependência de carregamento remoto. O suporte visual de MathML depende do navegador moderno.

**Nesta máquina em nuvem**, as ferramentas locais ficam em `/workspace/.tools/bin`. Antes dos comandos:

```bash
export PATH=/workspace/.tools/bin:$PATH
```

Para refazer a instalação local desta máquina Debian sem privilégios de administrador: `bash scripts/preparar_nuvem.sh`. O instalador mantém verificação de assinatura dos índices Debian e SHA256 do Quarto; os arquivos ficam fora do repositório, em `/workspace/.tools/`.

No **RStudio**, abra `projeto.Rproj`, execute `source('scripts/instalar_pacotes.R')` uma vez, abra `relatorio.qmd` e clique em **Render**. O HTML pode ser aberto pelo painel Viewer ou no navegador. Não é necessário um servidor.

PDF é opcional: `quarto render relatorio.qmd --to pdf`, após instalar uma distribuição LaTeX com os recursos de português. A exportação PDF não é requisito nem foi validada nesta entrega.

## Organização

- `R/config.R`: limiar de cobertura, bootstrap, semente, declustering e caminho relativo da base.
- `R/01_leitura_limpeza.R`: metadados CF, flags, preenchimentos, validações, `dados_xrs` e `dados_limpos`.
- `R/02_exploratoria.R`: estatísticas completas, cobertura, lacunas, gráficos e mudança anual exploratória.
- `R/03_dependencia.R`: ACF/PACF/Ljung–Box no maior trecho contíguo, sem colapsar lacunas.
- `R/04_block_maxima.R`: grades de calendário, cobertura e elegibilidade dos máximos.
- `R/05_gev.R`: múltiplos inícios de otimização, comparação de blocos e extensão temporal.
- `R/06_niveis_retorno.R`: IC por bootstrap móvel, níveis de retorno e episódios separados.
- `R/executar.R`: execução integral compartilhada com o relatório.
- `figuras/`, `tabelas/`, `resultados/`: saídas geradas, ignoradas no Git.
- `referencias/Carolyne.pdf`: referência fornecida, sem reprodução literal de seu texto.
- `testes/`: testes técnicos com uma base NetCDF artificial, exclusivamente em diretório temporário, sem resultados científicos.

Para executar só a análise: `Rscript R/executar.R`. Resultados resumidos ficam em `resultados/resumo.rds`; versões em `resultados/sessionInfo.txt`. A renderização sempre recalcula tudo. Reserve memória para milhões de registros; a leitura mantém a série original e a limpa e pode exigir alguns GB. O bootstrap pode demorar vários minutos; não é uma etapa de instalação.

## Escolhas e salvaguardas

- Datas são UTC e a origem é lida em `units`. Calendários não gregorianos, origem ambígua, coordenadas incompatíveis, duplicatas por minuto e unidades não reconhecidas interrompem a execução.
- `good_data` deve existir em `flag_meanings` com `flag_values` compatíveis. Flags em máscara sem enumeração inequívoca não são adivinhadas: exigem inspeção e adaptação explícita.
- `dados_xrs` mantém os registros organizados antes da seleção analítica; preenchimentos são representados por NA. O original permanece preservado no arquivo NetCDF.
- Cobertura padrão: 90% de cada bloco civil completo; sensibilidade em 80% e 95%. Bordas parciais não recebem denominadores reduzidos.
- Fluxos válidos não positivos são excluídos com contagem explícita; valores positivos elevados não são retirados para melhorar ajustes.
- Estatísticas usam todos os dados válidos; apenas gráficos de distribuição/Normal são amostrados (semente fixa, até 20 mil pontos).
- Maior agregação com ao menos 50 máximos, convergência, suporte e erro da forma válido, em região regular, é o padrão principal após a comparação. A regra não promete independência ou melhor ajuste. Alternativas são mostradas; diagnósticos podem desaconselhar extrapolação.
- AIC é comparado para estacionariedade apenas na mesma amostra; não seleciona entre blocos.
- IC principais: 399 replicações bootstrap circular móvel, janela `ceiling(n^(1/3))` da grade regular, com lacunas preservadas; mínimo de 80% e 100 replicações válidas. Intervalos da Hessiana são apresentados como aproximação iid.
- Comparação não estacionária: localização linear, escala/forma constantes; AIC e LRT nominais são exploratórios sob dependência. Uma tendência não modela um ciclo inteiro.
- Declustering: excedências do P99,9 global, regra de intervalo entre excedências, 6 h como principal, 1/24 h para sensibilidade. Não constitui identificação física de flares.
- Níveis históricos estacionários de 1, 2, 5 e 10 anos são resumos condicionais às hipóteses. Sob mudança temporal, não são previsões. Quantis da extensão mantêm a covariável congelada e recebem ressalvas explícitas.
- Não se conclui independência com p > 0,05, nem cauda Fréchet apenas pelo sinal de xi ou desvio de normalidade.

## Testes técnicos

```bash
Rscript testes/testar.R
```

Os dados artificiais existem somente para testar contratos, conversões, rejeições e a execução dos módulos; nunca são gravados em `Dados/` real nem apresentados como observações solares. Para o teste de renderização em área temporária, consulte o procedimento em `VALIDACAO.md`.
