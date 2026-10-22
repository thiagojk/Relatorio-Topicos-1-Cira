ajustar_seguro <- function(x, tempo=NULL, erros=TRUE, inicio=NULL) {
  avisos<-character();tentativas<-list()
  if(length(x)<30 || !is.finite(sd(x)) || sd(x)<=0) return(list(ok=FALSE,erro='Menos de 30 máximos ou variância nula.'))
  valido<-function(f) {
    if(inherits(f,'error') || !identical(f$convergence,'successful') || !is.finite(f$deviance) || f$deviance>=2e6) return(FALSE)
    e<-f$estimate;loc<-e['loc'];if(!is.null(tempo))loc<-loc+e['loctempo']*tempo
    sup<-1+e['shape']*(x-loc)/e['scale']
    if(e['scale']<=0 || any(!is.finite(sup)|sup<=0))return(FALSE)
    ll<-evd::dgev(x,loc=loc,scale=e['scale'],shape=e['shape'],log=TRUE)
    all(is.finite(ll)) && abs(-2*sum(ll)-f$deviance)<1e-3
  }
  starts<-list()
  if(!is.null(inicio)) {
    st<-as.list(inicio)
    if(!is.null(tempo) && !'loctempo'%in%names(st))st<-c(st[1],list(loctempo=0),st[-1])
    starts[[1]]<-st
  }
  escalas<-unique(c(IQR(x)/1.57,sd(x)*sqrt(6)/pi))
  # Localização inicial construída dentro do suporte; escalas robusta e de momentos.
  for(sc in escalas[is.finite(escalas)&escalas>0]) for(xi in c(0,.2,1,3)) {
    if(!is.null(inicio) && sc!=escalas[1])next
    loc<-if(xi==0)median(x)-.3665*sc else min(x)-.01*sc+sc/xi
    st<-list(loc=loc,scale=sc,shape=xi)
    if(!is.null(tempo))st<-c(st[1],list(loctempo=0),st[-1])
    starts[[length(starts)+1L]]<-st
  }
  executar<-function(st,ep=FALSE) tryCatch(withCallingHandlers(
    evd::fgev(x,start=st,nsloc=if(is.null(tempo))NULL else data.frame(tempo=tempo),
      method='Nelder-Mead',std.err=ep,
      control=list(maxit=10000,reltol=1e-10,ndeps=rep(1e-5,length(st)))),
    warning=function(w){avisos<<-c(avisos,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e)e)
  for(st in starts) {
    f<-executar(st)
    if(valido(f))tentativas[[length(tentativas)+1L]]<-f
  }
  if(!length(tentativas))return(list(ok=FALSE,erro=paste('Nenhuma otimização válida.',paste(unique(avisos),collapse='; '))))
  f<-tentativas[[which.min(vapply(tentativas,function(z)z$deviance,numeric(1)))]]
  if(erros) {
    ff<-executar(as.list(f$estimate),TRUE)
    if(valido(ff) && abs(ff$deviance-f$deviance)<.01) f<-ff else
      avisos<-c(avisos,'Informação observada indisponível/inconsistente; IC de Wald indisponível.')
  }
  if(f$estimate['shape']<=-.5)avisos<-c(avisos,'xi <= -0,5: inferência assintótica regular não garantida.')
  if(f$estimate['shape']>=1)avisos<-c(avisos,'xi >= 1: o modelo agregado implica média infinita; examinar heterogeneidade temporal e extrapolação.')
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
  comp<-rbindlist(linhas)
  comp[,`:=`(acf1_pares=NA_real_,n_pares=0L)]
  for(t in tipos) {
    b0<-block$blocos[[t]];z<-log10(ifelse(b0$elegivel,b0$maximo,NA_real_))
    anterior<-head(z,-1);seguinte<-tail(z,-1);ok<-is.finite(anterior)&is.finite(seguinte)
    rho<-if(sum(ok)>=3L)stats::cor(anterior[ok],seguinte[ok]) else NA_real_
    comp[bloco==t,`:=`(acf1_pares=rho,n_pares=sum(ok))]
  }
  csv(comp,'comparacao_blocos')
  sensibilidade<-list()
  for(t in tipos) {
    a<-modelos[[t]];if(!a$ok)next
    b0<-block$blocos[[t]]
    variacoes<-list()
    for(corte in config$coberturas)variacoes[[paste0('cobertura_',corte)]]<-b0[cobertura>=corte & is.finite(maximo),maximo]
    cheio<-b0[elegivel==TRUE,maximo]
    for(k in c(1L,3L))variacoes[[paste0('sem_',k,'_maiores')]]<-head(sort(cheio),-k)
    for(v in names(variacoes)) {
      x<-variacoes[[v]];z<-ajustar_seguro(x/a$escala,erros=FALSE,inicio=a$fit$estimate)
      sensibilidade[[paste(t,v)]]<-if(z$ok)data.table(bloco=t,variacao=v,n=length(x),
        mu=z$fit$estimate['loc']*a$escala,sigma=z$fit$estimate['scale']*a$escala,
        xi=z$fit$estimate['shape'],delta_xi=z$fit$estimate['shape']-a$fit$estimate['shape']) else
        data.table(bloco=t,variacao=v,n=length(x),mu=NA_real_,sigma=NA_real_,xi=NA_real_,delta_xi=NA_real_)
    }
  }
  sensibilidade<-rbindlist(sensibilidade);csv(sensibilidade,'sensibilidade_ajustes')
  # A escolha ocorre somente após comparação. Preferência por maior agregação física,
  # condicionada a n>=50, erro de forma finito, suporte e convergência; sem seleção por p ou AIC entre blocos.
  candidatos<-rev(tipos)
  admissiveis<-comp[convergiu & n>=50 & is.finite(ep_xi) & xi>-.5]$bloco
  aptos<-comp[bloco%in%admissiveis & is.finite(acf1_pares) & n_pares>=30L]
  # ACF é apenas um dos critérios: elegibilidade, suporte e regularidade são prévios.
  # Empates de até 0,02 favorecem maior agregação; sem seleção por valor p.
  menor_acf<-if(nrow(aptos))min(abs(aptos$acf1_pares)) else Inf
  preferidos<-aptos[abs(acf1_pares)<=menor_acf+.02]$bloco
  principal<-candidatos[candidatos%in%preferidos][1]
  if(is.na(principal)) stop('Nenhum bloco com ajuste regular e >=50 máximos; consulte tabelas/comparacao_blocos.csv. Não forçar GEV.')
  estavel<-comp[bloco==principal]
  justificativa<-paste0('Escolheu-se o bloco ',principal,
    ' após comparar as três agregações: pelo menos 50 máximos elegíveis, suporte válido, convergência e erro da forma finito (xi > -0,5) são requisitos prévios. ',
    'Entre os candidatos regulares, priorizou-se a menor correlação absoluta dos pares adjacentes da série logarítmica em toda a grade de calendário (sem colapsar lacunas), com tolerância de 0,02 para favorecer agregação maior. ',
    'No bloco escolhido, correlação dos pares adjacentes = ',round(estavel$acf1_pares,3),', N = ',estavel$n,
    ', com ',estavel$n_pares,' pares, e discrepância PP = ',signif(estavel$rmse_pp,3),'. Essa escolha é exploratória: menor ACF não prova independência; qualidade, estabilidade e diagnósticos permanecem condições para interpretação. AIC entre blocos e valores p não selecionam o modelo.')
  b<-block$blocos[[principal]][elegivel == TRUE]; a<-modelos[[principal]]; f<-a$fit
  tempo<-as.numeric(b$inicio-mean(b$inicio))/365.2425
  ns<-ajustar_seguro(b$maximo/a$escala,tempo,inicio=f$estimate)
  if(ns$ok && ns$fit$deviance>f$deviance+.001) ns<-list(ok=FALSE,erro='O modelo ampliado não alcançou a verossimilhança do modelo aninhado; LRT não calculado.')
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
    qq<-ggplot(data.table(teor,x),aes(teor,x))+geom_point(color=cor,alpha=.5)+
      geom_abline(slope=1,intercept=0)+labs(title=paste('QQ GEV:',t),x='Quantil GEV (W m⁻²)',y='Quantil observado (W m⁻²)')
    if(all(teor>0)&all(x>0)&max(teor)/min(teor)>100)qq<-qq+scale_x_log10()+scale_y_log10()+labs(subtitle='Ambos os eixos em escala log10; a diagonal representa igualdade.')
    plots[[paste0('qq_',t)]]<-fig(qq,paste0('qq_gev_',t))
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
      geom_point(color=cor,na.rm=TRUE)+geom_line(aes(y=pit_ns),color='#9b513d',linewidth=.4,na.rm=TRUE)+
      labs(title='PIT no tempo: estacionário (pontos) e linear (linha)',x='Data (UTC)',y='Probabilidade integral transformada'),'pit_tempo')
  }
  list(modelos=modelos,comparacao=comp,sensibilidade=sensibilidade,principal=principal,justificativa=justificativa,parametros=parametros,
    ns=ns,ns_parametros=ns_parametros,comparacao_ns=comparacao_ns,lr=lr,p_lr=plr,evidencia_ns=evidencia,
    centro_tempo=mean(b$inicio),plots=plots,pit_lb=pitlb)
}
