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

set w $p.pdfUrlLBL
label					$w -text Url
grid					$w -column 1 -row 1 -padx 2 -pady 2 -sticky nsew

set kw 17
set pdfName             Darmstadt_Speiseplan_KW_${kw}.pdf
set pdfUrl       https://www.commundo-tagungshotels.de/media/Default/user_upload/Speisenpl%C3%A4ne/Darmstadt/$pdfName

set w $p.pdfUrlENT
entry					$w -textvariable pdfUrl -width 80 -justify right
grid					$w -column 2 -row 1 -padx 2 -pady 2 -sticky nsew
$w						xview moveto 1.0

set w $p.pdfDownloadBTN
button					$w -text Download -command downloadPdf
grid					$w -column 3 -row 1 -padx 2 -pady 2 -sticky nsew
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
	set weekDayShort [ clock format $dateseconds -format %a ]
    set formel "($numberOfDayInYear + $::correctionDays($weekDay1Jan)) / 7"
    puts "$weekDay1Jan $formel"
    set calendarWeek [ expr $formel ]
    puts $calendarWeek
    if { ! $calendarWeek } {
		set calendarWeek [ calendarWeekOf 31.12.[expr $year - 1] ]
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
#==========================================================================================================


vwait forever


#==========================================================================================================
# Funktionen für den .i-Teil des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
proc lineInDeplTableSelected { } {
	# ja, nix erstmal
}
#
# ---------------------------------------------------------------------------------------------------------
#



if [ string is integer $updateCycleMinutes ] {
	if { $updateCycleMinutes < 1 } {
		set secondsBetweenUpdate 60
	} else {
		set secondsBetweenUpdate [ expr { $updateCycleMinutes * 60 } ]
	}
} else {
	set secondsBetweenUpdate $updateCycleMinutesDefault
}

set stepsOfProgressBar 20
set sleepSeconds [ expr { $secondsBetweenUpdate / $stepsOfProgressBar } ]
set odoMeter 0

proc keepTableUpToDate {} {
	while 1 {
		incr ::odoMeter
		set ::remainingSteps $::stepsOfProgressBar
		.f.barON configure -height $::remainingSteps  -bg orange
		.f.upd configure -state disabled
		update
		updateTable
		if  { ! ( $::odoMeter % 9 ) } { grid $::dStripLBL -column 1 -row 2; if [ catch dStrip ] { $::dStripLBL configure -text {:(} } }
		.f.barON configure -bg seagreen 
		while { $::remainingSteps > 0 } {
			.f.barON configure -height $::remainingSteps
			after [ expr { 1000 * $::sleepSeconds } ] { incr ::remainingSteps -1 }
			.f.upd configure -state normal
			tkwait variable ::remainingSteps
		}
		
	}
}
#
# ---------------------------------------------------------------------------------------------------------
#
proc updateTable {} {
	set isTagVersionRE {(\d+)-([[:upper:]]+_\d+\.\d+\.\d+\.\d+_[[:upper:]])_(\d+\.\d+)-(\w+)}
	set isBranchVersionRE {(\d+)-([[:upper:]]+_\d+\.\d+\.\d+\.\d+_[[:upper:]])_branch-(\w+)}
	
	set dTblBG [ $::dTBL cget -bg ]
	$::dTBL configure -bg orange
	
	set previousSortcolumn	[ $::dTBL sortcolumn ]
	set previousSortorder	[ $::dTBL sortorderlist ]
	$::dTBL delete 0 end
	
	set exList $::excludeEnvironmentsList
	foreach e $::allEnvs {
		if { "-1" == [ lsearch $exList $e ] } {
			set lsDoc [ dom parse [ exec $::svn ls --xml $::environmentURL/$e/trunk/deploying ] ]
			foreach entry [ $lsDoc selectNodes /lists/list/entry ] {
				set node		[ $entry selectNodes name ]
				set name		[ $node text ]		
				set node		[ $entry selectNodes commit/date ]
				set dateTimeZ	[ $node text ]
				set timeStamp 	[ clock scan [ string range $dateTimeZ 0 18 ]  -format "%Y-%m-%dT%H:%M:%S" -gmt 1  ]
				set dateTime	[ clock format $timeStamp -format "%Y-%m-%d %H:%M" ]
				set node		[ $entry selectNodes commit/author ]
				set author		[ $node text ]
				set isTagVersion	[ regexp $isTagVersionRE $name -> rev branchname tagVersion modDir ]
				set isBranchVersion	[ regexp $isBranchVersionRE $name -> rev branchname modDir ]
				if $isTagVersion {
					scan $tagVersion {%d.%d} majVer minVer
					set ver $majVer.$minVer
				} elseif $isBranchVersion {
					set ver branch
				} else { 
					error "In $envURL liegt Dreck rum ($name)!"
					exit 1
				}
				set relname [ ::mrutil::getReleasenameFromBranch $branchname ]
				$::dTBL insert end [ list $e $author $dateTime $relname $ver $modDir ]
				if { -1 != $previousSortcolumn } {
					$::dTBL sortbycolumn $previousSortcolumn -$previousSortorder
				}
			}
		}
	} 
	set ::updateTimestamp [ clock format [ clock seconds ] -format {%Y-%m-%d %H:%M} ]
	$::dTBL configure -bg $dTblBG
}
#
#==========================================================================================================





#==========================================================================================================
# Elemente im .f-Teil (Footer) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
#grid [ttk::button	.f.fbBTN -text "Feedback"		-command "browseURL $feedbackURL"		]	-row 1 -column 1 -padx 2 -pady 2 -sticky w
#grid [ttk::label	.f.fbLBL -text "Wer nicht sagt, was er will, braucht sich nicht wundern, was er kriegt!" ]	-row 1 -column 2 -padx 2 -pady 2 -sticky w
grid [frame	.f.barBG  -height 22 -width 5 -relief groove -bg ivory -bd 1 ]	-row 1 -column 4 -padx 2 -pady 3 -sticky se
grid [frame	.f.barON  -height 0 -width 3 -relief flat -bd 0 -bg gray ]	-row 1 -column 4 -padx 3 -pady 4 -sticky se
set updateTimestamp ""
grid [ttk::label	.f.updLBL -text Stand ]	-row 1 -column 1 -padx 2 -pady 2 -sticky w
grid [ttk::entry	.f.updENT -textvariable updateTimestamp -width 15 -state readonly ]	-row 1 -column 2 -padx 2 -pady 2 -sticky w
if { "1" == $updateCycleMinutes } {
	set cycleText "wird jede Minute aktualisiert."
} else {
	set cycleText "wird alle $updateCycleMinutes Minuten aktualisiert."
}
grid [ttk::label	.f.cycLBL -text $cycleText ]	-row 1 -column 3 -padx 2 -pady 2 -sticky w
grid [ttk::button	.f.upd  -text Aktualisieren	-command { set 	remainingSteps 0} -state disabled ]	-row 1 -column 5 -padx 2 -pady 2 -sticky e
grid [ttk::button	.f.canc -text Schließen		-command "pressedClose"	]			-row 1 -column 6 -padx 2 -pady 2 -sticky e
grid [ttk::button	.f.help -text Hilfe			-command "browseURL $helpURL"		]	-row 1 -column 7 -padx 2 -pady 2 -sticky e
grid columnconfigure .f 3 -weight 1
#
#==========================================================================================================





#==========================================================================================================
# Procs für den .f-Teil (Footer) des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
proc pressedClose 	{ } { eval after cancel [ after info ] ; exit }
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



#==========================================================================================================
# Strip-Display
# ---------------------------------------------------------------------------------------------------------
#
proc dStrip {} {
	http::config -proxyhost 192.168.1.112 -proxyport 3128
	set du [base64::decode aHR0cDovL2RpbGJlcnQuY29tLw==]
	set um [http::geturl $du]
	regexp -nocase {class="comic-item".*?data-image="([^"]+)"} [http::data $um] to picurl
	http::cleanup $um
	set um [http::geturl $picurl]
	set pic [http::data $um]
	http::cleanup $um
	image create photo dbt -data $pic
	$::dStripLBL configure -image dbt
}
#
#==========================================================================================================



#==========================================================================================================
# Start nach Aufbau des Hauptfensters
# ---------------------------------------------------------------------------------------------------------
#
keepTableUpToDate
#
#==========================================================================================================
