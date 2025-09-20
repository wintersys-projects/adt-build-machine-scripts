#!/usr/bin/bash
# shellcheck disable=SC2034
dns_dgon_info='DigitalOcean.com
Site: DigitalOcean.com/help/api/
Docs: github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_dgon
Options:
DO_API_KEY API Key
Author: <github@thewer.com>
'

#####################  Public functions  #####################

## Create the text record for validation.
## Usage: fulldomain txtvalue
## EG: "_acme-challenge.www.other.domain.com" "XKrxpRBosdq0HG9i01zxXp5CPBs"
dns_dgon_add() {
        fulldomain="$(echo "$1" | _lower_case)"
        txtvalue=$2

        _sub_domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f -2`"
        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"

        #       if ( [ "${DO_API_KEY}" = '' ] )
        #       then
        #               _err 'DO_API_KEY was not exported'
        #               return 1
        #       fi
        #
        #       _saveaccountconf_mutable DO_API_KEY "${DO_API_KEY}"

        _debug _sub_domain "$_sub_domain"
        _debug _domain "$_domain"

        _info "Adding record"

        if ( [ "`/usr/local/bin/doctl compute domain records list $_domain -o json | /usr/bin/jq -r '.[] | select ( .data | contains ( "'$txtvalue'")).id'`" = "" ] )
        then
                /usr/local/bin/doctl compute domain records create --record-type TXT --record-name $_sub_domain --record-data $txtvalue  --record-ttl 60 $_domain
        fi

        if ( [ "`/usr/local/bin/doctl compute domain records list $_domain -o json | /usr/bin/jq -r '.[] | select ( .data | contains ( "'$txtvalue'")).id'`" != "" ] )
        then
                _info "Added, OK"
                return 0
        fi

        _err "Add txt record error."
        return 1

}

## Remove the txt record after validation.
## Usage: fulldomain txtvalue
## EG: "_acme-challenge.www.other.domain.com" "XKrxpRBosdq0HG9i01zxXp5CPBs"
dns_dgon_rm() {
        fulldomain="$(echo "$1" | _lower_case)"
        txtvalue=$2

        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"
        _domain_id="`/usr/local/bin/doctl compute domain records list $_domain -o json | /usr/bin/jq -r '.[] | select ( .data | contains ( "'$txtvalue'")).id'`"

    #    DO_API_KEY="${DO_API_KEY:-$(_readaccountconf_mutable DO_API_KEY)}"
    #    # Check if API Key Exists
    #    if [ -z "$DO_API_KEY" ]; then
    #            DO_API_KEY=""
    #            _err "You did not specify DigitalOcean API key."
    #            _err "Please export DO_API_KEY and try again."
    #            return 1
     #   fi

        if ( [ "`/usr/local/bin/doctl compute domain records list $_domain -o json | /usr/bin/jq -r '.[] | select ( .data | contains ( "'$txtvalue'")).id'`" != "" ] )
        then
                /usr/local/bin/doctl compute domain records delete --force $_domain ${_domain_id}
        fi

        if ( [ "`/usr/local/bin/doctl compute domain records list $_domain -o json | /usr/bin/jq -r '.[] | select ( .data | contains ( "'$txtvalue'")).id'`" = "" ] )
        then
                _info "Removed, OK"
                return 0
        fi

        _err "Remove txt record error."
        return 1
}
