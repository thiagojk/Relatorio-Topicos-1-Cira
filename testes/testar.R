# Testes técnicos: a fixture NUNCA é usada como resultado científico.
# Todo o pipeline e qualquer HTML de teste ficam fora do checkout, em tempdir().
raiz <- normalizePath('.')
stopifnot(file.exists('relatorio.qmd'))
local_teste <- tempfile('goes_TESTE_ARTIFICIAL_',tmpdir='/tmp')
dir.create(local_teste)
for(p in c('R','relatorio.qmd','estilos.css','tema.scss','_quarto.yml')) {
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
          retornos$sucessos>=120)
# Fórmula de retorno e invariância à reescala.
e<-modelos$modelos$mensal$fit$estimate
s<-modelos$modelos$mensal$escala
p<-1-1/(12*retornos$tabela$anos)
stopifnot(max(abs(evd::pgev(retornos$tabela$estimativa/s,loc=e['loc'],scale=e['scale'],shape=e['shape'])-p))<1e-8)
cat('\nTESTES TÉCNICOS PASSARAM. Dados ARTIFICIAIS, sem interpretação solar.\n')
cat('DIRETORIO_TESTE=',local_teste,'\n',sep='')
writeLines(local_teste,file.path(raiz,'testes/ultimo_diretorio.txt'))
