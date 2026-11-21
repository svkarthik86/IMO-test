# IPA Maths Olympiad – Grade 3 (Student exam + Teacher dashboard)

Files: `index.html` (student exam) · `admin.html` (teacher live dashboard) · `config.js` (your Supabase keys) · `supabase-setup.sql` (database)

## Setup (about 20 minutes)
1. Create a free project at https://supabase.com (note Project URL and anon public key: Project Settings -> API).
2. Authentication -> Sign In / Providers: enable **Allow anonymous sign-ins**; turn OFF public email sign-ups.
3. SQL Editor -> New query -> paste all of `supabase-setup.sql` -> Run.
4. Authentication -> Users -> Add user (teacher email + password). Copy its UID, then run in SQL Editor:
   `insert into admins values ('PASTE-TEACHER-UID-HERE');`
5. Edit `config.js`: paste the URL and anon key. (Never use the service_role key.)
6. Upload all files to a GitHub repo -> Settings -> Pages -> deploy from `main` / root.
   Student page: `https://<user>.github.io/<repo>/`   Teacher page: `.../admin.html`

## Before exam day
- Free Supabase projects pause after 7 days of inactivity: open the dashboard the day before.
- Do a trial with 3-5 devices (refresh, camera alerts, submit, time-over).
- To reset between trials: SQL Editor -> `delete from attempts;`
