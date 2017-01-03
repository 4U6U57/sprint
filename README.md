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
following format

```sh
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
Good work
```

It also has the capability of emailing out reports (the contents of that
file) to each user in bulk.
