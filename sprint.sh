#!/bin/bash
# sprint - Grading utility, faster than running

GRADEFILE="grade.txt"
PWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLASSDIR="$(echo $PWD | cut -d '/' -f 1-5)"
CLASS="$(basename $CLASSDIR)"
ASG="$(basename $PWD)"
ASGBIN="$CLASSDIR/bin/$ASG"
ASGDIR="$CLASSDIR/$ASG"
SEPARATE="=================================================="
PROG="$(basename $0)"

# Standard library
String_AllCaps() {
  echo $@ | tr [a-z] [A-Z]
}
Echo_Warning() {
  echo "WARNING: $@"
}
ForAll() {
  CLASSNUM=$(echo $CLASS | cut -d '0' -f 2 | cut -d '-' -f 1)
  cd $ASGDIR
  for STUDENT in $(ls -d */); do
    STUDENTDIR=$ASGDIR/$STUDENT
    STUDENT=$(basename $STUDENT /)
    cd $STUDENTDIR
    #echo "$SEPARATE"
    #pwd
    $@
  done
}
score() {
  SCOREFILE=".score.f"
  case "$@" in
    (init)
      echo "0" > $SCOREFILE
      ;;
    (get)
      cat $SCOREFILE
      ;;
    ([0-9]*)
      echo $(($(score get) + ($@))) > $SCOREFILE
      ;;
    (*)
      EchoWarning "score: Invalid score $@ written for $STUDENT"
      ;;
  esac
}


# Read arguments
FUNC=""
FUNCDEFAULT="deduct compile export"
FUNCALL="$FUNCDEFAULT mail clean help"
if [[ $@ == "" ]]; then
  FUNC="$FUNCDEFAULT"
else
  for ARG in $@; do
    if echo "$FUNCALL" | grep -Pq "$ARG"; then
      FUNC+=$ARG
      FUNC+=" "
    else
      EchoWarning "$ARG is not a valid $PROG argument"
    fi
  done
fi

# Print welcome message

welcome() {
  echo; echo; echo; echo; echo
  echo $SEPARATE
  echo "$(String_AllCaps $PROG) - faster than running"
  echo "CLASS  = $CLASS"
  echo "ASG    = $ASG"
  echo "MODE   = $FUNC"
  echo $SEPARATE
}
welcome $1

# Declare all functions

deduct() {
  ForAll rm -f $GRADEFILE
  DSHBLANK="dsh.blank.sh"
  cd $ASGBIN
  echo "#!/bin/bash" > $DSHBLANK
  echo "# CLASS = none" >> $DSHBLANK
  chmod +x $DSHBLANK
  for DSH in dsh.*.sh; do
    cd $ASGBIN
    if ! grep -P 'CLASS' $DSH | grep -Pq "$CLASS"; then
      echo "DEDUCTSHELL $DSH ignored: $(grep -P 'CLASS' $DSH)"
    elif ! grep -P "ASG" $DSH | grep -Pq "$ASG"; then
      echo "DEDUCTSHELL $DSH ingored: $(grep -P 'ASG' $DSH)"
    elif grep -P 'USER' $DSH | grep -Pq "\*"; then
      echo "DEDUCTSHELL $DSH executed: set for all USERs"
      ForAll $ASGBIN/$DSH
    elif grep -P 'USER' $DSH | grep -Pq "$USER"; then
      echo "DEDUCTSHELL $DSH executed: recognized USER $USER"
      ForAll $ASGBIN/$DSH
    else
      echo "DEDUCTSHELL $DSH ignored: $(grep -P 'USER' $DSH)"
    fi
  done
  cd $ASGBIN
  rm -f $DSHBLANK
}

