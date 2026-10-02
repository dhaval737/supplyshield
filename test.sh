mkdir -p app/models app/agents app/mcp app/erp_mock app/templates tests

cat << 'EOF' > requirements.txt
fastapi>=0.110.0
uvicorn[standard]>=0.28.0
pydantic>=2.6.0
google-genai>=0.1.0
mcp>=1.0.0
httpx>=0.27.0
jinja2>=3.1.0
python-dotenv>=1.0.0
pytest>=8.0.0
EOF

cat << 'EOF' > app/__init__.py
EOF

cat << 'EOF' > app/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "SupplyShield"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"
    DATABASE_URL: str = "sqlite:///./supplyshield.db"
    MOCK_ERP_BASE_URL: str = "http://localhost:8000/erp"

    class Config:
        env_file = ".env"

settings = Settings()
EOF

cat << 'EOF' > app/models/__init__.py
EOF

cat << 'EOF' > app/models/events.py
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
EOF

cat << 'EOF' > app/models/recovery.py
from typing import List, Optional
from pydantic import BaseModel

class RecoveryOption(BaseModel):
    option_id: str
    title: str
    supplier_id: str
    supplier_name: str
    sku: str
    quantity: int
    unit_cost: float
    additional_shipping_cost: float
    total_cost: float
    estimated_lead_time_days: int
    pros: List[str]
    cons: List[str]

class ImpactAssessment(BaseModel):
    event_id: str
    affected_skus: List[str]
    projected_stockout_days: int
    total_financial_exposure: float
    recommended_options: List[RecoveryOption]
EOF

cat << 'EOF' > app/models/workflow.py
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
EOF

cat << 'EOF' > app/erp_mock/__init__.py
EOF

cat << 'EOF' > app/erp_mock/routes.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid

erp_router = APIRouter()

mock_inventory = {
    "SKU-1001": {"name": "Industrial Sensor Module", "stock_qty": 450, "reorder_level": 500, "unit": "pcs"},
    "SKU-2002": {"name": "Microcontroller Unit B", "stock_qty": 120, "reorder_level": 300, "unit": "pcs"},
    "SKU-3003": {"name": "Power Converter Module", "stock_qty": 80, "reorder_level": 200, "unit": "pcs"},
}

class PurchaseOrderRequest(BaseModel):
    supplier_id: str
    sku: str
    quantity: int
    unit_price: float
    shipping_address: str
    approval_reference: str

class PurchaseOrderResponse(BaseModel):
    po_number: str
    supplier_id: str
    sku: str
    quantity: int
    total_amount: float
    status: str
    created_at: datetime

@erp_router.get("/inventory/{sku}")
def get_inventory_item(sku: str):
    if sku not in mock_inventory:
        raise HTTPException(status_code=404, detail="SKU not found in ERP")
    return {"sku": sku, **mock_inventory[sku]}

@erp_router.post("/purchase-orders", response_model=PurchaseOrderResponse)
def create_purchase_order(po_req: PurchaseOrderRequest):
    po_number = f"PO-ERP-{uuid.uuid4().hex[:6].upper()}"
    total = po_req.quantity * po_req.unit_price
    
    return PurchaseOrderResponse(
        po_number=po_number,
        supplier_id=po_req.supplier_id,
        sku=po_req.sku,
        quantity=po_req.quantity,
        total_amount=total,
        status="CONFIRMED",
        created_at=datetime.utcnow()
    )
EOF

cat << 'EOF' > app/main.py
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
EOF

echo "✅ All SupplyShield files created successfully!"
