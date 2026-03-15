#!/bin/bash
set -eu

SSHPATH="$HOME/.ssh"
mkdir -p "$SSHPATH"
chmod 700 "$SSHPATH"

# Write deploy key and clean it up on exit
echo "$DEPLOY_KEY" > "$SSHPATH/key"
chmod 600 "$SSHPATH/key"
trap 'rm -f "$SSHPATH/key"' EXIT

# Add server host key to known_hosts to prevent MITM attacks
echo "$SERVER_HOST_KEY" >> "$SSHPATH/known_hosts"
chmod 600 "$SSHPATH/known_hosts"

SERVER_DEPLOY_STRING="$USERNAME@$SERVER_IP:$SERVER_DESTINATION"

# shellcheck disable=SC2086 — ARGS is intentionally word-split
rsync $ARGS \
  -e "ssh -i $SSHPATH/key -p $SERVER_PORT" \
  "$GITHUB_WORKSPACE/$FOLDER" \
  "$SERVER_DEPLOY_STRING"
