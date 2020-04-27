#!/bin/sh

install_jq() {
  jq_version="1.6"
  jq_release="https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64"

  curl \
    --location \
    --silent \
    --show-error \
    --output ./jq \
    "${jq_release}"

  chmod +x ./jq

  mv ./jq /usr/local/bin/jq
}

export EJSON_KMS_VERSION="3.0.0"

curl -s -Lo ejson-kms https://github.com/adrienkohlbecker/ejson-kms/releases/download/$EJSON_KMS_VERSION/ejson-kms-$EJSON_KMS_VERSION-linux-amd64

chmod +x ejson-kms

mv ejson-kms /usr/local/bin/ejson-kms

install_jq