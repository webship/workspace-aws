#!/usr/bin/env bash

# AWS Elastic Beanstalk through the aws CLI. The hooks the hosting dispatcher (fun-aws-tool.sh)
# calls for one project directory. Everything defaults to read-only; --link, --push and
# --pull-files each demand their flag, and nothing here ever creates or terminates an environment.

function aws_region() {
  local r; r="$(aws_link_get "$1" region)";
  printf '%s' "${r:-${AWS_DEFAULT_REGION:-${region:-eu-west-1}}}";
}

function ensure_aws() {
  if command -v aws > /dev/null 2>&1 ; then
    if ! aws sts get-caller-identity > /dev/null 2>&1 ; then
      echo "aws is installed but has no usable credentials. On the host: aws configure (or an SSO login); in the dashboard: the plugin settings." ;
      return 1 ;
    fi
    return 0 ;
  fi
  echo "The aws CLI is not installed. Install it first: https://docs.aws.amazon.com/cli/ (the v2 installer, or pipx install awscli)" ;
  return 1 ;
}

function aws_do_link() {
  local project_path="$1" app="$2" r;
  r="${REGION:-_none_}"; [ "${r}" == '_none_' ] && r="$(aws_region "${project_path}")";
  aws elasticbeanstalk describe-applications --application-names "${app}" --region "${r}" --output text --query 'Applications[0].ApplicationName' 2>/dev/null | grep -qx "${app}" \
    || { echo "No Elastic Beanstalk application '${app}' in ${r} (aws elasticbeanstalk describe-applications)."; return 1; } ;
  aws_link_set "${project_path}" id "${app}" ;
  aws_link_set "${project_path}" region "${r}" ;
  if [ ! "${FILES_BUCKET:-_none_}" == '_none_' ] ; then
    aws_link_set "${project_path}" files_bucket "${FILES_BUCKET}" ;
    echo "  --pull-files will sync s3://${FILES_BUCKET}." ;
  fi
}

function aws_list_environments() {
  aws elasticbeanstalk describe-environments --application-name "$2" --no-include-deleted --region "$(aws_region "$1")" --output text --query 'Environments[].EnvironmentName' 2>/dev/null | tr '\t' '\n' ;
}

function aws_do_environments() {
  aws elasticbeanstalk describe-environments --application-name "$2" --no-include-deleted --region "$(aws_region "$1")" --output json 2>/dev/null | python3 -c 'import json,sys
for e in json.load(sys.stdin).get("Environments",[]):
    print("  %-28s %-10s %-8s %-18s %s" % (e.get("EnvironmentName",""), e.get("Status",""), e.get("Health",""), (e.get("VersionLabel") or "")[:18], ("http://"+e["CNAME"]) if e.get("CNAME") else ""))' \
    || { echo "  (could not list the environments — check aws sts get-caller-identity)"; return 1; } ;
}

function aws_pull_db() {
  echo "RDS is not reachable generically from this machine: there is no --pull-db here.";
  echo "  The shape of it, from a host that can reach the instance: mysqldump -h <rds-endpoint> -u <user> -p <db> | gzip > dump.sql.gz && ddev import-db --file=dump.sql.gz";
  return 1 ;
}

function aws_pull_files() {
  local project_path="$1" app="$2" env="$3" docroot bucket;
  bucket="$(aws_link_get "${project_path}" files_bucket)";
  [ -z "${bucket}" ] && { echo "No files bucket is linked. Name it once: bash cmd-tools-aws.sh ${PROJECT_NAME} --link ${app} --files-bucket <bucket[/prefix]> --force"; return 1; } ;
  docroot="$(aws_docroot "${project_path}")";
  [ -z "${docroot}" ] && { echo "No web/ or docroot/ in ${doc_name}/${PROJECT_NAME} — nothing to pull files into."; return 1; } ;
  echo "";
  echo "aws s3 sync s3://${bucket}/ → ${docroot}/sites/default/files (adds and overwrites, never deletes). Client data.";
  mkdir -p "${project_path}/${docroot}/sites/default/files" ;
  aws s3 sync "s3://${bucket}/" "${project_path}/${docroot}/sites/default/files/" --region "$(aws_region "${project_path}")" || return 1 ;
  echo "  If Drupal still shows broken images: ddev drush cr";
}

