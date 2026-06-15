from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class BackupResponse(BaseModel):
    id: int
    filename: str
    filepath: str
    size_bytes: int
    backup_type: str
    description: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ExportRequest(BaseModel):
    export_type: str
    data_type: str
    date_from: Optional[str] = None
    date_to: Optional[str] = None
