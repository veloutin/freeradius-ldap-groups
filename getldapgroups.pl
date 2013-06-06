use strict;
# use ...
# This is very important ! Without this script will not get the filled  hashesh from main.
#use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK);
use Data::Dumper;
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
my $ldap_filter = "(&(objectClass=posixGroup)(memberUid=$RAD_REQUEST{'User-Name'}))";
my $group_key = 'Groups';


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
    use vars qw($ldap_server $ldap_user $ldap_pw $ldap_base $ldap_filter $group_key);
    my $ldap = Net::LDAP->new($ldap_server);
    if ($ldap->bind($ldap_user, password => $ldap_pw)->code) {
        &radiusd::radlog(4, "BIND FAILED");
        return 0;
    }

    my $res = $ldap->search(
        base => $ldap_base,
        scope => "sub",
        filter => $ldap_filter,
        attrs => "dn",
    );

    foreach my $entry ($res->entries) {
        push(@{$RAD_REQUEST{$group_key}}, $entry->dn);
    }

    return 1;

}

# Function to handle preacct
sub preacct {
    # For debugging purposes only
#       &log_request_attributes;

    return RLM_MODULE_OK;
}


# Function to handle post_auth
sub post_auth {
    # For debugging purposes only
#       &log_request_attributes;
    &log_request_attributes;

    if (&get_groups()) {
        &log_request_attributes;
        return RLM_MODULE_UPDATED;
    } else {
        return RLM_MODULE_OK;
    }
}


sub log_request_attributes {
    # This shouldn't be done in production environments!
    # This is only meant for debugging!
    for (keys %RAD_REQUEST) {
            &radiusd::radlog(1, "RAD_REQUEST: $_ = $RAD_REQUEST{$_}");
    }
}
