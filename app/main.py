from fastapi import FastAPI, HTTPException
from typing import Optional, Dict
from app.config import settings
from app.models.events import DisruptionAlert
from app.models.workflow import WorkflowState, WorkflowStatus
from app.erp_mock.routes import erp_router
import uuid

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Autonomous Supply Chain Disruption Recovery System"
)

app.include_router(erp_router, prefix="/erp", tags=["Mock ERP Engine"])

workflow_registry: Dict[str, WorkflowState] = {}

@app.get("/")
def health_check():
    return {
        "service": settings.PROJECT_NAME,
        "status": "healthy",
        "api_docs": "/docs"
    }

@app.post("/events/disruption", response_model=WorkflowState)
def handle_disruption_event(alert: DisruptionAlert):
    wf_id = f"wf_{uuid.uuid4().hex[:8]}"
    state = WorkflowState(
        workflow_id=wf_id,
        status=WorkflowStatus.RECEIVED,
        alert=alert
    )
    workflow_registry[wf_id] = state
    return state

@app.get("/workflows/{workflow_id}", response_model=WorkflowState)
def get_workflow_details(workflow_id: str):
    if workflow_id not in workflow_registry:
        raise HTTPException(status_code=404, detail="Workflow instance not found")
    return workflow_registry[workflow_id]

@app.post("/approvals/{workflow_id}/approve")
def approve_workflow(workflow_id: str, selected_option_id: str, manager_notes: Optional[str] = None):
    if workflow_id not in workflow_registry:
        raise HTTPException(status_code=404, detail="Workflow instance not found")
        
    wf_state = workflow_registry[workflow_id]
    
    if wf_state.status != WorkflowStatus.AWAITING_APPROVAL:
        raise HTTPException(
            status_code=400, 
            detail=f"Workflow is in '{wf_state.status}' state and cannot be approved."
        )
        
    wf_state.status = WorkflowStatus.APPROVED
    wf_state.selected_option_id = selected_option_id
    wf_state.manager_notes = manager_notes
    
    return {
        "message": f"Workflow {workflow_id} approved successfully.",
        "status": wf_state.status,
        "selected_option": selected_option_id
    }
