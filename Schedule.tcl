###############FUNCTIONS###############

###
#ReadFile: This function takes in a file handle and handles the reading of the data
#
#	in: This is a handle to an open input file.
#	out: This is a handle to an open output file
###
proc ReadFile {in out} {
	set currentCourse ""
	foreach line [split [read $in] \n] {
		if {[regexp {^\w} $line]} {
			#This is the start of a new course
			foreach {Name Command Colour} [split $line ";"] {}
			set currentCourse $Command
			puts $out "\\newcommand\{\\$Command\}\{\\colorbox\{$Colour\}\{$Name\}\}"
		} else {
			#This is a new date for the current course
			set lineM [string trim $line]
			set broken [split $lineM ";"]
			set dates [split [lindex $broken 0] ","]
			set time [split [lindex $broken 1] "-"]
			AddTime $currentCourse $dates [lindex $time 0] [lindex $time 1]
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
proc AddTime {command, dates, start, end} {
	global Schedule
	#Use the blocks to calculate which item should be changed
	set Blocks [TimeIndex $start $end]
	set sBlock [lindex $Blocks 0]
	set eBlock [lindex $Blocks 1]
	#Use a foreach loop to go through each day
	foreach day $dates {
		#Foreach day set the precalculated blocks to the given command
		for {set i $sBlock} {$i <= $eBlock} {incr i} {
			set Schedule($day) "\\$command"
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
 incr sH
 foreach c [list s e] {
	set Command "set sH \[expr \{${c}H+12\}\]"
 	if "\$${c}H >=1 && \$${c}H <8}" $Command
	 #First set the index to the hours minus 8 (The first time) times to (to skip all the 30s)
	 set Command "set ${c}Index \[expr \{(\$${c}H-8)*2\}\]"
	 #Then, if the minutes are larger than 30, add another block
	 set Command2 [list if "\$${c}M>30" "incr ${c}Index"]
	 eval $Command
	 eval $Command2
	 #Finally, add 1 to them both to account for the title bar
	 eval [list incr ${c}Index]
 }
 #Put them in a list and return it
 return [list $sIndex $eIndex]
}


###
#Setup: This starts the output by adding the top parts of the file.
#	It also initializes the array
#
#	out: This is a handle to an open output file
###
proc Setup {out} {
	global Schedule
	puts $out {\documentclass{article}

	 \usepackage {color}

	 \begin {document}

	 \begin {center}
	 \Huge
	Christopher's Schedule
	 \end {center}
	}
	#Set up the array
	set Schedule("0") ""
	for {set i 8} {$i <= 12} {incr i} {
		lappend Schedule("0") $i:00 $i:30
	}
	for {set i 1} {$i <= 7} {incr i} {
		lappend Schedule("0") $i:00 $i:30
	}
	set Schedule(Mon) "Monday"
	set Schedule(Tues) "Tuesday"
	set Schedule(Wed) "Wednesday"
	set Schedule(Thurs) "Thursday"
	set Schedule(Fri) "Friday"
}
###############Main###############
if {![file exists Schedule.txt]} {
	puts "No Schedule.txt file"
	return
}
set In [open Schedule.txt r]
set Out [open Schedule.tex w]
Setup $Out
ReadFile $In $Out
