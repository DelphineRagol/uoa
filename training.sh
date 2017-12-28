#/bin/bash


args=$(getopt f:c: $*)
if [ $? -ne 0 ]; then
  exit
fi
set -- $args


for arg; do
  case $arg in
  -f)
    base_macro_file=$2
    ;;

  -c)
    macro_comment=$2
    ;;

  esac

  shift
done


get_base_macro ()
{
  grep ^[0-9] $1 | sed 's/[0-9]*/&:/;s/:.*//'
}


get_macro_steps ()
{
  echo $(( $(get_base_macro $1 | sort -n | uniq | tail -1) + 1))
}


generate_loop_script ()
{
  macro_steps=$(get_macro_steps $1)

  echo 'generate ()'
  echo {

  head -3 $1 | sed 's/^/  echo /'
  echo "  echo MacroName=$macro_comment"
  echo " " for repeat in \$\(seq 0 $(( 200 / $macro_steps - 1 ))\)\; do

  for step in $(seq 0 $(( $macro_steps - 1 )) ); do
    echo "   " seq$step=\$\(\( \$repeat \* $macro_steps + $step \)\)
  done
  grep ^[0-9] $1 | sed 's/^[0-9]*/    echo ${seq&}/'

  echo " " done

  echo }
}



if [ "$(uname)" = Darwin ]; then
  loop_script=$(mktemp)
  generate_loop_script $base_macro_file > $loop_script
  source $loop_script
  rm -f $loop_script
else
  source <(generate_loop_script $base_macro_file)
fi


generate | perl -pe 's/\r//;s/\n/\r\n/' | iconv -f UTF8 -t CP932


exit 0
