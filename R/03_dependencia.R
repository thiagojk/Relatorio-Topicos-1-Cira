analisar_dependencia <- function(exploratoria,block) {
  series <- list(mediana_diaria=exploratoria$diario$mediana)
  for(t in names(block$blocos)) {
    b<-block$blocos[[t]]
    series[[paste0('maximos_',t)]]<-ifelse(b$elegivel,b$maximo,NA_real_)
  }
  resultados<-list(); graficos<-list(); resumo<-list()
  for(nm in names(series)) {
    v<-serie_contigua(series[[nm]]); n<-length(v)
    zlog<-log10(series[[nm]]);ant<-head(zlog,-1);seg<-tail(zlog,-1)
    pares<-is.finite(ant)&is.finite(seg)
    rho<-if(sum(pares)>=3L)stats::cor(ant[pares],seg[pares]) else NA_real_
    resumo[[nm]]<-data.table(serie=nm,total=length(series[[nm]]),trecho=n,
      ausentes=sum(!is.finite(series[[nm]])),n_pares=sum(pares),cor_pares=rho)
    if(n<12L || sd(v)==0) next
    y<-log10(v); lagmax<-min(36L,floor(n/4))
    ac<-as.numeric(acf(y,lag.max=lagmax,plot=FALSE)$acf)[-1]
    pa<-as.numeric(pacf(y,lag.max=lagmax,plot=FALSE)$acf)
    dg<-rbind(data.table(lag=seq_along(ac),valor=ac,tipo='ACF'),
              data.table(lag=seq_along(pa),valor=pa,tipo='PACF'))
    graficos[[nm]]<-fig(ggplot(dg,aes(lag,valor))+geom_hline(yintercept=0)+
      geom_hline(yintercept=c(-1,1)*1.96/sqrt(n),linetype=2,color='grey50')+
      geom_segment(aes(xend=lag,yend=0),color=cor)+facet_wrap(~tipo)+
      labs(title=paste('Dependência de log10:',nm),x='Lag (blocos da série)',y='Correlação'),paste0('dependencia_',nm))
    lags<-c(1,3,6,12,24); lags<-lags[lags<min(n/4,lagmax+1)]
    resultados[[nm]]<-rbindlist(lapply(lags,function(l) {
      bt<-Box.test(y,lag=l,type='Ljung-Box')
      data.table(serie=nm,n=n,lag=l,estatistica=unname(bt$statistic),p=bt$p.value,acf1=ac[1])
    }))
  }
  testes<-rbindlist(resultados); res<-rbindlist(resumo)
  csv(testes,'ljung_box');csv(res,'trechos_dependencia')
  list(testes=testes,trechos=res,plots=graficos)
}
