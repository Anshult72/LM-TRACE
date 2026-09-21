import asyncio
from sqlalchemy import text
from app.core.database import engine

cols = [
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS event_id VARCHAR(50);",
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS actor_name VARCHAR(150);",
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS inspection_id VARCHAR(100);",
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS result VARCHAR(50) DEFAULT 'SUCCESS';",
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS description TEXT;",
    "ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS correlation_id VARCHAR(100);",
]

async def migrate():
    if not engine:
        print("DATABASE_URL not configured; skipping PostgreSQL table alter.")
        return
    print("Running audit_logs schema upgrade on Neon Postgres...")
    async with engine.begin() as conn:
        for col_sql in cols:
            print(f"Executing: {col_sql}")
            await conn.execute(text(col_sql))
    print("Schema migration complete for audit_logs!")

if __name__ == "__main__":
    asyncio.run(migrate())
