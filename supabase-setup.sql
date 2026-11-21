-- Run once in Supabase: SQL Editor -> New query -> Run
create table attempts(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  name text, std text, place text,
  started_at timestamptz default now(),
  last_seen timestamptz default now(),
  status text default 'running',
  current_q int default 0, answered int default 0,
  warn_y int default 0, warn_o int default 0, warn_r int default 0,
  answers jsonb, score int, finished_at timestamptz);
create table questions_key(qno int primary key, answer int, marks int);
create table admins(user_id uuid primary key);

alter table attempts enable row level security;
alter table questions_key enable row level security;
alter table admins enable row level security;

create function is_admin() returns boolean language sql security definer
set search_path=public as $$ select exists(select 1 from admins where user_id=auth.uid()) $$;
create policy "admin read" on attempts for select using (is_admin());
alter publication supabase_realtime add table attempts;

-- Answer key (0=A,1=B,2=C,3=D). Q1-25 = 1 mark, Q26-35 = 2 marks
insert into questions_key
select i,(array[0,2,0,2,3,2,1,0,2,0,3,3,3,2,0,2,1,1,2,1,1,0,3,1,3,2,0,3,3,1,0,1,3,2,1])[i],
case when i<=25 then 1 else 2 end from generate_series(1,35) i;

create function start_attempt(p_name text,p_std text,p_place text) returns uuid
language plpgsql security definer set search_path=public as $$
declare v uuid; begin
 insert into attempts(user_id,name,std,place,answers)
 values(auth.uid(),left(p_name,60),left(p_std,20),left(p_place,60),to_jsonb(array_fill(-1,array[35]))) returning id into v;
 return v; end $$;

create function save_progress(p_id uuid,p_answers jsonb,p_cur int,p_y int,p_o int,p_r int)
returns void language sql security definer set search_path=public as $$
 update attempts set answers=p_answers,current_q=p_cur,warn_y=p_y,warn_o=p_o,warn_r=p_r,last_seen=now(),
  answered=(select count(*) from jsonb_array_elements_text(p_answers) x where x::int>=0)
 where id=p_id and user_id=auth.uid() and status='running' and now()<started_at+interval '62 minutes' $$;

create function submit_attempt(p_id uuid) returns jsonb
language plpgsql security definer set search_path=public as $$
declare a attempts; s int; begin
 select * into a from attempts where id=p_id and user_id=auth.uid();
 if not found then raise exception 'not allowed'; end if;
 if a.status<>'done' then
  select coalesce(sum(k.marks),0) into s from questions_key k where (a.answers->>(k.qno-1))::int=k.answer;
  update attempts set status='done',score=s,finished_at=now() where id=p_id;
 else s:=a.score; end if;
 return jsonb_build_object('score',s,'key',(select jsonb_agg(answer order by qno) from questions_key));
end $$;

-- After creating a teacher user (Authentication -> Users -> Add user), run:
-- insert into admins values ('PASTE-TEACHER-UID-HERE');
