import { describe, it, expect } from 'vitest';
import { SessionManager } from '../../src/modules/sessions/manager.js';
import type { Ctx } from '../../src/context.js';

describe('session loading after cancellation', () => {
  it('blocks new loads throughout mutation and releases on rollback/commit', async () => {
    let loads = 0;
    const query = {
      select() { return this; }, where() { return this; }, innerJoin() { return this; },
      async execute() { return [{ id: 's', started_at: new Date(Date.now() + 60000) }]; },
      async executeTakeFirstOrThrow() { loads++; return { id: 's', status: 'CANCELLED' }; },
    };
    const manager = new SessionManager({
      db: { selectFrom: () => query }, cfg: { engine: { lobbyOpenMs: 60000 }, openSessionsIntervalMs: 100 },
    } as unknown as Ctx);
    const release = manager.suspendLoading(['s']);
    manager.cancelLoaded('s');
    await manager.loadDue();
    expect(loads).toBe(0);
    release();
    await manager.loadDue();
    expect(loads).toBe(1);
    expect(manager.runtimes.size).toBe(0);
  });
  for (const operation of ['cancel', 'reschedule', 'terminal'] as const) {
    it(`does not install stale runtime: ${operation}`, async () => {
      let release!: (row: object) => void;
      const snapshot = new Promise<object>(resolve => { release = resolve; });
      let fetched!: () => void;
      const started = new Promise<void>(resolve => { fetched = resolve; });
      const query = {
        select() { return this; }, where() { return this; }, innerJoin() { return this; },
        async execute() { return [{ id: 's', started_at: new Date(Date.now() + 60000) }]; },
        executeTakeFirstOrThrow() { fetched(); return snapshot; },
      };
      const ctx = {
        db: { selectFrom: () => query },
        cfg: { engine: { lobbyOpenMs: 60000 }, openSessionsIntervalMs: 100 },
      } as unknown as Ctx;
      const manager = new SessionManager(ctx);
      const loading = manager.loadDue();
      await started;
      if (operation === 'cancel') manager.cancelLoaded('s');
      if (operation === 'reschedule') manager.unloadForReschedule('s');
      release({ id: 's', status: operation === 'terminal' ? 'CANCELLED' : 'SCHEDULED' });
      await loading;
      expect(manager.runtimes.size).toBe(0);
    });
  }
});
