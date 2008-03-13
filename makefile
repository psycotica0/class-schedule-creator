Schedule.pdf : Schedule.tex
	pdflatex Schedule.tex
Schedule.tex : Schedule.txt Schedule.tcl
	tclsh Schedule.tcl
View : Schedule.pdf
	xpdf Schedule.pdf
