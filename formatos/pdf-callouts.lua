-- Alternativa de impressão para callouts; aplicada antes dos filtros Quarto,
-- somente no formato PDF. Preserva título e conteúdo, sem ícones de interface.
function Div(el)
  if not FORMAT:match('latex') or not el.classes:includes('pdf-aviso') then return nil end
  local conteudo = el.content
  local titulo = ''
  if conteudo[1] and conteudo[1].t == 'Header' then
    titulo = pandoc.write(pandoc.Pandoc({pandoc.Plain(conteudo[1].content)}), 'latex'):gsub('%s+$', '')
    conteudo:remove(1)
  end
  local inicio = '\\begin{tcolorbox}[breakable,colback=white,colframe=black!50,boxrule=.5pt,arc=0pt,title={' .. titulo .. '},colbacktitle=black!7,coltitle=black,fonttitle=\\bfseries]'
  local blocos = pandoc.List({pandoc.RawBlock('latex', inicio)})
  blocos:extend(conteudo)
  blocos:insert(pandoc.RawBlock('latex', '\\end{tcolorbox}'))
  return blocos
end

-- Identificadores extensos precisam de pontos de quebra sem mudar seus caracteres.
function Str(el)
  if FORMAT:match('latex') and #el.text >= 28 and
    (el.text:find('[_/]') or el.text:match('^[%da-f]+$')) then
    local texto = pandoc.write(pandoc.Pandoc({pandoc.Plain({el})}), 'latex'):gsub('%s+$', '')
    return pandoc.RawInline('latex', '\\seqsplit{' .. texto .. '}')
  end
end
