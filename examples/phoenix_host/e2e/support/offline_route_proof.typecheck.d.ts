declare module 'node:fs' {
  export function mkdirSync(path: string, options?: { recursive?: boolean }): void;
  export function readFileSync(path: string, encoding: string): string;
}

declare module 'node:path' {
  const path: { join(...paths: string[]): string };
  export default path;
}

declare const process: { cwd(): string };

interface Window {
  liveSocket?: unknown;
}
