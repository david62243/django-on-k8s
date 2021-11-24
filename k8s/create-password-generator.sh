#!/usr/bin/env bash 

set -e

printUsage() {
    cat <<ZZZ

Usage: $0
    -n [namespace]
    -p [app_path]
    -f [fqdn]
Examples:
    $0 -n apps -p password-generator -f 20.106.67.102
ZZZ
}

NAMESPACE=""
APP_PATH=""
FQDN=""

while getopts "h?:n:p:f:" opt; do
    case "$opt" in
    n)  NAMESPACE=$OPTARG
        ;;
    p)  APP_PATH=$OPTARG
        ;;
    f)  FQDN=$OPTARG
        ;;
    :)
        echo "[ERROR] Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    h | \? | *)
        printUsage
        exit 0
        ;;
    esac
done

if [ "${NAMESPACE}" == "" ]; then 
  echo "You must specify a namespace"
  printUsage
  exit 2
fi

if [ "${APP_PATH}" == "" ]; then 
  echo "You must specify an app_path"
  printUsage
  exit 2
fi

if [ "${FQDN}" == "" ]; then 
  echo "You must specify an fqdn"
  printUsage
  exit 2
fi

SUBSTR="s/REPLACE_WITH_NS/${NAMESPACE}/;s/REPLACE_WITH_APP_PATH/${APP_PATH}/;s/REPLACE_WITH_FQDN/${FQDN}/"

sed ${SUBSTR} password-generator-template.yaml > ~/temp.yaml

echo "kubectl apply -f  ~/temp.yaml"
kubectl apply -f  ~/temp.yaml


