#And here's a starting point using Bash:
#  fci -- check if file_case_insensitive exists
# (on a case sensitive file system; complete file paths only!)

function fci() {

declare IFS checkdirs countslashes dirpath dirs dirstmp filepath fulldirpaths i name ndirs result resulttmp

[[ -f "$1" ]] && { return 0; }
[[ "${1:0:1}" != '/' ]] && { echo "No absolute file path given: ${1}" 2>&1; return 1; }
[[ "$1" == '/' ]] && { return 1; }

filepath="$1"
filepath="${filepath%"${filepath##*[!/]}"}"  # remove trailing slashes, if any
dirpath="${filepath%/*}"
name="${filepath##*/}"

IFS='/'
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

###################################
FILE='select.txt'

if fci "${FILE}" ; then
   echo "File (case insensitive) exists: ${FILE}"
else
   echo "File (case insensitive) does NOT exist: ${FILE}"
fi
