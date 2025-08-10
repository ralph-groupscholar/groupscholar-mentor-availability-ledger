pub const insert_mentor =
    "insert into groupscholar_mentor_availability.mentors " ++
    "(name, email, timezone, focus_areas, status) " ++
    "values ($1, $2, $3, $4, 'active') returning id;";

pub const list_mentors =
    "select id, name, email, timezone, status " ++
    "from groupscholar_mentor_availability.mentors " ++
    "order by name;";

pub const insert_availability =
    "insert into groupscholar_mentor_availability.availability_windows " ++
    "(mentor_id, start_ts, end_ts, max_sessions, notes) " ++
    "values ($1, $2::timestamptz, $3::timestamptz, $4::int, $5) returning id;";

pub const list_availability =
    "select id, mentor_id, start_ts, end_ts, max_sessions, notes " ++
    "from groupscholar_mentor_availability.availability_windows " ++
    "where mentor_id = $1::bigint " ++
    "order by start_ts;";

pub const insert_booking =
    "insert into groupscholar_mentor_availability.bookings " ++
    "(mentor_id, scholar_name, start_ts, end_ts, status) " ++
    "values ($1, $2, $3::timestamptz, $4::timestamptz, $5) returning id;";

pub const list_bookings =
    "select b.id, b.mentor_id, m.name, b.scholar_name, b.start_ts, b.end_ts, b.status " ++
    "from groupscholar_mentor_availability.bookings b " ++
    "join groupscholar_mentor_availability.mentors m on m.id = b.mentor_id " ++
    "where b.mentor_id = $1::bigint " ++
    "and ($2 = '' or b.status = $2) " ++
    "and ($3 = '' or b.start_ts >= $3::timestamptz) " ++
    "and ($4 = '' or b.start_ts < $4::timestamptz) " ++
    "order by b.start_ts;";

pub const capacity_range =
    "select m.id, m.name, " ++
    "coalesce(sum(a.max_sessions), 0) as available_sessions, " ++
    "coalesce(count(b.id), 0) as booked_sessions, " ++
    "coalesce(sum(a.max_sessions), 0) - coalesce(count(b.id), 0) as remaining_sessions " ++
    "from groupscholar_mentor_availability.mentors m " ++
    "left join groupscholar_mentor_availability.availability_windows a " ++
    "on m.id = a.mentor_id and a.start_ts >= $1::timestamptz and a.start_ts < $2::timestamptz " ++
    "left join groupscholar_mentor_availability.bookings b " ++
    "on m.id = b.mentor_id and b.start_ts >= $1::timestamptz and b.start_ts < $2::timestamptz " ++
    "group by m.id, m.name " ++
    "order by m.name;";

pub const utilization_range =
    "select m.id, m.name, " ++
    "coalesce(sum(a.max_sessions), 0) as available_sessions, " ++
    "coalesce(count(b.id), 0) as booked_sessions, " ++
    "case when coalesce(sum(a.max_sessions), 0) = 0 then 0 " ++
    "else round((coalesce(count(b.id), 0)::numeric / coalesce(sum(a.max_sessions), 0)::numeric) * 100, 1) end " ++
    "as utilization_pct " ++
    "from groupscholar_mentor_availability.mentors m " ++
    "left join groupscholar_mentor_availability.availability_windows a " ++
    "on m.id = a.mentor_id and a.start_ts >= $1::timestamptz and a.start_ts < $2::timestamptz " ++
    "left join groupscholar_mentor_availability.bookings b " ++
    "on m.id = b.mentor_id and b.start_ts >= $1::timestamptz and b.start_ts < $2::timestamptz " ++
    "group by m.id, m.name " ++
    "order by utilization_pct desc, m.name;";
