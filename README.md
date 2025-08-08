# Group Scholar Mentor Availability Ledger

A Zig-powered CLI to track mentor availability windows, session bookings, and remaining capacity for Group Scholar programs.

## Features
- Capture mentor profiles with focus areas and time zones
- Log availability windows and session bookings
- Compute remaining session capacity across a time range
- PostgreSQL-backed persistence for production use

## Tech Stack
- Zig 0.15
- PostgreSQL (via libpq)

## Setup
1. Install PostgreSQL client libraries (libpq).
2. Ensure `libpq-fe.h` and `libpq` are available. If needed, set:
   - `PG_INCLUDE_PATH=/path/to/include`
   - `PG_LIB_PATH=/path/to/lib`
3. Build the CLI:

```bash
zig build
```

## Database
Set `DATABASE_URL` when running the CLI in production environments.

Initialize schema and seed data (run against the production database only):

```bash
psql "$DATABASE_URL" -f sql/schema.sql
psql "$DATABASE_URL" -f sql/seed.sql
```

## Usage
Time inputs accept `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`.

```bash
./zig-out/bin/groupscholar-mentor-availability-ledger mentor list

./zig-out/bin/groupscholar-mentor-availability-ledger mentor add \
  --name "Renee Vaughn" \
  --email "renee.vaughn@groupscholar.com" \
  --timezone "America/New_York" \
  --focus-areas "essay coaching,transfer pathways"

./zig-out/bin/groupscholar-mentor-availability-ledger availability add \
  --mentor-id 1 \
  --start 2026-02-15T14:00:00 \
  --end 2026-02-15T16:00:00 \
  --max-sessions 2 \
  --notes "Scholarship review prep"

./zig-out/bin/groupscholar-mentor-availability-ledger booking add \
  --mentor-id 1 \
  --scholar "Kayla Ortiz" \
  --start 2026-02-15T14:30:00 \
  --end 2026-02-15T15:00:00

./zig-out/bin/groupscholar-mentor-availability-ledger capacity range \
  --start 2026-02-10 \
  --end 2026-02-17
```

## Testing
```bash
zig build test
```
