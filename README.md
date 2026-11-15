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

## The items it carries

The workspace is container-based (DDEV by default). Each item lands in the folder of its kind, when
that folder is an active workspace folder, is listed there like any other item, and is installed
into Claude Code from there:

| What | Lands in | What it is for |
| --- | --- | --- |
| The agent `aws-deployer` | `ai-agents/` | Says whether a site is linked to AWS and to what, reads its environments and its log, brings the live data here when asked, tests it before a deploy, and hands over the deploy line |
| The skill `aws-hosting` | `ai-skills/` | Every entry of the AWS menu and the command behind it, each option of `cmd-tools-aws.sh`, the link, the keys of `plugin.aws.settings.yml` |
| The command `/aws-status` | `ai-commands/` | `/aws-status <project>`: the link and the environments. Read-only |
| The prompt `aws-test-then-deploy` | `ai-prompts/` | The launch command of a session that checks a site, runs its webship-js suite when it has one, and gives the deploy line |

The plugin keeps its one command, `cmd-tools-aws.sh`; no other was added. The item bodies are plain Markdown any AI command-line assistant can follow; Claude Code is the default shape (frontmatter, the launch command of the prompt). A site that carries a webship-js suite is tested by the workspace's own `cmd-tools-testing.sh <project> --run` before a deploy, when it is there.

How the items are laid out and checked: [docs/plugin-items-pattern.md](docs/plugin-items-pattern.md).

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder: `dev`, `test`, `demos`, `sandboxes`, `projects` (`dev` is the one added when none is there). `cmd-tools-aws.sh`, which the menu's verbs run, is placed in it, and the menu is on its project rows.
- on the machine: `aws`, the provider's CLI (https://docs.aws.amazon.com/cli/).

`--require` says so, `--activate` and `--install` stop until the workspace has a sites folder, and `--with-needs` adds it first. A missing command is said and never added:

```bash
bash core/scripts/plugins.sh --activate aws --with-needs
bash core/scripts/plugins.sh --check aws      # each command: found, with its version, or missing, with how to install it
```

A workspace that knows none of this (Webship Workspace 1.0.8 and older) ignores the keys: add a sites folder yourself, then `--install aws` again.

It also needs the AI folders its items are placed in (`needs.plugins`): `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`, beside the sites folder. `--with-needs` adds what is missing first. A kind whose folder is not an active workspace folder is skipped, and the install says so.

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
| `ai/agents/aws-deployer.md` | The agent `aws-deployer` |
| `ai/skills/aws-hosting/` | The skill `aws-hosting` |
| `ai/commands/aws-status.md` | The command `/aws-status` |
| `ai/prompts/aws-test-then-deploy.md` | The prompt `aws-test-then-deploy` |
| `tests/items.test.ts` | The shape of every item, and that it names nothing the plugin does not have |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
