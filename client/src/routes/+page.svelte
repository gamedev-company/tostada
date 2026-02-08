<script lang="ts">
  import { Canvas } from '@threlte/core';
  import Scene from './Scene.svelte';
</script>

<div class="scene">
  <Canvas>
    <Scene />
  </Canvas>

  <nav class="auth-nav">
    <a href="/users/log-in" aria-label="Log in">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
        <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
        <path d="M10 17l5-5-5-5" />
        <path d="M15 12H3" />
      </svg>
    </a>
    <a href="/users/register" aria-label="Register">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M19 8v6" />
        <path d="M22 11h-6" />
      </svg>
    </a>
  </nav>
</div>

<style>
  .scene {
    position: fixed;
    inset: 0;
    background: #050505;
  }

  :global(canvas) {
    display: block;
    width: 100%;
    height: 100%;
  }

  .auth-nav {
    position: absolute;
    top: 24px;
    right: 24px;
    display: flex;
    gap: 12px;
    z-index: 10;
  }

  .auth-nav a {
    width: 40px;
    height: 40px;
    border-radius: 999px;
    display: grid;
    place-items: center;
    color: #e2e8f0;
    border: 1px solid rgba(148, 163, 184, 0.35);
    background: rgba(15, 23, 42, 0.6);
    transition: border-color 150ms ease, color 150ms ease, transform 150ms ease;
  }

  .auth-nav a:hover {
    color: #f8fafc;
    border-color: rgba(226, 232, 240, 0.9);
    transform: translateY(-1px);
  }

  .auth-nav svg {
    width: 18px;
    height: 18px;
  }
</style>
