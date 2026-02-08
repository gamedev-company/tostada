declare module 'phoenix' {
  export class Socket {
    constructor(url: string, opts?: { params?: Record<string, string> });
    connect(): void;
    disconnect(): void;
    onOpen(callback: () => void): void;
    onClose(callback: () => void): void;
    onError(callback: (error: unknown) => void): void;
    channel(topic: string, params?: Record<string, unknown>): Channel;
  }

  export class Channel {
    join(): Push;
    leave(): Push;
    push(event: string, payload?: Record<string, unknown>, timeout?: number): Push;
    on(event: string, callback: (payload: Record<string, unknown>) => void): void;
  }

  export class Push {
    receive(status: string, callback: (response: Record<string, unknown>) => void): Push;
  }
}
