#!/bin/bash
# filename='SELECT.txt'
# filelines=`cat $filename`
# for line in $filelines ; do
#     echo $line
#     ##first line shoulkd be ORACLE_SID
#     ## check pmon proces exists
#     #seconde line shoukle be SELECT if not ==> exit
# done
# echo
# echo
## first line
read -r oraclesid <SELECT.txt
(head -1 > /dev/null; cat > f2.txt) < SELECT.txt
echo $oraclesid

while read -rd ';' sql
do
    if [ "${sql#SELECT}" = "$sql" ]
    then
        echo "Not a SELECT!"
    else
        echo "$sql"
    fi
done < f2.txt
exit



old_IFS=$IFS
IFS=$'\n'
selectf=$(pwd)/SELECT.txt
lines=($(head -1 ${selectf})) # array from tekstfile
IFS=$old_IFS

echo first element ${lines[0]}
oracle_sid=${lines[0]}
echo oracle_sid $oracle_sid
## check oracle sid versus pmon...


#echo number lines ${#lines[@]}  #number elements
#echo all lines ${lines[@]}   #print array
pos=${lines[0]:0:${#lines[@]}+1}
#echo $pos
lines=(${lines[@]:0:$pos} ${lines[@]:$(($pos + 1))})
echo ${lines[@]}

## firast line should now be SELECT .... if not exit.

#printf "%s\n" "${lines[*]}" > temp_select.sql
printf "%s\n" "${lines[@]}" > temp_select.sql

# while IFS= read -r line; do
#     if [[ $line =~ debug ]]; then
#         echo "$line" >>debug.txt
#     else
#         echo "$line" >>info.txt
#     fi
# done <log.txt
#


line=$(head -1 file)

## start sqlplus outputting to output_select.txt somehow...
