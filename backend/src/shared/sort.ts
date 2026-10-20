// BR-115: sắp người theo display_name (vi, không phân biệt hoa thường), rồi joined_at, rồi user_id.
const coll = new Intl.Collator('vi', { sensitivity: 'base' });
export function sortPeople<T extends { display_name: string; joined_at?: string | Date | null; user_id?: string }>(xs: T[]): T[] {
  return [...xs].sort((a, b) => {
    const c = coll.compare(a.display_name, b.display_name);
    if (c) return c;
    const ja = a.joined_at ? new Date(a.joined_at).getTime() : 0;
    const jb = b.joined_at ? new Date(b.joined_at).getTime() : 0;
    if (ja !== jb) return ja - jb;
    return String(a.user_id ?? '').localeCompare(String(b.user_id ?? ''));
  });
}
