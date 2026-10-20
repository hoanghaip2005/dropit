// "Ngày" nghiệp vụ theo Asia/Ho_Chi_Minh (UTC+7, không DST) — BR-55, NFR-21.
const VN_OFFSET_MS = 7 * 3600 * 1000;
export function vnDay(d: Date): string {
  return new Date(d.getTime() + VN_OFFSET_MS).toISOString().slice(0, 10);
}
export const iso = (d: Date | number | null | undefined) =>
  d === null || d === undefined ? null : new Date(d).toISOString();
