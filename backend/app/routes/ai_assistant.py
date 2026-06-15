import os
import re
import json
import uuid
import tempfile
import zipfile
from io import BytesIO
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import Optional
import httpx
from app.database import get_db
from app.models.ai_settings import AISetting
from app.schemas.ai import (
    AISettingsCreate, AISettingsResponse,
    AIChatRequest, AIChatResponse,
    AITestRequest, AITestResponse,
    AIVoiceInputResponse, AIVoiceOutputRequest,
    FileUploadResponse, AgentRequest, AgentResponse,
    AgentConfirmRequest, AgentActionProposal,
)
from app.routes.auth import get_current_user
from app.utils.encryption import encrypt_data, decrypt_data
from app.services.agent_service import execute_action, call_ai, AGENT_SYSTEM_PROMPT, extract_action_json

router = APIRouter(prefix="/api/ai", tags=["AI Assistant"])

AUDIO_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "audio_responses")
os.makedirs(AUDIO_DIR, exist_ok=True)

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "uploaded_files")
os.makedirs(UPLOAD_DIR, exist_ok=True)


AI_PROVIDERS = {
    "groq": {
        "base_url": "https://api.groq.com/openai/v1",
        "models": [
            "llama-3.3-70b-versatile",
            "llama-3.1-70b-versatile",
            "llama-3.1-8b-instant",
            "deepseek-r1-distill-llama-70b",
            "mixtral-8x7b-32768",
            "gemma2-9b-it",
            "llama3-70b-8192",
            "llama3-8b-8192",
        ],
        "stt": True,
        "tts": False,
    },
    "openai": {
        "base_url": "https://api.openai.com/v1",
        "models": ["gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo"],
        "stt": True,
        "tts": True,
    },
    "gemini": {
        "base_url": "https://generativelanguage.googleapis.com/v1beta",
        "models": ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-1.5-pro"],
        "stt": True,
        "tts": False,
    },
    "openrouter": {
        "base_url": "https://openrouter.ai/api/v1",
        "models": [
            "deepseek/deepseek-v4-flash-free",
            "google/gemini-2.0-flash-free",
            "meta-llama/llama-3.2-3b-instruct:free",
            "google/gemini-2.0-flash",
            "meta-llama/llama-3.3-70b-instruct",
            "anthropic/claude-3.5-sonnet",
            "mistralai/mistral-7b-instruct:free",
        ],
        "stt": False,
        "tts": False,
    },
}


