#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2008 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /usr/share/debconf/confmodule

db_get auto-install/sitecode && sitecode=$RET
db_subst hands-off/pause/title DESC "Not found"
db_subst hands-off/pause DESCRIPTION "\
Sorry, $sitecode is not currently authorized for build in Foreman.
This machine will now shutdown."
db_input critical hands-off/pause
db_go
/sbin/shutdown -h now
