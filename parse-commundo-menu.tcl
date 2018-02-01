#!/usr/bin/env wish
#==========================================================================================================
# Name und Version dieses Skripts einstellen
# ---------------------------------------------------------------------------------------------------------
#
set progHomeFolder [ file dirname  $argv0 ]
set progName [ file rootname [ file tail $argv0 ] ]

set progHeadline {
Download der PDF-Datei mit der Speisekarte,
raten wo was steht und Ausgabe der Gerichte
im von der lunchtime-app benötigten Format.
}
set versHist {
0.6.2
	Format updated after feedback
0.6.1
	Format adapted for upload
0.6.0
	Simplifications for one-year-use deleted. Commundo continues operating in 2018.
0.5.4
	If magic word "enthält" contains spaces. Happened more than once.
0.5.3
	React on: Name of pdf was changed on commundo-page
0.5.2
    crop Values of last Week are now in repository
      for better start values in a fresh cloned environment
    commundo changed name of PDF-File in week 25
0.5.1
	React on "Aus dem Wok:" Title should be not the single word "Aus"
0.5.0
	Daily Checkwindow added. JSON-File gets nicer name
0.4.0
    Crop values saved now for better start when trying next week
0.3.1
	Daily opening time to 11:30
0.3.0
    Tabs engaged with clipping coordinates, writing json file
0.2.0
    Tabs for reviewing every day of the week
0.1.0
    Download of pdf-File
}
set progVers [ lindex $versHist 0 ]

wm title . "$progName - $progVers"
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

set folderUrl		https://www.commundo-tagungshotels.de/media/Default/user_upload/Speisenpl%C3%A4ne/Darmstadt

array set cropDefault {
	Montag,x 300
	Montag,y 220
	Montag,W 150
	Montag,H 300

	Dienstag,x 445
	Dienstag,y 220
	Dienstag,W 150
	Dienstag,H 300

    Mittwoch,x 0
    Mittwoch,y 20
    Mittwoch,W 140
    Mittwoch,H 300
    Mittwoch,f 2

    Donnerstag,x 140 
    Donnerstag,y 220
    Donnerstag,W 140
    Donnerstag,H 300
    Donnerstag,f 2

    Freitag,x 260
    Freitag,y 220
    Freitag,W 140
    Freitag,H 300
    Freitag,f 2
}

if [ catch { source cropValues.tcl } ] {
	foreach i [ array names ::cropDefault ] {
		set ::crop($i) $::cropDefault($i)
	}
}

set daySequence [ list Montag Dienstag Mittwoch Donnerstag Freitag ]

