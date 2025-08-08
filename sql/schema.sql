create schema if not exists groupscholar_mentor_availability;

create table if not exists groupscholar_mentor_availability.mentors (
    id bigserial primary key,
    name text not null,
    email text not null,
    timezone text not null,
    focus_areas text[] not null default '{}',
    status text not null default 'active',
    created_at timestamptz not null default now()
);

create table if not exists groupscholar_mentor_availability.availability_windows (
    id bigserial primary key,
    mentor_id bigint not null references groupscholar_mentor_availability.mentors(id) on delete cascade,
    start_ts timestamptz not null,
    end_ts timestamptz not null,
    max_sessions int not null default 1,
    notes text,
    created_at timestamptz not null default now()
);

create table if not exists groupscholar_mentor_availability.bookings (
    id bigserial primary key,
    mentor_id bigint not null references groupscholar_mentor_availability.mentors(id) on delete cascade,
    scholar_name text not null,
    start_ts timestamptz not null,
    end_ts timestamptz not null,
    status text not null default 'scheduled',
    created_at timestamptz not null default now()
);

create index if not exists idx_gs_mentor_availability_mentor on groupscholar_mentor_availability.availability_windows(mentor_id, start_ts);
create index if not exists idx_gs_mentor_bookings_mentor on groupscholar_mentor_availability.bookings(mentor_id, start_ts);
