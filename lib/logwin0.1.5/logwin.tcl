package provide logwin 0.1.5

namespace eval ::logwin:: {


#==========================================================================================================
# Logwin-Package
#
# Purpose: Run a command in tcl-exec-style and put the output line by line into a log-window.
# Feature: Multiple windows are supported, therefore you have to provide an identifer 
#          for the window you are talking about.
#----------------------------------------------------------------------------------------------------------
#



proc ::logwin::runCmd {w c} {

#----------------------------------------------------------------------------------------------------------
# Desc: Runs the command $c in Widget named $w
# in:     w: Valid widget-name determined by caller
#            The window named $w will be raised on top or created if not exists
#         c: Command which will be run
# out:    -
# return: 1: if $c was not found or returns an error itself
#         0: $c was called successfully and returned 0 itself
#----------------------------------------------------------------------------------------------------------
#
	writeCmd $w "$c\n"
	set cmd [ string map { \\ \\\\ } "|$c" ] ;# Weil irgendeiner mir die Backslashes ruiniert!
	set rc 1
	if { [ catch { open "$cmd" r} in ] } {
		writeErr $w "Calling command failed. $in\n"
	} else {
		while {[gets $in line] >= 0} {
			writeLine $w "$line"
			if { [ info exists ::logwin::scanCmd(w$w) ] } { eval "$::logwin::scanCmd(w$w) $w \{$line\}" }
		}
		catch { close $in } rcc
		if { "$rcc" == "" } { 
			set rc 0;
			writeOk $w "OK\n"
		} else { 
			writeErr $w "$rcc\n" 
		}
	}
	return $rc
}
#
#----------------------------------------------------------------------------------------------------------




proc ::logwin::enableCloseButton {w} {

#----------------------------------------------------------------------------------------------------------
# Desc: Put the close button which is diabled by default into an enabled state
# in:     w: Valid widget-name determined by caller to identify the window of the desired close-button.
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	wakeUpWindow $w
	$w.close configure -state normal
}
#
#----------------------------------------------------------------------------------------------------------



proc ::logwin::registerScanCmd {w c} {
#----------------------------------------------------------------------------------------------------------
# Desc: Registers a proc, which is called back by ::logwin::runCmd for each line of stdout of the cmd 
#       executed by ::logwin::runCmd. The call back will be appendend by widged-path of the log-window and
#       the line delivered by stdout
# in:     w: Valid widget-name determined by caller 
#         c: Command: Name of the callback function
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	set ::logwin::scanCmd(w$w) "$c"
}
#
#----------------------------------------------------------------------------------------------------------



proc ::logwin::openLogfile { w logFilePath} {

#----------------------------------------------------------------------------------------------------------
# Desc: The window $w will get a logfile assigned, where output is logged to.
# Intention: External use
# in:     w: Valid widget-name determined by caller
#     logFilePath: Path to the logfile
# out:    -
# return: fileHandle 
#----------------------------------------------------------------------------------------------------------
#
	if { [ catch { open "$logFilePath" w } ::logwin::logFileHandle(w$w) ] } { 
	} else { 
		return ::logwin::logFileHandle(w$w)
	}
}
#
#----------------------------------------------------------------------------------------------------------



proc ::logwin::wakeUpWindow { w } {

#----------------------------------------------------------------------------------------------------------
# Desc: The window named $w will be raised on top or created if not exists
# Intention: Designed for package-internal use - called by alle write*-procs of this package 
#            - calling from outside does not harm
# in:     w: Valid widget-name determined by caller
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	if { [ winfo exists $w ] } { 
		raise $w
	} else {
		toplevel $w
		wm title $w "Command Log"
		text $w.log -width 132 -height 30 -bd 2 -relief raised   -font "courier 8"  -yscrollcommand "$w.vsb set"
		ttk::scrollbar $w.vsb -orient vertical -command "$w.log yview"
		$w.log tag configure commanderr  -foreground red  -font "courier 8 bold"
		$w.log tag configure commandwarn  -foreground orange  -font "courier 8 bold"
		$w.log tag configure commandok   -foreground SeaGreen  -font "courier 8 bold"
		$w.log tag configure cmdechostyle -font "courier 8 bold"
		button $w.close -text Close -state disabled -command [list ::logwin::closeLog $w]
		grid $w.log -column 0 -row 0 -sticky nswe
		grid $w.close -column 0 -row 1
		grid $w.vsb -column 1 -row 0 -sticky nsw
		grid columnconfigure $w 0 -weight 1; 
		grid rowconfigure $w 0 -weight 1

	}
}
#
#----------------------------------------------------------------------------------------------------------







proc ::logwin::writeInStyle {w t style} {

#----------------------------------------------------------------------------------------------------------
# Desc: Writes a line in style (one of defined above) to log window
# Intention: Designed for package-internal use - calling from outside is not advised because predefined
#            styles are not known there.
# in:     w: Valid widget-name determined by caller. Into this window the message will be appended.
#         t: text to write to window.
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	if { [ info exists ::logwin::logFileHandle(w$w) ] } { puts $::logwin::logFileHandle(w$w) "$t\n" }
	wakeUpWindow $w
	if { "" == $style } {
		$w.log insert end "$t\n"
	} else {
		$w.log insert end "$t\n" "$style"
	}
	$w.log see end
	update
}
#
#----------------------------------------------------------------------------------------------------------




proc ::logwin::closeLogfile {w} {

#----------------------------------------------------------------------------------------------------------
# Desc: Destroys the logwindow identifed by widget-path w
# in:     w: Valid widget-name determined by caller
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	if { [ info exists ::logwin::logFileHandle(w$w) ] } { 
		close $::logwin::logFileHandle(w$w)
		unset  ::logwin::logFileHandle(w$w)
	}

}
#
#----------------------------------------------------------------------------------------------------------





proc ::logwin::closeLog {w} {

#----------------------------------------------------------------------------------------------------------
# Desc: Destroys the logwindow identifed by widget-path w
# in:     w: Valid widget-name determined by caller
# out:    -
# return: -
#----------------------------------------------------------------------------------------------------------
#
	if { [ winfo exists $w ] } {
		::logwin::closeLogfile $w
		if [ info exists ::logwin::errorCount(w$w) ] {unset ::logwin::errorCount(w$w)}
		destroy $w
	}	
}
#
#----------------------------------------------------------------------------------------------------------

proc ::logwin::getErrorCount {w} {

#----------------------------------------------------------------------------------------------------------
# Desc:   Returns the value
# in:     w: Valid widget-name determined by caller
# out:    -
# return: number of ::logwin::writeErr-calls in Widget w
#----------------------------------------------------------------------------------------------------------
#
	if {[ info exists ::logwin::errorCount(w$w) ]} {
		set rc $::logwin::errorCount(w$w)
	} else { 
		set rc 0
	}
	return $rc
}
#
#----------------------------------------------------------------------------------------------------------

proc ::logwin::setErrorCount {w e} {

#----------------------------------------------------------------------------------------------------------
# Desc:   Returns the value
# in:     w: Valid widget-name determined by caller
# in:     e: Value to which the error count will be set
# out:    -
# return: number of ::logwin::writeErr-calls in Widget w
#----------------------------------------------------------------------------------------------------------
#
	if {[ info exists ::logwin::errorCount(w$w) ]} {
		set ::logwin::errorCount(w$w) $e
		set rc $e
	} else { 
		set rc 0
	}
	return $rc
}
#
#----------------------------------------------------------------------------------------------------------


#----------------------------------------------------------------------------------------------------------
# Desc: These procs are for calling from outside this package
#
proc ::logwin::writeLine {w t} { writeInStyle $w $t "" }
proc ::logwin::writeCmd  {w t} { writeInStyle $w $t cmdechostyle }

proc ::logwin::writeOk   {w t} { writeInStyle $w $t commandok }
proc ::logwin::writeWarn {w t} { writeInStyle $w $t commandwarn }
proc ::logwin::writeErr  {w t} { 
	if { [ info exists ::logwin::errorCount(w$w) ] } {
		incr ::logwin::errorCount(w$w)
	} else { 
		set ::logwin::errorCount(w$w) 1
	}
	writeInStyle $w $t commanderr 
}
#
#----------------------------------------------------------------------------------------------------------


}

