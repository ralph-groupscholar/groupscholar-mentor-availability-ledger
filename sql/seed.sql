insert into groupscholar_mentor_availability.mentors (name, email, timezone, focus_areas, status)
values
    ('Dr. Maya Holt', 'maya.holt@groupscholar.com', 'America/New_York', '{STEM,graduate advising}', 'active'),
    ('Andre Flores', 'andre.flores@groupscholar.com', 'America/Chicago', '{essay coaching,first-gen}', 'active'),
    ('Leila Chen', 'leila.chen@groupscholar.com', 'America/Los_Angeles', '{career strategy,internships}', 'active')
on conflict do nothing;

insert into groupscholar_mentor_availability.availability_windows (mentor_id, start_ts, end_ts, max_sessions, notes)
values
    (1, '2026-02-10T14:00:00Z', '2026-02-10T17:00:00Z', 3, 'Midweek advising block'),
    (1, '2026-02-12T15:00:00Z', '2026-02-12T18:00:00Z', 2, 'STEM lab reviews'),
    (2, '2026-02-11T13:00:00Z', '2026-02-11T16:00:00Z', 3, 'Essay clinic'),
    (3, '2026-02-13T20:00:00Z', '2026-02-13T23:00:00Z', 4, 'Career readiness sessions')
on conflict do nothing;

insert into groupscholar_mentor_availability.bookings (mentor_id, scholar_name, start_ts, end_ts, status)
values
    (1, 'Sasha Patel', '2026-02-10T14:30:00Z', '2026-02-10T15:00:00Z', 'scheduled'),
    (2, 'Jordan Lee', '2026-02-11T13:30:00Z', '2026-02-11T14:00:00Z', 'scheduled'),
    (3, 'Amina Yusuf', '2026-02-13T20:30:00Z', '2026-02-13T21:00:00Z', 'scheduled')
on conflict do nothing;
