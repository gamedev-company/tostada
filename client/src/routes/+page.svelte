<script lang="ts">
  import { onMount } from 'svelte';
  import { connectSocket, disconnectSocket, pingSocket, socketStatus, lastSocketError } from '$lib';

  let user: { email: string; display_name: string; is_admin: boolean } | null = null;
  let pingResult: Record<string, unknown> | null = null;
  let isLoading = false;

  async function loadUser() {
    const res = await fetch('/api/me', { credentials: 'include' });
    if (!res.ok) {
      user = null;
      return;
    }
    const data = await res.json();
    user = data.user;
  }

  async function handleConnect() {
    isLoading = true;
    try {
      await connectSocket();
    } finally {
      isLoading = false;
    }
  }

  async function handlePing() {
    pingResult = await pingSocket({ message: 'hello from svelte' });
  }

  onMount(() => {
    loadUser();
  });
</script>

<section class="mx-auto flex max-w-6xl flex-col gap-12 px-6 py-14">
  <div class="space-y-4">
    <p class="text-sm uppercase tracking-[0.35em] text-slate-400">SvelteKit Client</p>
    <h1 class="text-4xl font-semibold">Welcome to the Tostada app shell</h1>
    <p class="max-w-2xl text-slate-300">
      This is the minimal SvelteKit surface. It talks to Phoenix through the Vite dev proxy
      and authenticates sockets with `/api/socket-token` when cookies are blocked.
    </p>
  </div>

  <div class="grid gap-6 lg:grid-cols-2">
    <div class="rounded-2xl border border-slate-700/70 bg-slate-900/70 p-6">
      <h2 class="text-lg font-semibold">Session</h2>
      <p class="mt-2 text-sm text-slate-300">
        {#if user}
          Logged in as <span class="font-semibold text-amber-200">{user.display_name}</span>
          <span class="text-slate-400">({user.email})</span>
        {:else}
          Not authenticated. Log in on the Phoenix side and refresh.
        {/if}
      </p>
      <div class="mt-4 flex flex-wrap gap-3">
        <a
          class="rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-200 transition hover:border-slate-300"
          href="/users/log-in"
        >
          Log In
        </a>
        <a
          class="rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-200 transition hover:border-slate-300"
          href="/users/register"
        >
          Register
        </a>
      </div>
    </div>

    <div class="rounded-2xl border border-slate-700/70 bg-slate-900/70 p-6">
      <h2 class="text-lg font-semibold">Socket</h2>
      <p class="mt-2 text-sm text-slate-300">
        Status: <span class="font-semibold">{$socketStatus}</span>
      </p>
      {#if $lastSocketError}
        <p class="mt-2 text-sm text-rose-300">{$lastSocketError}</p>
      {/if}

      <div class="mt-4 flex flex-wrap gap-3">
        <button
          class="rounded-lg bg-amber-400 px-4 py-2 text-sm font-semibold text-slate-900 transition hover:bg-amber-300 disabled:opacity-60"
          on:click={handleConnect}
          disabled={isLoading}
        >
          {isLoading ? 'Connecting...' : 'Connect'}
        </button>
        <button
          class="rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-200 transition hover:border-slate-300"
          on:click={disconnectSocket}
        >
          Disconnect
        </button>
        <button
          class="rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-200 transition hover:border-slate-300"
          on:click={handlePing}
        >
          Ping
        </button>
      </div>

      {#if pingResult}
        <pre class="mt-4 rounded-xl bg-slate-950/70 p-3 text-xs text-slate-200">
{JSON.stringify(pingResult, null, 2)}
        </pre>
      {/if}
    </div>
  </div>
</section>
