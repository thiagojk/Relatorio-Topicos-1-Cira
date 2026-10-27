# Deriva SOMENTE produtos de apresentação. Não ajusta modelos, sorteia amostras,
# altera a seleção de máximos ou modifica os objetos recebidos.
apresentar_resultados <- function(base, ex, block, modelos, retornos) {
  medidas <- c('N','Mínimo','Q1','Mediana','Média','Q3','Máximo','Desvio padrão',
               'CV','Assimetria (momento)','Curtose (Pearson)')
  rotulos <- c('Observações válidas','Mínimo','Primeiro quartil','Mediana','Média',
               'Terceiro quartil','Máximo','Desvio-padrão','Coeficiente de variação',
               'Assimetria empírica','Curtose de Pearson')
  desc <- ex$descritiva[match(medidas,medida),.(medida,valor)]
  stopifnot(identical(desc$medida,medidas),all(is.finite(desc$valor)))
  descritiva <- data.table(Estatística=rotulos,
    Valor=vapply(seq_along(medidas),function(i) {
      if(medidas[i]=='N') num(desc$valor[i]) else if(i<=8L) sci(desc$valor[i]) else
        format(round(desc$valor[i],2),big.mark='.',decimal.mark=',',trim=TRUE)
    },character(1)),
    Unidade=ifelse(seq_along(medidas)%in%2:8,'W/m²',
      ifelse(medidas=='N','contagem','adimensional')))
  csv(descritiva,'descritiva_relatorio')

  blocos <- copy(modelos$comparacao[,.(bloco,total,n,
    retidos_percentual=100*fracao_retida,correlacao=acf1_pares,xi)])
  setnames(blocos,c('Bloco','Calendário','Elegíveis','Retidos (%)','Correlação','Forma GEV'))
  blocos[,Bloco:=c(diario='Diário',semanal='Semanal',mensal='Mensal')[Bloco]]
  csv(blocos,'blocos_relatorio')
  pars <- merge(modelos$parametros[,.(parametro,estimativa)],retornos$bootstrap,
    by='parametro',sort=FALSE)
  pars <- pars[match(c('mu','sigma','xi'),parametro)]
  pars[,unidade:=ifelse(parametro=='xi','adimensional','W/m²')]
  setnames(pars,c('Parâmetro','Estimativa','IC inferior','IC superior','Unidade'))
  csv(pars,'gev_relatorio')
  nr <- copy(retornos$tabela[,.(anos,estimativa,inferior,superior)])
  setnames(nr,c('Período (anos)','Nível (W/m²)','IC inferior','IC superior'))
  csv(nr,'retornos_relatorio')
  # Uniformizar a unidade da comparação temporal apenas na apresentação.
  # Ambos os ajustes já existentes utilizam os mesmos dados e reescalonamento.
  ns <- copy(modelos$comparacao_ns)
  n <- modelos$modelos[[modelos$principal]]$fit$n
  s <- modelos$modelos[[modelos$principal]]$escala
  ns[,logLik:= -deviance/2-n*log(s)]
  ns[,AIC:= -2*logLik+2*parametros]
  ns[,BIC:= -2*logLik+parametros*log(n)]
  ns <- ns[,.(modelo,parametros,logLik,AIC,BIC)]
  setnames(ns,c('Modelo','Parâmetros','logLik','AIC','BIC'))
  csv(ns,'estacionariedade_relatorio')

  # Envelope horário de TODOS os minutos válidos: preserva o máximo e o mínimo
  # de cada hora, sem amostragem aleatória e sem ligar horas sem dados.
  horas <- base$dados_limpos[,.(n=.N,minimo=min(xrsb_flux),
    mediana=median(xrsb_flux),maximo=max(xrsb_flux)),
    by=.(hora=as.POSIXct(floor(as.numeric(data_hora)/3600)*3600,
                       origin='1970-01-01',tz='UTC'))]
  grade <- data.table(hora=seq(min(horas$hora),max(horas$hora),by='hour'))
  horas <- merge(grade,horas,by='hora',all.x=TRUE,sort=TRUE)
  horas[is.na(n),n:=0L]
  stopifnot(sum(horas$n)==nrow(base$dados_limpos),
    max(horas$maximo,na.rm=TRUE)==max(base$dados_limpos$xrsb_flux))
  csv(horas,'serie_horaria_visual')
  g1 <- fig(ggplot(horas,aes(hora,mediana))+
    geom_ribbon(aes(ymin=minimo,ymax=maximo),fill=cor,alpha=.25,na.rm=TRUE)+
    geom_line(color=cor,linewidth=.2,na.rm=TRUE)+scale_y_log10()+
    labs(title='Série histórica do fluxo XRS-B',x='Data (UTC)',
      y='Fluxo (W/m²), eixo log10',
      caption='Faixa: mínimo–máximo por hora; linha: mediana horária. Todos os minutos válidos contribuem.'),
    'serie_fluxo_horaria')

  todos <- rbindlist(lapply(names(block$blocos),function(t) {
    b <- copy(block$blocos[[t]])
    b[elegivel==FALSE,maximo:=NA_real_]
    b[,bloco:=t];b
  }))
  todos[,bloco:=factor(bloco,levels=c('diario','semanal','mensal'),
    labels=c('Diários','Semanais','Mensais'))]
  g2 <- fig(ggplot(todos,aes(inicio,maximo))+
    geom_line(color=cor,linewidth=.3,na.rm=TRUE)+
    facet_wrap(~bloco,ncol=1)+scale_y_log10()+
    labs(title='Como a agregação modifica os máximos?',x='Início do bloco (UTC)',
      y='Máximo (W/m²), eixo log10',caption='Mesma escala nos três painéis; blocos inelegíveis ficam sem valor.'),
    'maximos_comparados',h=6)
  mensal <- copy(block$blocos$mensal[elegivel==TRUE,.(inicio,fim,maximo,cobertura)])
  destaques <- mensal[head(order(-maximo,inicio),3L)]
  destaques[,rotulo_y:=maximo*c(1.4,1.5,2.5)[seq_len(.N)]]
  stopifnot(identical(mensal$maximo,block$blocos$mensal[elegivel==TRUE,maximo]))
  # A grade completa impede que linhas atravessem meses inelegíveis.
  grade_mensal <- copy(block$blocos$mensal)
  grade_mensal[elegivel==FALSE,maximo:=NA_real_]
  g3 <- fig(ggplot(grade_mensal,aes(inicio,maximo))+
    geom_line(color=cor,linewidth=.4,na.rm=TRUE)+geom_point(color=cor,na.rm=TRUE)+
    geom_point(data=destaques,color='#9b513d',size=2.5)+
    geom_text(data=destaques,aes(y=rotulo_y,label=format(inicio,'%Y-%m')),
      vjust=0,size=3,color='#9b513d',check_overlap=FALSE)+
    scale_y_log10(expand=expansion(mult=c(.05,.18)))+
    labs(title=paste(nrow(mensal),'máximos mensais usados na modelagem'),
      x='Mês do bloco (UTC)',y='Máximo mensal (W/m²), eixo log10',
      caption='Destaques: três maiores máximos. Rótulos identificam o mês, não a data de um flare.'),
    'mensais_destaque')
  list(descritiva=descritiva,blocos=blocos,parametros=pars,retornos=nr,
    estacionariedade=ns,horas=horas,mensal=mensal,
    destaques=destaques,plots=list(serie=g1,blocos=g2,mensal=g3))
}
