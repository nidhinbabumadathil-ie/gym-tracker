from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

DATABASE_URL = os.getenv("DATABASE_URL")

# Fail with a clear message instead of a confusing SQLAlchemy error later on
# if the environment variable was never set.
if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not set. Point it at your Postgres connection string "
        "(Render, Neon, Supabase, or a local database)."
    )

# pool_pre_ping tests that a pooled connection is still alive before handing it
# out. Free/serverless Postgres providers (Render, Neon, Supabase) close idle
# connections, and without this you get intermittent
# "server closed the connection unexpectedly" errors after the app has been idle.
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
