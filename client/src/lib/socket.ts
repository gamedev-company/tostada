import { Socket, type Channel } from 'phoenix';
import { writable } from 'svelte/store';

export type SocketStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export const socketStatus = writable<SocketStatus>('disconnected');
export const lastSocketError = writable<string | null>(null);

let socket: Socket | null = null;
let channel: Channel | null = null;

export async function connectSocket(): Promise<void> {
  socketStatus.set('connecting');
  lastSocketError.set(null);

  const socketToken = await fetchSocketToken();
  const wsUrl = resolveWsUrl();

  socket = new Socket(wsUrl, {
    params: socketToken ? { token: socketToken } : {},
  });

  socket.onOpen(() => socketStatus.set('connected'));
  socket.onClose(() => socketStatus.set('disconnected'));
  socket.onError(() => {
    socketStatus.set('error');
    lastSocketError.set('Socket connection error');
  });

  socket.connect();

  channel = socket.channel('app:lobby', {});

  await new Promise<void>((resolve, reject) => {
    channel
      ?.join()
      .receive('ok', () => resolve())
      .receive('error', (err: Record<string, unknown>) => {
        lastSocketError.set((err?.reason as string) ?? 'Join failed');
        reject(err);
      });
  });
}

export function disconnectSocket(): void {
  channel?.leave();
  channel = null;
  socket?.disconnect();
  socket = null;
  socketStatus.set('disconnected');
}

export async function pingSocket(payload: Record<string, unknown> = {}): Promise<Record<string, unknown>> {
  if (!channel) {
    throw new Error('Socket channel not connected');
  }

  return new Promise((resolve, reject) => {
    channel
      ?.push('ping', payload, 5000)
      .receive('ok', (resp: Record<string, unknown>) => resolve(resp))
      .receive('error', (err: Record<string, unknown>) => reject(err));
  });
}

async function fetchSocketToken(): Promise<string | null> {
  try {
    const response = await fetch('/api/socket-token', { credentials: 'include' });
    if (!response.ok) return null;
    const data = await response.json();
    return data?.token ?? null;
  } catch (_err) {
    return null;
  }
}

function resolveWsUrl(): string {
  const envUrl = import.meta.env.VITE_WS_URL;

  if (!envUrl) {
    return defaultWsUrl();
  }

  if (import.meta.env.DEV) {
    return envUrl;
  }

  if (isLocalNetworkUrl(envUrl)) {
    return defaultWsUrl();
  }

  return envUrl;
}

function defaultWsUrl(): string {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.host;
  return `${protocol}//${host}/socket`;
}

function isLocalNetworkUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();

    if (host === 'localhost' || host === '127.0.0.1' || host === '::1') return true;
    if (host.endsWith('.local') || host.endsWith('.lan')) return true;
    if (host.startsWith('10.')) return true;
    if (host.startsWith('192.168.')) return true;

    if (host.startsWith('172.')) {
      const parts = host.split('.');
      const second = Number(parts[1]);
      return second >= 16 && second <= 31;
    }

    return false;
  } catch (_err) {
    return false;
  }
}
