MAIN = relatorio

LATEX = pdflatex
BIBTEX = bibtex

AUX_FILES = *.aux *.log *.toc *.out *.bbl *.blg *.lof *.lot *.fls *.fdb_latexmk

.PHONY: all clean

all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex
	$(LATEX) $(MAIN).tex
	$(LATEX) $(MAIN).tex
	$(LATEX) $(MAIN).tex

clean:
	rm -f $(MAIN).pdf $(AUX_FILES)