compile() {
  DFILEPAT=".d.*.f"
  DFILEBLANK=".d.blank.f"
  INFOFILE="$ASGBIN/info.f"
  NOTESFILE=".notes.f"
  ASGSCORE=20
  ForAll touch $DFILEBLANK
  scoregen() {
    score init
    for DFILE in $DFILEPAT; do
      while read LINE; do
        score $(echo $LINE | cut -d "/" -f 1)
      done <$DFILE
    done
  }
  ForAll scoregen
  scorecap() {
    if [[ $(score get) -gt $ASGSCORE ]]; then
      SCORECAP=$(($ASGSCORE - $(score get)))
      score $SCORECAP
      echo "$SCORECAP / X | OVERRIDE: Score over defined maximum $ASGSCORE" > $DFILEBLANK
    elif [[ $(score get) -lt 0 ]]; then
      SCORECAP=$((-1 * $(score get)))
      score $SCORECAP
      echo "$SCORECAP / X | OVERRIDE: Score less than 0" > $DFILEBLANK
    fi
  }
  ForAll scorecap
  CLASSCOUNT=0
  SCORETOTAL=0
  makeavg(){
    CLASSCOUNT=$(($CLASSCOUNT + 1))
    SCORETOTAL=$(($SCORETOTAL + $(score get)))
  }
  ForAll makeavg
  CLASSAVG=$(($SCORETOTAL / $CLASSCOUNT))
  makegraders() {
    GRADERFILE="$ASGBIN/graders.txt"
    GRADERSPACE=""
    while read GRADER; do
      echo "$GRADERSPACE $(getent passwd $GRADER | cut -d ":" -f 5) <$GRADER>"
      GRADERSPACE="         "
    done <$GRADERFILE
  }
  makepercent() {
    echo $(($1 * 100 / $2))%
  }
  makeintro() {
    rm -f $GRADEFILE
    STUDENTLS=$(ls -m)
    echo "CLASS:    $CLASS" >> $GRADEFILE
    echo "ASG:      $ASG" >> $GRADEFILE
    echo -n "GRADERS:  " >> $GRADEFILE
    makegraders >> $GRADEFILE
    echo "STUDENT:  $(getent passwd $STUDENT | cut -d ":" -f 5) <$STUDENT>" >> $GRADEFILE
    echo "FILES:    $STUDENTLS" >> $GRADEFILE
    echo "SCORE:    $(score get) / $ASGSCORE ($(makepercent $(score get) $ASGSCORE)" >> $GRADEFILE
    echo "AVERAGE:  $CLASSAVG / $ASGSCORE ($(makepercent $CLASSAVG $ASGSCORE)" >> $GRADEFILE
  }
  ForAll makeintro
  makebreakdown() {
    echo >> $GRADEFILE
    echo "GRADE BREAKDOWN:" >> $GRADEFILE
    for DFILE in $DFILEPAT; do
      cat $DFILE >> $GRADEFILE
    done
  }
  ForAll makebreakdown
  makenotes() {
    echo >> $GRADEFILE
    echo "NOTES:" >> $GRADEFILE
    if [[ -e $NOTESFILE ]]; then
      cat $NOTESFILE >> $GRADEFILE
    else
      echo "N/A" >> $GRADEFILE
    fi
  }
  ForAll makenotes
  makeinfo() {
    echo >> $GRADEFILE
    echo "INFO:" >> $GRADEFILE
    cat $INFOFILE >> $GRADEFILE
  }
  if [[ -e $INFOFILE ]]; then
    ForAll makeinfo
  fi
  ForAll rm -f $DFILEBLANK
}

export() {
  CSVFILE="$ASGBIN/$CLASS.$ASG.csv"
  ALLFILE="$ASGBIN/$CLASS.$ASG.$GRADEFILE"
  echo "student,$ASG" > $CSVFILE
  echo "$CLASS.$ASG.$GRADEFILE" > $ALLFILE
  makeexport() {
    echo "$STUDENT,$(score get)" >> $CSVFILE
    echo $(pwd) >> $ALLFILE
    cat $GRADEFILE >> $ALLFILE
    echo "$SEPARATE" >> $ALLFILE
  }
  ForAll makeexport
}

mail() {
  MAILFILE=".mail.f"
  MAILDELAY=3
  MAILTIMER=0
  CLASSCOUNT=0
  makemailtime(){
    if [[ -e $MAILFILE ]]; then
      if ! diff -q $MAILFILE $GRADEFILE; then
        rm $MAILFILE
        MAILTIMER=$(($MAILTIMER + $MAILDELAY))
        echo -n $STUDENT " "
      fi
    else
      MAILTIMER=$(($MAILTIMER + $MAILDELAY))
      echo -n $STUDENT " "
    fi
    CLASSCOUNT=$(($CLASSCOUNT + 1))
  }
  ForAll makemailtime
  echo
  makeprinttime() {
    HOURS=0
    MINUTES=0
    SECONDS=$@
    if [[ $SECONDS -ge 60 ]]; then
      MINUTES=$(($SECONDS / 60))
      SECONDS=$(($SECONDS % 60))
    fi
    if [[ $MINUTES -ge 60 ]]; then
      HOURS=$(($MINUTES / 60))
      MINUTES=$(($MINUTES % 60))
    fi
    echo "$HOURS:$MINUTES:$SECONDS"
  }
  makemail() {
    if [[ -e $MAILFILE ]]; then
      echo "$STUDENT skipped, $(makeprinttime $MAILTIMER) remaining"
    else
      cat $GRADEFILE | mailx -s "[$CLASS] $ASG grade for $STUDENT" $STUDENT@ucsc.edu
      cat $GRADEFILE > $MAILFILE
      echo "$STUDENT mailed, $(makeprinttime $MAILTIMER) remaining"
      MAILTIMER=$(($MAILTIMER - $MAILDELAY))
      sleep $MAILDELAY
    fi
  }
  echo "About to mail $(($MAILTIMER / $MAILDELAY)) / $CLASSCOUNT students."
  echo "This will take ~$(makeprinttime $MAILTIMER). You can Ctrl+C at any time."
  echo "Type MAIL in all caps to confirm, or anything else to cancel."
  echo -n "MAIL: "
  read INPUT
  if [[ $INPUT == "MAIL" ]]; then
    echo "Starting mail"
    ForAll makemail
    echo "Ending mail"
  else
    echo "Canceled mail"
  fi
}

clean() {
  echo "Please type the word CLEAN in all caps to confirm that you would like"
  echo "to clean $CLASS.$ASG. Note: This will clear out all .f files, meaning"
  echo "that while grade.txt files will remain, they will not be recompilable."
  echo -n "Sign off CLEAN = "
  read INPUT
  if [[ $INPUT == "CLEAN" ]]; then
    ForAll rm -rf .*.f
  fi
}

help() {
  echo "SPRINT - faster than running"
  echo "USAGE: sprint [commands]"
  echo "Default (no commands): $FUNCDEFAULT"
  echo "All commands: $FUNCALL"
}

for ARG in $FUNC; do
  echo "MODE $ARG"
  $ARG
done