@router.get("/settings", response_model=Optional[AISettingsResponse])
def get_ai_settings(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    setting = db.query(AISetting).filter(AISetting.user_id == user_id, AISetting.is_active == True).first()
    if not setting:
        return None
    return AISettingsResponse(
        id=setting.id, provider=setting.provider,
        model=setting.model, is_active=setting.is_active,
        has_api_key=bool(setting.api_key_encrypted),
    )


@router.post("/settings", response_model=AISettingsResponse)
def save_ai_settings(data: AISettingsCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    existing = db.query(AISetting).filter(AISetting.user_id == user_id).first()
    if existing:
        existing.provider = data.provider
        if data.api_key:
            existing.api_key_encrypted = encrypt_data(data.api_key)
        existing.model = data.model
        existing.is_active = True
        db.commit()
        db.refresh(existing)
        return AISettingsResponse(
            id=existing.id, provider=existing.provider,
            model=existing.model, is_active=existing.is_active,
            has_api_key=bool(existing.api_key_encrypted),
        )
    else:
        if not data.api_key:
            raise HTTPException(status_code=400, detail="API key required for new settings")
        setting = AISetting(
            provider=data.provider,
            api_key_encrypted=encrypt_data(data.api_key),
            model=data.model,
            is_active=True,
            user_id=user_id,
        )
        db.add(setting)
        db.commit()
        db.refresh(setting)
        return AISettingsResponse(
            id=setting.id, provider=setting.provider,
            model=setting.model, is_active=setting.is_active,
            has_api_key=bool(setting.api_key_encrypted),
        )


@router.delete("/settings")
def delete_ai_settings(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    db.query(AISetting).filter(AISetting.user_id == user_id).delete()
    db.commit()
    return {"message": "AI settings deleted"}


@router.post("/test", response_model=AITestResponse)
async def test_ai_connection(data: AITestRequest):
    provider_config = AI_PROVIDERS.get(data.provider)
    if not provider_config:
        raise HTTPException(status_code=400, detail="Invalid provider")

    model = data.model or provider_config["models"][0]
    headers = {
        "Authorization": f"Bearer {data.api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "Reply with only: OK"}],
        "max_tokens": 10,
    }

    if data.provider == "openrouter":
        headers["HTTP-Referer"] = "https://arynoxtech.com"
        headers["X-Title"] = "Arynoxtech Tally"

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                f"{provider_config['base_url']}/chat/completions",
                headers=headers,
                json=payload,
            )
            if response.status_code == 200:
                return AITestResponse(success=True, message="Connection successful!")
            else:
                try:
                    err_detail = response.json()
                    err_msg = err_detail.get("error", {}).get("message", "") or err_detail.get("message", "")
                except Exception:
                    err_msg = response.text[:200]
                return AITestResponse(success=False, message=f"Error ({response.status_code}): {err_msg}")
    except httpx.TimeoutException:
        return AITestResponse(success=False, message="Connection timed out after 10s. Provider may be slow.")
    except Exception as e:
        return AITestResponse(success=False, message=f"Connection failed: {str(e)}")


@router.post("/chat", response_model=AIChatResponse)
async def ai_chat(
    request: AIChatRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    setting = db.query(AISetting).filter(AISetting.user_id == user_id, AISetting.is_active == True).first()
    if not setting or not setting.api_key_encrypted:
        raise HTTPException(status_code=400, detail="AI not configured. Please configure AI settings first.")

    api_key = decrypt_data(setting.api_key_encrypted)
    provider_config = AI_PROVIDERS.get(setting.provider)
    if not provider_config:
        raise HTTPException(status_code=400, detail="Invalid provider configuration")

    model = setting.model or provider_config["models"][0]

    system_prompt = """You are Arynox, the AI Business Assistant built into Arynoxtech Tally accounting software.
You help small business owners with accounting, inventory, invoicing, and business management.
Keep responses concise, practical, and focused on Indian small business context.
Offer actionable advice and explain accounting concepts simply.
Since the user may be using voice input, keep responses clear, well-structured, and easy to read aloud.
Use short paragraphs and bullet points where appropriate.
You can help with:
- Accounting concepts and best practices
- Invoice and quotation drafting
- Business report analysis
- Revenue and expense insights
- Inventory management tips
- Business improvement recommendations
- GST compliance and tax filing guidance"""

    if request.include_business_data:
        system_prompt += "\n\nThe user has requested analysis of their business data. Provide data-driven insights."

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    if setting.provider == "openrouter":
        headers["HTTP-Referer"] = "https://arynoxtech.com"
        headers["X-Title"] = "Arynoxtech Tally"

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": request.message},
        ],
        "max_tokens": 2048,
        "temperature": 0.7,
    }

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{provider_config['base_url']}/chat/completions",
                headers=headers,
                json=payload,
            )
            if response.status_code == 200:
                result = response.json()
                ai_response = result["choices"][0]["message"]["content"]
                return AIChatResponse(response=ai_response)
            else:
                try:
                    err_detail = response.json()
                    err_msg = err_detail.get("error", {}).get("message", "") or err_detail.get("message", "")
                except Exception:
                    err_msg = response.text[:200]
                if response.status_code == 401:
                    return AIChatResponse(response="Invalid API key. Please check your key in AI Settings.")
                elif response.status_code == 429:
                    return AIChatResponse(response="Rate limited. Please wait a moment and try again.")
                elif response.status_code == 402:
                    return AIChatResponse(response="Insufficient credits for this model. Try a free model in OpenRouter settings.")
                else:
                    return AIChatResponse(response=f"AI Error ({response.status_code}): {err_msg or 'Unknown error'}")
    except httpx.TimeoutException:
        return AIChatResponse(response="Request timed out. The model may be overloaded. Try a different model.")
    except Exception as e:
        return AIChatResponse(response=f"Connection error: {str(e)}")


