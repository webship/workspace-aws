---
name: aws-hosting
description: Work with a Webship Workspace site on AWS through the AWS plugin (`@webship.co/workspace-aws`) — the AWS menu of a project row and the command behind every entry, `cmd-tools-aws.sh`, with each of its options, how a project is linked, the keys of `plugin.aws.settings.yml` and the credential they hold, and what the command says when something is missing. Use when asked "is this site linked to AWS", "link this project", "list the environments", "what was deployed last", "deploy this site", "the menu says not linked", or "where does the AWS token go".
argument-hint: '<project>'
---

# aws-hosting

AWS for a site of a Webship Workspace (`~/workspace`, container-based, DDEV by default). It comes
with the AWS plugin (`@webship.co/workspace-aws`), a provider of the hosting family (`@webship.co/workspace-hosting`),
like the agent `aws-deployer`, the command `/aws-status` and the prompt `aws-test-then-deploy`.

## The AWS menu

The AWS menu is on the project rows of the sites folders. The caption beside it says `linked`
or `not linked`. A project that is not linked is shown how to link it; a linked one gets these
entries, and each of them runs the command of the plugin in a terminal session, from the sites
folder:

| Menu entry | The command |
| --- | --- |
| **Link and environments** | `bash cmd-tools-aws.sh <project>` |
| **Last 10 events** | `bash cmd-tools-aws.sh <project> --activities` |
| **Tail logs of the environment** | `bash cmd-tools-aws.sh <project> --logs` |
| **Deploy a version (zip → Beanstalk)…** | `bash cmd-tools-aws.sh <project> --push` |

The menu ends with the note "RDS is not pulled from here (no --pull-db); files come from the S3 bucket named with --files-bucket".

### Get the live data

The menu also offers to get the database and the files of an environment into the local site. From a terminal:

| What | The command | What it does |
| --- | --- | --- |
| The files | `bash cmd-tools-aws.sh <project> --environment <environment> --pull-files` | aws s3 sync the files bucket into the local docroot's sites/default/files (adds and overwrites, never deletes). Client data. |

## The command

`cmd-tools-aws.sh` is placed in every sites folder of the workspace. The first word after it is the
project; with nothing else it says whether the project is linked, and to what.

```bash
cd ~/workspace/<folder>
bash cmd-tools-aws.sh <project>
bash cmd-tools-aws.sh <project> --link <beanstalk-application> --region <region>
bash cmd-tools-aws.sh <project> --environments
```

| Option | What it does |
| --- | --- |
| `--link <value>` | Link the project to an Elastic Beanstalk application by name (aws elasticbeanstalk describe-applications). Add --region to pin its region. |
| `--region <value>` | The region of the application, remembered by --link. Default: the plugin's setting. |
| `--files-bucket <value>` | Remember the S3 bucket (and optional prefix: bucket/prefix) --pull-files syncs the public files from. |
| `--push` | Deploy: zip the current code (git archive), upload it to the Beanstalk storage bucket, create an application version and update the selected environment to it. Outward-facing: asks before updating. |
| `--environment <value>` | Environment for THIS run: the --push target, the --logs and --pull-files source. Default: the one remembered by --select. |
| `--environments` | List the application's environments with their status, health and URL. |
| `--select <value>` | Remember which environment this project works against (in .aws/workspace.yml, git-excluded). Checked against the real list. |
| `--pull-files` | aws s3 sync the files bucket into the local docroot's sites/default/files (adds and overwrites, never deletes). Client data. |
| `--logs` | Fetch the selected environment's tail logs (request-environment-info tail, then retrieve). |
| `--activities` | List the application's last 10 events. |
| `--force` | Allow --link to relink a project that already points at a different application. |

With no project the command says that `PROJECT_NAME` is required; with a project that is not in
the folder, "No such project"; with an option that needs a link on a project that has none, "Not
linked to AWS".

## Link a project

A project is linked to an Elastic Beanstalk application by its name, with its region. The link is written to `.aws/workspace.yml` in the project, which git does not track. An Elastic Beanstalk application name: letters, digits, spaces, dots, dashes and underscores, up to 100 characters.

```bash
bash cmd-tools-aws.sh <project> --link <beanstalk-application> --region <region>
```

## The settings: `core/config/plugin.aws.settings.yml`

| Key | What it is |
| --- | --- |
| `profile:` | The named profile in ~/.aws (mounted from the host) the dashboard and the tool use. Ignored when an access key is set below. |
| `region:` | The region the applications live in, unless the project's link says otherwise. |
| `access_key_id:` | An IAM access key for the dashboard (optional when the host profile is mounted). Read by the CLI as AWS_ACCESS_KEY_ID. |
| `secret_access_key:` | The secret of that key. Read by the CLI as AWS_SECRET_ACCESS_KEY. |

The dashboard reaches AWS with the host ~/.aws profile, or access_key_id and secret_access_key in core/config/plugin.aws.settings.yml. The file is created mode 600 and its secrets are
masked on the Settings page. Never print them, never copy them into another file, and never commit
the file.

## Turn it on, and check it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-aws
bash core/scripts/plugins.sh --activate aws --with-needs     # adds a sites folder and the AI folders when they are missing
bash core/scripts/plugins.sh --install aws
bash core/scripts/plugins.sh --configure aws
bash core/scripts/plugins.sh --check aws                     # the commands it needs on the machine
```

## Traps

- **"Unable to locate credentials", "InvalidClientTokenId", "ExpiredToken"**: the dashboard reaches AWS with the profile of the machine's `~/.aws` (`profile:`), or with `access_key_id:` and `secret_access_key:` when they are set.
- **No database pull**: the database of an application (RDS) is not reached from here, and the command has no `--pull-db`.
- **The files pull needs a bucket**: name it once with `--files-bucket` (a bucket, or `bucket/prefix`); it is synced into `sites/default/files` of the local docroot, adding and overwriting, never deleting.
- **A deploy is a new application version**: the current code is zipped with `git archive`, uploaded to the storage bucket of Beanstalk, and the selected environment is updated to it. What is not committed is not in it. It asks before it updates.
- **The region** is the one remembered by `--link --region`, else `region:`.
- **A deploy is outward-facing.** The command asks before it sends anything, in a terminal: it is
  not a step for an AI assistant to take on its own.

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
