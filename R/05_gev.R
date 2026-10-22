ajustar_seguro <- function(x, tempo=NULL, erros=TRUE) {
  avisos<-character(); tentativas<-list()
  sc<-sd(x)*sqrt(6)/pi
  if(length(x)<30 || !is.finite(sc) || sc<=0) return(list(ok=FALSE,erro='Menos de 30 máximos ou variância nula.'))
  for(xi in c(0,.15,-.1,.4)) {
    st<-list(loc=mean(x)-.57722*sc,scale=sc,shape=xi)
    if(!is.null(tempo)) st<-c(st[1],list(loctempo=0),st[-1])
    f<-tryCatch(withCallingHandlers(
      evd::fgev(x,start=st,nsloc=if(is.null(tempo)) NULL else data.frame(tempo=tempo),
        std.err=FALSE, control=list(maxit=1500)),
      warning=function(w) {avisos<<-c(avisos,conditionMessage(w)); invokeRestart('muffleWarning')}),
      error=function(e) e)
    if(!inherits(f,'error') && identical(f$convergence,'successful') && is.finite(f$deviance) && f$deviance<2e6) {
      loc<-f$estimate['loc']; if(!is.null(tempo)) loc<-loc+f$estimate['loctempo']*tempo
      suporte<-1+f$estimate['shape']*(x-loc)/f$estimate['scale']
      if(all(is.finite(suporte)&suporte>0)) tentativas[[length(tentativas)+1L]]<-f
    }
  }
  if(!length(tentativas)) return(list(ok=FALSE,erro=paste('Nenhuma otimização válida.',paste(unique(avisos),collapse='; '))))
  f<-tentativas[[which.min(vapply(tentativas,function(z)z$deviance,numeric(1)))]]
  if(erros) {
    ff<-tryCatch(withCallingHandlers(evd::fgev(x,start=as.list(f$estimate),
      nsloc=if(is.null(tempo))NULL else data.frame(tempo=tempo),std.err=TRUE,control=list(maxit=1500)),
      warning=function(w) {avisos<<-c(avisos,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e)e)
    if(!inherits(ff,'error') && identical(ff$convergence,'successful') &&
       abs(ff$deviance-f$deviance)<.01) f<-ff else avisos<-c(avisos,'Informação observada indisponível/inconsistente; IC de Wald indisponível.')
  }
  # Erros da Hessiana exigem regularidade; xi <= -0,5 é explicitamente sinalizado.
  if(f$estimate['shape']<=-.5) avisos<-c(avisos,'xi <= -0,5: inferência assintótica regular não garantida.')
  list(ok=TRUE,fit=f,avisos=unique(avisos))
}
modelar <- function(block,dep) {
  tipos<-names(block$blocos); modelos<-list(); linhas<-list()
  for(t in tipos) {
    b<-block$blocos[[t]]; x<-b[elegivel == TRUE,maximo]
    unidade_ajuste<-if(length(x)) median(x) else 1
    a<-ajustar_seguro(x/unidade_ajuste)
    modelos[[t]]<-c(a,list(escala=unidade_ajuste))
    ac<-dep$testes[serie==paste0('maximos_',t)]$acf1
    if(a$ok) {
      f<-a$fit; est<-f$estimate; se<-if(is.null(f$std.err)) NA_real_ else f$std.err['shape']
      pit<-sort(evd::pgev(x/unidade_ajuste,loc=est['loc'],scale=est['scale'],shape=est['shape']))
      linhas[[t]]<-data.table(bloco=t,total=nrow(b),n=length(x),fracao_retida=mean(b$elegivel),
        mu=est['loc']*unidade_ajuste,sigma=est['scale']*unidade_ajuste,xi=est['shape'],ep_xi=se,
        AIC=f$deviance+6,acf1=if(length(ac))ac[1] else NA_real_,
        rmse_pp=sqrt(mean((pit-ppoints(length(pit)))^2)),convergiu=TRUE,
        avisos=paste(a$avisos,collapse='; '))
    } else linhas[[t]]<-data.table(bloco=t,total=nrow(b),n=length(x),fracao_retida=mean(b$elegivel),
      mu=NA_real_,sigma=NA_real_,xi=NA_real_,ep_xi=NA_real_,AIC=NA_real_,acf1=NA_real_,rmse_pp=NA_real_,convergiu=FALSE,avisos=a$erro)
  }
  comp<-rbindlist(linhas);csv(comp,'comparacao_blocos')
  # A escolha ocorre somente após comparação. Preferência por maior agregação física,
  # condicionada a n>=50, erro de forma finito, suporte e convergência; sem seleção por p ou AIC entre blocos.
  candidatos<-rev(tipos)
  admissiveis<-comp[convergiu & n>=50 & is.finite(ep_xi) & xi>-.5]$bloco
  principal<-candidatos[candidatos%in%admissiveis][1]
  if(is.na(principal)) stop('Nenhum bloco com ajuste regular e >=50 máximos; consulte tabelas/comparacao_blocos.csv. Não forçar GEV.')
  estavel<-comp[bloco==principal]
  justificativa<-paste0('Escolheu-se o bloco ',principal,
    ' como a maior agregação entre as alternativas com pelo menos 50 máximos elegíveis, convergência e erro padrão de forma finito, na região regular xi > -0,5. ',
    'A comparação completa inclui retenção, dependência e discrepância PP. Esta regra privilegia a agregação de episódios solares e reduz a fragmentação de eventos, mas não garante independência nem superioridade do ajuste. ',
    'ACF e diagnósticos são apresentados como ressalvas, e resultados das alternativas permanecem disponíveis; AIC entre blocos não foi usado para seleção.')
  b<-block$blocos[[principal]][elegivel == TRUE]; a<-modelos[[principal]]; f<-a$fit
  tempo<-as.numeric(b$inicio-mean(b$inicio))/365.2425
  ns<-ajustar_seguro(b$maximo/a$escala,tempo)
  comparacao_ns<-data.table(modelo='Estacionário',parametros=3L,AIC=f$deviance+6,deviance=f$deviance)
  if(ns$ok) comparacao_ns<-rbind(comparacao_ns,data.table(modelo='Localização linear no tempo',parametros=4L,
    AIC=ns$fit$deviance+8,deviance=ns$fit$deviance))
  lr<-if(ns$ok)max(0,f$deviance-ns$fit$deviance) else NA_real_
  plr<-if(ns$ok)pchisq(lr,df=1,lower.tail=FALSE) else NA_real_
  evidencia<-ns$ok && is.finite(plr) && plr<.05 && diff(comparacao_ns$AIC)< -2
  csv(comparacao_ns,'comparacao_estacionariedade')
  if(ns$ok) csv(data.table(aviso=ns$avisos),'avisos_gev_nao_estacionaria')
  ns_parametros<-NULL
  if(ns$ok) {
    fatores<-ifelse(names(ns$fit$estimate)=='shape',1,a$escala)
    ns_parametros<-data.table(parametro=names(ns$fit$estimate),estimativa=as.numeric(ns$fit$estimate)*fatores,
      ep=if(is.null(ns$fit$std.err))NA_real_ else as.numeric(ns$fit$std.err)*fatores)
    ns_parametros[,`:=`(inferior=estimativa-1.96*ep,superior=estimativa+1.96*ep)]
    ns_parametros[,unidade:=ifelse(parametro=='shape','adimensional',ifelse(parametro=='loctempo','W m^-2 por ano','W m^-2'))]
    csv(ns_parametros,'parametros_gev_nao_estacionaria')
  }
  parametros<-data.table(parametro=c('mu','sigma','xi'),estimativa=as.numeric(f$estimate)*c(a$escala,a$escala,1),
    ep=if(is.null(f$std.err))NA_real_ else as.numeric(f$std.err)*c(a$escala,a$escala,1))
  parametros[,`:=`(inferior=estimativa-1.96*ep,superior=estimativa+1.96*ep)]
  csv(parametros,'parametros_gev')
  # Diagnósticos em todos os blocos, incluindo PP/QQ em probabilidade original.
  plots<-list()
  for(t in tipos) {
    a<-modelos[[t]];if(!a$ok)next
    x<-sort(block$blocos[[t]][elegivel == TRUE,maximo]);p<-ppoints(length(x));e<-a$fit$estimate
    teor<-evd::qgev(p,loc=e['loc'],scale=e['scale'],shape=e['shape'])*a$escala
    pp<-evd::pgev(x/a$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'])
    plots[[paste0('qq_',t)]]<-fig(ggplot(data.table(teor,x),aes(teor,x))+geom_point(color=cor,alpha=.5)+
      geom_abline(slope=1,intercept=0)+labs(title=paste('QQ GEV:',t),x='Quantil GEV (W m⁻²)',y='Quantil observado (W m⁻²)'),paste0('qq_gev_',t))
    plots[[paste0('pp_',t)]]<-fig(ggplot(data.table(p,pp),aes(p,pp))+geom_point(color=cor,alpha=.5)+
      geom_abline(slope=1,intercept=0)+labs(title=paste('PP GEV:',t),x='Probabilidade empírica',y='Probabilidade GEV'),paste0('pp_gev_',t))
    xx<-seq(min(x),max(x),length.out=600)
    dens<-data.table(x=xx,dens=evd::dgev(xx/a$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'])/a$escala)
    plots[[paste0('dens_',t)]]<-fig(ggplot(data.table(x),aes(x))+geom_histogram(aes(y=after_stat(density)),bins=25,fill='grey80')+
      geom_line(data=dens,aes(x,dens),color=cor,linewidth=.8)+labs(title=paste('Densidade GEV:',t),x='Máximo do bloco (W m⁻²)',y='Densidade'),paste0('densidade_gev_',t))
  }
  # PIT e dependência residual: comparação no mesmo trecho de calendário.
  e<-f$estimate;grid<-block$blocos[[principal]]
  u<-rep(NA_real_,nrow(grid));ok<-grid$elegivel
  u[ok]<-evd::pgev(grid$maximo[ok]/modelos[[principal]]$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'])
  pitserie<-serie_contigua(u); lp<-min(6L,floor(length(pitserie)/5))
  pitlb<-if(lp>=1) Box.test(pitserie,lag=lp,type='Ljung-Box')$p.value else NA_real_
  if(ns$ok) {
    e<-ns$fit$estimate;tn<-as.numeric(grid$inicio-mean(b$inicio))/365.2425
    un<-rep(NA_real_,nrow(grid));un[ok]<-evd::pgev(grid$maximo[ok]/modelos[[principal]]$escala,
      loc=e['loc']+e['loctempo']*tn[ok],scale=e['scale'],shape=e['shape'])
    plots$pit_ns<-fig(ggplot(data.table(p=ppoints(sum(ok)),u=sort(un[ok])),aes(p,u))+
      geom_point(color=cor)+geom_abline(slope=1,intercept=0)+
      labs(title='PP: GEV com localização linear',x='Probabilidade empírica',y='PIT condicional'),'pp_gev_nao_estacionaria')
    plots$pit_tempo<-fig(ggplot(data.table(data=grid$inicio,pit=u,pit_ns=un),aes(data,pit))+
      geom_point(color=cor)+geom_line(aes(y=pit_ns),color='#9b513d',linewidth=.4)+
      labs(title='PIT no tempo: estacionário (pontos) e linear (linha)',x='Data (UTC)',y='Probabilidade integral transformada'),'pit_tempo')
  }
  list(modelos=modelos,comparacao=comp,principal=principal,justificativa=justificativa,parametros=parametros,
    ns=ns,ns_parametros=ns_parametros,comparacao_ns=comparacao_ns,lr=lr,p_lr=plr,evidencia_ns=evidencia,
    centro_tempo=mean(b$inicio),plots=plots,pit_lb=pitlb)
}
