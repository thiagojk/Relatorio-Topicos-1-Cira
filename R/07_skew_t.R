# Skew-t univariada de Azzalini–Capitanio, DP de sn: (xi, omega, alpha, nu).
# xi é localização (NÃO a forma xi da GEV); omega > 0 é escala, NÃO desvio padrão;
# alpha é slant, NÃO o coeficiente de assimetria; nu > 0 são graus de liberdade.
# Sem truncamento em zero, transformação log da resposta, penalização ou exclusão no principal.
# dst/pst/qst e o estimador são do pacote sn; nenhuma densidade é implementada aqui.
criterios_mesma_escala <- function(logLik,n,k) {
  stopifnot(length(logLik)==1L,is.finite(logLik),n>k,k>0)
  data.table(n=n,k=k,logLik=logLik,AIC=-2*logLik+2*k,BIC=-2*logLik+k*log(n))
}
amostra_mensal_comum <- function(block,modelos) {
  if(modelos$principal!='mensal') stop('A comparação solicitada exige GEV principal mensal; não comparar amostras de blocos diferentes.')
  b<-copy(block$blocos$mensal[elegivel==TRUE,.(inicio,fim,maximo,cobertura)])
  a<-modelos$modelos$mensal
  stopifnot(a$ok,nrow(b)==a$fit$n,!anyNA(b),!anyDuplicated(b$inicio),
    all(diff(b$inicio)>0),all(b$maximo>0 & is.finite(b$maximo)),
    isTRUE(all.equal(b$maximo/a$escala,as.numeric(a$fit$data),tolerance=1e-12)))
  # Checagem explícita de ordem, valores e datas contra o objeto original da GEV.
  stopifnot(identical(b$inicio,block$blocos$mensal[elegivel==TRUE,inicio]))
  b
}
ajustar_skew_t <- function(x,escala=median(x)) {
  if(length(x)<30L || any(!is.finite(x)|x<=0) || sd(x)<=0 || !is.finite(escala) || escala<=0)
    stop('Amostra Skew-t inválida; nenhuma observação é removida silenciosamente.')
  y<-x/escala;sc<-max(IQR(y),.1)
  starts<-expand.grid(alpha=c(-3,0,3,20),nu=c(.5,5))
  tentativas<-list();fits<-list()
  for(i in seq_len(nrow(starts))) for(metodo in c('nlminb','Nelder-Mead')) {
    dp<-c(if(starts$alpha[i]>0)min(y) else median(y),sc,starts$alpha[i],starts$nu[i])
    avisos<-character()
    controle<-if(metodo=='nlminb')list(iter.max=3000,eval.max=6000,rel.tol=1e-10) else list(maxit=10000,reltol=1e-11)
    fit<-tryCatch(withCallingHandlers(sn::st.mple(y=y,dp=dp,penalty=NULL,
      opt.method=metodo,control=controle),warning=function(w) {
        avisos<<-c(avisos,conditionMessage(w));invokeRestart('muffleWarning')
      }),error=identity)
    id<-length(tentativas)+1L
    erro<-inherits(fit,'error')
    est<-if(erro)rep(NA_real_,4) else unname(fit$dp)
    valido<-!erro && all(is.finite(est)) && est[2]>0 && est[4]>0 && is.finite(fit$logL)
    ll<-if(valido)sum(sn::dst(y,dp=est,log=TRUE)) else NA_real_
    valido<-valido && is.finite(ll) && abs(ll-fit$logL)<1e-4
    codigo<-if(erro)NA_integer_ else fit$opt.method$convergence
    tentativas[[id]]<-data.table(tentativa=id,inicio_alpha=starts$alpha[i],inicio_nu=starts$nu[i],
      metodo=metodo,codigo=codigo,valido=valido,convergiu=valido && codigo==0L,
      logLik=ll-length(y)*log(escala),localizacao=est[1]*escala,omega=est[2]*escala,
      alpha=est[3],nu=est[4],fronteira=valido && isTRUE(fit$boundary),
      mensagem=if(erro)conditionMessage(fit) else paste(fit$opt.method$message,collapse='; '),
      avisos=paste(unique(avisos),collapse='; '))
    if(valido)fits[[as.character(id)]]<-fit
  }
  tentativas<-rbindlist(tentativas)
  candidatos<-tentativas[convergiu==TRUE]
  if(!nrow(candidatos))candidatos<-tentativas[valido==TRUE]
  if(!nrow(candidatos))stop('Nenhum ajuste Skew-t numericamente válido. Erros: ',paste(unique(tentativas$mensagem),collapse='; '))
  melhor<-candidatos[which.max(logLik)]
  fit<-fits[[as.character(melhor$tentativa)]];dp<-unname(fit$dp)
  names(dp)<-c('xi','omega','alpha','nu')
  # Informação observada apenas se solução interior e bem condicionada. Na fronteira,
  # não fabricar EP ou IC Wald para uma estimativa de alpha efetivamente divergente.
  regular<-isTRUE(melhor$convergiu) && !isTRUE(fit$boundary)
  ep<-li<-ls<-rep(NA_real_,4);condicao<-NA_real_;avisos<-character()
  nll<-function(t) -sum(sn::dst(y,dp=c(t[1],exp(t[2]),sinh(t[3]),exp(t[4])),log=TRUE))
  theta<-c(dp[1],log(dp[2]),asinh(dp[3]),log(dp[4]))
  if(regular) {
    h<-tryCatch(numDeriv::hessian(nll,theta),error=identity)
    if(!inherits(h,'error') && all(is.finite(h))) {
      ev<-eigen(h,symmetric=TRUE,only.values=TRUE)$values
      condicao<-max(ev)/min(ev)
      regular<-all(ev>0) && is.finite(condicao) && condicao<1e8 && max(abs(numDeriv::grad(nll,theta)))<.01
      if(regular) {
        se<-sqrt(diag(solve(h)));ep<-se*c(escala,dp[2]*escala,cosh(theta[3]),dp[4])
        li<-c((theta[1]-1.96*se[1])*escala,exp(theta[2]-1.96*se[2])*escala,
          sinh(theta[3]-1.96*se[3]),exp(theta[4]-1.96*se[4]))
        ls<-c((theta[1]+1.96*se[1])*escala,exp(theta[2]+1.96*se[2])*escala,
          sinh(theta[3]+1.96*se[3]),exp(theta[4]+1.96*se[4]))
      }
    } else regular<-FALSE
  }
  if(!regular)avisos<-c(avisos,'Solução não regular/fronteira ou informação mal condicionada: EP e IC Wald não são reportados.')
  if(isTRUE(fit$boundary))avisos<-c(avisos,'sn sinaliza fronteira (|alpha| > 1000 ou nu > 1000). Alpha não tem estimativa finita estável; valores são aproximações numéricas ao limite, não um MLE interior validado.')
  if(dp[4]<=1)avisos<-c(avisos,'nu <= 1: a média não existe no modelo ajustado; não atribuir essa propriedade ao processo solar.')
  if(any(!tentativas$convergiu))avisos<-c(avisos,'Há tentativas sem convergência: códigos, mensagens e valores iniciais estão na tabela de otimização.')
  if(any(nzchar(tentativas$avisos))) {
    avisos<-c(avisos,unique(tentativas$avisos[nzchar(tentativas$avisos)]))
    warning('Avisos da otimização Skew-t registrados: ',paste(unique(tentativas$avisos[nzchar(tentativas$avisos)]),collapse='; '),call.=FALSE)
  }
  parametros<-data.table(parametro=c('xi_ST (localização)','omega (escala)','alpha (slant)','nu (graus de liberdade)'),
    estimativa=dp*c(escala,escala,1,1),ep=ep,inferior=li,superior=ls,
    unidade=c('W m^-2','W m^-2','adimensional','adimensional'))
  list(dp=dp,escala=escala,logLik=melhor$logLik,convergiu=melhor$convergiu,
    regular=regular,fronteira=isTRUE(fit$boundary),condicao=condicao,parametros=parametros,
    tentativas=tentativas,selecionada=melhor$tentativa,avisos=unique(avisos))
}
comparar_skew_t <- function(block,modelos,retornos) {
  amostra_comum<-amostra_mensal_comum(block,modelos)
  x<-amostra_comum$maximo;n<-length(x);a<-modelos$modelos$mensal;e<-a$fit$estimate
  skew<-ajustar_skew_t(x,escala=a$escala)
  dp_original<-skew$dp*c(a$escala,a$escala,1,1)
  # Log-densidades na MESMA unidade W/m²: f_X(x)=f_Y(x/s)/s.
  llg<-sum(evd::dgev(x/a$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'],log=TRUE))-n*log(a$escala)
  lls<-sum(sn::dst(x,dp=dp_original,log=TRUE))
  stopifnot(abs(llg-(-a$fit$deviance/2-n*log(a$escala)))<1e-6,abs(lls-skew$logLik)<1e-5)
  criterios<-rbind(cbind(modelo='GEV',criterios_mesma_escala(llg,n,3L)),
    cbind(modelo='Skew-t',criterios_mesma_escala(lls,n,4L)))
  criterios[,status:=c('Convergência e suporte validados',if(skew$regular)'Solução interior; Hessiana validada' else 'Aproximação numérica não regular; critérios nominais')]
  resumo_amostra<-data.table(n=n,primeiro=min(amostra_comum$inicio),ultimo=max(amostra_comum$inicio),
    minimo=min(x),mediana=median(x),maximo=max(x),invalidos=sum(!is.finite(x)|x<=0),
    escala_numerica=a$escala)
  qgev<-function(p)evd::qgev(p,loc=e['loc'],scale=e['scale'],shape=e['shape'])*a$escala
  qst<-function(p)sn::qst(p,dp=skew$dp)*a$escala
  xs<-sort(x);p<-ppoints(n)
  diag<-rbind(data.table(modelo='GEV',p=p,observado=xs,teorico=qgev(p),
    pit=evd::pgev(xs/a$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'])),
    data.table(modelo='Skew-t',p=p,observado=xs,teorico=qst(p),pit=sn::pst(xs/a$escala,dp=skew$dp)))
  stopifnot(all(is.finite(as.matrix(diag[,.(p,observado,teorico,pit)]))),all(diag$pit>=0 & diag$pit<=1))
  probs<-c(.9,.95,.975,.99)
  cauda<-data.table(probabilidade=probs,n_esperado_acima=n*(1-probs),
    empirico=as.numeric(quantile(x,probs,type=7)),GEV=qgev(probs),Skew_t=qst(probs))
  cauda[,`:=`(erro_rel_GEV=GEV/empirico-1,erro_rel_Skew_t=Skew_t/empirico-1)]
  cauda[,interpretacao:=ifelse(n_esperado_acima<5,'Menos de 5 observações esperadas acima: apenas extrapolação/descrição muito incerta','Comparação descritiva; dependência reduz informação efetiva')]
  diagnosticos<-diag[,.(rmse_pp=sqrt(mean((pit-p)^2)),
    erro_log_cauda=mean(abs(log10(teorico[p>=.9]/observado[p>=.9]))),
    quantil_maior_ponto=tail(teorico,1)),by=modelo]
  # Dados positivos, família ST não truncada: quantificar a massa não física em X <= 0.
  massa_nao_positiva<-sn::pst(0,dp=dp_original)
  equivalentes<-data.table(anos=retornos$tabela$anos,probabilidade=1-1/(12*retornos$tabela$anos),
    GEV=retornos$tabela$estimativa,Skew_t=qst(1-1/(12*retornos$tabela$anos)))
  equivalentes[,`:=`(razao_Skew_t_maximo=Skew_t/max(x),rotulo='Skew-t: quantis equivalentes, não níveis de retorno TVE validados')]
  # Sensibilidade: mesmas datas/valores para ambos em cada cenário; escala fixa original.
  sens<-list();sens_diagnosticos<-list();otimizacoes<-list(completa=skew$tentativas)
  for(k in c(0L,1L,3L)) {
    nome<-c('completa','sem_1_maior','sem_3_maiores')[match(k,c(0L,1L,3L))]
    manter<-if(k==0L)seq_len(n) else setdiff(seq_len(n),head(order(-x,amostra_comum$inicio),k))
    xx<-x[manter]
    ss<-if(k==0L)skew else ajustar_skew_t(xx,escala=a$escala)
    gg<-if(k==0L)a else ajustar_seguro(xx/a$escala,erros=FALSE,inicio=e)
    if(!gg$ok)stop('GEV da sensibilidade falhou: ',nome,'. ',gg$erro)
    eg<-gg$fit$estimate
    logg<-sum(evd::dgev(xx/a$escala,loc=eg['loc'],scale=eg['scale'],shape=eg['shape'],log=TRUE))-length(xx)*log(a$escala)
    sens[[nome]]<-rbind(
      cbind(cenario=nome,modelo='GEV',criterios_mesma_escala(logg,length(xx),3L),
        data.table(localizacao=eg['loc']*a$escala,escala=eg['scale']*a$escala,
          xi_GEV=eg['shape'],alpha_ST=NA_real_,nu_ST=NA_real_,convergiu=TRUE,fronteira=FALSE)),
      cbind(cenario=nome,modelo='Skew-t',criterios_mesma_escala(ss$logLik,length(xx),4L),
        data.table(localizacao=ss$dp[1]*a$escala,escala=ss$dp[2]*a$escala,
          xi_GEV=NA_real_,alpha_ST=ss$dp[3],nu_ST=ss$dp[4],convergiu=ss$convergiu,fronteira=ss$fronteira)))
    pg<-evd::pgev(sort(xx)/a$escala,loc=eg['loc'],scale=eg['scale'],shape=eg['shape'])
    ps<-sn::pst(sort(xx)/a$escala,dp=ss$dp)
    sens_diagnosticos[[nome]]<-data.table(cenario=nome,n=length(xx),
      delta_AIC=sens[[nome]][modelo=='Skew-t',AIC]-sens[[nome]][modelo=='GEV',AIC],
      delta_BIC=sens[[nome]][modelo=='Skew-t',BIC]-sens[[nome]][modelo=='GEV',BIC],
      rmse_pp_GEV=sqrt(mean((pg-ppoints(length(xx)))^2)),
      rmse_pp_ST=sqrt(mean((ps-ppoints(length(xx)))^2)),
      P99_GEV=evd::qgev(.99,loc=eg['loc'],scale=eg['scale'],shape=eg['shape'])*a$escala,
      P99_ST=sn::qst(.99,dp=ss$dp)*a$escala)
    otimizacoes[[nome]]<-ss$tentativas
    csv(amostra_comum[manter],paste0('amostra_comum_',nome))
  }
  sens<-rbindlist(sens);sens_diagnosticos<-rbindlist(sens_diagnosticos)
  otimizacoes<-rbindlist(otimizacoes,idcol='cenario')
  delta_aic<-criterios[modelo=='Skew-t',AIC]-criterios[modelo=='GEV',AIC]
  delta_bic<-criterios[modelo=='Skew-t',BIC]-criterios[modelo=='GEV',BIC]
  # Conclusão gerada DOS resultados; nunca decidir antecipadamente pela Skew-t.
  melhor_cauda<-diagnosticos[which.min(erro_log_cauda),modelo]
  if(delta_aic< -2 && delta_bic< -2 && melhor_cauda=='Skew-t' && skew$regular &&
     diagnosticos[modelo=='Skew-t',rmse_pp]<diagnosticos[modelo=='GEV',rmse_pp]) {
    conclusao<-'A Skew-t apresenta evidência de representação empírica melhor nos critérios e diagnósticos examinados. Isso não valida automaticamente extrapolações nem lhe confere a justificativa assintótica da GEV.'
  } else if(delta_aic>2 && delta_bic>2 && melhor_cauda=='GEV') {
    conclusao<-'Não. A Skew-t não apresentou evidência de ajuste empírico melhor que a GEV: os critérios e o erro descritivo dos maiores quantis favorecem a GEV. Essa preferência relativa não corrige a má calibração superior da GEV; nenhuma das duas distribuições oferece representação plenamente satisfatória para extrapolação.'
  } else conclusao<-'Não há evidência conjunta suficiente para afirmar clara superioridade empírica da Skew-t. Os critérios, a cauda e a regularidade devem ser examinados em conjunto; a dependência e a heterogeneidade temporal permanecem.'
  cols<-c('GEV'=cor,'Skew-t'='#9b513d')
  # Grade log-espaçada e Jacobiano x*log(10) para densidade de log10(X).
  # Somente a visualização usa log; ambos os ajustes são nos fluxos originais.
  xx<-exp(seq(log(min(x)/2),log(max(x)*1.2),length.out=1000))
  dens<-rbind(data.table(x=xx,modelo='GEV',densidade=evd::dgev(xx/a$escala,loc=e['loc'],scale=e['scale'],shape=e['shape'])/a$escala),
    data.table(x=xx,modelo='Skew-t',densidade=sn::dst(xx,dp=dp_original)))
  dens[,densidade_log:=densidade*x*log(10)]
  plots<-list()
  plots$densidade<-fig(ggplot(data.table(z=log10(x)),aes(z))+geom_histogram(aes(y=after_stat(density)),bins=20,fill='grey80',color='white')+
    geom_line(data=dens,aes(log10(x),densidade_log,color=modelo),linewidth=.8)+scale_color_manual(values=cols)+
    labs(title='Máximos mensais: distribuição empírica e modelos',x='log10 do fluxo (W m⁻²)',y='Densidade por unidade de log10',color='Modelo',
      caption='Curvas com Jacobiano x × log(10); ajustes na escala original, sem log-transformar a resposta.'),'comparacao_densidade')
  for(m in c('GEV','Skew-t')) {
    d<-diag[modelo==m]
    g<-ggplot(d,aes(teorico,observado))+geom_point(color=cols[m],alpha=.65)+geom_abline(slope=1,intercept=0)+
      labs(title=paste('QQ:',m,'— mesma amostra mensal'),x='Quantil teórico (W m⁻²)',y='Máximo observado (W m⁻²)')
    if(all(diag$teorico>0)) {
      limites<-range(c(diag$teorico,diag$observado))
      g<-g+scale_x_log10(limits=limites)+scale_y_log10(limits=limites)+
        coord_fixed()+labs(subtitle='Eixos log10 e limites comuns aos dois modelos; diagonal de igualdade.')
    } else g<-g+coord_fixed()+labs(subtitle='Escala original: algum quantil teórico não é positivo.')
    plots[[paste0('qq_',m)]]<-fig(g,paste0('comparacao_qq_',if(m=='GEV')'gev' else 'skew_t'),w=7,h=6)
  }
  plots$pp<-fig(ggplot(diag,aes(p,pit,color=modelo))+geom_point(alpha=.6)+geom_abline(slope=1,intercept=0)+
    scale_color_manual(values=cols)+facet_wrap(~modelo)+coord_fixed()+
    labs(title='PP: mesmos máximos e posições empíricas',x='Probabilidade empírica (ppoints)',y='Probabilidade do modelo',color='Modelo'),'comparacao_pp')
  dc<-rbind(data.table(probabilidade=probs,quantil=cauda$empirico,modelo='Empírico (tipo 7)'),
    data.table(probabilidade=probs,quantil=cauda$GEV,modelo='GEV'),
    data.table(probabilidade=probs,quantil=cauda$Skew_t,modelo='Skew-t'))
  plots$cauda<-fig(ggplot(dc,aes(probabilidade,quantil,color=modelo))+geom_line()+geom_point()+scale_y_log10()+
    scale_color_manual(values=c(cols,'Empírico (tipo 7)'='grey30'))+
    labs(title='Cauda superior: quantis empíricos e ajustados',x='Probabilidade de não excedência',y='Quantil (W m⁻²), eixo log10',color='Distribuição',
      caption='P97,5 e P99 têm menos de cinco observações esperadas acima; não são validação de extrapolação.'),'comparacao_cauda')
  # Exportação rastreável: objeto da amostra, todas as tentativas e diagnósticos ponto a ponto.
  csv(amostra_comum,'amostra_comum_mensal');csv(resumo_amostra,'resumo_amostra_comum')
  csv(skew$parametros,'parametros_skew_t');csv(criterios,'comparacao_gev_skew_t')
  csv(diag,'diagnosticos_gev_skew_t');csv(diagnosticos,'metricas_gev_skew_t');csv(cauda,'quantis_cauda_gev_skew_t')
  csv(sens,'sensibilidade_gev_skew_t');csv(sens_diagnosticos,'diagnosticos_sensibilidade_skew_t');csv(otimizacoes,'otimizacao_skew_t');csv(equivalentes,'quantis_equivalentes_skew_t')
  csv(data.table(aviso=skew$avisos),'avisos_skew_t')
  resultado<-list(amostra_comum=amostra_comum,resumo_amostra=resumo_amostra,ajuste=skew,
    criterios=criterios,diagnosticos=diag,metricas=diagnosticos,cauda=cauda,sensibilidade=sens,sens_diagnosticos=sens_diagnosticos,
    otimizacoes=otimizacoes,equivalentes=equivalentes,delta_aic=delta_aic,delta_bic=delta_bic,
    melhor_cauda=melhor_cauda,massa_nao_positiva=massa_nao_positiva,conclusao=conclusao)
  saveRDS(resultado,'resultados/comparacao_skew_t.rds')
  c(resultado,list(plots=plots))
}
