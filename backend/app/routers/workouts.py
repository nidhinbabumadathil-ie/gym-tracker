from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import SessionLocal
from .. import models, schemas

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Workout)
def create_workout(workout: schemas.WorkoutCreate, db: Session = Depends(get_db)):
    # Check if workout already exists
    existing = db.query(models.Workout).filter(models.Workout.name == workout.name).first()
    if existing:
        return existing  # <-- just return it

    new_w = models.Workout(name=workout.name, category=workout.category)
    db.add(new_w)
    db.commit()
    db.refresh(new_w)
    return new_w
