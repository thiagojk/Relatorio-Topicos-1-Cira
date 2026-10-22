retornos_eventos <- function(base,ex,block,mod) {
  t<-mod$principal; a<-mod$modelos[[t]]; f<-a$fit; e<-f$estimate
  por_ano<-switch(t,diario=365.2425,semanal=365.2425/7,mensal=12)
  anos<-c(1,2,5,10); probs<-1-1/(anos*por_ano)
  quantis<-function(e,p) evd::qgev(p,loc=e['loc'],scale=e['scale'],shape=e['shape'])*a$escala
  estimativa<-quantis(e,probs)
  # Bootstrap circular de blocos móveis sobre a grade completa, conservando lacunas.
  # Preserva dependência local; não corrige mistura de fases solares ou tendência.
  grid<-block$blocos[[t]]; y<-ifelse(grid$elegivel,grid$maximo/a$escala,NA_real_)
  n<-length(y); L<-as.integer(max(2L,ceiling(n^(1/3)))); B<-config$bootstrap
  boot<-matrix(NA_real_,B,7L); colnames(boot)<-c('mu','sigma','xi',paste0('T',anos))
  set.seed(config$semente+2L)
  for(i in seq_len(B)) {
    inicios<-sample.int(n,ceiling(n/L),replace=TRUE)
    ind<-as.vector(vapply(inicios,function(j)((j-1L+seq.int(0,L-1L))%%n)+1L,integer(L)))[seq_len(n)]
    xx<-y[ind];xx<-xx[is.finite(xx)]
    fit<-ajustar_seguro(xx,erros=FALSE,inicio=e)
    if(fit$ok) {
      be<-fit$fit$estimate
      valores_boot<-c(be*c(a$escala,a$escala,1),quantis(be,probs))
      if(all(is.finite(valores_boot))) boot[i,]<-valores_boot
    }
  }
  sucesso<-sum(complete.cases(boot));taxa<-sucesso/B
  if(sucesso<max(100,ceiling(.8*B))) stop('Bootstrap insuficiente: ',sucesso,'/',B,'. Não publicar IC não confiáveis.')
  ic<-apply(boot,2,quantile,c(.025,.975),na.rm=TRUE)
  retorno<-data.table(anos=anos,blocos=anos*por_ano,estimativa=estimativa,
    inferior=ic[1,4:7],superior=ic[2,4:7],unidade='W m^-2',
    prob_excedencia_por_bloco=1/(anos*por_ano),
    prob_excedencia_ano_indep=1-(1-1/(anos*por_ano))^por_ano)
  retorno[,`:=`(razao_maximo_observado=estimativa/max(base$dados_limpos$xrsb_flux),
    fora_faixa_metadados=estimativa>base$limites_fluxo[2])]
  calibracao<-data.table(anos=anos,observadas=vapply(estimativa,function(z)sum(grid$maximo[grid$elegivel]>z),integer(1)),
    esperadas_modelo=sum(grid$elegivel)/(anos*por_ano))
  csv(calibracao,'calibracao_niveis_retorno')
  csv(retorno,'niveis_retorno');csv(as.data.table(boot),'bootstrap_blocos_moveis')
  parboot<-data.table(parametro=c('mu','sigma','xi'),inferior=ic[1,1:3],superior=ic[2,1:3])
  csv(parboot,'ic_parametros_bootstrap')
  ci_xi<-ic[,3]
  classe<-if(ci_xi[1]>0)'Fréchet: o intervalo bootstrap da forma está inteiramente acima de zero' else
    if(ci_xi[2]<0)'Weibull reversa: o intervalo bootstrap da forma está inteiramente abaixo de zero' else
      'Indeterminada entre os domínios compatíveis com o intervalo: zero está incluído; Gumbel não pode ser descartada'
  # Curva de retorno com as mesmas replicações, sem nova otimização.
  tr<-exp(seq(log(max(2/por_ano,.1)),log(10),length.out=120));pp<-1-1/(tr*por_ano)
  bb<-boot[complete.cases(boot),,drop=FALSE]
  curvas<-vapply(seq_len(nrow(bb)),function(i)evd::qgev(pp,loc=bb[i,1]/a$escala,
    scale=bb[i,2]/a$escala,shape=bb[i,3])*a$escala,numeric(length(tr)))
  ci<-apply(curvas,1,quantile,c(.025,.975),na.rm=TRUE)
  curva<-data.table(anos=tr,nivel=quantis(e,pp),inf=ci[1,],sup=ci[2,])
  xv<-sort(grid[elegivel == TRUE,maximo]);te<-1/(1-ppoints(length(xv)))/por_ano
  graf<-fig(ggplot(curva,aes(anos,nivel))+geom_ribbon(aes(ymin=inf,ymax=sup),fill=cor,alpha=.15)+
    geom_line(color=cor)+geom_point(data=data.table(anos=te,nivel=xv)[anos<=10],size=1)+scale_x_log10()+scale_y_log10()+
    labs(title=paste('Níveis de retorno históricos — bloco',t),x='Período de retorno (anos, escala log10)',
      y='Fluxo (W m⁻²), escala log10',caption='Faixa: IC percentil 95%, bootstrap de blocos móveis; pontos: máximos empíricos.'),'niveis_retorno')
  # Níveis condicionais no último bloco para a extensão não estacionária. IC delta (aproximação iid).
  condicional<-NULL
  if(mod$ns$ok && !is.null(mod$ns$fit$var.cov)) {
    fn<-mod$ns$fit;en<-fn$estimate;ultimo<-max(grid$inicio[grid$elegivel])
    tt<-as.numeric(ultimo-mod$centro_tempo)/365.2425
    fun<-function(v)evd::qgev(probs,loc=v['loc']+v['loctempo']*tt,scale=v['scale'],shape=v['shape'])*a$escala
    grad<-sapply(seq_along(en),function(j) {
      h<-1e-5*max(1,abs(en[j]));vp<-vm<-en;vp[j]<-vp[j]+h;vm[j]<-vm[j]-h
      (fun(vp)-fun(vm))/(2*h)
    })
    se<-sqrt(pmax(0,diag(grad%*%fn$var.cov%*%t(grad))))
    qcond<-fun(en)
    if(all(qcond>0)) {
      li<-qcond*exp(-1.96*se/qcond);ls<-qcond*exp(1.96*se/qcond)
      metodo<-'Delta no log-quantil/Hessiana; independência aproximada; covariável congelada'
    } else {li<-qcond-1.96*se;ls<-qcond+1.96*se;metodo<-'Delta/Hessiana; quantil não positivo exige ressalva'}
    condicional<-data.table(anos=anos,referencia=ultimo,estimativa=qcond,inferior=li,superior=ls,metodo=metodo)
    csv(condicional,'retornos_condicionais_nao_estacionarios')
  }
  d<-base$dados_limpos
  idx_picos<-head(order(d$xrsb_flux,decreasing=TRUE),20L)
  picos<-d[idx_picos,.(data_hora,xrsb_flux)]
  picos[,`:=`(posicao=.I,data=as.Date(data_hora,tz='UTC'),horario=format(data_hora,'%H:%M:%S',tz='UTC'))]
  csv(picos,'top20_minutos')
  excedentes<-d[xrsb_flux>ex$limiar_eventos,.(data_hora,xrsb_flux)]
  eventos<-list();sens<-list()
  for(h in config$janelas_h) {
    dd<-copy(excedentes)
    dd[,grupo:=cumsum(c(TRUE,diff(as.numeric(data_hora))>h*3600))]
    ev<-dd[,.(inicio=min(data_hora),fim=max(data_hora),n_minutos=.N,
      data_pico=data_hora[which.max(xrsb_flux)],fluxo=max(xrsb_flux)),by=grupo]
    ev<-ev[order(-fluxo)]
    ev[,`:=`(posicao=.I,data=as.Date(data_pico,tz='UTC'),horario=format(data_pico,'%H:%M:%S',tz='UTC'))]
    eventos[[as.character(h)]]<-ev
    sens[[as.character(h)]]<-data.table(janela_h=h,n_eventos=nrow(ev),limiar=ex$limiar_eventos)
    csv(ev[order(-fluxo)],paste0('eventos_',h,'h'))
  }
  ev<-eventos[['6']];if(is.null(ev))ev<-eventos[[1]]
  porano<-ev[,.(eventos=.N),by=.(ano=as.integer(format(data_pico,'%Y')))];csv(porano,'eventos_por_ano')
  sens<-rbindlist(sens);csv(sens,'sensibilidade_declustering')
  # Série diária agregada, picos reais sobrepostos; sem desenhar milhões de minutos.
  gp<-linha(ex$diario,'data','maximo','Maiores episódios de fluxo XRS-B')+
    geom_point(data=ev[seq_len(min(.N,20L))],aes(x=as.Date(data_pico,tz='UTC'),y=fluxo),color='#9b513d',size=2)+
    geom_text(data=ev[seq_len(min(.N,5L))],aes(x=as.Date(data_pico,tz='UTC'),y=fluxo,
      label=format(data_pico,'%Y-%m-%d')),vjust=-.6,size=3,check_overlap=TRUE)
  gp<-fig(gp,'eventos_extremos')
  list(tabela=retorno,calibracao=calibracao,condicional=condicional,bootstrap=parboot,sucessos=sucesso,B=B,L=L,
    classe=classe,picos=picos,eventos=ev,sensibilidade=sens,eventos_ano=porano,plots=list(retorno=graf,eventos=gp))
}
