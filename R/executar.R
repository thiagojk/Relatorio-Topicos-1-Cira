# Executar a partir da raiz do projeto; relatorio.qmd usa exatamente esta rotina.
source('R/config.R')
source('R/utils.R')
for(arq in c('01_leitura_limpeza','02_exploratoria','03_dependencia','04_block_maxima','05_gev','06_niveis_retorno','08_apresentacao'))
  source(file.path('R',paste0(arq,'.R')))
message('1/6 — Leitura e controle de qualidade')
base <- ler_xrs(config$arquivo)
dados_xrs <- base$dados_xrs
dados_limpos <- base$dados_limpos
message('2/6 — Cobertura, exploração e mudanças anuais')
exploratoria <- explorar(base)
message('3/6 — Máximos e cobertura de blocos')
block <- construir_blocos(base)
message('4/6 — Dependência sem colapsar lacunas')
dependencia <- analisar_dependencia(exploratoria,block)
message('5/6 — Comparação e ajuste GEV')
modelos <- modelar(block,dependencia)
message('6/6 — Incerteza, retornos e episódios separados')
retornos <- retornos_eventos(base,exploratoria,block,modelos)
apresentacao <- apresentar_resultados(base,exploratoria,block,modelos,retornos)
# Não serializar as bases de milhões de linhas nem os objetos ggplot com seus dados.
resumo <- list(arquivo=basename(config$arquivo),md5=base$md5,n_total=nrow(dados_xrs),
  n_validos=nrow(dados_limpos),inicio=min(dados_xrs$data_hora),fim=max(dados_xrs$data_hora),
  bloco=modelos$principal,parametros=modelos$parametros,ic_bootstrap=retornos$bootstrap,
  retornos=retornos$tabela,forma=retornos$classe,evidencia_ns=modelos$evidencia_ns,
  p_lr=modelos$p_lr,validacao=base$validacao,comparacao_blocos=modelos$comparacao,
  comparacao_ns=modelos$comparacao_ns,calibracao=retornos$calibracao,config=config)
saveRDS(resumo,'resultados/resumo.rds')
capture.output(sessionInfo(),file='resultados/sessionInfo.txt')
message('Análise concluída. Resultados em tabelas/, figuras/ e resultados/.')
