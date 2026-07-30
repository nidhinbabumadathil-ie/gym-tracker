from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from .routers import workouts, sessions, sets

app = FastAPI(title="Gym Tracker API")

origins = ["*"]  # Allow all origins for testing

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def create_tables():
    # Previously this ran at import time. If the database was unreachable, the
    # whole app crashed on boot (which is exactly what happened when the free
    # database expired). Running it on startup inside a try/except means the
    # service still boots and returns clear per-request errors instead of
    # crash-looping.
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as exc:  # noqa: BLE001
        print(f"[startup] Could not create tables (database unreachable?): {exc}")


@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(workouts.router, prefix="/workouts")
app.include_router(sessions.router, prefix="/sessions")
app.include_router(sets.router, prefix="/sets")
