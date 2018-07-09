#!/bin/bash

set -e

echo "get ConfigMaps for all event providers (--label 'discovery=event-provider')"
readarray array < <(kubectl get cm -l discovery=event-provider -o name)

echo "go over ConfigMaps and read config.json into files"
for index in "${!array[@]}"; do
  echo "creating JSON file type_${index}.json"
  kubectl get ${array[$index]} -o "jsonpath={.data['config\.json']}" > "type_${index}.json"
done

echo "combine all configurations into single type_config.json"
jq -s '{"types": .}' *.json > type_config.json

echo "update hermes ConfigMap with kubectl"
kubectl create configmap "${HERMES_CONFIGMAP}" --from-file=type_config.json --dry-run -o yaml | kubectl replace --force -f -

echo "done"
