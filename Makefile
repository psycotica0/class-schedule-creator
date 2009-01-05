Schedule.html : Schedule.txt Schedule.tcl
	tclsh Schedule.tcl -f Schedule.txt -o Schedule.html -t html
Schedule.pdf : Schedule.tex
	pdflatex Schedule.tex
Schedule.tex : Schedule.txt Schedule.tcl
	tclsh Schedule.tcl -f Schedule.txt -o Schedule.tex -t tex
ViewHtml : Schedule.html
	open Schedule.html
ViewTex : Schedule.pdf
	xpdf Schedule.pdf
