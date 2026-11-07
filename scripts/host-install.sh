#!/usr/bin/env bash
## The host side of the AWS plugin: the CLI on this machine and the dashboard's credentials.
## Run by core/scripts/plugins.sh --install aws, and by core/scripts/install.sh for every installed
## plugin that ships one. Idempotent: whatever is already there is reported, not redone. Offered,
## never automatic: a hosting CLI carries cloud credentials for real environments.
set -u
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)}";

# The aws CLI on this machine, mounted into the dashboard from ~/.local/bin or found on PATH.
BIN='';
for candidate in "$(command -v aws 2>/dev/null)" "${HOME}/.local/bin/aws" ; do
  [ -n "${candidate}" ] && [ -x "${candidate}" ] && { BIN="${candidate}"; break; }
done
if [ -n "${BIN}" ] ; then
  printf '  ✓ %-16s %s\n' "aws" "${BIN}" ;
else
  printf '  ✗ %-16s %s\n' "aws" "missing — the AWS menu needs it (docs.aws.amazon.com/cli — the v2 installer, or pipx install awscli)" ;
fi

STATE="$(grep -E '^access_key_id:' "${WORKSPACE_ROOT}/core/config/plugin.aws.settings.yml" 2>/dev/null | head -1 | sed -E 's/^[a-z_]+:[[:space:]]*//')";
case "${STATE}" in
  ''|CHANGE_ME|"''"|'""') printf '  ✗ %-16s %s\n' "access_key_id" "not set in plugin.aws.settings.yml — the dashboard cannot reach AWS" ;;
  *)                       printf '  ✓ %-16s %s\n' "access_key_id" "set (plugin.aws.settings.yml)" ;;
esac

STATE="$(grep -E '^secret_access_key:' "${WORKSPACE_ROOT}/core/config/plugin.aws.settings.yml" 2>/dev/null | head -1 | sed -E 's/^[a-z_]+:[[:space:]]*//')";
case "${STATE}" in
  ''|CHANGE_ME|"''"|'""') printf '  ✗ %-16s %s\n' "secret_access_key" "not set in plugin.aws.settings.yml — the dashboard cannot reach AWS" ;;
  *)                       printf '  ✓ %-16s %s\n' "secret_access_key" "set (plugin.aws.settings.yml)" ;;
esac

