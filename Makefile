

targets = \
	presentation.html


md_format = \
	markdown+pandoc_title_block+pipe_tables+table_captions+escaped_line_breaks+implicit_figures+strikeout+tex_math_dollars+latex_macros+fenced_code_blocks

math_opt = --mathml
#math_opt = --mathjax
#math_opt = --glatex

slide_opts = \
	--self-contained --standalone \
	$(math_opt)
##	--incremental

%.html: %.md
	pandoc -f $(md_format) -t s5 $(slide_opts) -o $@ $<

%.tex: %.md
	pandoc -f $(md_format) -t beamer -s --slide-level=2 -o $@ $<


%.dvi %.log %.aux: %.tex
	platex $<


%.pdf: %.dvi
	dvipdfmx $(@:.pdf=.dvi)


all: $(targets)

clean:
	$(RM) $(targets)
	$(RM) *.dvi *.pdf
	$(RM) *.aux *.log *.nav *.out *.snm *.toc *.vrb