function aws_do_push() {
  local project_path="$1" app="$2" env="$3" r label zip bucket key a;
  r="$(aws_region "${project_path}")";
  label="$(cd "${project_path}" && git rev-parse --short HEAD 2>/dev/null || date +%s)-$(date +%Y%m%d%H%M%S)";
  echo "Deploy ${doc_name}/${PROJECT_NAME} (${label}) → environment ${env} of application ${app} in ${r}";
  echo "  git archive HEAD → zip → the Beanstalk storage bucket → application version → update-environment. The live environment changes.";
  read -r -p "  Continue? [y/N] " a < /dev/tty || return 1 ;
  [[ "${a}" =~ ^[Yy] ]] || { echo "Not deployed."; return 1; } ;
  zip="$(mktemp -d)/${PROJECT_NAME}-${label}.zip";
  (cd "${project_path}" && git archive --format=zip -o "${zip}" HEAD) || { echo "git archive failed — the deploy ships the committed tree."; return 1; } ;
  bucket="$(aws elasticbeanstalk create-storage-location --region "${r}" --output text --query S3Bucket)" || return 1 ;
  key="${app}/${PROJECT_NAME}-${label}.zip";
  aws s3 cp "${zip}" "s3://${bucket}/${key}" --region "${r}" || return 1 ;
  aws elasticbeanstalk create-application-version --application-name "${app}" --version-label "${label}" --source-bundle "S3Bucket=${bucket},S3Key=${key}" --region "${r}" > /dev/null || return 1 ;
  aws elasticbeanstalk update-environment --application-name "${app}" --environment-name "${env}" --version-label "${label}" --region "${r}" > /dev/null || return 1 ;
  echo "  Version ${label} is deploying to ${env}. Follow it with --activities, or in the console.";
}

function aws_do_logs() {
  local project_path="$1" app="$2" env="$3" r url;
  [ -z "${env}" ] && { echo "Select an environment first (--select) to fetch its logs."; return 1; } ;
  r="$(aws_region "${project_path}")";
  aws elasticbeanstalk request-environment-info --environment-name "${env}" --info-type tail --region "${r}" > /dev/null || return 1 ;
  sleep 8 ;
  url="$(aws elasticbeanstalk retrieve-environment-info --environment-name "${env}" --info-type tail --region "${r}" --output text --query 'EnvironmentInfo[-1].Message')" || return 1 ;
  [ -n "${url}" ] && [ ! "${url}" == 'None' ] && curl -sS "${url}" | tail -200 || echo "  (no tail yet — run again in a moment)";
}

function aws_do_activities() {
  aws elasticbeanstalk describe-events --application-name "$2" --max-items 10 --region "$(aws_region "$1")" --output json 2>/dev/null | python3 -c 'import json,sys
for e in json.load(sys.stdin).get("Events",[])[:10]:
    print("  %-20s %-6s %-24s %s" % ((e.get("EventDate") or "")[:19], e.get("Severity",""), (e.get("EnvironmentName") or "")[:24], e.get("Message","")))' \
    || echo "  (could not list the events)" ;
}

function aws_status() {
  local project_path="$1" app="$2";
  if [ -z "${app}" ] ; then
    echo "    (find applications with: aws elasticbeanstalk describe-applications)";
    return 0 ;
  fi
  echo "    region:  $(aws_region "${project_path}")";
  echo "    files:   $(aws_link_get "${project_path}" files_bucket)";
  echo "";
  aws_do_environments "${project_path}" "${app}" ;
  echo "";
  echo "  Console: https://$(aws_region "${project_path}").console.aws.amazon.com/elasticbeanstalk/home#/application/overview?applicationName=${app}";
  echo "  --push deploys a version; --pull-files syncs the S3 files bucket; RDS is not pulled from here.";
}
