#!/bin/sh
#

# Load config.
. /etc/profile
oe_setup_addon service.rTorrent

if [ "$#" -lt 1 ] 
then
   echo "Need input"
   echo "Exiting..."
   exit 1
fi

# Load vars.
HASH=$1
shift

FROM="$@"
FROM="${FROM%/}"

NAME=${FROM##*/}

# Do we have a MATCH
MATCH=${FROM%/*}
MATCH=${MATCH##*/}

# Do we have a watch dir match, if do use it.
for RTORRENT_DIR in ${RTORRENT_DIRS//,/ } ;do
   if [[ "$MATCH" == "$RTORRENT_DIR" ]];then
      STORE=${RTORRENT_COMPLETE_DIR}${RTORRENT_DIR}
   fi
done

# if we dont have a watch dir match use the rutorrent label
if [ -z "$STORE" ] ;then
   RTORRENT_DIR=$(xmlrpc2scgi.py -p 'scgi://localhost:5000' d.get_custom1 $HASH |sed 's/%20/ /g;s/%2F/\//g')
   if [ "$RTORRENT_DIR" ];then
      STORE=${RTORRENT_COMPLETE_DIR}${RTORRENT_DIR}
   fi
fi

# Do on complete action if we have STORE var here and
# RTORRENT_ON_COMPLETE is Move or Link, else do nothing.
if [ "$STORE" ] ;then
   # Make sure series are in a dir with series.name.sNN, if possible.
   if [ "$RTORRENT_SORT_SERIES" == "true" ];then
      echo $NAME |grep -qi s[0-9][0-9]e[0-9][0-9]
      if [ "$?" -eq "0" ];then
          SEASON=$(echo $NAME | egrep -oi "s[0-9][0-9]") # grep season from name
          DIR=${NAME%[s,S][0-9]*} # Trim string to get show name
          DIR=${DIR// /.} # replace all spaces with dots
          DIR=$(echo $DIR | sed -e 's/\.*$//') # Trim trailing dots
          DIR="$DIR/$SEASON" # Add season as sub directory
          DIR=$(echo $DIR |tr '[A-Z]' '[a-z]') # to lowercase
          STORE="$STORE/$DIR"
      fi
   fi

   # Should we run complete action if so run it.
   if [ $RTORRENT_ON_COMPLETE == Move ] ;then
      mkdir -p "$STORE"
      xmlrpc2scgi.py -p 'scgi://localhost:5000' d.set_directory $HASH "$STORE"
      mv "$FROM" "$STORE"
   elif [ $RTORRENT_ON_COMPLETE == Link ] ;then
      mkdir -p "$STORE"
      ln -sf "$FROM" "$STORE"
   fi
fi

# Notify xbmc user
kodi-send -a "Notification(rTorrent - Download Completed,$NAME,10000)"

