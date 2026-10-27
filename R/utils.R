necessarios <- c('ncdf4', 'data.table', 'ggplot2', 'evd', 'knitr')
faltam <- necessarios[!vapply(necessarios, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltam)) stop('Instale: ', paste(faltam, collapse = ', '))
library(data.table)
library(ggplot2)
options(stringsAsFactors = FALSE, scipen = 0)
Sys.setenv(TZ = 'UTC')
if (!nzchar(Sys.getenv('XDG_CACHE_HOME'))) Sys.setenv(XDG_CACHE_HOME=file.path(tempdir(),'cache'))
dir.create(Sys.getenv('XDG_CACHE_HOME'),recursive=TRUE,showWarnings=FALSE)
data.table::setDTthreads(min(4L, data.table::getDTthreads()))
for (d in c('figuras', 'tabelas', 'resultados')) dir.create(d, showWarnings = FALSE)
set.seed(config$semente)
theme_set(theme_minimal(base_size = 12) + theme(
  plot.title = element_text(face = 'bold'), panel.grid.minor = element_blank(),
  plot.caption = element_text(hjust = 0), legend.position = 'bottom'))
cor <- '#24536b'
sci <- function(x) formatC(x, format = 'e', digits = 3)
num <- function(x) format(x, big.mark = '.', decimal.mark = ',', trim = TRUE)
csv <- function(x, nome) fwrite(x, file.path('tabelas', paste0(nome, '.csv')), na = 'NA')
fig <- function(p, nome, w = 9, h = 4.6) {
  ggsave(file.path('figuras', paste0(nome, '.png')), p, width = w, height = h, dpi = 180)
  p
}
linha <- function(d, x, y, titulo, eixo = 'Fluxo (W m⁻²)', log = TRUE) {
  p <- ggplot(d, aes(x = .data[[x]], y = .data[[y]])) + geom_line(color = cor, linewidth = .35, na.rm = TRUE) +
    labs(title = titulo, x = 'Data (UTC)', y = eixo)
  if (log) p <- p + scale_y_log10(labels = scales::label_scientific())
  p
}
# ACF/PACF: apenas o maior trecho contíguo completo, nunca colapsar lacunas.
serie_contigua <- function(x) {
  z <- rle(is.finite(x)); fins <- cumsum(z$lengths)
  candidatos <- which(z$values)
  if (!length(candidatos)) return(numeric())
  k <- candidatos[which.max(z$lengths[candidatos])]
  x[seq.int(fins[k] - z$lengths[k] + 1L, fins[k])]
}
bloco_inicio <- function(d, tipo) {
  if (tipo == 'diario') return(as.Date(d))
  if (tipo == 'semanal') return(as.Date(d) - (as.integer(format(d, '%u')) - 1L))
  as.Date(format(d, '%Y-%m-01'))
}
bloco_fim <- function(inicio, tipo) {
  if (tipo == 'diario') return(inicio + 1L)
  if (tipo == 'semanal') return(inicio + 7L)
  as.Date(vapply(as.character(inicio), function(x) as.character(seq(as.Date(x), by = 'month', length.out = 2)[2]), character(1)))
}
