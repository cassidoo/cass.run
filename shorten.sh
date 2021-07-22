# Simple script that makes adding a new shortcut trivial from the
# command line. Simply type:
#   shorten.sh foo https://bar.com 
# and a shortcut from https://yourdomain.com/foo to https://bar.com will be added
#
# Note that this also commits and pushes to your personal repo using git.
#
# For added convenience, you can add an alias to this script to your .bash_profile,
# e.g.
#   function short() {
#     ~/code/cass.run/shorten.sh $1 $2
#   }
#
# Then run it from any folder like
#   short goo https://google.com

if [ -z "$1" ]
  then
    echo "You must provide the shortcode as the first argument"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "You must provide the full URL as the second argument"
    exit 1
fi

if ! [[ $2 =~ https?://.* ]]; then
  echo "Invalid URL $2"
  exit 1
fi


lenFunc() {
  echo ${#1}
}

# We need the folder of the script, not the pwd. This lets us
# execute this script using an alias, from any directory.
ScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ArgLen=$(lenFunc $1)

NewLine="/$1"

# 15 is a magic number, the number of spaces that Cassidy chose for her
# _redirects file to keep it neat and tidy.
Count=$((15-$ArgLen))
i=0

# Build the string with spaces until we've used up 15 characters.
while [ $i -ne $Count ]
do
  i=$(($i+1))
  NewLine=$NewLine" "
done

# Append the URL
NewLine=$NewLine"$2"

SourceFile="$ScriptDir/_redirects"
TmpFile="$ScriptDir/tmpRedirects"

# Ensure we are not adding a shortcut that's already taken
if grep -q "/$1 " "$SourceFile"; then
  echo "Error: the shortcut /$1 already exists"
  exit 1
fi

# Ensure we're not adding a second shortcut for the same url
# Note the $ after $2, this ensures that the URL matches only
# the end of the line, so "google.com" will not match "google.com/foo" 
if grep -q "$2$" "$SourceFile"; then
  echo "Error: a shortcut for the url $2 already exists"
  exit 1
fi

# Add the line at the top of the file. This avoids messing with the
# fallback url
{ echo "$NewLine"; cat $SourceFile; } > $TmpFile

mv $TmpFile $SourceFile 

# Push to whatever branch you are on
(cd $ScriptDir \
  && git add $SourceFile \
  && git commit -am "Add a new shortcut for $1 to $2" \
  && git branch | grep "*" | sed 's/* //g' | xargs git push origin
)

echo "Added the shortcut '/$1' pointing to '$2'"