array set moncode {
	Januar 0
	Februar 1
	März 2
	April 3
	Mai 4
	Juni 5
	Juli 6
	August 7
	September 8
	Oktober 9
	November 10
	Dezember 11
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

set year void
set w $p.yearENT
entry					$w -textvariable year -width 4 -justify right
grid					$w -column 2 -row $row -padx 2 -pady 2 -sticky nsw
incr row


set w $p.folderUrlLBL
label					$w -text "Folder Url"
grid					$w -column 1 -row $row -padx 2 -pady 2 -sticky nse

set w $p.folderUrlENT
entry					$w -textvariable folderUrl -width 80 -justify right
grid					$w -column 2 -row $row -padx 2 -pady 2 -sticky nsew -columnspan 5
$w						xview moveto 1.0
incr row
set col 1

set w $p.dieseBTN
button					$w -text Diese -command pressedDiese
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nsew
incr col

set w $p.naechsteBTN
button					$w -text Nächste -command pressedNaechste
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nsw
incr col

set w $p.wocheLBL
label					$w -text Woche
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nsw
incr col

set w $p.pdfNameLBL
label					$w -text "PDF-Datei"
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nse
incr col

set w $p.pdfNameENT
entry					$w -textvariable pdfName -width 24
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nswe
incr col

set w $p.pdfStateLBL
set pdfState	""
label					$w -textvariable pdfState
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nse
incr row
set col 1

set w 	$p.n
ttk::notebook 			$w
grid					$w -column $col -row $row -padx 2 -pady 2 -sticky nsew -columnspan 8

set p $w
foreach day $daySequence {
	set w $p.f$day
	ttk::frame $w
	$p add $w -text $day
	set nCol 1
	set nRow 1
	foreach l { x y W H f } {
		set nw $w.e${l}LBL
		label			$nw -text $l:
		grid			$nw -column $nCol -row $nRow -padx 2 -pady 2 -sticky nsew
		incr nCol

		set nw $w.e${l}SBX
		tk::spinbox 	$nw -from 0 -to 999 -width 5 -textvariable crop($day,$l)
		grid			$nw -column $nCol -row $nRow -padx 2 -pady 2 -sticky nsew
		incr nCol
		
	}
	set nCol 1
	incr nRow
	set nw $w.e${l}FME
	frame       	$nw 
	grid			$nw -column $nCol -row $nRow -padx 2 -pady 2 -sticky nsew -columnspan 12
	incr nCol

	set nCol 1
	incr nRow
	set fw $nw.blockTXT
	set sw $nw.blockVSB
	text              $fw -height 24 -width 50 -yscrollcommand "$sw set"
	ttk::scrollbar    $sw -orient vertical -command "$fw yview"
	grid              $fw -row $nRow -column $nCol -sticky nsew
	grid              $sw -row $nRow -column [ expr $nCol + 1 ] -sticky nsew
	set blockTXTw($day) $fw

	incr nCol 3
	set fw $nw.resultTXT
	set sw $nw.resultVSB
	text              $fw -height 24 -width 50 -wrap word -yscrollcommand "$sw set"
	ttk::scrollbar    $sw -orient vertical -command "$fw yview"
	grid              $fw -row $nRow -column $nCol -sticky nsew
	grid              $sw -row $nRow -column [ expr $nCol + 1 ] -sticky nsew
	set resultTXTw($day) $fw
}

#
#==========================================================================================================





#==========================================================================================================
# Procs für den .i-Teil (Header) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
proc saveCropValues fileName {
	set fc [ open $fileName w ]
	puts $fc "array set crop \{"
	foreach i [ array names ::crop ] {
		puts $fc "  $i $::crop($i)"
	}
	puts $fc "\}"
	close $fc
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc assurePDF {} {
	if { ! [ file exists $::pdfName ] } {
		set ::pdfState Downloading...
		update
		downloadPdf
	}
	set ::pdfState [ clock format  [ file mtime $::pdfName ] -format {%Y-%m-%d %H:%M:%S} ]
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc pressedDiese {} {
	set when [ clock seconds ] 
	set ::kw [ clock format $when -format %V ]
    set ::year [ clock format $when -format %Y]

	assurePDF
	pdfToTxt
	parseTxt
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc pressedNaechste {} {
	set when [ expr [ clock seconds ] + 7 * 86400 ] 
	set ::kw [ clock format $when -format %V ]
    set ::year [ clock format $when -format %Y]

	assurePDF
	pdfToTxt
	parseTxt
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc kwChanged args {
	if { "$::year$::kw" > 201733 } {
		set ::pdfName             D_Speiseplan_KW_${::kw}.pdf
	} elseif { "$::year$::kw" > 201724 } {
		set ::pdfName             Speiseplan_KW_${::kw}.pdf
    } else {
		set ::pdfName             Darmstadt_Speiseplan_KW_${::kw}.pdf
    }
	set ::pdfUrl       https://www.commundo-tagungshotels.de/media/Default/user_upload/Speisenpl%C3%A4ne/Darmstadt/$::pdfName
}

trace add variable kw write kwChanged
set kw void


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
	foreach tag $::daySequence {
		
		set pdftotextCMD [ format "pdftotext -layout -x %d -y %d -W %d -H %d" $::crop($tag,x) $::crop($tag,y) $::crop($tag,W) $::crop($tag,H)]
		if $::crop($tag,f) { append pdftotextCMD " -f $::crop($tag,f)" }
		append pdftotextCMD " $::pdfName $tag.txt"
		eval "exec $pdftotextCMD"
		set fp [ open $tag.txt r ]
		set blockText [ read $fp ]
		close $fp
        $::blockTXTw($tag) delete 1.0 end
        $::blockTXTw($tag) insert 1.0 $blockText
	}
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc parseTxt {} {
	set jf [ open Commundo-Speiseplan_${::year}-$::kw.json w ]
	puts $jf "\["
	set firstEntry 1
	foreach tag $::daySequence {
		msg i "Processing day >$tag<"
		set fp [ open $tag.txt r ]
		set allLinesOfCurrentFile [ split [ read $fp ] "\n" ]
		close $fp
		$::resultTXTw($tag) delete 1.0 end
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
					if { $einsamesWort in $::daySequence } {
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
					if [ regexp {n\s?t\s?h\s?\w\s?l\s?t} $l -> ] { # enthält mit Leerzeichen suchen
						if { $menuPrizeCent > 150 } {
							set foundOneMainCourse 1
							set title ""
							set desc ""
							set inTitle 1
							# Kombi- Menü zu Kombi-Menü
							regsub -all {(\w\w\w+\-) (\w+)} [ string trim $text ] {\1\2} text
							# mit dem ersten klein geschriebenen Wort beginnt die Desc, vorher ist es Title - Zuerst aber noch Aus dem Wok: mittels :-Suchen retten.
							if [ regexp -line {^\s*([^:]+)\s*:\s*(.+)$} $text -> title desc ] {
							} else {
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
							puts $jf  [ format {      "price": "%s",} $menuPrizeCent ]
							puts $jf  [ format {      "starts": "%d-%d-%d 11:30:00",} $::year $::moncode($monthname) $date  ]
							puts $jf  [ format {      "ends": "%d-%d-%d 14:00:00"} $::year $::moncode($monthname) $date  ]
							$::resultTXTw($tag) insert end "$menuPrizeCent\n>$title<\n$desc\n====================\n"
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
 \]"
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
proc pressedClose 	{ } { 
	saveCropValues cropValues.tcl
	saveCropValues cropValues_${::year}-$::kw.tcl

	exit
}
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



if [ file exists $::pdfName ] {
	set ::pdfState [ clock format  [ file mtime $::pdfName ] -format {%Y-%m-%d %H:%M:%S} ]
}

$blockTXTw(Montag) insert 1.0 "
Dieser Bereich zeigt, was das Poppler-Tool
\"pdftotext\" mit den oben stehenden Crop-Werten
aus dem PDF für den jeweiligen Wochentag
ausgeschnitten hat.

Ändere ggf. die Crop-Werte, so dass
- der Name des Wochentags zu sehen ist,
- immer \"enthält\" als Gerichtende zu sehen ist,
- die Preise mit \u20ac-Zeichen zu sehen sind,
- alle zu übernehmenden Gerichte vollständig
  zu sehen sind.

Drücke immer wieder \"Nächste\" Woche und
kontrolliere erneut.

Die Crop-Werte werden für den nächsten Aufruf
dieses Skripts in der Datei cropValues.tcl
gepeichert. Lösche die Datei, wenn Du sie nicht
mehr magst!
"

$resultTXTw(Montag) insert 1.0 "
Dieser Review-Bereich zeigt, wie die Gerichte für
den jeweiligen Wochentag übernommen werden.

Was hier zu sehen ist, steht dann bereits auch
schon in der JSON-Datei in diesem Verzeichnis.

Wie Gerichte übernommen werden:

\"enthält\" wird jeweils als Gerichtende gewertet.
Liegt der Preis über 150 Cent wird das Gericht
als Hauptgericht gewertet und übernommen.

Wurde bereits ein Hauptgericht übernommen und
danach folgt ein Gericht billiger als 150,
wird Nachtisch angenommen und die Übernahme
für diesen Tag wird gestoppt.

Mit dem ersten kleingeschriebenen Wort beginnt
\"desc\". Die Wörter davor werden zum \"title\".

Ausnahme: Wird ein \":\" gefunden, trennt dieser
\"title\" und \"desc\".
"




