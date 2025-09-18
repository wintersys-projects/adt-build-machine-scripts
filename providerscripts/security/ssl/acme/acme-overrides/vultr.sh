#!/usr/bin/bash
# shellcheck disable=SC2034
dns_vultr_info='vultr.com
Site: vultr.com
Docs: github.com/acmesh-official/acme.sh/wiki/dnsapi2#dns_vultr
Options:
VULTR_API_KEY API Key
Issues: github.com/acmesh-official/acme.sh/issues/2374
'

VULTR_Api="https://api.vultr.com/v2"

########  Public functions #####################
#
#Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_vultr_add() {
        fulldomain=$1
        txtvalue=$2

        _sub_domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f -2`"
        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"


        _debug _sub_domain "$_sub_domain"
        _debug _domain "$_domain"

        _info "Adding record"

        /usr/bin/vultr dns record create $_domain -n $_sub_domain -t TXT -d "$txtvalue" --ttl=60

        if ( [ "`/usr/bin/vultr dns record list $_domain -o json | /usr/bin/jq -r '.records[] | select (.data | contains("'$txtvalue'")).id'`" != "" ] )
        then
                _info "Added, OK"
                return 0
        fi

        _err "Add txt record error."
        return 1
}

#fulldomain txtvalue
dns_vultr_rm() {
        fulldomain=$1
        txtvalue=$2

        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"
        _domain_id="`/usr/bin/vultr dns record list $_domain -o json | /usr/bin/jq -r '.records[] | select (.data == "'$txtvalue'").id'`"

        /usr/bin/vultr dns record delete ${domainurl} ${_domain_id}

        if ( [ "$?" = "1" ] )
        then
                _err "Delete record error."
                return 1
        fi

        return 0

}
