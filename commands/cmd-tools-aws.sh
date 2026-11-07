#!/usr/bin/env bash

# Installed by the AWS plugin (plugins.sh --install aws); __WORKSPACE__ is the workspace it was installed into.
#
# The local ⇄ cloud bridge for one project on AWS: show its link and environments, link it,
# bring a database and files down into DDEV, deploy, read logs.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings and extra lists.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

ARGPARSE_DESCRIPTION="Show, link, pull from or deploy a __WORKSPACE__ project on AWS"
# The args file comes with the plugin: core/scripts/plugins/aws/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/aws/args/arg-aws.sh || exit 1 ;

shift $#;

aws_project_tool ;
