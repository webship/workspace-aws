# @webship.co/workspace-aws

AWS for the [Webship Workspace](https://github.com/webship/workspace) dashboard: the **AWS**
menu on every site row, a live-site chip on the project card, "Link to AWS" when a new folder is
made, and the `cmd-tools-aws.sh` command in every site workspace. A provider of
[`@webship.co/workspace-hosting`](https://github.com/webship/workspace-hosting), which draws the menu,
the environments modal, the get-database-and-files flow and the New-folder section for every host.

Elastic Beanstalk is the AWS product that has environments the way the family understands them: an application with named environments, each with a URL, a status and a health. A deploy zips the code, uploads it to the Beanstalk bucket, creates an application version and updates the environment. The database (RDS) is not reachable generically from a laptop, so there is no `--pull-db`; the public files come from an S3 bucket named once with `--files-bucket`.

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-aws
bash core/scripts/plugins.sh --activate aws
bash core/scripts/plugins.sh --install aws
bash core/scripts/plugins.sh --configure aws      # core/config/plugin.aws.settings.yml
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page.

## The command

```bash
cd ~/workspace/dev
bash cmd-tools-aws.sh <project> [verb]
```

| Verb | What it does |
| --- | --- |
| `--link` <value> | Link the project to an Elastic Beanstalk application by name (aws elasticbeanstalk describe-applications). Add --region to pin its region. |
| `--region` <value> | The region of the application, remembered by --link. Default: the plugin's setting. |
| `--files-bucket` <value> | Remember the S3 bucket (and optional prefix: bucket/prefix) --pull-files syncs the public files from. |
| `--push` | Deploy: zip the current code (git archive), upload it to the Beanstalk storage bucket, create an application version and update the selected environment to it. Outward-facing: asks before updating. |
| `--environment` <value> | Environment for THIS run: the --push target, the --logs and --pull-files source. Default: the one remembered by --select. |
| `--environments` | List the application's environments with their status, health and URL. |
| `--select` <value> | Remember which environment this project works against (in .aws/workspace.yml, git-excluded). Checked against the real list. |
| `--pull-files` | aws s3 sync the files bucket into the local docroot's sites/default/files (adds and overwrites, never deletes). Client data. |
| `--logs` | Fetch the selected environment's tail logs (request-environment-info tail, then retrieve). |
| `--activities` | List the application's last 10 events. |
| `--force` | Allow --link to relink a project that already points at a different application. |

The link lives in the project's `.aws/workspace.yml` (git-excluded); the dashboard reads it to know
the project is linked and which environment it works against.

## What the package holds

| Path | What it is |
| --- | --- |
| `src/index.ts` | `register(api)`: `registerHosting(api, awsProvider(api))` |
| `src/lib/provider.ts` | The AWS provider: the credentials, the environments and their URLs, the verbs, the pulls, the console |
| `src/lib/link.ts` | The link file reader |
| `commands/cmd-tools-aws.sh` | The per-workspace command |
| `scripts/functions/fun-aws.sh` | The provider's bash hooks (aws) |
| `scripts/functions/fun-aws-tool.sh` | The family's dispatcher: link file, environment selection, safety export, status |
| `scripts/args/arg-aws.sh` | Its argparse |
| `scripts/host-install.sh` | The host side: the CLI and the credential check |
| `config/plugin.aws.settings.yml` | The settings template |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
