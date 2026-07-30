from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class Workout(Base):
    __tablename__ = "workouts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True)
    category = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class WorkoutSession(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    # Loose day tag (1-6), not a strict foreign key, so starting a session on a
    # fresh database can't fail with a foreign-key violation.
    workout_id = Column(Integer, index=True)
    date = Column(DateTime, default=datetime.utcnow)

    sets = relationship("WorkoutSet", back_populates="session")


class WorkoutSet(Base):
    __tablename__ = "sets"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("sessions.id"))
    set_number = Column(Integer)
    # Float so decimal weights like 2.5 kg are stored accurately.
    weight = Column(Float)
    reps = Column(Integer)
    rest_seconds = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("WorkoutSession", back_populates="sets")