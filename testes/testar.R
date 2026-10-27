# Testes técnicos: a fixture NUNCA é usada como resultado científico.
# Todo o pipeline e qualquer HTML de teste ficam fora do checkout, em tempdir().
raiz <- normalizePath('.')
stopifnot(file.exists('relatorio.qmd'))
local_teste <- tempfile('goes_TESTE_ARTIFICIAL_',tmpdir='/tmp')
dir.create(local_teste)
for(p in c('R','formatos','relatorio.qmd','estilos.css','tema.scss','_quarto.yml')) {
  stopifnot(file.copy(file.path(raiz,p),local_teste,recursive=TRUE))
}
setwd(local_teste)
source('R/config.R');config$bootstrap<-149L
source('R/utils.R');source('R/01_leitura_limpeza.R')
source('R/04_block_maxima.R')
criar_fixture <- function(arquivo,falha=NULL) {
  ini<-as.POSIXct('2018-01-01',tz='UTC');fim<-as.POSIXct('2023-01-01',tz='UTC')
  tempo<-seq(ini,fim-60,by=60)
  # Origem de propósito diferente do começo da série e em HORAS, não segundos.
  origem<-as.POSIXct('2001-02-03 04:05:06',tz='UTC')
  horas<-as.numeric(difftime(tempo,origem,units='hours'))
  if(identical(falha,'tempo')) horas[10]<-horas[9]
  dt<-ncdf4::ncdim_def('time','hours since 2001-02-03 04:05:06 UTC',horas)
  vf<-ncdf4::ncvar_def('xrsb_flux',if(identical(falha,'unidade'))'bananas' else 'W m-2',list(dt),missval=-999,compression=4)
  vq<-ncdf4::ncvar_def('xrsb_flag','1',list(dt),missval=-9,prec='short',compression=4)
  nc<-ncdf4::nc_create(arquivo,list(vf,vq),force_v4=TRUE)
  on.exit(ncdf4::nc_close(nc))
  ncdf4::ncatt_put(nc,'time','calendar','gregorian')
  # good_data não é zero: flag 7 deve ser lida dos metadados.
  ncdf4::ncatt_put(nc,'xrsb_flag','flag_values',c(7L,9L),prec='short')
  ncdf4::ncatt_put(nc,'xrsb_flag','flag_meanings',if(identical(falha,'flags'))'unknown bad_data' else 'good_data bad_data')
  set.seed(711)
  mes<-as.integer(factor(format(tempo,'%Y-%m')))
  max_mes<-evd::rgev(max(mes),loc=10,scale=3,shape=.12)*1e-6
  # Valores de teste, não um modelo físico de fluxo solar.
  x<-runif(length(tempo),.02,.7)*max_mes[mes]
  primeiros<-which(!duplicated(mes));x[primeiros+500]<-max_mes
  flags<-rep(7L,length(x));flags[1001:1100]<-9L
  x[2001:2005]<- -999;x[3001]<-0;x[4001]<- -1e-8
  ncdf4::ncvar_put(nc,'xrsb_flux',x);ncdf4::ncvar_put(nc,'xrsb_flag',flags)
  invisible(list(n=length(x),validos=length(x)-107L,primeiro=ini,ultimo=fim-60))
}
dir.create('Dados')
verdade<-criar_fixture(config$arquivo)
b<-ler_xrs(config$arquivo)
stopifnot(nrow(b$dados_xrs)==verdade$n,nrow(b$dados_limpos)==verdade$validos,
          b$good_data==7,b$unidades_tempo=='hours since 2001-02-03 04:05:06 UTC',
          abs(as.numeric(min(b$dados_xrs$data_hora)-verdade$primeiro))<1e-3,
          abs(as.numeric(max(b$dados_xrs$data_hora)-verdade$ultimo))<1e-3)
bl<-construir_blocos(b)
stopifnot(nrow(bl$blocos$mensal)==60L,all(bl$blocos$mensal$n>0),
  bl$blocos$diario[inicio==as.Date('2020-02-29'),esperado]==1440)
# Contrato real: máscaras compostas, dimensão sem coordenada e faixa valid_min/max.
tc<-ncdf4::ncdim_def('time','seconds since 2000-01-01 12:00:00 UTC',
  as.numeric(difftime(as.POSIXct('2017-02-07',tz='UTC'),as.POSIXct('2000-01-01 12:00:00',tz='UTC'),units='secs'))+(0:6)*60)
