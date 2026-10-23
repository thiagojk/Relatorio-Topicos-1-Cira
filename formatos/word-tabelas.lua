-- Apenas apresentação Word: larguras proporcionais, sem alterar células ou valores.
function Table(t)
  if FORMAT ~= 'docx' then return nil end
  local n = #t.colspecs
  local pesos = {}
  for i = 1, n do pesos[i] = 7 end
  local function medir(rows, cabecalho)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        if i <= n then
          local texto = pandoc.utils.stringify(cell.contents)
          local tamanho = utf8.len(texto) or #texto
          if cabecalho then
            tamanho = 0
            for palavra in texto:gmatch('%S+') do tamanho = math.max(tamanho, utf8.len(palavra) or #palavra) end
          end
          pesos[i] = math.max(pesos[i], math.min(32, tamanho + 1))
        end
      end
    end
  end
  medir(t.head.rows, true)
  for _, corpo in ipairs(t.bodies) do medir(corpo.head, false); medir(corpo.body, false) end
  medir(t.foot.rows, false)
  local total = 0
  for _, peso in ipairs(pesos) do total = total + peso end
  for i = 1, n do t.colspecs[i] = {t.colspecs[i][1], pesos[i] / total} end
  return t
end
