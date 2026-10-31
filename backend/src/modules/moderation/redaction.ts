import type { DB } from '../../shared/db.js';
/** Redact authored text at delivery time; never mutate attendance IDs or amounts. */
export async function redactBlockedText<T>(db: DB, viewer: string, payload: T): Promise<T> {
  const rows = await db.selectFrom('user_blocks').innerJoin('users', (j) => j.on((eb) => eb.or([
    eb.and([eb('user_blocks.blocker_id','=',viewer), eb('users.id','=',eb.ref('user_blocks.blocked_id'))]),
    eb.and([eb('user_blocks.blocked_id','=',viewer), eb('users.id','=',eb.ref('user_blocks.blocker_id'))]),
  ]))).select(['users.id','users.display_name']).execute();
  if (!rows.length) return payload;
  const ids=rows.map(r=>r.id);
  const groups=await db.selectFrom('groups').select('name').where('owner_id','in',ids).execute();
  const names=new Set([...rows.map(r=>r.display_name),...groups.map(g=>g.name)].filter(Boolean));
  const visit=(value:unknown,key=''):unknown => {
    if (typeof value === 'string') {
      // IDs, enums, timestamps and URL keys are preserved. Only authored text fields are changed.
      if (!/(name|title|body|reason|lobby_members)/.test(key)) return value;
      let result=value; for(const name of names) result=result.split(name).join('Nội dung đã ẩn'); return result;
    }
    if(Array.isArray(value)) return value.map(v=>visit(v,key));
    if(value && typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,visit(v,k)]));
    return value;
  };
  return visit(payload) as T;
}
