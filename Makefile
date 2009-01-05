Output.html : Input.txt Schedule.tcl
	tclsh Schedule.tcl -f Input.txt -o Output.html -t html
Output.pdf : Output.tex
	pdflatex Output.tex
Output.tex : Input.txt Schedule.tcl
	tclsh Schedule.tcl -f Input.txt -o Output.tex -t tex
ViewHtml : Output.html
	open Output.html
ViewTex : Output.pdf
	xpdf Output.pdf
