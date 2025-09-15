#!/usr/bin/bash
# shellcheck disable=SC2034
dns_exoscale_info='Exoscale.com
Site: Exoscale.com
Docs: github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_exoscale
Options:
EXOSCALE_API_KEY API Key
EXOSCALE_SECRET_KEY API Secret key
'

########  Public functions #####################


# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_exoscale_add() {
        fulldomain=$1
        txtvalue=$2

        domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d "." -f 3-`"
        /usr/bin/exo dns add TXT ${domain} -c ${txtvalue} 

        if ( [ "$?" = "0" ] )
        then
                return 0
        else
                return 1
        fi

}

dns_exoscale_add acme.www.the-galley.uk hello1

# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_exoscale_rm() {
        fulldomain=$1
        txtvalue=$2

        domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d "." -f 3-`"
        recordid="`/usr/bin/exo dns show ${domain} -O json | /usr/bin/jq -r '.[] | select ( .content | contains ("'${txtvalue}'")).id'`"
        /usr/bin/exo dns remove ${domain} ${recordid} -Q -f

        if ( [ "$?" = "0" ] )
        then
                return 0
        else
                return 1
        fi
}

####################  Private functions below ##################################

_checkAuth() {
        EXOSCALE_API_KEY="${EXOSCALE_API_KEY:-$(_readaccountconf_mutable EXOSCALE_API_KEY)}"
        EXOSCALE_SECRET_KEY="${EXOSCALE_SECRET_KEY:-$(_readaccountconf_mutable EXOSCALE_SECRET_KEY)}"

        if [ -z "$EXOSCALE_API_KEY" ] || [ -z "$EXOSCALE_SECRET_KEY" ]; then
                EXOSCALE_API_KEY=""
                EXOSCALE_SECRET_KEY=""
                _err "You don't specify Exoscale application key and application secret yet."
                _err "Please create you key and try again."
                return 1
        fi

        _saveaccountconf_mutable EXOSCALE_API_KEY "$EXOSCALE_API_KEY"
        _saveaccountconf_mutable EXOSCALE_SECRET_KEY "$EXOSCALE_SECRET_KEY"

        return 0
}

#_acme-challenge.www.domain.com
#returns
# _sub_domain=_acme-challenge.www
# _domain=domain.com
# _domain_id=sdjkglgdfewsdfg
# _domain_token=sdjkglgdfewsdfg
_get_root() {

}

# returns response
_exoscale_rest() {
}
