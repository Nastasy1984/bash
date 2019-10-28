#!/bin/bash

#IMPORTANT to get correct result put this file to the separate directory without any other files

#creating two temporary files with random names
std=$(mktemp)
err=$(mktemp)
#a variable for the load testing
N=1000
#creating new file in the same directory - it will be used in tests
touch task.txt

function Check {
#$? - is the return code of the previous command, it must be equal to the first argument
    if [ "$?" -ne $1 ]; then echo "Fail (return code $?)"; exit 1; fi
	
#getting data from temp files to variables STD and ERR
    STD=`cat $std`
    ERR=`cat $err`
# here $2 and $3 are arguments for expected stdout and stderr
    if [ "$STD" != "$2" ]; then echo "Fail stdout"; echo "$STD"; exit 1; fi
    if [ "$ERR" != "$3" ]; then echo "Fail stderr"; echo "$ERR"; exit 1; fi
    echo "OK";
}

#the same func, but without printing OK each time - for the load testing
function Bench {
    if [ "$?" -ne $1 ]; then echo "Fail (return code $?)"; exit 1; fi

    STD=`cat $std`
    ERR=`cat $err`
    if [ "$STD" != "$2" ]; then echo "Fail stdout"; echo "$STD"; exit 1; fi
    if [ "$ERR" != "$3" ]; then echo "Fail stderr"; echo "$ERR"; exit 1; fi
}

#1 test - echo command
echo -n "1. echo... "
#sending stdout and stderr to the temporary files that I created at the beginning
echo -n "123" 1> "$std" 2> "$err"
#calling func check with argument 0 - for the return code, 123 for stdout and empty string for stderr
Check 0 "123" ""


#1 test -  command - the load testing
#doing the same for N times
for (( c=1; c<=$N; c++ ))
do
    echo -n "123" 1> "$std" 2> "$err"
    Bench 0 "123" ""
done
#if testing was not interrupted because of error
echo "   Load testing echo command ... OK"


#2 test - touch command
echo -n "2. touch... "
#in the tmp directory I create file test-123 and assign it to the variable FILE
FILE=/tmp/test-123.txt
touch $FILE 1> "$std" 2> "$err"
#checking if the variable refers to file
if [ ! -f "$FILE" ]; then echo "2. Fail"; exit 1; fi
Check 0 "" ""


#3 test - sort command
echo -n "3. sort... "
# sending the result of echo command to sort command dividing standard and error outputs
# here -e - \n as a new line symbol
echo -e "1\n3\n2" | sort 1> "$std" 2> "$err"
Check 0 $'1\n2\n3' ""


#3 test - sort command - the load testing
for (( c=1; c<=$N; c++ ))
do
    echo -e "1\n3\n2" | sort 1> "$std" 2> "$err"
    Bench 0 $'1\n2\n3' ""
done
echo "   Load testing sort command... OK"


#4 test - grep command
echo -n "4. grep... "
# using the file from the 2 test
echo -e "1\n3\n3\n2" > $FILE
#getting lines that include 3 - here they are the second and the third ones
grep "3" $FILE 1> "$std" 2> "$err"
Check 0 $'3\n3' ""


#4 test - grep command - the load testing
for (( c=1; c<=$N; c++ ))
do
    grep "3" $FILE 1> "$std" 2> "$err"
    Bench 0 $'3\n3' ""
done
echo "   Load testing grep command... OK"


#5 test - mkdir command
echo -n "5. mkdir... "
mkdir -p /tmp/a/b 1> "$std" 2> "$err"
#checking if there are such directory in the tmp directory
if [ ! -d /tmp/a/b ]; then echo "Fail"; exit 1; fi
Check 0 "" ""


#6 test - mkdir command
echo -n "6. cat... "
# using the same file as in the 2 and 4 tests
echo "42" > $FILE
cat $FILE 1> "$std" 2> "$err"
Check 0 "42" ""


#6 test - mkdir command - the load testing
for (( c=1; c<=$N; c++ ))
do
    cat $FILE 1> "$std" 2> "$err"
    Bench 0 "42" ""
done
echo "   Load testing mkdir command... OK"


#7 test - ls command without parameters
echo -n "7. ls... "
ls 1> "$std" 2> "$err"
#in the beginnig of the script the file task.txt was created and test.sh is this file
Check 0 $'task.txt\ntest.sh' ""

#7 test - ls command - the load testing
for (( c=1; c<=$N; c++ ))
do
    ls 1> "$std" 2> "$err"
    Bench 0 $'task.txt\ntest.sh' ""
done
echo "   Load testing ls command... OK"


# 8 test - which command 
echo -n "8. which... "
# wich will return the location of the binary (the command itself)
# bin with ls command is in the bin directory
which ls 1> "$std" 2> "$err"
Check 0 "/bin/ls" ""


# 9 test - basename command
# getting the name of my previously created temporary file without extension
echo -n "9. basename... "
basename $FILE 1> "$std" 2> "$err"
Check 0 "test-123.txt" ""


# 10 test - wc command with -l parameter - counting lines
echo -n "10. wc -l (count lines)... "
# sending 4 lines to the temporary file
echo -e "1\n2\n3\n444" > $FILE
wc -l $FILE 1> "$std" 2> "$err"
Check 0 "4 $FILE" ""


# 11 test - find command
echo -n "11. find... "
# looking for the file with name starting from task - the task.txt created in the beginning
find . -name "task*" 1> "$std" 2> "$err"
Check 0 "./task.txt" ""


# 12 test - head command
echo -n "12. head... "
#the first line in this file
head -n 1 test.sh 1> "$std" 2> "$err"
Check 0 "#!/bin/bash" ""


# 13 test - cat command with missing file - awaiting for error
echo -n "13. cat (missing file)... "
cat test2.sh 1> "$std" 2> "$err"
Check 1 "" "cat: test2.sh: No such file or directory"


# 14 test - tail command 
echo -n "14. tail... "
#the last line in this file
tail -n 1 test.sh 1> "$std" 2> "$err"
Check 0 "rm \$FILE" ""


#15 test - ls command with -a parameter 
# showing all files and directories including hiddan
echo -n "15. ls -a... "
ls -a 1> "$std" 2> "$err"
Check 0 $'.\n..\ntask.txt\ntest.sh' ""


#16 test - uname command 
echo -n "16. uname... "
# showing the kernel's name
uname -s 1> "$std" 2> "$err"
Check 0 "Linux" ""


#17 test - whoami command 
echo -n "17. whoami... "
#showing user's name
whoami 1> "$std" 2> "$err"
Check 0 "$USER" ""


#18 test - date command 
echo -n "18. date... "
# getting only the year
date +%Y 1> "$std" 2> "$err"
Check 0 "2019" ""

# 19 test - rm command 
echo -n "20. rm... "
# creating new temporary file
tmp=$(mktemp)
# deleting this file
rm $tmp 1> "$std" 2> "$err"
Check 0 "" ""


#20 test - date command with incorrect format
echo -n "19. date (incorrect format)... "
date YY 1> "$std" 2> "$err"
Check 1 "" "date: invalid date 'YY'"


echo "ALL TESTS PASSED"


# Cleanup
rm task.txt
rm $std
rm $err
rm $FILE