#!/usr/bin/bash
# -xv
#  fci -- check if file_case_insensitive exists

function fci() {

declare IFS checkdirs countslashes dirpath dirs dirstmp filepath fulldirpaths i name ndirs result resulttmp

[[ -f "$1" ]] && { return 0; }
[[ "${1:0:1}" != '/' ]] && { echo "No absolute file path given: ${1}" 2>&1; return 1; }
[[ "$1" == '/' ]] && { return 1; }

filepath="$1"
filepath="${filepath%"${filepath##*[!/]}"}"  # remove trailing slashes, if any
dirpath="${filepath%/*}"
name="${filepath##*/}"

IFS='/python/'  ##aanpassen voor de server variant
dirs=( ${dirpath} )

if [[ ${#dirs[@]} -eq 0 ]]; then
   fulldirpaths=( '/' )
   ndirs=1
else
   IFS=""
   dirs=( ${dirs[@]} )
   ndirs=${#dirs[@]}
   for ((i=0; i < ${ndirs}; i++)); do
      if [[ $i -eq 0 ]]; then
         checkdirs=( '/' )
      else
         checkdirs=( "${dirstmp[@]}" )
      fi
      IFS=$'\777'
      dirstmp=( $( find -x -L "${checkdirs[@]}" -mindepth 1 -maxdepth 1 -type d -iname "${dirs[i]}" -print0 2>/dev/null | tr '\0' '\777' ) )
      IFS=""
      fulldirpaths=( ${fulldirpaths[@]} ${dirstmp[@]} )
   done
fi

printf "fulldirpaths: %s\n" "${fulldirpaths[@]}" | nl

for ((i=0; i < ${#fulldirpaths[@]}; i++)); do
   countslashes="${fulldirpaths[i]//[^\/]/}"
   [[ ${#countslashes} -ne ${ndirs} ]] && continue
   IFS=$'\777'
   resulttmp=( $( find -x -L "${fulldirpaths[i]}" -mindepth 1 -maxdepth 1 -type f -iname "${name}" -print0 2>/dev/null | tr '\0' '\777' ) )
   IFS=""
   result=( ${result[@]} ${resulttmp[@]} )
done

IFS=""
result=( ${result[@]} )

printf "result: %s\n" "${result[@]}" | nl

if [[ ${#result[@]} -eq 0 ]]; then
   return 1
else
   return 0
fi
}

#------------------------------------------------------------------
# === Basic functions =============================================
#------------------------------------------------------------------
### setup environment
## oracle version test
oraver ()
{
  oraver=$(cat /etc/oratab | sed -n '/^'"$ORACLE_SID"'.*$/p' | sed -e 's/^'"$ORACLE_SID"'.*\/product\/\([[:digit:]]\{0,2\}\.[[:digit:]]\).*$/\1/')
}

find_sqlplus ()
{
  SQLPLUS=$(which sqlplus 2>/dev/null)
  if [ $? -eq 0 ]
  then
    if [ -x $SQLPLUS ]
    then
      # echo $SQLPLUS
      return 0
    fi
  fi
  grep "^[^+].*:/.*:[YN]" $ORATAB|cut -f 2 -d :|while read OH
  do
    SQLPLUS=$OH/bin/sqlplus
    if [ -x $SQLPLUS ]
    then
      # echo $SQLPLUS
      return 0
    fi
  done
  return 1
}

do_set_env ()
{
export PLATFORM=`uname`
export DATUM=$(date +"%Y""%m""%d_""%H""%M")
export SCRIPT=$(basename $0)
export CURDIR="$( cd "$( dirname "$0" )" && pwd )"
#export ORATAB="/etc/oratab"
export ORATAB=./oratab
export LOGDIR=/python/read_select
export LOGFILE=${CURDIR}/${SCRIPT}_${ORACLE_SID}_${DATUM}.out
export TMPFILE=${LOGDIR}/${SCRIPT}_${ORACLE_SID}_${DATUM}_tmp
export SQLFILE=${CURDIR}/${SCRIPT}_${ORACLE_SID}_${DATUM}.sql
## USAGE="Usage ${SCRIPT} SID"
## test running database pmon proces:
## if [ ps ax | grep  ora_pmon_$ORACLE_SID > /dev/null]; then echo $ORACLE_SID ; else exit; fi
export SQLPLUS=$(find_sqlplus)
#export ORACLE_HOME=$(dirname $(dirname $SQLPLUS))
#cygwin :::
export ORACLE_HOME='C:\oracle\product\dbhome_1\'
export PATH=PATH=/usr/local/bin:/usr/bin:/cygdrive/c/oracle/product/dbhome_1/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows
}

###  do_sql function
do_sql ()
{
# temp=`$SQLPLUS -s system/oracle  >>$LOGFILE <<endl
#   set define off echo off head on feed off newpage none pagesize 1000 linesize 200
#   @f2.sql
#   exit
#endl `
temp=$($SQLPLUS -s system/oracle  >>$LOGFILE <<endl
  set define off echo off head on feed off newpage none pagesize 1000 linesize 200
  @f2.sql
  exit
endl
)


#echo tempvariable $temp
#x=$(echo ${temp} | sed -e 's/^ *//g;s/ *$//g')
#echo tempvariable $temp
#return $x
}

############
## start main
## clean logfile last run
rm *.out

## alle oracle gerelateerde variabelen zijn gezet
do_set_env

# echo platform $PLATFORM
# echo $DATUM
# echo current directory: $CURDIR
# echo $SCRIPT
# echo $ORATAB
# echo $LOGDIR
# echo $LOGFILE
# echo $TMPFILE
# echo sqlplus $SQLPLUS
# echo oracle_home $ORACLE_HOME

find_sqlplus

# echo $SQLPLUS
# echo $ORACLE_HOME
# echo PATH $PATH
# export LD_LIBRARY_PATH=/cygdrive/c/oracle/product/dbhome_1/lib
# echo $LD_LIBRARY_PATH

###################################
## select.txt exists in any case sensitive form
FILE='select.txt'

if fci "${FILE}" ; then
   echo "Select.txt: ${FILE}" >$LOGFILE
else
   echo "Select.txt bestand niet gevonden: ${FILE}"  >$LOGFILE
   ## exit if $FILE not exists
fi

## first line contains orasid
read -r oraclesid <$FILE
## test oraclesid against existing oracle db

echo $ORATAB
#db=`egrep -i ":Y|:N" $ORATAB | cut -d":" -f1 | grep -v "\#" | grep -v "\*"`
db=$(egrep -i ":Y|:N" $ORATAB | cut -d":" -f1 | grep -v "\#" | grep -v "\*")
echo $db

# pslist="`ps -ef | grep pmon`"
# for i in $db ; do
#   echo  "$pslist" | grep  "ora_pmon_$i"  > /dev/null 2>$1
#   if (( $? )); then
#         echo "Oracle Instance - $i:       Down"
#   else
#         echo "Oracle Instance - $i:       Up"
#   fi
# done


## rest file contains sql text
(head -1 > /dev/null; cat > f2.sql) < $FILE

## test constructie select.txt file
## als ongeldig statement >> exit
## create sql file from select.txt
while read -rd ';' sql
do
    if [ "${sql#SELECT}" = "$sql" ]
    then
        echo "Not a SELECT!" >>$LOGFILE
        echo $sql >>$LOGFILE
        exit
    else
        echo "$sql"  >>$LOGFILE
    fi
done < f2.sql

do_sql

#na testwerk:
# rm $FILE