qd<-ncdf4::ncdim_def('quad_diode','',1:4,create_dimvar=FALSE)
vf<-ncdf4::ncvar_def('xrsb_flux','W/m2',list(tc),missval=-9999)
vq<-ncdf4::ncvar_def('xrsb_flag','1',list(tc),missval=255,prec='short')
va<-ncdf4::ncvar_def('auxiliar','1',list(qd),missval=-9999)
mascara_arq<-'Dados/contrato_mascaras.nc'
nc<-ncdf4::nc_create(mascara_arq,list(vf,vq,va),force_v4=TRUE)
ncdf4::ncatt_put(nc,'xrsb_flag','flag_values',c(0,1,2,4))
ncdf4::ncatt_put(nc,'xrsb_flag','flag_masks',c(3,1,2,4))
ncdf4::ncatt_put(nc,'xrsb_flag','flag_meanings','good_data eclipse bad_data interpolated')
ncdf4::ncatt_put(nc,'xrsb_flux','valid_min',1e-9)
ncdf4::ncatt_put(nc,'xrsb_flux','valid_max',.2)
ncdf4::ncvar_put(nc,'xrsb_flux',c(rep(1e-6,6),1e-10))
ncdf4::ncvar_put(nc,'xrsb_flag',c(0,1,2,4,5,255,0))
ncdf4::nc_close(nc)
bm<-ler_xrs(mascara_arq)
stopifnot(nrow(bm$dados_limpos)==1L,bm$good_data==0,
  bm$flags[xrsb_flag==5,significado]=='eclipse | interpolated',
  bm$exclusoes[motivo=='fluxo fora da faixa válida dos metadados',N]==1L,
  bm$validacao$total==7L,bm$validacao$removidos==6L,
  !any(grepl('HAS NO DIMVAR',bm$avisos_metadados,fixed=TRUE)))
# Testes de falhas usam cópias; não criam repetidamente fixtures grandes.
nc<-ncdf4::nc_open(config$arquivo,write=TRUE)
ncdf4::ncatt_put(nc,'xrsb_flag','flag_meanings','unknown bad_data');ncdf4::nc_close(nc)
err<-tryCatch(ler_xrs(config$arquivo),error=identity)
stopifnot(inherits(err,'error'),grepl('good_data',conditionMessage(err)))
nc<-ncdf4::nc_open(config$arquivo,write=TRUE)
ncdf4::ncatt_put(nc,'xrsb_flag','flag_meanings','good_data bad_data')
ncdf4::ncatt_put(nc,'xrsb_flux','units','bananas');ncdf4::nc_close(nc)
err<-tryCatch(ler_xrs(config$arquivo),error=identity)
stopifnot(inherits(err,'error'),grepl('Unidade',conditionMessage(err)))
nc<-ncdf4::nc_open(config$arquivo,write=TRUE)
ncdf4::ncatt_put(nc,'xrsb_flux','units','W m-2');ncdf4::nc_close(nc)
# Exercita todos os módulos com a configuração de produção, alterando SOMENTE B em cópia temporária.
cf<-readLines('R/config.R');cf<-sub('bootstrap = 399L','bootstrap = 149L',cf,fixed=TRUE);writeLines(cf,'R/config.R')
rm(b,bl);gc()
source('R/executar.R')
stopifnot(file.exists('resultados/resumo.rds'),modelos$principal=='mensal',
          all(diff(retornos$tabela$estimativa)>0),
          all(retornos$tabela$inferior<=retornos$tabela$superior),
          all(is.finite(modelos$parametros$estimativa)),
          all(modelos$comparacao$convergiu),
          nrow(retornos$picos)==20,
          all(diff(retornos$sensibilidade$n_eventos)<=0),
          retornos$sucessos>=120,
          base$validacao$validos==verdade$validos,
          all(retornos$eventos$posicao==seq_len(nrow(retornos$eventos))),
          !modelos$ns$ok || modelos$ns$fit$deviance<=modelos$modelos[[modelos$principal]]$fit$deviance+.001)
