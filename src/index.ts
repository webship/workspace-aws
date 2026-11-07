/**
 * AWS for Webship Workspace.
 *
 * The AWS menu on every site row, a live-site chip, the New-folder link option and the
 * `/aws-site/<workspace>/<project>` jump: all of it is the hosting family's surface
 * (@webship/workspace-hosting). This package is the AWS provider plus what the installer places
 * (the per-workspace command, its bash functions, the settings template, the host install).
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from
 * the dashboard's own files.
 */

import type { PluginApi } from '@webship/workspace-plugin-api';
import { registerHosting } from '@webship/workspace-hosting';

import { awsProvider } from './lib/provider';

export { awsProvider };
export { awsLinkOf } from './lib/link';

export function register(api: PluginApi): void {
  registerHosting(api, awsProvider(api));
}
