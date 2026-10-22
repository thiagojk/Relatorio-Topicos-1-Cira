ler_xrs <- function(arquivo) {
  if (!file.exists(arquivo)) stop('NetCDF ausente: ', arquivo,
    '. Copie a base real para Dados/. Nenhum resultado é fabricado.')
  nc <- ncdf4::nc_open(arquivo)
  on.exit(ncdf4::nc_close(nc))
  avisos_metadados <- character()
  ler_atributos <- function(v, a=NULL) {
    texto <- capture.output(z <- if(is.null(a)) ncdf4::ncatt_get(nc,v) else ncdf4::ncatt_get(nc,v,a))
    if(length(texto)) avisos_metadados <<- unique(c(avisos_metadados,texto))
    z
  }
  att <- function(v, a, default = NULL) {
    z <- ler_atributos(v,a)
    if (isTRUE(z$hasatt)) z$value else default
  }
  for (v in c('xrsb_flux', 'xrsb_flag')) if (!v %in% names(nc$var)) stop('Variável ausente: ', v)
  dimensoes_coordenadas <- names(nc$dim)[vapply(nc$dim,function(d)isTRUE(d$create_dimvar),logical(1))]
  nomes <- unique(c(names(nc$var), dimensoes_coordenadas))
  un <- lapply(nomes, function(v) att(v, 'units', ''))
  candidatas <- nomes[vapply(un, function(u) grepl(' since ', u, fixed = TRUE), logical(1))]
  if (length(candidatas) != 1L) stop('Coordenada temporal ausente ou ambígua.')
  tv <- candidatas[1]; tu <- att(tv, 'units'); cal <- att(tv, 'calendar', 'standard')
  if (!cal %in% c('standard','gregorian','proleptic_gregorian')) stop('Calendário não suportado: ', cal)
  re <- regexec('^([A-Za-z]+) since (.+)$', tu); partes <- regmatches(tu, re)[[1]]
  fatores <- c(seconds=1, second=1, sec=1, s=1, minutes=60, minute=60,
               hours=3600, hour=3600, days=86400, day=86400, milliseconds=.001, microseconds=.000001)
  fator <- unname(fatores[tolower(partes[2])])
  if (length(fator) != 1L || !is.finite(fator)) stop('Unidade temporal não suportada: ', tu)
  origem_txt <- trimws(gsub('T', ' ', partes[3], fixed = TRUE))
  origem_txt <- sub(' (UTC|GMT)$', '', origem_txt)
  origem_txt <- sub('Z$', '', origem_txt)
  origem_txt <- sub(' ([+-]00:00)$', '', origem_txt)
  if (grepl('[+-][0-9]{2}:?[0-9]{2}$', origem_txt)) stop('Fuso CF não UTC exige conversão explícita: ', origem_txt)
  origem <- as.POSIXct(origem_txt, tz = 'UTC', tryFormats = c('%Y-%m-%d %H:%M:%OS','%Y-%m-%d'))
  if (is.na(origem)) stop('Origem temporal inválida: ', tu)
  readraw <- function(v) {
    x <- as.vector(ncdf4::ncvar_get(nc, v, raw_datavals = TRUE))
    for (a in c('_FillValue','missing_value')) {
      fill <- att(v,a)
      if (length(fill)) x[x %in% fill] <- NA_real_
    }
    x <- x * att(v, 'scale_factor', 1) + att(v, 'add_offset', 0)
    x[!is.finite(x)] <- NA_real_; x
  }
  t <- readraw(tv); fluxo <- readraw('xrsb_flux'); flags <- readraw('xrsb_flag')
  if (length(t) != length(fluxo) || length(t) != length(flags)) stop('Dimensões incompatíveis.')
  tempo <- origem + t * fator
  if (anyNA(tempo) || any(diff(as.numeric(tempo)) <= 0)) stop('Datas inválidas, duplicadas ou fora de ordem.')
  if (min(tempo) < as.POSIXct('2017-01-01', tz='UTC') || max(tempo) > as.POSIXct('2026-01-01',tz='UTC'))
    stop('Datas incompatíveis com o produto GOES-16 fornecido; confira os metadados.')
  cadencia <- median(diff(as.numeric(tempo)))
  if (!is.finite(cadencia) || abs(cadencia - 60) > 1) stop('Cadência não é aproximadamente 1 minuto.')
  unidade <- att('xrsb_flux','units','')
  normal <- gsub('[[:space:]^*{}()]', '', tolower(unidade))
  if (!normal %in% c('wm-2', 'w/m2', 'wm−2')) stop('Unidade de fluxo não reconhecida: ', unidade)
  significados <- strsplit(trimws(att('xrsb_flag','flag_meanings','')), '[[:space:]]+')[[1]]
  valores <- att('xrsb_flag','flag_values'); mascaras <- att('xrsb_flag','flag_masks')
  ig <- which(significados == 'good_data')
  if (length(ig) != 1L || length(valores) != length(significados))
    stop('Não foi possível mapear good_data por flag_values/flag_meanings. Inspecione os metadados; não assumir código.')
  bom <- valores[ig]
  dados_xrs <- data.table(data_hora=tempo, data=as.Date(tempo,tz='UTC'),
    ano=as.integer(format(tempo,'%Y')), mes=format(tempo,'%Y-%m'),
    semana=format(tempo,'%G-W%V'), xrsb_flux=fluxo, xrsb_flag=flags)
  freq <- dados_xrs[, .N, by=xrsb_flag][order(xrsb_flag)]
  if(length(mascaras) && length(mascaras)!=length(valores)) stop('Máscaras e valores de flags incompatíveis.')
  decodificar <- function(v) {
    if(is.na(v)) return(NA_character_)
    if(!length(mascaras)) return(significados[match(v,valores)])
    encontrados <- significados[bitwAnd(as.integer(v),as.integer(mascaras))==as.integer(valores)]
    if(length(encontrados)>1L) encontrados <- setdiff(encontrados,'good_data')
    if(length(encontrados)) paste(encontrados,collapse=' | ') else 'código não descrito nos metadados'
  }
  freq[, significado := vapply(xrsb_flag,decodificar,character(1))]
  freq[, percentual := 100*N/nrow(dados_xrs)]
  csv(freq, 'flags_antes_exclusao')
  limites_fluxo <- c(att('xrsb_flux','valid_min',-Inf),att('xrsb_flux','valid_max',Inf))
  if(anyNA(limites_fluxo) || limites_fluxo[1]>limites_fluxo[2]) stop('Faixa válida do fluxo inconsistente.')
  # Seleção conservadora: código good_data puro; interpolados são excluídos mesmo
  # quando a máscara good_data também é satisfeita. Categorias disjuntas.
  motivo <- fifelse(is.na(flags), 'flag ausente/não finita/fill',
            fifelse(flags != bom, 'flag diferente de good_data',
            fifelse(!is.finite(fluxo), 'fluxo ausente/não finito/fill',
            fifelse(fluxo <= 0, 'fluxo não positivo',
            fifelse(fluxo<limites_fluxo[1] | fluxo>limites_fluxo[2], 'fluxo fora da faixa válida dos metadados', 'válida')))))
  exclusoes <- data.table(motivo)[,.N,by=motivo]; csv(exclusoes,'controle_qualidade')
  dados_limpos <- dados_xrs[motivo == 'válida']
  if (!nrow(dados_limpos)) stop('Nenhuma observação válida após controle de qualidade.')
  if (anyDuplicated(floor((as.numeric(tempo)+.001)/60))) stop('Mais de uma observação no mesmo minuto UTC.')
  meta_lista <- lapply(list(tv,'xrsb_flux','xrsb_flag',0), function(v) {
    a <- ler_atributos(v)
    if (!length(a)) return(data.table(variavel=character(), atributo=character(), valor=character()))
    data.table(variavel=as.character(v), atributo=names(a), valor=vapply(a,paste,collapse=' | ',FUN.VALUE=character(1)))
  })
  metadados <- rbindlist(meta_lista); csv(metadados,'metadados_netcdf')
  csv(data.table(aviso=avisos_metadados),'avisos_metadados')
  validacao <- data.table(total=nrow(dados_xrs),validos=nrow(dados_limpos),
    removidos=nrow(dados_xrs)-nrow(dados_limpos),percentual_valido=100*nrow(dados_limpos)/nrow(dados_xrs),
    inicio=min(tempo),fim=max(tempo),unidade=unidade,cadencia_segundos=cadencia,
    good_data=bom,codigos_encontrados=paste(freq$xrsb_flag,collapse=' | '))
  csv(validacao,'validacao_base')
  list(dados_xrs=dados_xrs, dados_limpos=dados_limpos, flags=freq, exclusoes=exclusoes,
       metadados=metadados, unidade=unidade, temporal=tv, unidades_tempo=tu,
       origem=origem, good_data=bom, cadencia=cadencia, arquivo=arquivo,
       md5=unname(tools::md5sum(arquivo)), mascaras=mascaras, limites_fluxo=limites_fluxo,
       validacao=validacao,avisos_metadados=avisos_metadados)
}
