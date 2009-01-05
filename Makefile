Schedule.html : Input.txt Schedule.tcl
	tclsh Schedule.tcl -f Input.txt -o Schedule.html -t html
Schedule.pdf : Schedule.tex
	pdflatex Schedule.tex
Schedule.tex : Input.txt Schedule.tcl
	tclsh Schedule.tcl -f Input.txt -o Schedule.tex -t tex
ViewHtml : Schedule.html
	open Schedule.html
ViewTex : Schedule.pdf
	xpdf Schedule.pdf
