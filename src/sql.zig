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
