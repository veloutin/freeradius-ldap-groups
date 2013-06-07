use strict;
# use ...
# This is very important ! Without this script will not get the filled  hashesh from main.
use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK);
use Net::LDAP;

# This is hash wich hold original request from radius
#my %RAD_REQUEST = (
#    "User-Name", "tenag",
#);
# In this hash you add values that will be returned to NAS.
#my %RAD_REPLY;
#This is for check items
#my %RAD_CHECK;


my $ldap_server = "IP";
my $ldap_user = "BIND_USER_DN";
my $ldap_pw = "BIND_PW";
my $ldap_base = "BASE_SEARCH_DN";
my $ldap_attr = "cn";
my $joiner = ",";
my $group_key = 'Ruckus-User-Groups';


# This the remapping of return values
#
    use constant    RLM_MODULE_REJECT=>    0;#  /* immediately reject the request */
    use constant    RLM_MODULE_FAIL=>      1;#  /* module failed, don't reply */
    use constant    RLM_MODULE_OK=>        2;#  /* the module is OK, continue */
    use constant    RLM_MODULE_HANDLED=>   3;#  /* the module handled the request, so stop. */
    use constant    RLM_MODULE_INVALID=>   4;#  /* the module considers the request invalid. */
    use constant    RLM_MODULE_USERLOCK=>  5;#  /* reject the request (user is locked out) */
    use constant    RLM_MODULE_NOTFOUND=>  6;#  /* user not found */
    use constant    RLM_MODULE_NOOP=>      7;#  /* module succeeded without doing anything */
    use constant    RLM_MODULE_UPDATED=>   8;#  /* OK (pairs modified) */
    use constant    RLM_MODULE_NUMCODES=>  9;#  /* How many return codes there are */

sub get_groups {
    use vars qw($ldap_server $ldap_user $ldap_pw $ldap_base $ldap_attr $group_key $joiner);
    
    my $ldap_filter = "(&(objectClass=posixGroup)(memberUid=$RAD_REQUEST{'User-Name'}))";
    my $ldap = Net::LDAP->new($ldap_server);
    if ($ldap->bind($ldap_user, password => $ldap_pw)->code) {
        &radiusd::radlog(4, "BIND FAILED");
        return 0;
    }
    #&radiusd::radlog(1, "Connected: $ldap\n");
    #&radiusd::radlog(1, "Searching: $ldap_base, $ldap_filter, $ldap_attr\n");
    

    my $res = $ldap->search(
        base => $ldap_base,
        scope => "sub",
        filter => $ldap_filter,
        attrs => [$ldap_attr],
    );
    
    my $max = $res->count;
    #&radiusd::radlog(1, "Results: $max ($res)\n");

    my @groups = ();
    if ($ldap_attr eq "dn") {
        for (my $i = 0; $i < $max; $i++) {
            my $entry = $res->entry($i);

            push(@groups, $entry->dn);
        }
    } else {
        for (my $i = 0; $i < $max; $i++) {
            my $entry = $res->entry($i);
            my $val = $entry->get_value($ldap_attr);

            if ($val) {
                push(@groups, $val);
            }
        }
    }

    $RAD_REPLY{$group_key} = join($joiner, @groups);

    return 1;

}

# Function to handle post_auth
sub post_auth {
    # For debugging purposes only
#    &log_request_attributes;

    if (&get_groups) {
#        &log_reply_attributes;
        return RLM_MODULE_UPDATED;
    } else {
        return RLM_MODULE_OK;
    }
}

sub authorize {
    return RLM_MODULE_OK;
}
sub authenticate {
    return RLM_MODULE_OK;
}
sub accounting {
    return RLM_MODULE_OK;
}
sub preacct {
    return RLM_MODULE_OK;
}
sub checksimul {
    return RLM_MODULE_OK;
}
sub detach {
    return RLM_MODULE_OK;
}
sub xlat {
    return RLM_MODULE_OK;
}
sub pre_proxy {
    return RLM_MODULE_OK;
}
sub post_proxy {
    return RLM_MODULE_OK;
}
sub recv_coa {
    return RLM_MODULE_OK;
}
sub send_coa {
    return RLM_MODULE_OK;
}


sub log_request_attributes {
    # This shouldn't be done in production environments!
    # This is only meant for debugging!
    for (keys %RAD_REQUEST) {
            &radiusd::radlog(1, "RAD_REQUEST: $_ = $RAD_REQUEST{$_}");
    }
}

sub log_reply_attributes {
    # This shouldn't be done in production environments!
    # This is only meant for debugging!
    for (keys %RAD_REPLY) {
        &radiusd::radlog(1, "RAD_REPLY: $_ = $RAD_REQUEST{$_}");
    }
}
