explorar <- function(base) {
  d <- base$dados_limpos; x <- d$xrsb_flux
  q <- quantile(x,c(.25,.5,.75,.9,.95,.99,.999,.9999),names=FALSE)
  m <- mean(x); s <- sd(x); desvio <- x-m
  desc <- data.table(medida=c('N','Média','Mediana','Variância','Desvio padrão','Mínimo','Máximo',
    'Q1','Q3','IQR','CV','P90','P95','P99','P99,9','P99,99','Assimetria (momento)','Curtose (Pearson)'),
    valor=c(length(x),m,q[2],var(x),s,min(x),max(x),q[1],q[3],q[3]-q[1],s/m,
            q[4:8],mean(desvio^3)/mean(desvio^2)^1.5,mean(desvio^4)/mean(desvio^2)^2))
  csv(desc,'descritiva')
  inicio <- min(base$dados_xrs$data); fim <- max(base$dados_xrs$data)
  diario <- data.table(data=seq(inicio,fim,by='day'))
  obs <- d[,.(n=.N, mediana=median(xrsb_flux), media=mean(xrsb_flux),
    maximo=max(xrsb_flux), p95=quantile(xrsb_flux,.95),p99=quantile(xrsb_flux,.99)),by=data]
  diario <- merge(diario,obs,by='data',all.x=TRUE,sort=TRUE)
  diario[is.na(n),n:=0L]; diario[,cobertura:=n/1440]
  csv(diario,'cobertura_diaria')
  anual <- d[,.(n=.N, media=mean(xrsb_flux),mediana=median(xrsb_flux),
    p95=quantile(xrsb_flux,.95),p99=quantile(xrsb_flux,.99),maximo=max(xrsb_flux),
    minutos_extremos=sum(xrsb_flux>q[7])),by=ano]
  anos <- data.table(ano=seq(as.integer(format(inicio,'%Y')),as.integer(format(fim,'%Y'))))
  anual <- merge(anos,anual,by='ano',all.x=TRUE)
  anual[is.na(n),n:=0L]
  anual[,esperado_ano:=as.numeric(as.Date(paste0(ano+1,'-01-01'))-as.Date(paste0(ano,'-01-01')))*1440]
  anual[,dias_na_janela:=as.numeric(pmin(as.Date(paste0(ano+1,'-01-01')),fim+1)-pmax(as.Date(paste0(ano,'-01-01')),inicio))]
  anual[,`:=`(cobertura_ano=100*n/esperado_ano, cobertura_janela=100*n/(dias_na_janela*1440))]
  # Lacunas efetivas entre observações válidas; inclui dados rejeitados por qualidade.
  dt <- diff(as.numeric(d$data_hora)); k <- which(dt > 90)
  gaps <- data.table(inicio=d$data_hora[k]+60, fim=d$data_hora[k+1]-60,
    duracao_h=(dt[k]-60)/3600)
  csv(gaps[order(-duracao_h)],'lacunas'); csv(anual,'resumo_anual')
  # Somente os gráficos de distribuição são amostrados.
  visual <- d[sort(sample.int(nrow(d),min(nrow(d),config$max_visual))),.(data_hora,ano,xrsb_flux)]
  p <- list()
  p$cobertura <- fig(linha(diario,'data','cobertura','Cobertura diária válida','Fração dos 1.440 minutos',FALSE)+
     geom_hline(yintercept=config$cobertura,linetype=2,color='#9b513d'),'cobertura_diaria')
  p$cobertura_anual <- fig(ggplot(anual,aes(factor(ano),cobertura_ano))+geom_col(fill=cor)+
    labs(title='Cobertura por ano civil completo',x='Ano',y='Minutos válidos (%)'),'cobertura_anual')
  p$hist <- fig(ggplot(visual,aes(xrsb_flux))+geom_histogram(bins=70,fill=cor)+
    labs(title='Distribuição do fluxo: escala original',x='Fluxo (W m⁻²)',y='Frequência na amostra visual'),'histograma')
  p$hist_log <- fig(ggplot(visual,aes(xrsb_flux))+geom_histogram(bins=70,fill=cor)+scale_x_log10()+
    labs(title='Distribuição de log10 do fluxo',x='Fluxo (W m⁻²), eixo log10',y='Frequência na amostra visual'),'histograma_log')
  p$densidade <- fig(ggplot(visual,aes(xrsb_flux))+geom_density(color=cor,linewidth=.7)+
    labs(title='Densidade do fluxo (amostra visual)',x='Fluxo (W m⁻²)',y='Densidade estimada'),'densidade')
  p$box <- fig(ggplot(visual,aes(x='',y=xrsb_flux))+geom_boxplot(color=cor,outlier.alpha=.12)+
    labs(title='Boxplot do fluxo',x=NULL,y='Fluxo (W m⁻²)'),'boxplot')
  p$box_log <- fig(p$box+scale_y_log10()+labs(title='Boxplot de log10 do fluxo',y='Fluxo (W m⁻²), eixo log10'),'boxplot_log')
  p$qq_normal <- fig(ggplot(visual,aes(sample=xrsb_flux))+stat_qq(color=cor,alpha=.25)+stat_qq_line()+
    labs(title='QQ-plot contra a Normal',x='Quantis normais teóricos',y='Quantis do fluxo (W m⁻²)'),'qq_normal')
  p$ano_box <- fig(ggplot(visual,aes(factor(ano),xrsb_flux))+geom_boxplot(color=cor,outlier.alpha=.10)+scale_y_log10()+
    labs(title='Distribuição por ano (amostra visual global)',x='Ano',y='Fluxo (W m⁻²), eixo log10'),'boxplots_ano')
  for (v in c('mediana','media','maximo')) p[[paste0('diario_',v)]] <-
    fig(linha(diario,'data',v,paste('Evolução diária:',v)),paste0('diario_',v))
  for (v in c('mediana','p95','p99','maximo')) p[[paste0('anual_',v)]] <-
    fig(ggplot(anual,aes(ano,.data[[v]]))+geom_line(color=cor)+geom_point(color=cor)+scale_y_log10()+
      labs(title=paste('Evolução anual:',v),x='Ano',y='Fluxo (W m⁻²), eixo log10'),paste0('anual_',v))
  p$diarios_ano <- fig(ggplot(diario[is.finite(maximo)],aes(factor(format(data,'%Y')),maximo))+
    geom_boxplot(color=cor)+scale_y_log10()+labs(title='Máximos diários por ano',x='Ano',y='Máximo diário (W m⁻²), eixo log10'),'maximos_diarios_por_ano')
  # Diferenças anuais de medianas diárias, não milhões de minutos como réplicas independentes.
  # Teste exploratório com permutação de segmentos contíguos de 27 dias, preservando agrupamento local.
  z <- diario[is.finite(mediana),.(data, y=log10(mediana))]
  z[,ano:=format(data,'%Y')]; z[,segmento:=as.integer(data-min(data))%/%27]
  segmentos <- split(z$y,z$segmento); comprimentos <- lengths(segmentos)
  yy <- z$ano
  estat <- function(v) {
    medias <- tapply(v,yy,mean); nn <- table(yy)
    sum(as.numeric(nn)*(medias-mean(v))^2)/sum((v-mean(v))^2)
  }
  obs_est <- estat(z$y)
  set.seed(config$semente+1L)
  perm <- replicate(499,estat(unlist(segmentos[sample.int(length(segmentos))],use.names=FALSE)))
  mudanca <- data.table(estatistica=obs_est,p_permutacao=(1+sum(perm>=obs_est))/500,
    segmentos=length(segmentos),duracao_segmento_dias=27)
  csv(mudanca,'mudanca_anual_exploratoria')
  list(descritiva=desc,anual=anual,diario=diario,lacunas=gaps,visual=visual,plots=p,
    limiar_eventos=q[7],mudanca=mudanca)
}
