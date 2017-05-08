#!/usr/bin/env wish
#==========================================================================================================
# Name und Version dieses Skripts einstellen
# ---------------------------------------------------------------------------------------------------------
#
set progHomeFolder [ file dirname  $argv0 ]
set progName [ file rootname [ file tail $argv0 ] ]
set progVers 0.1.0

set progHeadline {
Download der PDF-Datei mit der Speisekarte,
raten wo was steht und Ausgabe der Gerichte
im von der lunchtime-app benötigten Format.
}

wm title . "$progName - $progVers"

set versHist {
0.1.0
	Download of pdf-File
}
#
#==========================================================================================================





#==========================================================================================================
# Die Debug-Geschichte: Wenn es die Umgebugsvariable SCRIPT_DEBUG mit einem Wert ungleich 0 gibt,
# machen wir eine Konsole auf.
# ---------------------------------------------------------------------------------------------------------
#
if { [ catch { set script_debug  $env(SCRIPT_DEBUG) } ] } {
	set script_debug 0
} else {
	if { [ string is integer $script_debug ] } {
		console show
	} else { 
		set script_debug 0 ;# Eine Zahl hätte er schon sein sollen!
	}
}
# und dann definieren wir uns neue Komandos d1puts..d9puts mit dem wir die Debugausgabe machen...
for { set i 1 } { $i <= 9 } { incr i } { 
	if { $i <= $script_debug } {
		eval "proc d${i}puts t { puts \$t }"
		eval "proc d${i}errputs t { puts stderr \$t }"
	} else {
		eval "proc d${i}puts t #"
		eval "proc d${i}errputs t #"
	}
}
# nur die, die kleinergleich dem Debug-Level in script_debug sind, machen einen puts. Die andern sind leise.
# ... und noch was Praktisches, damit kann man einfach eine "Name=Value"-Ausgabe erzeugen:
proc show varname {
	upvar 1 $varname value
	if [ catch { dict get [ info frame -1 ] proc } callProc ] { set callProc ? }
	puts "$callProc $varname=$value"
}
#
#==========================================================================================================





#==========================================================================================================
# Pakete, die wir benötigen
# ---------------------------------------------------------------------------------------------------------
#
set     ourLibs [ file join $progHomeFolder lib ]
lappend auto_path "$ourLibs"

package require logwin

package require http
package require tls
#
#==========================================================================================================


tls::init -tls1 true -ssl2 false -ssl3 false
http::register https 443 tls::socket


#==========================================================================================================
# Allgemeine Definitionen/Initialisierungen (Konstanten)
# ---------------------------------------------------------------------------------------------------------
#
set helpURL 		https://topedia.telekom.de/display/ITPTDP/$::progName
set helpURL 		https://topedia.telekom.de/x/A6GSAw
set helpURL 		https://github.com/spreis/commundo-menu

set cropValues {
	Montag     { -layout -x 300 -y 220 -W 150 -H 300 }
	Dienstag   { -layout -x 445 -y 220 -W 150 -H 300 }
	Mittwoch   { -layout -x  0 -y 220 -W 140 -H 300 -f 2 }
	Donnerstag { -layout -x 140 -y 220 -W 140 -H 300 -f 2 }
	Freitag    { -layout -x 260 -y 220 -W 140 -H 300 -f 2 }
}

array set mon3 {
	Januar Jan
	Februar Feb
	März Mar
	April Apr
	Mai May
	Juni Jun
	Juli Jul
	August Aug
	September Sep
	Oktober Oct
	November Nov
	Dezember Dec
}
#
#==========================================================================================================





#==========================================================================================================
# Log-Messages
# ---------------------------------------------------------------------------------------------------------
# 
#
set msg_w .logwindow
proc msg { severity text } {
	set sev [ string toupper [ string range $severity 0 0 ] ]
	set msgtxt "${::progName}_$sev $text"
	switch $sev {
		I { ::logwin::writeLine $::msg_w $msgtxt }
		W { ::logwin::writeWarn $::msg_w $msgtxt }
		E { ::logwin::writeErr  $::msg_w $msgtxt }
	}
}
#
#==========================================================================================================





