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
