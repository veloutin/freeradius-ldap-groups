Yea yea, this works!

HOWTO:
0. add export LD_PRELOAD=/usr/lib/libperl.so.5.10 in /etc/init.d/freeradius
   if freeradius < 2.1.10
1. put getldapgroups.pl in ${confdir}
2. set module = ${confdir}/getldapgroups.pl in ${confdir}/modules/perl
3. in ${confdir}/sites-enables/default (or other site), make sure to have the
    perl module called in post-auth, like so

    post-auth {
        perl
    }
4. drop share/dictionary.ruckus in /usr/share/freeradius/
5. add $INCLUDE dictionary.ruckus somewhere in /usr/share/freeradius/dictionary
