/**
 * AWS Elastic Beanstalk, as a hosting provider.
 *
 * The link is `.aws/workspace.yml` (application name, region, files bucket); the environments come
 * from `aws elasticbeanstalk describe-environments` with the host profile or the access key from
 * plugin.aws.settings.yml; the deploy, the logs, the events and the files sync go through
 * cmd-tools-aws.sh in a screen session. No database pull: RDS is not reachable generically.
 */

import fs from 'fs';
import path from 'path';
import type { PluginApi, PluginLib } from '@webship.co/workspace-plugin-api';
import { configured, findCli } from '@webship.co/workspace-hosting';
import type { EnvInfo, EnvRow, HostingLink, HostingProvider } from '@webship.co/workspace-hosting';

import { awsLinkOf } from './link';

interface EbEnv { EnvironmentName: string; Status: string; Health?: string; CNAME?: string; EndpointURL?: string; VersionLabel?: string }

export function awsProvider(api: PluginApi): HostingProvider {
  const settings = () => api.settings.read() || {};
  const bin = () => findCli('aws') || 'aws';

  // Either the dashboard's own key, or the host's ~/.aws mounted into the container.
  const jobEnv = (): NodeJS.ProcessEnv | null => {
    const s = settings();
    const key = configured(s.access_key_id); const secret = configured(s.secret_access_key);
    const base: NodeJS.ProcessEnv = { ...process.env, AWS_DEFAULT_REGION: String(s.region || 'eu-west-1'), AWS_PAGER: '' };
    if (key && secret) return { ...base, AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret };
    const profile = String(s.profile || 'default');
    const creds = path.join(process.env.HOME || '', '.aws', 'credentials');
    const config = path.join(process.env.HOME || '', '.aws', 'config');
    if (fs.existsSync(creds) || fs.existsSync(config)) return { ...base, AWS_PROFILE: profile };
    return null;
  };

  async function environments(link: HostingLink, lib: PluginLib, env: NodeJS.ProcessEnv): Promise<EnvInfo> {
    const id = link.id as string;
    const region = ((link as any).fields && (link as any).fields.region) || env.AWS_DEFAULT_REGION;
    const out = await lib.run(bin(), ['elasticbeanstalk', 'describe-environments', '--application-name', id, '--no-include-deleted', '--region', String(region), '--output', 'json'],
      process.env.HOME, { timeoutMs: 60 * 1000, env });
    if (!out.ok) return { id, rows: [], why: 'list failed' };
    let list: EbEnv[] = [];
    try { list = JSON.parse(String(out.stdout)).Environments || []; } catch (_) { return { id, rows: [], why: 'list failed' }; }
    const rows: EnvRow[] = list.map((e) => ({
      title: `${e.EnvironmentName}${e.Health ? ` (${e.Health.toLowerCase()})` : ''}`,
      envId: e.EnvironmentName,
      status: /^ready$/i.test(e.Status) ? 'active' : String(e.Status || 'unknown').toLowerCase(),
      url: e.CNAME ? `http://${e.CNAME}` : (e.EndpointURL ? `http://${e.EndpointURL}` : undefined),
    }));
    return { id, rows };
  }

  return {
    id: 'aws',
    label: 'AWS',
    title: 'AWS',
    cli: 'aws',
    script: 'cmd-tools-aws.sh',
    detect: (projectDir) => awsLinkOf(projectDir),
    linkHint: (project) => `bash cmd-tools-aws.sh ${project} --link <beanstalk-application> --region <region>`,
    consoleUrl: (link) => {
      if (!link.id) return null;
      const region = ((link as any).fields && (link as any).fields.region) || String(settings().region || 'eu-west-1');
      return `https://${region}.console.aws.amazon.com/elasticbeanstalk/home?region=${region}#/application/overview?applicationName=${encodeURIComponent(link.id)}`;
    },
    jobEnv,
    tokenHint: 'the host ~/.aws profile, or access_key_id and secret_access_key in core/config/plugin.aws.settings.yml',
    environments,
    tools: {
      status: { verb: 'aws', label: 'Link and environments', icon: 'info', args: [] },
      activities: { verb: 'aws-activities', label: 'Last 10 events', icon: 'list', args: ['--activities'] },
      logs: { verb: 'aws-logs', label: 'Tail logs of the environment', icon: 'file-text', args: ['--logs'] },
      deploy: { verb: 'aws-push', label: 'Deploy a version (zip → Beanstalk)…', icon: 'push', args: ['--push'] },
    },
    pull: {
      db: false, files: true,
      dbArgs: () => [],
      filesArgs: (e) => ['--environment', e, '--pull-files'],
    },
    errorHint: (msg) => (/InvalidClientTokenId|SignatureDoesNotMatch|Unable to locate credentials|ExpiredToken/i.test(msg)
      ? `${msg}\n\nThe dashboard reaches AWS with the host's ~/.aws profile (mounted) or access_key_id and secret_access_key in core/config/plugin.aws.settings.yml.`
      : msg),
    folder: {
      idPattern: /^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$/,
      idPlaceholder: 'webship-demo',
      idHelp: 'An Elastic Beanstalk application name: letters, digits, spaces, dots, dashes and underscores, up to 100 characters.',
    },
    menuNote: 'RDS is not pulled from here (no --pull-db); files come from the S3 bucket named with --files-bucket',
  };
}
