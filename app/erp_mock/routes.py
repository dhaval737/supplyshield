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
