#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The project directory in this workspace.')
parser.add_argument('-l', '--link',
                    default="_none_",
                    help='Link the project to an Elastic Beanstalk application by name (aws elasticbeanstalk describe-applications). Add --region to pin its region.')
parser.add_argument('-r', '--region',
                    default="_none_",
                    help='The region of the application, remembered by --link. Default: the plugin's setting.')
parser.add_argument('-b', '--files-bucket',
                    default="_none_",
                    help='Remember the S3 bucket (and optional prefix: bucket/prefix) --pull-files syncs the public files from.')
parser.add_argument('-p', '--push',
                    action='store_true',
                    default=False,
                    help='Deploy: zip the current code (git archive), upload it to the Beanstalk storage bucket, create an application version and update the selected environment to it. Outward-facing: asks before updating.')
parser.add_argument('-e', '--environment',
                    default="_none_",
                    help='Environment for THIS run: the --push target, the --logs and --pull-files source. Default: the one remembered by --select.')
parser.add_argument('-E', '--environments',
                    action='store_true',
                    default=False,
                    help='List the application's environments with their status, health and URL.')
parser.add_argument('-s', '--select',
                    default="_none_",
                    help='Remember which environment this project works against (in .aws/workspace.yml, git-excluded). Checked against the real list.')
parser.add_argument('-F', '--pull-files',
                    action='store_true',
                    default=False,
                    help='aws s3 sync the files bucket into the local docroot's sites/default/files (adds and overwrites, never deletes). Client data.')
parser.add_argument('-g', '--logs',
                    action='store_true',
                    default=False,
                    help='Fetch the selected environment's tail logs (request-environment-info tail, then retrieve).')
parser.add_argument('-a', '--activities',
                    action='store_true',
                    default=False,
                    help='List the application's last 10 events.')
parser.add_argument('-f', '--force',
                    action='store_true',
                    default=False,
                    help='Allow --link to relink a project that already points at a different application.')
ARGEOF
