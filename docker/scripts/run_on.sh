#!/bin/sh

TIPO_NODO=$(echo "$1" | cut -d "-" -f 2)
NUM_NODO=$(echo "$1" | cut -d "-" -f 3)

HAPROXY_IP=$(terraform -chdir=/terraform output --json haproxy | jq -r .connection_ip)

case $TIPO_NODO in
gameserver) DIRECCION=$(terraform -chdir=/terraform output --json gameserver | jq -r .name) ;;
team) DIRECCION=$(terraform -chdir=/terraform output --json nodes | jq -r .[$NUM_NODO-1].name) ;;
haproxy) DIRECCION=$(terraform -chdir=/terraform output --json haproxy | jq -r .name) ;;
esac


ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -W %h:%p -q root@$HAPROXY_IP" \
-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$DIRECCION" "$2" && echo ""