@router.get("/providers")
def get_providers():
    providers = []
    for key, config in AI_PROVIDERS.items():
        providers.append({
            "id": key,
            "name": key.capitalize(),
            "models": config["models"],
            "stt_supported": config.get("stt", False),
            "tts_supported": config.get("tts", False),
        })
    return {"providers": providers}


@router.post("/upload", response_model=list[FileUploadResponse])
async def upload_files(
    files: list[UploadFile] = File(...),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    results = []
    for file in files:
        content = await file.read()
        if not content:
            continue
        file_id = uuid.uuid4().hex[:12]
        ext = os.path.splitext(file.filename or "file")[1] or ".bin"
        safe_name = f"{file_id}{ext}"
        filepath = os.path.join(UPLOAD_DIR, safe_name)
        with open(filepath, "wb") as f:
            f.write(content)

        preview = f"[File: {file.filename} ({len(content)} bytes)]"
        try:
            if ext.lower() in (".txt", ".csv", ".md", ".json", ".xml", ".log", ".ini", ".cfg"):
                text = content.decode("utf-8", errors="replace")
                preview = text[:1000]
            elif ext.lower() == ".pdf":
                preview = "[PDF file - content parsed by AI]"
            elif ext.lower() in (".xlsx", ".xls"):
                preview = "[Excel file - content parsed by AI]"
        except Exception:
            preview = f"[File: {file.filename}]"

        results.append(FileUploadResponse(
            file_id=file_id,
            filename=file.filename or f"file{ext}",
            content_type=file.content_type or "application/octet-stream",
            size=len(content),
            preview=preview,
        ))
    return results


@router.post("/agent", response_model=AgentResponse)
async def agent_chat(
    request: AgentRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    setting = db.query(AISetting).filter(AISetting.user_id == user_id, AISetting.is_active == True).first()
    if not setting or not setting.api_key_encrypted:
        raise HTTPException(status_code=400, detail="AI not configured. Configure AI settings first.")

    api_key = decrypt_data(setting.api_key_encrypted)
    provider_config = AI_PROVIDERS.get(setting.provider)
    if not provider_config:
        raise HTTPException(status_code=400, detail="Invalid provider")

    model = setting.model or provider_config["models"][0]

    file_context = ""
    if request.file_ids:
        file_context += "\n\nThe user has uploaded the following files:\n"
        for fid in request.file_ids:
            for fname in os.listdir(UPLOAD_DIR):
                if fname.startswith(fid):
                    fpath = os.path.join(UPLOAD_DIR, fname)
                    try:
                        with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                            content = f.read(2000)
                        file_context += f"\n--- File: {fname} ---\n{content}\n---\n"
                    except Exception:
                        file_context += f"\n--- File: {fname} ---\n[Binary file - cannot display]\n---\n"
                    break

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    if setting.provider == "openrouter":
        headers["HTTP-Referer"] = "https://arynoxtech.com"
        headers["X-Title"] = "Arynoxtech Tally"

    messages = [{"role": "system", "content": AGENT_SYSTEM_PROMPT}]
    for h in request.history:
        messages.append({"role": h.get("role", "user"), "content": h.get("content", "")})

    user_content = request.message
    if file_context:
        user_content = file_context + "\n\nUser message: " + request.message
    messages.append({"role": "user", "content": user_content})

    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": 2048,
        "temperature": 0.3,
    }

    try:
        async with httpx.AsyncClient(timeout=90) as client:
            response = await client.post(
                f"{provider_config['base_url']}/chat/completions",
                headers=headers,
                json=payload,
            )
            if response.status_code == 200:
                result = response.json()
                ai_text = result["choices"][0]["message"]["content"]

                action_data = extract_action_json(ai_text)
                if action_data and action_data.get("agent_action"):
                    actions = [
                        AgentActionProposal(**a) for a in action_data.get("actions", [])
                    ]
                    clean_msg = action_data.get("message", ai_text)
                    return AgentResponse(
                        type="agent_action",
                        response=clean_msg,
                        actions=actions,
                    )
                return AgentResponse(type="chat", response=ai_text)

            try:
                err_detail = response.json()
                err_msg = err_detail.get("error", {}).get("message", "") or err_detail.get("message", "")
            except Exception:
                err_msg = response.text[:200]
            if response.status_code == 401:
                return AgentResponse(response="Invalid API key. Please check your key in AI Settings.")
            elif response.status_code == 429:
                return AgentResponse(response="Rate limited. Please wait and try again.")
            elif response.status_code == 402:
                return AgentResponse(response="Insufficient credits. Try a free model.")
            return AgentResponse(response=f"AI Error ({response.status_code}): {err_msg or 'Unknown error'}")
    except httpx.TimeoutException:
        return AgentResponse(response="Request timed out. The model may be overloaded.")
    except Exception as e:
        return AgentResponse(response=f"Connection error: {str(e)}")


@router.post("/agent/execute", response_model=dict)
def execute_agent_action(
    request: AgentConfirmRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    result = execute_action(request.action, request.params, db, user_id)
    return result


@router.post("/voice-input", response_model=AIVoiceInputResponse)
async def voice_to_text(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    setting = db.query(AISetting).filter(AISetting.user_id == user_id, AISetting.is_active == True).first()
    if not setting or not setting.api_key_encrypted:
        raise HTTPException(status_code=400, detail="AI not configured")

    provider_config = AI_PROVIDERS.get(setting.provider)
    if not provider_config or not provider_config.get("stt"):
        raise HTTPException(status_code=400, detail=f"{setting.provider} does not support speech-to-text")

    api_key = decrypt_data(setting.api_key_encrypted)
    content = await file.read()

    if not content:
        raise HTTPException(status_code=400, detail="Empty audio file")

    stt_urls = {
        "openai": "https://api.openai.com/v1/audio/transcriptions",
        "groq": "https://api.groq.com/openai/v1/audio/transcriptions",
        "gemini": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
    }

    url = stt_urls.get(setting.provider)
    if not url:
        raise HTTPException(status_code=400, detail="Speech-to-text not available for this provider")

    headers = {"Authorization": f"Bearer {api_key}"}

    try:
        if setting.provider == "gemini":
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    f"{url}?key={api_key}",
                    json={"contents": [{"parts": [{"inlineData": {"mimeType": file.content_type or "audio/wav", "data": content}}]}]},
                )
                data = resp.json()
                text = ""
                for candidate in data.get("candidates", []):
                    for part in candidate.get("content", {}).get("parts", []):
                        text += part.get("text", "")
                return AIVoiceInputResponse(transcript=text.strip())
        else:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    url,
                    headers=headers,
                    files={"file": (file.filename or "audio.wav", content, file.content_type or "audio/wav")},
                    data={"model": "whisper-1", "response_format": "json", "language": "en"},
                )
                if resp.status_code == 200:
                    text = resp.json().get("text", "")
                    return AIVoiceInputResponse(transcript=text)
                else:
                    raise HTTPException(status_code=502, detail=f"STT failed: {resp.text}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Speech-to-text error: {str(e)}")


@router.post("/voice-output")
async def text_to_voice(
    request: AIVoiceOutputRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    setting = db.query(AISetting).filter(AISetting.user_id == user_id, AISetting.is_active == True).first()
    if not setting or not setting.api_key_encrypted:
        raise HTTPException(status_code=400, detail="AI not configured")

    provider_config = AI_PROVIDERS.get(setting.provider)
    if not provider_config or not provider_config.get("tts"):
        raise HTTPException(status_code=400, detail=f"{setting.provider} does not support text-to-speech")

    api_key = decrypt_data(setting.api_key_encrypted)

    tts_urls = {
        "openai": "https://api.openai.com/v1/audio/speech",
    }

    url = tts_urls.get(setting.provider)
    if not url:
        raise HTTPException(status_code=400, detail="Text-to-speech not available for this provider")

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                url,
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json={
                    "model": "tts-1",
                    "input": request.text,
                    "voice": request.voice or "alloy",
                    "response_format": "wav",
                },
            )
            if resp.status_code == 200:
                filename = f"response_{uuid.uuid4().hex}.wav"
                filepath = os.path.join(AUDIO_DIR, filename)
                with open(filepath, "wb") as f:
                    f.write(resp.content)
                return FileResponse(filepath, media_type="audio/wav", filename=filename)
            else:
                raise HTTPException(status_code=502, detail=f"TTS failed: {resp.text}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Text-to-speech error: {str(e)}")