#==========================================================================================================
# Kommandozeilenparser
# ---------------------------------------------------------------------------------------------------------
# http://wiki.tcl.tk/17342
#
 proc getopt {_argv name {_var ""} {default ""}} {
     upvar 1 $_argv argv $_var var
     set pos [lsearch -regexp $argv ^$name]
     if {$pos>=0} {
         set to $pos
         if {$_var ne ""} {
             set var [lindex $argv [incr to]]
         }
         set argv [lreplace $argv $pos $to]
         return 1
     } else {
         if {[llength [info level 0]] == 5} {set var $default}
         return 0
     }
 }

set noAutostartDefault 0
getopt argv -noAutostart noAutostart $noAutostartDefault
#
#==========================================================================================================





#==========================================================================================================
# Allgemeine Initialisierung mit Progressbar - so etwas haben wir hier nicht.
# Das Template darf noch eine Weile hier stehen bleiben.
# ---------------------------------------------------------------------------------------------------------
#
set cmdList \
{
{Collecting Environmentnames from Repository}
	{
		set environmentURL $repoURL/Cordoba/Environment
		# Bereit zum Test im Testbereich des Repositories
		set environmentURL $repoURL/Probebetrieb/develop/TASK-2236/Environment
		set allEnvs [ string map { / "" }  [ lsearch -all -inline [ exec $svn ls $environmentURL ] */ ] ]
	}
}
#
# ---------------------------------------------------------------------------------------------------------
#
set cmdList ""
#
# ---------------------------------------------------------------------------------------------------------
#
if [ llength $cmdList ] {
	set Progress 0
	set ProgressMax 400

	set nrOfInitSteps [ expr { [ llength $cmdList ] / 2 } ]
	set ProgressInc   [ expr { $ProgressMax / ( $nrOfInitSteps ) } ]

	grid [ttk::frame .p -padding 50  ] -padx 5 -pady 5 -column 0 -row 0 -sticky nwes
	grid [ttk::label .p.barLabel -textvariable WhatsUp] -column 0 -row 0  -sticky w
	grid [ttk::progressbar .p.bar -orient horizontal -length $ProgressMax -maximum $ProgressMax -mode determinate -variable Progress] -column 0 -row 1  -sticky w

	foreach { WhatsUp initCmd } $cmdList {
		incr Progress $ProgressInc ; update
		eval $initCmd
	}

	grid forget .p
}
#
#==========================================================================================================


focus -force .


#==========================================================================================================
# Fenster mit drei Teilen: 
#    .h für den oberen (Header-)Teil
#    .i für den mittleren (Input-)Teil
#    .f für den unteren (Finish-)Teil
#
# ---------------------------------------------------------------------------------------------------------
#
ttk::style configure header.TFrame -background white
grid [ttk::frame .h 	-padding 8  -style header.TFrame  ]	-column 0 -row 1 -sticky nwes
grid [ttk::separator .isep -orient horizontal ]				-column 0 -row 2 -pady "0 5" -sticky nwe
grid [ttk::frame  .i	-padding 2 ]						-column 0 -row 3 -sticky nwes
grid [ttk::separator .fsep -orient horizontal ]				-column 0 -row 4 -pady 5 -sticky nwe
grid [ttk::frame .f 	-padding 2 ] 						-column 0 -row 5 -sticky nsew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 3 -weight 1
#
#==========================================================================================================





#==========================================================================================================
# Elemente im .h-Teil (Header) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
image create photo programIcon -file [ file join $progHomeFolder Dish-Pasta-Spaghetti-icon.png ]
font create headerFont -family Helvetica -size 11 
ttk::style configure header.TLabel -background white -foreground #ac9753 -font headerFont
font create pnameFont -family Helvetica -size 12 -weight bold
ttk::style configure pname.TLabel -background white -foreground #ac9753 -font pnameFont

