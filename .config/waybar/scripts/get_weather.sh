text=$(curl -s "https://wttr.in/$1?format=1")
if [[ $? == 0 ]]
then
  text=$(echo "$text" | sed -E "s/\s+/ /g" | sed 's/C$//')
  tooltip=$(curl -s "https://wttr.in/$1?format=4")
  if [[ $? == 0 ]]
  then
    tooltip=$(echo "$tooltip" | sed -E "s/\s+/ /g")
    echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
    exit
  fi
fi
echo "{\"text\":\"Error\", \"tooltip\":\"error\"}"
