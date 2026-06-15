from cryptography.fernet import Fernet
import base64
import hashlib
from app.config import settings


def _get_fernet() -> Fernet:
    key = hashlib.sha256(settings.ENCRYPTION_KEY.encode()).digest()
    key_b64 = base64.urlsafe_b64encode(key)
    return Fernet(key_b64)


def encrypt_data(data: str) -> str:
    f = _get_fernet()
    return f.encrypt(data.encode()).decode()


def decrypt_data(encrypted_data: str) -> str:
    f = _get_fernet()
    return f.decrypt(encrypted_data.encode()).decode()
