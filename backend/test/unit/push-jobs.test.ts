import { afterEach, describe, expect, it, vi } from 'vitest';
import { startJobs } from '../../src/modules/jobs/cron.js';
import type { Ctx } from '../../src/context.js';

vi.mock('../../src/modules/groups/service.js', () => ({ applyPendingRemovals: vi.fn(async () => {}) }));

describe('push worker scheduling', () => {
  afterEach(() => vi.useRealTimers());
  it('does not block domain ticks and drains a single in-flight worker on shutdown', async () => {
    vi.useFakeTimers();
    let finish!: () => void;
    const pending = new Promise<void>(resolve => { finish = resolve; });
    const loadDue = vi.fn(async () => {});
    const flushPush = vi.fn(() => pending);
    const ctx = { cfg: { openSessionsIntervalMs: 100, monthlyReportCron: false },
      sessions: { loadDue }, notifications: { flushPush } } as unknown as Ctx;
    const stop = startJobs(ctx);
    await vi.advanceTimersByTimeAsync(300);
    expect(loadDue.mock.calls.length).toBeGreaterThan(1);
    expect(flushPush).toHaveBeenCalledTimes(1);
    let stopped = false;
    const closing = stop().then(() => { stopped = true; });
    await Promise.resolve();
    expect(stopped).toBe(false);
    finish(); await closing;
    expect(stopped).toBe(true);
    const calls = loadDue.mock.calls.length;
    await vi.advanceTimersByTimeAsync(500);
    expect(loadDue).toHaveBeenCalledTimes(calls);
    expect(flushPush).toHaveBeenCalledTimes(1);
  });
});
