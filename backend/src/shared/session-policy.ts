import { AppError } from './errors.js';

export const MIN_DURATION_MIN = 1;
export const MAX_DURATION_MIN = 240;
export function validateDuration(minutes: number): void {
  if (!Number.isInteger(minutes) || minutes < MIN_DURATION_MIN || minutes > MAX_DURATION_MIN) {
    throw new AppError(422, 'DURATION_OUT_OF_RANGE', 'Thời lượng từ 1 đến 240 phút');
  }
}

/** Preserve 25/50-minute rewards; shorter sessions scale down, longer ones cap. */
export function sessionReward(minutes: number, cfg: { coins25: number; coins50: number }): number {
  if (minutes <= 25) return Math.max(0, Math.floor(minutes * cfg.coins25 / 25));
  if (minutes >= 50) return cfg.coins50;
  return cfg.coins25 + Math.floor((minutes - 25) * (cfg.coins50 - cfg.coins25) / 25);
}
