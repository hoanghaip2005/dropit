import { describe, expect, it } from 'vitest';
import { sessionReward, validateDuration } from '../../src/shared/session-policy.js';

describe('BR-02 fixed session duration policy', () => {
  it('accepts only 25 or 50 integer minutes', () => {
    for (const duration of [25, 50]) expect(() => validateDuration(duration)).not.toThrow();
    for (const duration of [0, 1, 17, 30, 240, 241, -1, 1.5, NaN, Infinity]) {
      expect(() => validateDuration(duration)).toThrow();
    }
  });
  it('preserves legacy rewards without short-session reward inflation', () => {
    const cfg = { coins25: 10, coins50: 25 };
    expect([1, 2, 5, 17, 25, 30, 49, 50, 240].map((duration) => sessionReward(duration, cfg)))
      .toEqual([0, 0, 2, 6, 10, 13, 24, 25, 25]);
  });
});
