from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class SeverityLevel(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

class DisruptionAlert(BaseModel):
    event_id: str = Field(..., description="Unique event ID")
    event_type: str = Field(..., example="PORT_SHUTDOWN")
    location: str = Field(..., example="Port of Long Beach")
    affected_supplier_id: Optional[str] = Field(None, example="SUP-102")
    severity: SeverityLevel
    estimated_duration_days: int
    description: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