grid [ttk::label .h.pname -text $progName -style pname.TLabel -padding 4 ] 	 -column 0 -row 2 -sticky nsew
grid [ttk::label .h.header -text [ string trim $progHeadline ] -style header.TLabel -padding 4 ] 	 -column 0 -row 3 -sticky nsew
grid [ttk::label .h.icon -image  programIcon -style header.TLabel  ] 	 -column 1 -row 2 -rowspan 2 -sticky nsew
bind .h.icon <ButtonRelease-1> iconClicked

grid columnconfigure .h 0 -weight 1
#
#==========================================================================================================





#==========================================================================================================
# Procs für den .h-Teil (Header) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
proc iconClicked {} {
	showHistoryInformation
}

proc showHistoryInformation {} {
	set w .histWIN
	if { [ winfo exists $w ] } { 
		wm manage $w
		raise $w
	} else {
		toplevel $w
		wm title $w "$::progName - $::progVers - History-Informationen"
		set p $w
		set w $p.hTXT
		pack [ text $w -font "Courier 8" -width 160 ]
		$w insert end $::versHist
	}
}
#
#==========================================================================================================






#==========================================================================================================
# Elemente im .i-Teil des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
set p .i		;# p wie Parent

set row 1

set w $p.yearLBL
label					$w -text Jahr
grid					$w -column 1 -row $row -padx 2 -pady 2 -sticky nse

set year 2017
set w $p.yearENT
entry					$w -textvariable year -width 4 -justify right
grid					$w -column 2 -row $row -padx 2 -pady 2 -sticky nsw
incr row

set w $p.kwLBL
label					$w -text Kalenderwoche
grid					$w -column 1 -row $row -padx 2 -pady 2 -sticky nse

set w $p.kwSBX
tk::spinbox				$w -from 1 -to 53 -justify right -increment 1 -width 3 -textvariable kw -command kwChanged
grid					$w -column 2 -row $row -padx 2 -pady 2 -sticky nsw
incr row

proc kwChanged {} {
	set ::pdfName             Darmstadt_Speiseplan_KW_${::kw}.pdf
	set ::pdfUrl       https://www.commundo-tagungshotels.de/media/Default/user_upload/Speisenpl%C3%A4ne/Darmstadt/$::pdfName
}
set kw 18
kwChanged

set w $p.pdfUrlLBL
label					$w -text Url
grid					$w -column 1 -row $row -padx 2 -pady 2 -sticky nse


set w $p.pdfUrlENT
entry					$w -textvariable pdfUrl -width 80 -justify right
grid					$w -column 2 -row $row -padx 2 -pady 2 -sticky nsew
$w						xview moveto 1.0

set w $p.pdfDownloadBTN
button					$w -text Download -command downloadPdf
grid					$w -column 3 -row $row -padx 2 -pady 2 -sticky nsew
incr row

set w $p.pdfToTxtBTN
button					$w -text {to Text} -command pdfToTxt
grid					$w -column 3 -row $row -padx 2 -pady 2 -sticky nsew
incr row

set w $p.parseTxtBTN
button					$w -text {Parse Text} -command parseTxt
grid					$w -column 3 -row $row -padx 2 -pady 2 -sticky nsew
incr row
#
#==========================================================================================================





