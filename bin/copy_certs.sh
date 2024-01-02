#! /usr/bin/env bash

set -e


echoerr() { printf "%s\n" "$*" >&2; }

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
project_dir=$(dirname "$script_dir")


if [[ ! -v SSL_CERTS_DIR ]]; then
  echoerr "\$SSL_CERTS_DIR environment variable is unset. Exiting now"
  exit 1
fi


# 2023-12-25-01_53_17
date_version_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}_[0-9]{2}$'
if [[ ! -v ROOT_CERT_VERSION ]]; then
  echoerr "\$ROOT_CERT_VERSION envionment variable is unset. Exiting now"
  exit 1
elif [[ ! "$ROOT_CERT_VERSION" =~ $date_version_regex ]]; then
  echoerr "\$ROOT_CERT_VERSION envionment variable is unset or malformed. value: \"${ROOT_CERT_VERSION}\". Exiting now"
  exit 1
else
  echoerr "Using ROOT_CERT_VERSION=${ROOT_CERT_VERSION}"
fi;

versioned_root_cert_dir="${SSL_CERTS_DIR}/root-cert-${ROOT_CERT_VERSION}"
root_cert_file="${versioned_root_cert_dir}/pihome-ca.pem"
root_cert_key_file="${versioned_root_cert_dir}/pihome-ca.key"

if [[ ! -d "$versioned_root_cert_dir" ]] \
  || [[ ! -f  $root_cert_file ]] \
  || [[ ! -f "$root_cert_key_file" ]]; then
  echoerr "the desired version of the root cert is missing a required component. Check ${versioned_root_cert_dir} for a pem and a key file"
  exit 1
fi


if [[ ! -v CERT_VERSION ]]; then
  echoerr "\$CERT_VERSION envionment variable is unset. Exiting now"
  exit 1
elif [[ ! "$CERT_VERSION" =~ $date_version_regex ]]; then
  echoerr "\$CERT_VERSION envionment variable is malformed. value: \"${CERT_VERSION}\". Exiting now"
  exit 1
else
  echoerr "using ROOT_CERT_VERSION=${ROOT_CERT_VERSION} and CERT_VERSION=${CERT_VERSION}"
fi

versioned_cert_dir="${SSL_CERTS_DIR}/cert-${CERT_VERSION}"
pico_to_mqtt_prefix='pico-to-mqtt'
existing_cert_dir="${versioned_cert_dir}/${pico_to_mqtt_prefix}"
existing_cert="${existing_cert_dir}/${pico_to_mqtt_prefix}.crt"
existing_cert_key="${existing_cert_dir}/${pico_to_mqtt_prefix}.key"

if [[ ! -d "$existing_cert_dir" ]] \
  || [[ ! -f "$existing_cert_key" ]] \
  || [[ ! -f "$existing_cert" ]]; then
  echoerr "the desired version of the ${pico_to_mqtt_prefix} is missing a required component. Exiting now"
  exit 1
fi

ssl_cert_destination="${project_dir}/etc-pico-to-mqtt/ssl/cert-${CERT_VERSION}"
ca_cert_destination="${project_dir}/etc-pico-to-mqtt/ssl/root-cert-${ROOT_CERT_VERSION}"

echoerr "copying pihome root cert to ${ca_cert_destination}"
mkdir -p "$ca_cert_destination"
cp "$root_cert_file" "$ca_cert_destination"

echoerr "copying pico-to-mqtt certs to ${ssl_cert_destination}"
mkdir -p "$ssl_cert_destination"
cp "$existing_cert" "$existing_cert_key" "$ssl_cert_destination"

echoerr "done copying the mqtt certs, but you still need the caseta certs to run this application."
