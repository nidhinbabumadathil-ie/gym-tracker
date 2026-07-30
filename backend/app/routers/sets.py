from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import SessionLocal
from .. import models, schemas
from typing import List
from datetime import datetime
from pydantic import BaseModel

router = APIRouter()


# Response schema
class WorkoutSetOut(BaseModel):
    id: int
    session_id: int
    set_number: int
    weight: float   # accepts decimals like 2.5
    reps: int
    rest_seconds: int
    created_at: datetime

    class Config:
        from_attributes = True


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/{session_id}", response_model=WorkoutSetOut)
def add_set(session_id: int, set_data: schemas.SetCreate, db: Session = Depends(get_db)):
    new_set = models.WorkoutSet(
        session_id=session_id,
        set_number=set_data.set_number,
        weight=set_data.weight,
        reps=set_data.reps,
        rest_seconds=set_data.rest_seconds,
    )
    db.add(new_set)
    db.commit()
    db.refresh(new_set)
    return new_set


# GET sets for ONE workout
@router.get("/workout/{workout_id}", response_model=List[WorkoutSetOut])
def get_sets_for_workout(workout_id: int, db: Session = Depends(get_db)):
    return (
        db.query(models.WorkoutSet)
        .join(models.WorkoutSession, models.WorkoutSet.session_id == models.WorkoutSession.id)
        .filter(models.WorkoutSession.workout_id == workout_id)
        .order_by(models.WorkoutSet.set_number)
        .all()
    )


# GET all sets (for analytics)
@router.get("/all", response_model=List[WorkoutSetOut])
def get_all_sets(db: Session = Depends(get_db)):
    return db.query(models.WorkoutSet).order_by(models.WorkoutSet.id).all()