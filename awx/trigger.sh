#!/bin/bash

# A script used by Travis to trigger an AWX Job.
#
# This assumes the 'tower-cli' utility is available,
# usually installed via a requirements file prior to our execution.

set -eo pipefail

: "${AWX_HOST?Need to set AWX_HOST}"
: "${AWX_USER?Need to set AWX_USER}"
: "${AWX_USER_PASSWORD?Need to set AWX_USER_PASSWORD}"
: "${AWX_JOB_NAME?Need to set AWX_JOB_NAME}"

echo "Attempting to deploy to ${AWX_HOST} using Job Template '$AWX_JOB_NAME'..."
# Get the AWX Job Template ID from the expected Job Template name
jtid=$(tower-cli job_template list -n "$AWX_JOB_NAME" -f id \
  -h "$AWX_HOST" \
  -u "$AWX_USER" \
  -p "$AWX_USER_PASSWORD")

# If we have a template ID (i.e. a number) then trigger it
# and disable any input that might be expected by the Job.
if [[ $jtid =~ ^[0-9]+$ ]]; then
  echo "Launching Job ID ${jtid} and waiting..."
  tower-cli job launch -J "$jtid" --no-input --wait \
    -h "$AWX_HOST" \
    -u "$AWX_USER" \
    -p "$AWX_USER_PASSWORD"
else
  echo "Job Template '$AWX_JOB_NAME' does not exist ($jtid)"
  exit 1
fi
