// Con trỏ mờ (P8): base64url của "created_at|id".
export const encodeCursor = (t: Date, id: string) => Buffer.from(`${t.toISOString()}|${id}`).toString('base64url');
export function decodeCursor(c?: string): { t: Date; id: string } | null {
  if (!c) return null;
  const [t, id] = Buffer.from(c, 'base64url').toString().split('|');
  const d = new Date(t);
  return isNaN(d.getTime()) || !id ? null : { t: d, id };
}
