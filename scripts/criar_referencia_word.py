#!/usr/bin/env python3
"""Recria somente o modelo visual Word; requer python-docx e Quarto."""
from pathlib import Path
import io, subprocess
from docx import Document
from docx.shared import Mm, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

root = Path(__file__).resolve().parents[1]
base = subprocess.check_output(['quarto', 'pandoc', '--print-default-data-file', 'reference.docx'])
doc = Document(io.BytesIO(base))
sec = doc.sections[0]
sec.page_width, sec.page_height = Mm(210), Mm(297)
sec.top_margin = sec.bottom_margin = sec.left_margin = sec.right_margin = Mm(24)
sec.header_distance = sec.footer_distance = Mm(12)
for name in ['Normal', 'Body Text', 'First Paragraph', 'Bibliography', 'Block Text']:
    s = doc.styles[name]
    s.font.name, s.font.size = 'Liberation Serif', Pt(11)
    s.font.color.rgb = RGBColor.from_string('000000')
    s.paragraph_format.line_spacing = 1.12
    s.paragraph_format.space_after = Pt(6)
    s.paragraph_format.widow_control = True
for level in range(1, 10):
    s = doc.styles[f'Heading {level}']
    s.font.name, s.font.size = 'Liberation Sans', Pt(14 if level == 1 else 12 if level == 2 else 11)
    s.font.color.rgb = RGBColor.from_string('243E50')
    s.paragraph_format.keep_with_next = True
    s.paragraph_format.space_before = Pt(14 if level == 1 else 10)
    s.paragraph_format.space_after = Pt(6)
for name in ['Compact', 'Table']:
    doc.styles[name].font.name = 'Liberation Serif'
    doc.styles[name].font.size = Pt(9.5)
doc.styles['Compact'].paragraph_format.line_spacing = 1.05
doc.styles['Compact'].paragraph_format.space_after = Pt(0)
for name in ['Caption', 'Table Caption', 'Image Caption']:
    s = doc.styles[name]
    s.font.name, s.font.size = 'Liberation Serif', Pt(9.5)
    s.paragraph_format.keep_together = True
    s.paragraph_format.keep_with_next = name == 'Table Caption'
    s.paragraph_format.space_after = Pt(6)
doc.styles['Captioned Figure'].paragraph_format.keep_with_next = True
for name, size in [('Title', 21), ('Subtitle', 13), ('Date', 11)]:
    s = doc.styles[name]
    s.font.name, s.font.size = 'Liberation Sans', Pt(size)
    s.font.color.rgb = RGBColor.from_string('243E50')
    s.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    s.paragraph_format.keep_with_next = name != 'Date'
doc.styles['Title'].paragraph_format.space_before = Pt(90)
doc.styles['Title'].paragraph_format.space_after = Pt(20)
doc.styles['Subtitle'].paragraph_format.space_after = Pt(30)
doc.styles['TOC Heading'].paragraph_format.page_break_before = True
footer = sec.footer.paragraphs[0]
footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
field = OxmlElement('w:fldSimple'); field.set(qn('w:instr'), 'PAGE')
footer._p.append(field)
settings = doc.settings.element
update = settings.find(qn('w:updateFields'))
if update is None:
    update = OxmlElement('w:updateFields'); settings.append(update)
update.set(qn('w:val'), 'true')
math = settings.find(qn('m:mathPr'))
if math is None:
    math = OxmlElement('m:mathPr'); settings.append(math)
font = OxmlElement('m:mathFont'); font.set(qn('m:val'), 'Latin Modern Math'); math.append(font)
doc.save(root / 'formatos' / 'referencia-word.docx')
