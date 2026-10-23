pacotes <- c('ncdf4','data.table','ggplot2','evd','knitr','rmarkdown','sn','numDeriv')
ausentes <- pacotes[!vapply(pacotes,requireNamespace,quietly=TRUE,FUN.VALUE=logical(1))]
if(length(ausentes)) install.packages(ausentes,repos='https://cloud.r-project.org')
stopifnot(all(vapply(pacotes,requireNamespace,quietly=TRUE,FUN.VALUE=logical(1))))
print(sapply(pacotes,function(p)as.character(packageVersion(p))))
