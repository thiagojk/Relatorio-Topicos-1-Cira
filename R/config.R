# Todas as escolhas de sensibilidade são explícitas; não ajustar para obter p > 0,05.
config <- list(arquivo = file.path('Dados', 'sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc'),
               cobertura = 0.90, coberturas = c(0.80, 0.90, 0.95),
               quantil_evento = 0.999, janelas_h = c(1, 6, 24),
               bootstrap = 399L, semente = 20261022L, max_visual = 20000L)
