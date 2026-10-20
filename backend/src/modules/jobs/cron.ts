// Job trong tiến trình (ADR-04). MVP 1 instance: chưa lấy pg_try_advisory_lock.
import type { Ctx } from '../../context.js';
import { vnDay } from '../../shared/time.js';
import { prevMonth, runMonthlyReportJob } from '../reports/service.js';
import { applyPendingRemovals } from '../groups/service.js';

/** 06:00 giờ VN của ngày chạy lượt đầu (report_retry_deadline, BR-101). */
export function retryDeadline(firstRun: Date): number {
  const d = vnDay(firstRun);
  return Date.parse(`${d}T06:00:00Z`) - 7 * 3600e3;
}

/** monthly-report: sau 02:00 giờ VN (BR-56), chạy bù kỳ trước nếu job_runs chưa có lượt SUCCEEDED. */
export async function monthlyReportTick(ctx: Ctx, now = new Date()) {
  const vnHour = new Date(now.getTime() + 7 * 3600e3).getUTCHours();
  const thisMonth = vnDay(now).slice(0, 7);
  const isFirst = vnDay(now).endsWith('-01');
  if (isFirst && vnHour < 2) return null;
  const month = prevMonth(thisMonth);
  const done = await ctx.db.selectFrom('job_runs').select('id').where('job', '=', 'monthly-report').where('run_key', '=', month)
    .where('status', '=', 'SUCCEEDED').executeTakeFirst();
  if (done) return null;
  const tries = await ctx.db.selectFrom('job_runs').select(['id', 'started_at']).where('job', '=', 'monthly-report').where('run_key', '=', month)
    .orderBy('started_at', 'desc').execute();
  if (tries.length) {
    // BR-101: thử lại tối đa report_retry_max = 3 lần (tổng 4 lượt), cách nhau ≥ 1 giờ, KHÔNG quá 06:00 giờ VN của ngày
    // chạy lượt đầu (thường là 01). Lượt đầu chạy bù được bất cứ lúc nào; chỉ lượt THỬ LẠI bị chặn bởi 06:00 (giả định).
    if (tries.length > 3) return { month, results: [], skipped: 'RETRY_MAX' as const };
    if (now.getTime() >= retryDeadline(tries[tries.length - 1].started_at)) return { month, results: [], skipped: 'RETRY_DEADLINE' as const };
    if (now.getTime() - tries[0].started_at.getTime() < 3600e3) return null;
  }
  return runMonthlyReportJob(ctx, month);
}

export function startJobs(ctx: Ctx) {
  let running = false;
  let lastMonthly = 0;
  const tick = async () => {
    if (running) return;
    running = true;
    try {
      await ctx.sessions.loadDue(); // open-scheduled-sessions (DQ-03: 30 s + bộ hẹn giờ trong engine)
      await applyPendingRemovals(ctx); // BR-77: xóa thành viên chờ sau ends_at (dự phòng nếu bỏ lỡ lúc chốt phiên)
      if (ctx.cfg.monthlyReportCron && Date.now() - lastMonthly > 3600e3) {
        lastMonthly = Date.now();
        const r = await monthlyReportTick(ctx);
        if (r && 'skipped' in r) console.warn(`[jobs] monthly-report ${r.month}: dừng thử lại (${r.skipped}) — cần quản trị chạy tay (BR-101)`);
        else if (r) console.log(`[jobs] monthly-report ${r.month}: ${r.results.filter((x) => x.created).length} báo cáo mới`);
      }
    } catch (e) {
      console.error('[jobs] lỗi', e);
    } finally {
      running = false;
    }
  };
  void tick();
  const t = setInterval(tick, ctx.cfg.openSessionsIntervalMs);
  return () => clearInterval(t);
}
