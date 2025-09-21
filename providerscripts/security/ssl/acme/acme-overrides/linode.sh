#!/usr/bin/bash
# shellcheck disable=SC2034
dns_linode_info='Linode.com (Old)
Deprecated. Use dns_linode_v4
Site: Linode.com
'


########  Public functions #####################
#
#Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_linode_v4_add() {
        fulldomain=$1
        txtvalue=$2

        _sub_domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f -2`"
        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"

        _debug _sub_domain "$_sub_domain"
        _debug _domain "$_domain"

        _info "Adding record"

        _domain_id="`/usr/local/bin/linode-cli --json domains list | /usr/bin/jq -r '.[] | select (.domain | contains("'${domain_url}'")).id'`"

        if ( [ "`/usr/local/bin/linode-cli --json domains records-list $_domain_id | /usr/bin/jq -r '.[] | select (.target | contains("'$txtvalue'")).id'`" = "" ] )
        then
                /usr/local/bin/linode-cli domains records-create $_domain_id --type TXT --name $_sub_domain --target $txtvalue --ttl_sec 60
        fi

        if ( [ "`/usr/local/bin/linode-cli --json domains records-list $_domain_id | /usr/bin/jq -r '.[] | select (.target | contains("'$txtvalue'")).id'`" != "" ] )
        then
                _info "Added, OK"
                return 0
        fi

        _err "Add txt record error."
        return 1
}

#fulldomain txtvalue
dns_linode_v4_rm() {
        fulldomain=$1
        txtvalue=$2

        _domain="`/bin/echo ${fulldomain} | /usr/bin/cut -d '.' -f 3-`"
        _domain_id="`/usr/local/bin/linode-cli --json domains list | /usr/bin/jq -r '.[] | select (.domain | contains("'$_domain'")).id'`"
        _record_id="`/usr/local/bin/linode-cli --json domains records-list $_domain_id | /usr/bin/jq -r '.[] | select (.target | contains("'$_txtvalue'")).id'`"

        if ( [ "`/usr/local/bin/linode-cli --json domains records-list $_domain_id | /usr/bin/jq -r '.[] | select (.target | contains("'$_txtvalue'")).id'`" != "" ] )
        then
                /usr/local/bin/linode-cli domains records-delete $_domain_id $_record_id
        fi

        if ( [ "`/usr/local/bin/linode-cli --json domains records-list $_domain_id | /usr/bin/jq -r '.[] | select (.target | contains("'$_txtvalue'")).id'`" = "" ] )
        then
                _info "Removed, OK"
                return 0
        fi

        _err "Remove txt record error."
        return 1

}