# Fórmula de retorno e invariância à reescala.
e<-modelos$modelos$mensal$fit$estimate
s<-modelos$modelos$mensal$escala
p<-1-1/(12*retornos$tabela$anos)
stopifnot(max(abs(evd::pgev(retornos$tabela$estimativa/s,loc=e['loc'],scale=e['scale'],shape=e['shape'])-p))<1e-8)
# Skew-t: contrato da mesma amostra e fórmulas na unidade física original.
am<-skew_t$amostra_comum
stopifnot(identical(am$inicio,block$blocos$mensal[elegivel==TRUE,inicio]),
  identical(am$maximo,block$blocos$mensal[elegivel==TRUE,maximo]),
  nrow(am)==modelos$modelos$mensal$fit$n,
  all(skew_t$criterios$n==nrow(am)),
  all(complete.cases(skew_t$diagnosticos)),
  all(is.finite(skew_t$diagnosticos$teorico)),
  all(skew_t$diagnosticos$pit>=0 & skew_t$diagnosticos$pit<=1),
  skew_t$ajuste$dp['omega']>0,skew_t$ajuste$dp['nu']>0,
  skew_t$ajuste$convergiu,
  all(abs(skew_t$criterios$AIC-(-2*skew_t$criterios$logLik+2*skew_t$criterios$k))<1e-8),
  all(abs(skew_t$criterios$BIC-(-2*skew_t$criterios$logLik+log(nrow(am))*skew_t$criterios$k))<1e-8))
dp<-skew_t$ajuste$dp
prob<-c(.1,.5,.9,.99)
q<-sn::qst(prob,dp=dp)
stopifnot(all(is.finite(q)),all(diff(q)>0),
  max(abs(sn::pst(q,dp=dp)-prob))<2e-6,
  all(sn::dst(am$maximo/s,dp=dp)>0),
  abs(sum(sn::dst(am$maximo,dp=dp*c(s,s,1,1),log=TRUE))-skew_t$ajuste$logLik)<1e-5)
# Caso conhecido alpha=0: Student t simétrica, densidade normalizada e quantis exatos.
z<-seq(-5,5,length.out=51)
stopifnot(max(abs(sn::dst(z,dp=c(0,1,0,5))-dt(z,df=5)))<1e-10,
  max(abs(sn::qst(prob,dp=c(0,1,0,5))-qt(prob,df=5)))<1e-6,
  abs(integrate(function(t)sn::dst(t,dp=c(0,1,3,5)),-Inf,Inf)$value-1)<1e-6)
# Divergência da amostra GEV deve interromper, não ser corrigida silenciosamente.
err<-tryCatch(amostra_mensal_comum(block,within(modelos,principal<-'diario')),error=identity)
stopifnot(inherits(err,'error'))
mod_errado<-modelos
mod_errado$modelos$mensal$fit$data[1]<-mod_errado$modelos$mensal$fit$data[1]+1
err<-tryCatch(amostra_mensal_comum(block,mod_errado),error=identity)
stopifnot(inherits(err,'error'))
# Cenários com exclusões têm o mesmo n para as duas famílias, sem mudar o principal.
stopifnot(all(skew_t$sensibilidade[,uniqueN(n),by=cenario]$V1==1L),
  identical(skew_t$sens_diagnosticos$n,c(nrow(am),nrow(am)-1L,nrow(am)-3L)),
  all(is.finite(skew_t$sensibilidade$logLik)))
# Exercita identificação de fronteira: a amostra real não entra no teste artificial.
if(skew_t$ajuste$fronteira)stopifnot(!skew_t$ajuste$regular,all(is.na(skew_t$ajuste$parametros$ep)))
# Apresentação: envelope usa todos os minutos e conserva extremos; mesma amostra.
stopifnot(sum(apresentacao$horas$n)==nrow(dados_limpos),
  max(apresentacao$horas$maximo,na.rm=TRUE)==max(dados_limpos$xrsb_flux),
  min(apresentacao$horas$minimo,na.rm=TRUE)==min(dados_limpos$xrsb_flux),
  identical(apresentacao$mensal$inicio,skew_t$amostra_comum$inicio),
  identical(apresentacao$mensal$maximo,skew_t$amostra_comum$maximo),
  identical(apresentacao$retornos[['Nível (W/m²)']],retornos$tabela$estimativa),
  max(abs(diff(apresentacao$estacionariedade$AIC)-diff(modelos$comparacao_ns$AIC)))<1e-8,
  all(abs(apresentacao$comparacao$AIC-skew_t$criterios$AIC)<1e-8))
cat('\nTESTES TÉCNICOS PASSARAM. Dados ARTIFICIAIS, sem interpretação solar.\n')
cat('DIRETORIO_TESTE=',local_teste,'\n',sep='')
writeLines(local_teste,file.path(raiz,'testes/ultimo_diretorio.txt'))