#==========================================================================================================
# Procs für den .i-Teil (Header) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
array set correctionDays { Mon 6 Tue 7 Wed 8 Thu 9 Fri 3 Sat 4 Sun 5 }
proc calendarWeekOf {datestring} {
    set dateseconds [clock scan $datestring -format %d.%m.%Y]
    set numberOfDayInYear [ clock format $dateseconds -format %j ]
    set year [ clock format $dateseconds -format %Y]
    set weekDay1Jan [ clock format [clock scan 01.01.$year -format %d.%m.%Y] -format %a]
    set formel "($numberOfDayInYear + $::correctionDays($weekDay1Jan)) / 7"
    # puts "$weekDay1Jan $formel"
    set calendarWeek [ expr $formel ]
    # puts $calendarWeek
    if { ! $calendarWeek } {
        set calendarWeek [ calendarWeekOf 31.12.[expr $year - 1] ]
    } elseif { $calendarWeek == 53 } {
      if { [ clock format [ clock scan 01.01.[expr $year + 1] -format %d.%m.%Y] -format %a] in "Tue Wed Thu" } {
        set calendarWeek 1
      }
    }
   return $calendarWeek
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc downloadPdf {} {
	set um [http::geturl $::pdfUrl -binary 1]
	set pdfRawData [http::data $um]
	http::cleanup $um
	set fp [ open $::pdfName w ]
    fconfigure $fp -translation binary
    puts -nonewline $fp $pdfRawData
	close $fp
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc pdfToTxt {} {
	foreach tag [ dict keys $::cropValues ] {
		eval "exec [ concat pdftotext [ join [ dict get $::cropValues $tag ] ] $::pdfName $tag.txt ]"
	}
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc parseTxt {} {
	set jf [ open 1.json w ]
	puts $jf "\{
  \"restaurantID\": \"commundo-darmstadt\",
  \"lat\": \"49.863080\",
  \"long\": \"8.626300\",
  \"title\": \"Commundo\",
  \"description\": \"Tagungshotel und Restaurant\",
  \"offers\": \["
	set firstEntry 1
	foreach tag [ dict keys $::cropValues ] {
		msg i "Processing day >$tag<"
		set fp [ open $tag.txt r ]
		set allLinesOfCurrentFile [ split [ read $fp ] "\n" ]
		close $fp
		set linesOfWeekDay_stillTooLong {}
		set euroColumn 0
		set copyTheLine 0
		msg i "allLinesOfCurrentFile >[ join $allLinesOfCurrentFile "<\n>" ]<"
		foreach l $allLinesOfCurrentFile {
			if [ regexp -line {^\s*(\w+)\s*$} $l -> einsamesWort] {
				if [ string equal $einsamesWort $tag ] {
					set copyTheLine 1
					msg i "Expected day of week detected >$tag<"
				} else {
					if { $einsamesWort in [ dict keys $::cropValues ] } {
						msg i "Found >$einsamesWort< as single word on line. Seems to be a week day. Copying stopped."
						set copyTheLine 0
					}
				}
			}
			if $copyTheLine {
				set euroColumnInThisLine [ string first "\u20ac" $l ]
				if { $euroColumn < $euroColumnInThisLine } {
					set euroColumn $euroColumnInThisLine
				}
				lappend linesOfWeekDay_stillTooLong $l
			}
		}
		if { ! $euroColumn } {
			msg i "No Euro sign found during copying $tag. Skipping this day."
			continue
		}
		msg i "linesOfWeekDay_stillTooLong >[ join $linesOfWeekDay_stillTooLong "<\n>" ]<"
		set linesOfWeekDay {}

		foreach l $linesOfWeekDay_stillTooLong {
			lappend linesOfWeekDay [ string range $l 0 $euroColumn ]
		}
		msg i "linesOfWeekDay >[ join $linesOfWeekDay "<\n>" ]<"
		set menuNr 0
		set foundOneMainCourse 0
		set expect weekDay
		foreach l $linesOfWeekDay {
			msg i "Processing line >$l<"
			switch $expect { 
				weekDay { 
					if [ regexp {\w+} $l w ] {
						msg i "Found weekday in PDF: >$w<"
						set expect dateMonth
					}
				}
				dateMonth {
					if [ regexp {(\d+)\.\s*(\w+)} $l -> datestring monthname ] {
						scan $datestring {%d} date
						msg i "Found day in PDF, date: >$date<, monthname: >$monthname<"
						set expect menuLines
					}
					
				}
				menuLines {
					if [ regexp {enth\wlt} $l -> ] {
						if { $menuPrizeCent > 150 } {
							set foundOneMainCourse 1
							set title ""
							set desc ""
							set inTitle 1
							# Kombi- Menü zu Kombi-Menü
							regsub -all {(\w\w\w+\-) (\w+)} [ string trim $text ] {\1\2} text
							# mit dem ersten klein geschriebenen Wort beginnt die Desc, vorher ist es Title
							foreach word $text {
								set firstChar [ string index $word 0 ]
								if [ string is lower $firstChar ] {
									set inTitle 0
								}
								if $inTitle {
									lappend title $word
								} else {
									lappend desc $word
								}
							}
							msg i "Found Enthält line. title >$title<"
							msg i "Found Enthält line. desc >$desc<"
							msg i "Found Enthält line. menuPrizeCent >$menuPrizeCent<"
							if $firstEntry {
								puts $jf "    \{"
								set firstEntry 0
							} else {
								puts $jf "    \},    \{"
							}

							puts $jf  [ format {      "title": "%s",} $title ]
							puts $jf  [ format {      "description": "%s",} $desc ]
							puts $jf  [ format {      "prize": "%s",} $menuPrizeCent ]
							puts $jf  [ format {      "starts": "%s %02d %s 11:34:00 GMT+0100",} $::mon3($monthname) $date $::year  ]
							puts $jf  [ format {      "ends": "%s %02d %s 14:00:00 GMT+0100",} $::mon3($monthname) $date $::year  ]
							puts $jf  {      "category": "Lunch",}
							puts $jf  {      "ingredients": []}
							set text ""
							incr menuNr
						} else {
							msg i "Menu ignored too cheap"
							if $foundOneMainCourse {
								set expect skipTheRest
								msg i "Ignoring the rest of menus for this day."
							}
						}
						set text ""
						set title ""
						set desc ""
						set menuPrizeCent 0
					} elseif [ regexp {(.+)\s+(\d+),(\d+)\s+\u20ac} $l -> linetext euro cent ] {
						set menuPrizeCent [ expr 100 * $euro + $cent ]
						append text " " [string trim $linetext]
						msg i "Prize detected on line with other text, text appended, now: >$text<, menuPrizeCent: >$menuPrizeCent<"
					} elseif [ regexp -line {^(\s*)(\d+),(\d+)\s+\u20ac\s*$} $l -> space euro cent ] {
						set menuPrizeCent [ expr 100 * $euro + $cent ]
						msg i "Prize detected on line, menuPrizeCent: >$menuPrizeCent<"
					} elseif { ! [string is space $l] } {
						append text " " [string trim $l]
						msg i "Text found, appended. Now text: >$text<"
					}
			    }
			    skipTheRest {
					msg i "In skip-mode, line >$l<"
				}
			}
		}
		::logwin::enableCloseButton $::msg_w
	}
	puts $jf "    \}
 \]
\}"
	close $jf
}
#
#==========================================================================================================




#==========================================================================================================
# Elemente im .f-Teil (Footer) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
grid [ttk::button	.f.canc -text Schließen		-command "pressedClose"	]			-row 1 -column 6 -padx 2 -pady 2 -sticky e
grid [ttk::button	.f.help -text Hilfe			-command "browseURL $helpURL"		]	-row 1 -column 7 -padx 2 -pady 2 -sticky e
grid columnconfigure .f 3 -weight 1
#
#==========================================================================================================





#==========================================================================================================
# Procs für den .f-Teil (Footer) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
proc pressedClose 	{ } { exit }
# ---------------------------------------------------------------------------------------------------------
proc browseURL {url}    { 
    exec $::env(ComSpec) /c start $url &
}
#
#==========================================================================================================





#==========================================================================================================
# Wenn das Fenster mit dem kleinen x rechts oben geschlossen wird....
# ---------------------------------------------------------------------------------------------------------
#
wm protocol . WM_DELETE_WINDOW {
    pressedClose
}
#
#==========================================================================================================
