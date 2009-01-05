###############FUNCTIONS###############

###
#ReadFile: This function takes in a file handle and handles the reading of the data
#
#	in: This is a handle to an open input file.
#	out: This is a handle to an open output file
###
proc ReadFile {in} {
	global Title
	global Courses
	set currentCourse ""
	foreach line [split [read $in] \n] {
		if {[regexp {^#} $line]} {
			#This is a comment line
			continue
		} elseif {[regexp {^[^\n;]+;[^\n;]+;[^\n;]+$} $line]} {
			#This is the start of a new course
			foreach {Name UId Colour} [split $line ";"] {}
			set currentCourse $UId
			if {[string equal $Colour black]} {
				set TextColour {white}
			} else {
				set TextColour ""
			}
			#Add this Course to the list of courses
			lappend Courses [list $Name $UId $Colour $TextColour]
		} elseif {[regexp {^[\t ]} $line]} {
			#This is a new date for the current course
			set lineM [string trim $line]
			set broken [split $lineM ";"]
			set dates [split [lindex $broken 0] ","]
			set time [split [lindex $broken 1] "-"]
			AddTime $currentCourse $dates [lindex $time 0] [lindex $time 1]
		} elseif {[regexp {\w+} $line]} {
			#This is a title
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
			set Schedule($day) [lreplace $Schedule($day) $i $i "$command"]
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
	#Pull the time apart
	regexp {(\d+):(\d+)} $start Mat sH sM
	regexp {(\d+):(\d+)} $end Mat eH eM

	#Then for both the start and end time
	foreach c [list s e] {
		#This command increases a time by 12 hours
		set Command "set ${c}H \[expr \{\$${c}H+12\}\]"

		#If a time is between 1 and 8, add 12, to make 24h time
		if "\$${c}H >=1 && \$${c}H <8" $Command

		#First set the index to the hours minus 8 (The first time) times 2 to (to skip all the 30s)
		#The reason it is done with eval, is because I have a variable variable in there.
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
#PrintChart:tex: This is the part that prints out the chart in tex format.
#
#	out: This is the open handle to the output file
###
proc PrintChart:tex {out} {
	global Schedule
	global Title 
	global Courses
	#Set up the document
	puts $out {\documentclass{article}

	 \usepackage {color}

	 \begin {document}

	 \begin {center}
	 \Huge}
 #Then output the title
 puts $out $Title
 #And end the title section
 puts $out {\end {center}
	}
	#Now, setup each course command
	foreach Course $Courses {
		foreach {Name Command Colour TextColour} $Course {}
		if {$TextColour !="" } {
			puts $out "\\newcommand\{\\$Command\}\{\\colorbox\{$Colour\}\{\\color{$TextColour}$Name\}\}"
		} else {
			puts $out "\\newcommand\{\\$Command\}\{\\colorbox\{$Colour\}\{$Name\}\}"
		}
	}
	#Start the table
	puts $out {\begin{tabular}{|c|c|c|c|c|c|}
	\hline
	}
	#For each item in the first column
	for {set i 0} {$i < [llength $Schedule("0")] } {incr i} {
		#Print the time
		puts -nonewline $out [lindex $Schedule("0") $i]
		#Then go through each day of the week
		foreach column [list Mon Tues Wed Thurs Fri] {
			#Get the value from this time on this dau
			set Value [lindex $Schedule($column) $i]
			if {$i > 0} {
				#This is a row value, which is a command in tex
				if {$Value != ""} {
					puts -nonewline $out "&\\$Value"
				}
			} else {
				#This is a row header
				puts -nonewline $out "&$Value"
			}
		}
		#End the row
		puts $out {\\\hline}
	}
	#End the table, and the document
	puts $out {\end{tabular}
	\end{document}
	}
}

###
#PrintChart:html: This prints out the chart as an HTML document
#
#out: Handle to the output file.
###
proc PrintChart:html {out} {
	global Schedule
	global Title 
	global Courses
	puts $out "<html>
	<head>
		<title>
			$Title
		</title>"
	puts $out "<style type=\"text/css\">"
	puts $out "table {border: thin solid black}"
	puts $out "td {border: thin solid black}"
	puts $out ".time {font-weight:bold}"
	puts $out ".day {font-weight:bold}"
	#For each Course
	foreach Course $Courses {
		foreach {Name Command Colour TextColour} $Course {}
		#Make a Style
		puts -nonewline $out ".$Command {background: $Colour;"
		if {$TextColour != ""} {
			puts -nonewline $out "color:$TextColour;"
		}
		puts $out "}"
		#And make the map from Id to Text to be used in output
		set Macro($Command) $Name
	}
	puts $out "</style>"
	puts $out "	</head>
	<body>
		<center><h1>$Title</h1></center>
		<body>"
	puts $out "<table>"
	#For each item in the first column
	for {set i 0} {$i < [llength $Schedule("0")] } {incr i} {
		#Start the row
		puts $out "<tr>"
		#Print the time
		set time [lindex $Schedule("0") $i]
		puts $out "<td class='time'> $time </td>"
		#Then go through each day of the week
		foreach column [list Mon Tues Wed Thurs Fri] {
			#Get the value from this time on this dau
			set Value [lindex $Schedule($column) $i]
			if {$i > 0} {
				#This is a row value
				if {$Value != " "} {
					puts $out "<td class='$Value'> $Macro($Value) </td>"
				} else {
					puts $out "<td></td>"
				}
			} else {
				#This is a row header
				puts $out "<td class='day'> $Value </td>"
			}
		}
		#End the row
		puts $out "</tr>"
	}
	puts $out "</table>"
	puts $out "</body>"
	puts $out "</html>"
}

###
#Setup: This initializes the array
###
proc Setup {} {
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

#This is the title that goes at the top of the file.
set Title "Schedule"

#This is a list of course info.
# It is a list of lists, where each element is of the form [list Name UId Colour TextColour]
set Courses [list ]

#Now do the actual formatting
switch $flags(t) {
	html {
		set Command "PrintChart:html"
	} tex {
		set Command "PrintChart:tex"
	} default {
		puts stderr "Unrecognized Output Type \"$flags(t)\"."
		exit
	}
	
}
Setup 
ReadFile $In
$Command $Out

#And close the streams, if I can
if {$Out != "stdout"} {
	close $Out
}

if {$In != "stdin"} {
	close $In
}
