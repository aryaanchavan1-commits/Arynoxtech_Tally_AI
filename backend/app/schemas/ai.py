from pydantic import BaseModel, Field, ConfigDict
from typing import Optional


class AISettingsCreate(BaseModel):
    provider: str
    api_key: Optional[str] = None
    model: Optional[str] = None


class AISettingsResponse(BaseModel):
    id: int
    provider: str
    model: Optional[str] = None
    is_active: bool
    has_api_key: bool

    model_config = ConfigDict(from_attributes=True)


class AIChatRequest(BaseModel):
    message: str
    include_business_data: bool = False


class AIChatResponse(BaseModel):
    response: str


class AITestRequest(BaseModel):
    provider: str
    api_key: str
    model: Optional[str] = None


class AITestResponse(BaseModel):
    success: bool
    message: str


class AIVoiceInputResponse(BaseModel):
    transcript: str


class AIVoiceOutputRequest(BaseModel):
    text: str
    voice: Optional[str] = "alloy"


class AIVoiceOutputResponse(BaseModel):
    audio_url: str


class FileUploadResponse(BaseModel):
    file_id: str
    filename: str
    content_type: str
    size: int
    preview: str


class AgentActionProposal(BaseModel):
    action: str
    params: dict
    description: str
    requires_confirmation: bool = True


class AgentActionMessage(BaseModel):
    type: str = "agent_action"
    message: str
    actions: list[AgentActionProposal] = []


class AgentRequest(BaseModel):
    message: str
    history: list[dict] = []
    file_ids: list[str] = []


class AgentResponse(BaseModel):
    type: str = "chat"
    response: str
    actions: list[AgentActionProposal] = []


class AgentConfirmRequest(BaseModel):
    action: str
    params: dict
