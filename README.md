# Valores extremos do fluxo solar GOES-16

Projeto em R e Quarto inspirado metodologicamente no trabalho de Carolyne Soares de Brito. A análise usa XRS-B, controles de qualidade do próprio NetCDF, máximos diários/semanais/mensais, GEV, extensão de localização linear no tempo, diagnósticos e níveis de retorno com bootstrap de blocos móveis.

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

## Estado atual

A análise foi executada com a **base real GOES-16**, disponível localmente em `Dados/`, e o relatório é gerado por Quarto. A validação e o registro dos resultados estão em `VALIDACAO.md`.

**Resultado científico central:** a GEV estacionária global produz uma cauda excessivamente pesada e não calibra a cauda superior observada. Seus níveis de retorno são resultados formais de um ajuste inadequado para previsão, não projeções solares recomendadas. A extensão simples de localização linear não resolveu a heterogeneidade temporal. O relatório mostra os resultados, os diagnósticos e essas limitações explicitamente.

O NetCDF de 252.483.840 bytes permanece ignorado pelo Git. A cópia fornecida pelo usuário está em [Google Drive](https://drive.google.com/file/d/12OXm9-VJg8EdJA3ulyxTtnWHNax1EDHg/view). Ao clonar este repositório, baixe o arquivo e coloque-o em `Dados/`; ele não acompanha o código. SHA256 da base analisada:

```text
2b5dded7d1a6e1f55cffb4d049664dfd52b4082245ae7d8abe05bbff63a3daa0
```

O HTML é autocontido e está em `relatorio.html` após a execução. HTML, figuras, tabelas e RDS são produtos reproduzíveis ignorados pelo Git; o relatório real também é disponibilizado como artefato separado da entrega.

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

## Testes técnicos

```bash
Rscript testes/testar.R
```

Os dados artificiais existem somente para testar contratos, conversões, rejeições e a execução dos módulos; nunca são gravados em `Dados/` real nem apresentados como observações solares. Para o teste de renderização em área temporária, consulte o procedimento em `VALIDACAO.md`.
