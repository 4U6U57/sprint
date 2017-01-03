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

## How to Use

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

### Deduction Scripts

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

ASG="lab0"
DFILE=".d.example.f"

...
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
executed by everyone, the line should read `# USER all`.

A deduction file should write it's output to a file `.d.*.f` in the
current directory. Each line of output should be of the form 
`1 / 2 | Description`, exactly as it would appear on the grade file, 
where the first number is the points earned and the second the points
possible for that specific deduction. A single deduction file can write 
multiple lines of output to differentiate different segments of the 
graded work.
