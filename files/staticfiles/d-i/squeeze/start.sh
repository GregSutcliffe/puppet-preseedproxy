#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

# create templates for use in on-the-fly creation of dialogs
cat > /tmp/HandsOff.templates <<'!EOF!'
Template: hands-off/meta/text
Type: text
Description: ${DESC}
 ${DESCRIPTION}

Template: hands-off/meta/string
Type: string
Description: ${DESC}
 ${DESCRIPTION}

Template: hands-off/meta/boolean
Type: boolean
Description: ${DESC}
 ${DESCRIPTION}
!EOF!

debconf-loadtemplate hands-off /tmp/HandsOff.templates

cat > /tmp/HandsOff-fn.sh <<'!EOF!'
# useful functions for preseeding
checkflag() {
	flagname=$1 ; shift
	if db_get $flagname && [ "$RET" ]
	then
		for i in "$@"; do
			echo ";$RET;" | grep -q ";$i;" && return 0
		done
	fi
	return 1
}
pause() {
	desc=$1 ; shift

	db_register hands-off/meta/text hands-off/pause/title
	db_subst hands-off/pause/title DESC "Conditional Debugging Pause"
	db_settitle hands-off/pause/title

	db_register hands-off/meta/text hands-off/pause
	db_subst hands-off/pause DESCRIPTION "$desc"
	db_input critical hands-off/pause
	db_unregister hands-off/pause
	db_unregister hands-off/pause/title
	db_go
}

# db_set fails if the variable is not already registered -- this gets round that
# this might need to check if the variable already exits
db_really_set() {
  var=$1 ; shift
  val=$1 ; shift
  seen=$1 ; shift

  db_register debian-installer/dummy "$var"
  db_set "$var" "$val"
  db_subst "$var" ID "$var"
  db_fset "$var" seen "$seen"
}

check_udeb_ver() {
        # returns true if the udeb is at least Version: ver
	udeb=$1 ; shift
        ver=$1 ; shift

        { echo $ver ;
          sed -ne '/^Package: '${udeb}'$/,/^$/s/^Version: \(.*\)$/\1/p' /var/lib/dpkg/status ;
        } | sort -t. -c 2>/dev/null
}
!EOF!

. /usr/share/debconf/confmodule
. /tmp/HandsOff-fn.sh

db_register hands-off/meta/text hands-off/pause/title
db_register hands-off/meta/text hands-off/pause

db_get auto-install/sitecode || {
  db_register hands-off/meta/string auto-install/sitecode/title
  db_register hands-off/meta/string auto-install/sitecode
  db_subst auto-install/sitecode ID auto-install/sitecode
}

server="autoinstall.mydomain.com"

# Get sitecode
db_subst auto-install/sitecode/title DESC "Enter SITECODE"
db_settitle auto-install/sitecode/title
db_subst auto-install/sitecode DESCRIPTION "\
Enter the site code for the server you are building, all in lowercase.
Sitecode is the shortname of the host you are building."
db_set auto-install/sitecode ''
db_input critical auto-install/sitecode
db_go

db_get auto-install/sitecode && sitecode=$RET
if [ -z "$(debconf-get auto-install/sitecode)" ] ; then
  db_subst hands-off/pause/title DESC "No sitecode"
  db_subst hands-off/pause DESCRIPTION "You have not specified a sitecode. This machine will shutdown" 
  db_input critical hands-off/pause
  db_go
  /sbin/shutdown -h now
fi

incl=$(wget -q -O - "http://$server/$sitecode")
db_set preseed/include $incl
