from pydantic import BaseModel
from datetime import datetime
 
 
class WorkoutCreate(BaseModel):
    name: str
    category: str
 
    class Config:
        from_attributes = True  # Pydantic v2 replaces orm_mode
 
 
class Workout(BaseModel):
    id: int
    name: str
    category: str
    created_at: datetime  # Pydantic automatically converts to ISO string
 
    class Config:
        from_attributes = True
 
 
class SetCreate(BaseModel):
    set_number: int
    weight: float   # accepts decimals like 2.5
    reps: int
    rest_seconds: int
 
