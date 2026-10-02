from enum import Enum
from typing import Optional
from pydantic import BaseModel
from datetime import datetime
from app.models.events import DisruptionAlert
from app.models.recovery import ImpactAssessment

class WorkflowStatus(str, Enum):
    RECEIVED = "RECEIVED"
    ANALYZING = "ANALYZING"
    AWAITING_APPROVAL = "AWAITING_APPROVAL"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    EXECUTING = "EXECUTING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class WorkflowState(BaseModel):
    workflow_id: str
    status: WorkflowStatus
    alert: DisruptionAlert
    impact_assessment: Optional[ImpactAssessment] = None
    selected_option_id: Optional[str] = None
    manager_notes: Optional[str] = None
    created_at: datetime = datetime.utcnow()
    updated_at: datetime = datetime.utcnow()
