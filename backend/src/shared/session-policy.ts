import { AppError } from './errors.js';

export const ALLOWED_DURATION_MIN = [25, 50] as const;
export function validateDuration(minutes: number): void {
  if (!ALLOWED_DURATION_MIN.some((duration) => duration === minutes)) {
    throw new AppError(422, 'DURATION_OUT_OF_RANGE', 'Thời lượng chỉ có thể là 25 hoặc 50 phút');
  }
}

/** Preserve 25/50-minute rewards; shorter sessions scale down, longer ones cap. */
export function sessionReward(minutes: number, cfg: { coins25: number; coins50: number }): number {
  if (minutes <= 25) return Math.max(0, Math.floor(minutes * cfg.coins25 / 25));
  if (minutes >= 50) return cfg.coins50;
  return cfg.coins25 + Math.floor((minutes - 25) * (cfg.coins50 - cfg.coins25) / 25);
}
