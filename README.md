# Sprint Grading Script

*Sprint - faster than running*

Sprint is an automated grading script written in *bash* for the 
*unix.ucsc.edu* timeshare. It was originally written for the 
[CMPS 12B Spring 2016]
(https://github.com/legendddhgf/cmps012b-s16-scripts) 
quarter.

Sprint is no longer under development, and to my knowledge, is not being
used by anyone. Feel free to reference it as an interesting piece of
code that I wrote in a hurry.

## Output Format

Sprint creates `grade.txt` files in each student directory with the
following format:

```
CLASS:    cmps012b-pt.s16
ASG:      lab0
GRADERS:  Isaak Joseph Cherdak <icherdak>
          August Salay Valera <avalera>
STUDENT:  John Smith <jsmith>
FILES:    HelloWorld.java README Makefile
SCORE:    19 / 20 (95%)
AVERAGE:  16 / 20 (80%)

GRADE BREAKDOWN:
2 / 2 | Makefile cleans correctly
3 / 4 | Some files named incorrectly (README.txt -> README)
...

NOTES:
Good work John!

INFO:
This assignment was uploaded to eCommons on January 1, 2017.
Please email one of the graders if you have any questions.
```

It also has the capability of emailing out reports (the contents of that
file) to each user in bulk.

## Overview

Sprint is a command line tool which takes as arguments a list of 
subcommands for it to execute. Running `sprint` by itself is equivalent
to running the defaults: `sprint deduct compile export`. 
Running `sprint help` will give a list of available commands, which are
described below:

- `deduct`: Runs user's deduction scripts on all student's directories, 
  generating deduction stubs
- `compile`: Compiles the deduction stubs for reach student into a 
`grade.txt` file
- `export`: Exports all of the student's scores into a CSV file for 
  import into eCommons, UCSC's gradebook host
- `mail`: Emails each student the contents of their compiled grade file 
  if it exists and is different from the last emailed grade file
- `clean`: Cleans all of the sprint generated files in all student 
  directories, with the exception of the compiled grade files
  - **WARNING**: This is destructive, and will destroy any progress made
    on manual deduction scripts
- `help`: Prints a usage message

## Deduction Scripts

The grunt work of grading is performed by deduction scripts written by
the grader. These scripts should be stored in the same directory as the
executable, and have a file name that matches `dsh.*.sh`. By convention,
the string matching the wildcard should be descriptive to what the
script is checking.

Here is the contents of an example script `dsh.example.sh`:

```bash
#!/bin/bash
# CLASS cmps012b-pt.s16
# ASG lab0
# USER avalera

DFILE=".d.example.f"

# YOUR CODE HERE
```

The first three lines after the `#!` should be exactly of the format 
described above, and are verified by sprint before execution. The first
two, `CLASS` and `ASG` are self explanatory and must match the current 
assignment being graded. This allows users to copy deduction files from
other assignments into the directory for reference, without worrying 
that they will be executed. The `USER` tag specifies (by username) which
users will execute the script. This may be useful if specific segments
of grading are assigned to specific users, or if the scripts contain 
dependencies that not all users have access to. If a script should be 
executed by everyone, the line should read `# USER *`.

A deduction script should write it's output to a file `.d.*.f` in the
current directory. (The filename for this file is canonically stored in
the shell variable `$DFILE` at the beginning of the script, as shown 
above.) Each line of output should be of the form:

`1 / 2 | Description (Output)`

This is exactly as it would appear on the grade file, the first number 
being the points earned and the second the points possible for that 
specific deduction. The description should describe either the reason 
for either the points earned or the deduction, and can include an 
optional command output in parenthesis to highlight this (such as the 
output of a diff of incorrectness, or an incorrectly named filename 
compared to the expected value). Command output is generally used for 
automatic deduction scripts, which will be discussed in more detail 
below. Multiple output lines in a deduction file are used to separate 
points to make it easier for the student to understand.

A deduction file also has access to write to the notes file `.notes.f`,
which is an optional list of notes specific to the user, and will appear
below the grade breakdown as shown in the grade file example in the 
previous section. Notes are generally used as a substitution for
optional command outputs for manual deduction scripts.

### Manual vs. Automatic Deduction Scripts

Aside from the format described above, the contents of the deduction
script is mainly up to the developer to implement. For reference, there
are two general classes of deduction scripts, those that are meant to be
ran automatically and those that are manual and require user 
interaction. These two classes have different purposes, and a good 
grading rubric should include both of these types of scripts.

Automatic scripts are easier to program and run, but only handle basic 
operations such as diff testing, grepping for specific phrases, and
checking basic properties of the submission. Automatic scripts should be
designed to be idempotent, meaning they can be ran over and over again
with no change to the results. Thus, an automatic script will usually
begin by deleting it's deduction file to generate a new one from
scratch. Automatic scripts are meant to be changed often, tweaking the
commands as new errors are discovered.

Example of code for an Automatic Deduction Script
```bash
DFILE=".d.automatic.f"
STUDENT=$(basename $(pwd))

rm -f $DFILE
for FILE in README Makefile HelloWorld.java; do
  if head -n 10 $FILE | grep -pQ $STUDENT; then
    echo "1 / 1 | File $FILE contains student identifier" » $DFILE
  else
    echo "0 / 1 | File $FILE missing student identifier" » $DFILE
  fi
done
```

Contrary to that, manual scripts are meant to be interactive, and the 
bulk of the grading should be done by the user, with the script simply
making the submission easier to grade by automating frequently used 
commands. Once a manual script has finished with a student's submission,
the grade is considered finalized. This is why a manual script should
only be run if a deduction file does not exist for it yet (and regrading
a submission is done by manually deleting the deduction file). 
The structure of the script should generally be several iterations of 
running a command to produce output, then prompting the user for input
to respond to that output, optionally allowing the user to select from 
several options to streamline grading and maintain consistency. In
general, manual scripts should not be modified except in ways that will
not make the already graded work obsolete.

Example of code for a Manual Deduction Script
```bash
DFILE=".d.manual.f"
STUDENT=$(basename $(pwd))

if [[ -e $DFILE ]]; then
  echo "Already graded student $STUDENT"
  cat $DFILE
else
  cat Makefile
  echo -n "How many points is this this worth? "
  PTS=""
  read $PTS
  if [[ $PTS -ge 5 ]]; then
    echo "5 / 5 | Full points on Makefile" » $DFILE
  else
    echo -n "What is the description? "
    read $DESC
    echo "$PTS / 5 | $DESC" » $DFILE
  fi
fi
```
