# PXEProxy Puppet module

This module is horribly named, as it's actually a Debian Preseed proxy for
TheForeman.

This module is currently still quite heavily flavoured by the way we operate - 
for example you'll see 'sitecode' used a lot instead of 'hostname'. A cleanup
task is on the TODO.

# Description

Foreman is wonderful when your host are on a subnet controlled by Foreman, as
then your hosts will PXE, TFTP, and DHCP into the correct installer, retrieve
the corect preseed, and install.

But what if you can't control the boot environment? What if some of your
installers want to test the install at home, or in some small office that you
have no authority over?

That's where this proxy comes it. It provides a system where a user can boot
from the normal Debian install CD, enter the URL of this proxy, enter the
hostname of the Foreman host to build, and recieve a preseed/finish/puppet cert
just like normal.

# How it works

The proxy makes use of two Debian tricks.

Firstly, when you don't provide a URL
(only a hostname) to the Debian autoinstaller, it assumes a certain path. So we
serve a simple static preseed,cfg from that path which asks the user for a
hostname.

Secondly we use a preseed trick that allows you to replace the current pressed
with a new one, which is how we can ask for a hostname, _then_ check Foreman
for details, and _then_ return the real preseed.

It also relies on Foreman's _spoof_ feature to return the unattended data. Since
the client does not talk to Foreman directly, the proxy looks up the IP address
configured with the client, and uses that to get the spoof=<ip> URL.

# Extra features

This proxy was developed partly because we didn;t want to expose out Foreman
instance to the public Internet. The proxy transparently rewrites the URLs in
your preseed, so URLS like

    http://foreman.mydomain.com/unattended/{provision|finish|built}

instead become

    http:///proxy.mydomain.com/:hostame/{provision|finish|built}

and the proxy also knows how to retrieve those parts of the URLs. As such, a
preseed client on the public internet can talk to the proxy using the exact
same preseed that a test client on a Foreman subnet uses - handy for testing
changes to your preseeds.

# Installation

This module has two dependencies, both from https://github.com/theforeman/:

* puppet-apache
* puppet-passenger

Simply `include pxeproxy` to set up the files. There's a mess of hardcoded
variables in pxeproxy.rb - edit to suit, and uncomment the return in get_cookie
if you're not using authentication.

# Testing

You can go to http://proxy/:sitecode/preseed to see the full preseed for a host,
in any browser. If that host doesn't exist in Foreman, you should get
'notfound.cfg'. If the hosts exists but isn't in build mode, you should get
'notauth.cfg'. Otherwise you should get the correct preseed data, just as if
you spoofed the IP in Foreman. 'sitecode/finish' should likewise return the
finish script.

This has only been tested for installs of Debian Squeeze, but the module should
work for any webserver supported by the apache/passenger modules.

# TODO

* Rename module to 'preseed_proxy'
* Convert lingering 'sitecode' references to 'hostname' or 'fqdn'
* Add proxy support for 'unattended/script'
* Parameterized the mess of hardcoded variables
* Cache data better between the calls.

# Contributing

* Fork the project
* Commit and push until you are happy with your contribution

# More info

Copyright (c) 2012 Greg Sutcliffe

This entire repository is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
