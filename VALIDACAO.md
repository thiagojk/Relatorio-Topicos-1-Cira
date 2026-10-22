# Validação e pendência dos dados reais

## O que foi executado

- R 4.5.0 e Quarto 1.7.32 instalados localmente em `/workspace/.tools/`, com índices Debian autenticados por assinatura e SHA256 do arquivo oficial do Quarto verificado.
- `bash scripts/preparar_nuvem.sh`: executado novamente com sucesso para verificar reutilização da instalação.
- `quarto check knitr`: detecção de R, pacotes e renderização do mecanismo knitr aprovadas.
- `Rscript testes/testar.R`: aprovado. A fixture NetCDF é **artificial**, com cinco anos de minutos, origem temporal diferente do início da série, tempo em horas, código `good_data = 7`, registros ruins, fill values e fluxos não positivos. O teste verifica conversão temporal, contagens de qualidade, fevereiro bissexto, falhas explícitas para flags/unidades inválidas, ajuste dos três tamanhos de bloco, quantis GEV, bootstrap e separação de episódios.
- A fixture fica exclusivamente em `/tmp/goes_TESTE_ARTIFICIAL_*`, fora da pasta de dados real. Não foi usada para estimar resultados solares.
- `bash testes/renderizar_teste.sh`: relatório HTML técnico renderizado com a marca **TESTE ARTIFICIAL — NÃO USAR COMO RESULTADO SOLAR**. A cópia de teste usa 149 replicações bootstrap; a configuração científica mantém 399. Nenhum HTML artificial é entregue como o trabalho final.
- As versões dos pacotes diretamente utilizados estão em `referencias/pacotes_validados.tsv`. A renderização real também registrará todas as versões em `resultados/sessionInfo.txt`.

A inspeção do HTML de teste verificou figuras incorporadas, tabelas e MathML. O tema usa fontes locais, sem carregar Google Fonts; a validação no navegador é feita com acesso externo bloqueado. As capturas e o HTML técnico permanecem na área temporária, separados da entrega científica.

## O que ainda não foi executado

A ferramenta de transferência recusou o arquivo `sci_xrsf-l2-avg1m_g16_s20170207_e20250407_v2-2-2.nc` por exceder **32 MiB**. A base não está disponível no filesystem. A execução na pasta real foi tentada e interrompeu com a mensagem esperada de NetCDF ausente.

Consequentemente, **não há escolha empírica de bloco, estimativas solares de mu/sigma/xi, classificação da cauda, níveis de retorno ou conclusão sobre não estacionariedade validados para a base real**. A presença de código funcional e de testes técnicos não supre essa pendência. O suporte aos metadados específicos do arquivo real também só poderá ser confirmado após sua leitura; formatos ambíguos param explicitamente em vez de assumir códigos ou origens.

## Retomar e concluir

1. Disponibilizar o NetCDF original na pasta `Dados/`, ou fornecer um link HTTPS para download. Uma versão compactada que caiba no limite também pode ser extraída preservando a base integral.
2. Na raiz do projeto:

```bash
export PATH=/workspace/.tools/bin:$PATH
quarto render relatorio.qmd
```

3. Conferir os CSVs de metadados, qualidade, cobertura e comparação de blocos; examinar os avisos, os diagnósticos GEV e a comparação temporal. Investigar qualquer falha em vez de reduzir controles para obter convergência.
4. Confirmar e revisar o **HTML real** em:

`/workspace/Relatorio-Topicos-1-Cira/relatorio.html`

Esse é o caminho esperado, **não um arquivo científico já produzido**.

A exportação PDF é opcional e não foi validada. A configuração reutilizável do ambiente foi salva nos campos `install_script` e `start_skill`; isso não publica o ambiente nem prova restauração em uma nova tarefa. A publicação é feita pelo usuário na interface, após revisar e salvar as configurações.

## Resultado da revisão visual final

O HTML técnico final foi aberto internamente em Chromium por HTTP local, sem disponibilizar um link de preview ao usuário. Requests externos foram bloqueados. Verificaram-se **37 imagens incorporadas, 22 tabelas, 21 elementos MathML, nenhuma imagem quebrada, nenhum erro JavaScript e nenhuma tabela com rolagem horizontal** em viewport de 1440 px. A renderização final não registrou avisos de recursos externos. Cabeçalhos, introdução, tabela de comparação de blocos e gráfico de retorno foram inspecionados visualmente. Esses números descrevem a validação da apresentação, não resultados solares.
