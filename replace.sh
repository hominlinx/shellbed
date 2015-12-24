#!/bin/bash
if [ "$2" = ""  ]
then
 echo "Usage: Fllow the file and Module example :  1.txt Base"
 echo "Module must in Base Map Guide Path Location..."
 exit 10
fi


aItems=("new"
  "malloc"
  "free"
  "std::list"
  "std::vector"
  "std::map"  
  "std::multimap"
  "std::set"
  "std::multiset"
  "__gnu_cxx::hash_map"
  "std::hash_map"
  "std::deque"
  "std::queue"
  "std::stack"
  "std::priority_queue"
"boost::unordered_set"
	"boost::unordered_map"
  )

aNewItems=("new(MEM_"
  "new(MEM_"
  "delete"
  "List"
  "Vector"
  "Map"  
  "MultiMap"
  "Set"
  "MultiSet"
  "HashMap"
  "HashMap"
  "Deque"
  "Queue"
  "Stack"
  "PriorityQueue"
"UnorderedSet"
	"UnorderedMap"
  )

sed -i 's/file://' $1
sed -i 's/line://' $1
filename=(`awk '{print $1}' $1 `)
sub=(`awk '{print $4}' $1 `)
line=(`awk '{ print $2};' $1 `)
echo $line
indx=0
for fn in ${filename[@]}
do
  echo $fn replace in line ${line[indx]}
  linno=${line[indx]}
  ((linno++))
  # find sub in aItems
  itemIdx=0
  for item in ${aItems[@]}
   do
    if [ $item = ${sub[indx]} ]
    then
       echo "found ${sub[indx]} idx:$itemIdx"
       break
    fi
    ((itemIdx++))
  done
   echo replace in $fn , line:${line[indx]}, $linno  ${aItems[itemIdx]} ${aNewItems[itemIdx]}
  if [ $itemIdx -gt 2 ]
  then
     sed -i "s/${aItems[itemIdx]}<\([^>]*\)>::/$2${aNewItems[itemIdx]}<\1>::/" $fn
     sed -i "s/${aItems[itemIdx]}<\([^>]*\)>/$2${aNewItems[itemIdx]}<\1>::type/" $fn
  else    
	echo "sed -i "${line[indx]}, $linno s/${aItems[itemIdx]} /${aNewItems[itemIdx]} /" $fn"
	sed -i "${line[indx]}, $linno s/${aItems[itemIdx]} /${aNewItems[itemIdx]}$2) /" $fn
 fi
  
  ((indx++))
done

echo "array len: ${#filename[@]} "

