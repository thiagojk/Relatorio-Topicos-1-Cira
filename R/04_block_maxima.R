construir_blocos <- function(base) {
  d <- base$dados_limpos
  tipos <- c('diario','semanal','mensal')
  blocos <- setNames(lapply(tipos,function(tipo) {
    ini <- bloco_inicio(min(base$dados_xrs$data),tipo)
    fim <- bloco_inicio(max(base$dados_xrs$data),tipo)
    grade <- data.table(inicio=seq(ini,fim,by=switch(tipo,diario='day',semanal='week',mensal='month')))
    observado <- d[,.(n=.N,maximo=max(xrsb_flux)),by=.(inicio=bloco_inicio(data,tipo))]
    b <- merge(grade,observado,by='inicio',all.x=TRUE,sort=TRUE)
    b[is.na(n),n:=0L]; b[,fim:=bloco_fim(inicio,tipo)]
    b[,esperado:=as.numeric(fim-inicio)*1440]
    b[,cobertura:=n/esperado]
    b[,elegivel:=cobertura>=config$cobertura & is.finite(maximo)]
    if(any(b$cobertura>1+1e-6)) stop('Cobertura >100%; confira a grade temporal.')
    csv(b,paste0('blocos_',tipo)); b
  }),tipos)
  sens <- rbindlist(lapply(tipos,function(t) rbindlist(lapply(config$coberturas,function(corte)
    data.table(bloco=t,corte=corte,n_total=nrow(blocos[[t]]),n_elegivel=sum(blocos[[t]]$cobertura>=corte))))))
  csv(sens,'sensibilidade_cobertura')
  plots <- lapply(tipos,function(t) {
    b <- copy(blocos[[t]]); b[elegivel == FALSE,maximo:=NA_real_]
    fig(linha(b,'inicio','maximo',paste('Máximos por bloco:',t)),paste0('maximos_',t))
  }); names(plots)<-tipos
  list(blocos=blocos,sensibilidade=sens,plots=plots)
}
