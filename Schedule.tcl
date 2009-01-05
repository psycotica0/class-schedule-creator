###############FUNCTIONS###############

###
#ReadFile: This function takes in a file handle and handles the reading of the data
#
#	in: This is a handle to an open input file.
#	out: This is a handle to an open output file
###
proc ReadFile {in out} {
	global Title
	set currentCourse ""
	foreach line [split [read $in] \n] {
		if {[regexp {^#} $line]} {
			#This is a comment line
			continue
		} elseif {[regexp {^[^\n;]+;[^\n;]+;[^\n;]+$} $line]} {
			#This is the start of a new course
			foreach {Name Command Colour} [split $line ";"] {}
			set currentCourse $Command
			if {[string equal $Colour black]} {
				set TextColour {\color{white}}
			} else {
				set TextColour ""
			}
			puts $out "\\newcommand\{\\$Command\}\{\\colorbox\{$Colour\}\{$TextColour$Name\}\}"
		} elseif {[regexp {^[\t ]} $line]} {
			#This is a new date for the current course
			set lineM [string trim $line]
			set broken [split $lineM ";"]
			set dates [split [lindex $broken 0] ","]
			set time [split [lindex $broken 1] "-"]
			AddTime $currentCourse $dates [lindex $time 0] [lindex $time 1]
		} elseif {[regexp {\w+} $line]} {
			set Title $line
		}
	}
}

###
#AddTime: This function takes an a course command, a list of days, a start time, and an end time.
#	This then puts it into the schedule array
#
#	command: This is the command to be called in this block
#	dates: This is a list of days the command should be put in
#	start: This is the start of the block the commands should be put in
#	end: This is the end of the block the commands should end in
###
proc AddTime {command dates start end} {
	global Schedule
	#Use the blocks to calculate which item should be changed
	set Blocks [TimeIndex $start $end]
	set sBlock [lindex $Blocks 0]
	set eBlock [lindex $Blocks 1]
	#Use a foreach loop to go through each day
	foreach day $dates {
		#Foreach day set the precalculated blocks to the given command
		for {set i $sBlock} {$i <= $eBlock} {incr i} {
			set Schedule($day) [lreplace $Schedule($day) $i $i "\\$command"]
		}
	}
}

###
#TimeIndex: This function takes in a start and end time (In the form H(H)?:MM) and returns the index of the list it should start with and the index it should end with.
#	It's basically magic
#	It returns a list with the first item the starting index and  the next the ending index
#
#	start: This is the end time
#	end: This is the end time
###
proc TimeIndex {start end} {
 regexp {(\d+):(\d+)} $start Mat sH sM
 regexp {(\d+):(\d+)} $end Mat eH eM
 #foreach {sH sM} [split $start ":"] {}
 #foreach {eH eM} [split $end ":"] {}
 foreach c [list s e] {
	set Command "set ${c}H \[expr \{\$${c}H+12\}\]"
 	if "\$${c}H >=1 && \$${c}H <8" $Command
	 #First set the index to the hours minus 8 (The first time) times 2 to (to skip all the 30s)
	 set Command "set ${c}Index \[expr \{(\$${c}H-8)*2\}\]"
	 #Then, if the minutes are larger than 30, add another block
	 set Command2 [list if "\$${c}M>=30" "incr ${c}Index"]
	 eval $Command
	 eval $Command2
	 #Finally, add 1 to them both to account for the title bar
	 eval [list incr ${c}Index]
 }
 #Put them in a list and return it
 return [list $sIndex $eIndex]
}

###
#PrintChart: This is the part that prints out the chart and ends the file
#
#	out: This is the open handle to the output file
###
proc PrintChart {out} {
	global Schedule
	global Title 
	puts $out {\documentclass{article}

	 \usepackage {color}

	 \begin {document}

	 \begin {center}
	 \Huge}
 puts $out $Title
 puts $out {\end {center}
	}
	puts $out {\begin{tabular}{|c|c|c|c|c|c|}
	\hline
	}
	for {set i 0} {$i < [llength $Schedule("0")] } {incr i} {
		#Print the time
		puts -nonewline $out [lindex $Schedule("0") $i]
		foreach column [list Mon Tues Wed Thurs Fri] {
			puts -nonewline $out "&[lindex $Schedule($column) $i]"
		}
		puts $out {\\\hline}
	}
	puts $out {\end{tabular}
	\end{document}
	}
}

###
#Setup: This starts the output by adding the top parts of the file.
#	It also initializes the array
#
#	out: This is a handle to an open output file
###
proc Setup {out} {
	global Schedule
	#Set up the array
	set Schedule("0") [list " "]
	set Schedule(Mon) "Monday"
	set Schedule(Tues) "Tuesday"
	set Schedule(Wed) "Wednesday"
	set Schedule(Thurs) "Thursday"
	set Schedule(Fri) "Friday"
	for {set i 8} {$i <= 12} {incr i} {
		lappend Schedule("0") $i:00 $i:30
		foreach day [list Mon Tues Wed Thurs Fri] {
			lappend Schedule($day) " " " "
		}
	}
	for {set i 1} {$i <= 7} {incr i} {
		lappend Schedule("0") $i:00 $i:30
		foreach day [list Mon Tues Wed Thurs Fri] {
			lappend Schedule($day) " " " "
		}
	}
}
###############Main###############

#Import cmdline
package require cmdline
#Pull in options
set options [list \
	[list t.arg "html" "This is the type of the output file. Currently Accepted values are html and tex."]\
	[list f.arg "" "This is the filename of the input file. If not given, stdin is read."]\
	[list o.arg "" "This is the filename of the output argument. If not given, stout is printed to."]\
]
set usage {
This command takes in a file describing a schedule and outputs a representation of this schedule in the format specified.
If no format is specified, it is output as an HTML table.
Options:
}
if {[catch {array set flags [::cmdline::getoptions argv $options $usage]} output]} {
	puts $output
	exit
}

#Make some global variables
if {$flags(f) != ""} {
	if {![file exists $flags(f)]} {
		puts "Input file \"$flags(f)\" doesn't exist"
		return
	} else {
		set In [open $flags(f) r]
	}
} else {
	set In stdin
}

if {$flags(o) != ""} {
	set Out [open $flags(o) w]
} else {
	set Out stdout 
}

set Title "Schedule"

#Now do the actual formatting
Setup $Out
ReadFile $In $Out
PrintChart $Out

#And close the streams, if I can
if {$Out != "stdout"} {
	close $Out
}

if {$In != "stdin"} {
	close $In
}
