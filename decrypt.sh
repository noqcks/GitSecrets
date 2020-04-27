#!/bin/sh

# This is a secret decryption script that will decrypt ejson-kms secrets and
# export them to the shell environment.
#
# It expects two sane defaults:
#
# 1. That $ENV has been set already, so that we know which environment we're in
#    and what secrets to export.
#
# 2. That the location of your secrets are either relative at
#    _infra/secrets/$ENV.json or absolutely located at /opt/_infra/secrets/$ENV.json

if [ -n "$BASH" ]; then
    set -o pipefail
fi

echo "Decrypting secrets..."

# set AWS_REGION for KMS. For now, we always store our secrets in AWS KMS region us-east-1 because
# we don't want developers to worry about something like setting AWS_REGION for their secrets.
# The higher latency of calling a single AWS Region should be marginally long in this scenario.
KMS_AWS_REGION="us-east-1"

# exit if $ENV doesn't exist. We're not sure what environment to decrypt!
if [ -z "${ENV}" ]; then
  echo "WARN: >>> SKIPPING SECRET DECRYPTION <<<"
  echo "WARN: secrets not decrypted. You haven't specified "\$ENV", so we don't know what environment to decrypt."
  return 0
fi

# exit if there are no secrets at the 2 locations we know about
if [ ! -f _infra/secrets/$ENV.json ] && [ ! -f /opt/_infra/secrets/$ENV.json ]; then
  echo "WARN: >>> SKIPPING SECRET DECRYPTION <<<"
  echo "WARN: secrets not decrypted. Secrets do not exist at _infra/secrets/$ENV.json or /opt/_infra/secrets/$ENV.json"
  return 0
fi

# set the path to the secrets we've found
if [ -e "_infra/secrets/$ENV.json" ]; then
  path="_infra/secrets/$ENV.json"
fi

if [ -e "/opt/_infra/secrets/$ENV.json" ]; then
  path="/opt/_infra/secrets/$ENV.json"
fi

# export decrypted secrets to env variables
set -a

case "${SECRETS_EXPORT_FORMAT}" in
  'bash-ifnotset')
      eval "$(
        AWS_REGION="${KMS_AWS_REGION}" ejson-kms export --format json --path "$path" \
        | jq -r 'to_entries | map(": ${\(.key | ascii_upcase)=\(.value | tostring | @sh)}") | .[]'
      )"
    ;;

  'bash-ifempty')
      eval "$(
        AWS_REGION="${KMS_AWS_REGION}" ejson-kms export --format json --path "$path" \
        | jq -r 'to_entries | map(": ${\(.key | ascii_upcase):=\(.value | tostring | @sh)}") | .[]'
      )"
    ;;

  *)
    eval "$(AWS_REGION="${KMS_AWS_REGION}" ejson-kms export --format bash --path "$path")"
    ;;
esac

set +x

echo "Done."
