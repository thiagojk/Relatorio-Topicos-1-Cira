# Apresentação exclusiva para LaTeX. Recebe os MESMOS valores já formatados
# por mostrar(); não arredonda novamente, não filtra nem recalcula estatísticas.
tabela_pdf <- function(z,legenda) {
  nc<-ncol(z)
  pesos<-vapply(seq_len(nc),function(j) {
    cabecalho<-max(nchar(strsplit(names(z)[j],' ',fixed=TRUE)[[1]]))
    valores<-max(nchar(as.character(z[[j]])),na.rm=TRUE)+1
    max(7,min(32,max(cabecalho,valores)))
  },numeric(1))
  # 6 pt por coluna, em largura útil de 162 mm (A4 com margens de 24 mm).
  frac<-(1-nc*6/(162*72.27/25.4))*pesos/sum(pesos)
  alinhamento<-sprintf('>{\\raggedright\\arraybackslash}p{%.5f\\linewidth}',frac)
  tab<-knitr::kable(z,format='latex',caption=legenda,booktabs=TRUE,longtable=TRUE,
    align=alinhamento,linesep='',escape=TRUE)
  # Legenda e primeiro cabeçalho permanecem juntos; páginas seguintes repetem
  # as colunas. Não criar floats aninhados: o Quarto controla a numeração.
  texto<-as.character(tab)
  inicio<-regexpr('\\toprule',texto,fixed=TRUE)[1]
  meio<-regexpr('\\midrule',texto,fixed=TRUE)[1]+nchar('\\midrule')-1L
  cabecalho<-substr(texto,inicio,meio)
  tab<-paste0(substr(texto,1,meio),'\n\\endfirsthead\n',cabecalho,
    '\n\\endhead\n',substr(texto,meio+1L,nchar(texto)))
  # Reservar também as linhas de tabelas curtas. Estimativa conservadora de
  # altura, incluindo quebras de cabeçalho/células, legenda e espaçamentos.
  altura<-7*14.75
  if(nrow(z)<=10L && max(nchar(as.matrix(z)),na.rm=TRUE)<80L) {
    caracteres<-90*frac
    linhas_cab<-max(ceiling(nchar(names(z))/caracteres))
    linhas<-sum(apply(ceiling(sweep(nchar(as.matrix(z)),2,caracteres,'/')),1,max))
    estimada<-(linhas+linhas_cab)*14.75+ceiling(nchar(legenda)/85)*13+45
    if(estimada<600)altura<-estimada
  }
  knitr::asis_output(paste0('\n\\Needspace{',altura,'pt}\n\\begingroup\n',
    '\\fontsize{9.5}{11.5}\\selectfont\n\\setlength{\\tabcolsep}{3pt}\n',
    tab,'\n\\endgroup\n'))
}
