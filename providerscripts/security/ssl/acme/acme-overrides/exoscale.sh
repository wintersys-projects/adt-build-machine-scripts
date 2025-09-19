#!/usr/bin/bash

# shellcheck disable=SC2034
dns_exoscale_info='Exoscale.com
Site: Exoscale.com
Docs: github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_exoscale
'

########  Public functions #####################

# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_exoscale_add() {
        fulldomain=$1
        txtvalue=$2

        _sub_domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f -2`"
        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"


        _debug _sub_domain "$_sub_domain"
        _debug _domain "$_domain"

        _info "Adding record"
        
        if ( [ "`/usr/bin/exo dns show $_domain -O json | /usr/bin/jq -r '.[] | select ( .content | contains ( "'$txtvalue'")).id'`" = "" ] )
        then
                /usr/bin/exo dns add TXT $_domain -c $txtvalue -n $_sub_domain -t 120
        fi
        
        if ( [ "`/usr/bin/exo dns show $_domain -O json | /usr/bin/jq -r '.[] | select ( .content | contains ( "'$txtvalue'")).id'`" != "" ] )
        then
                _info "Added, OK"
                return 0
        fi

        _err "Add txt record error."
        return 1

}

# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_exoscale_rm() {
        fulldomain=$1
        txtvalue=$2

        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"
        _domain_id="`/usr/bin/exo dns show $_domain -O json | /usr/bin/jq -r '.[] | select ( .content | contains ( "'$txtvalue'")).id'`" 

        if ( [ "`/usr/bin/exo dns show $_domain -O json | /usr/bin/jq -r '.[] | select ( .content | contains ( "'$txtvalue'")).id'`" != "" ] )
        then
                /usr/bin/exo dns remove $_domain $_domain_id --force
        fi
        
        if ( [ "`/usr/bin/exo dns show $_domain -O json | /usr/bin/jq -r '.[] | select ( .content | contains ( "'$txtvalue'")).id'`" = "" ] )
        then
                _info "Removed, OK"
                return 0
        fi

        _err "Remove txt record error."
        return 1
}
