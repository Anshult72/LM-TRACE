from datetime import datetime, timedelta, timezone
from typing import Optional, Any, Dict
import jwt
from pwdlib import PasswordHash
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.config import settings

password_hash = PasswordHash.recommended()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return password_hash.verify(plain_password, hashed_password)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    return password_hash.hash(password)

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None

async def get_current_user_payload(token: str = Depends(oauth2_scheme)) -> Dict[str, Any]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"code": "INVALID_TOKEN", "message": "Could not validate credentials", "details": None},
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    user_id = payload.get("sub")
    role = payload.get("role")
    if user_id is None or role is None:
        raise credentials_exception
    return payload

def require_role(*allowed_roles: str):
    def role_checker(payload: Dict[str, Any] = Depends(get_current_user_payload)):
        user_role = payload.get("role")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "FORBIDDEN", "message": f"Action requires one of roles: {', '.join(allowed_roles)}", "details": None}
            )
        return payload
    return role_checker

ROLE_PERMISSIONS: Dict[str, set] = {
    "INSPECTOR": {
        "INSPECTION_CREATE", "INSPECTION_VIEW", "INSPECTION_UPDATE", "INSPECTION_SUBMIT",
        "EVIDENCE_CREATE", "EVIDENCE_VIEW", "CALIBRATION_CREATE", "CALIBRATION_VIEW",
        "PRODUCT_VIEW", "REFERENCE_VIEW", "STATUTORY_VIEW", "REPORT_VIEW"
    },
    "SUPERVISOR": {
        "INSPECTION_VIEW", "INSPECTION_REVIEW", "EVIDENCE_VIEW", "CALIBRATION_VIEW",
        "PRODUCT_VIEW", "REFERENCE_VIEW", "RULE_VIEW", "STATUTORY_VIEW",
        "REVIEW_VIEW", "REVIEW_DECIDE", "AUDIT_VIEW", "REPORT_VIEW", "REPORT_FINALIZE"
    },
    "ADMIN": {
        "INSPECTION_CREATE", "INSPECTION_VIEW", "INSPECTION_UPDATE", "INSPECTION_SUBMIT", "INSPECTION_REVIEW",
        "INSPECTION_DELETE",
        "EVIDENCE_CREATE", "EVIDENCE_VIEW", "CALIBRATION_CREATE", "CALIBRATION_VIEW",
        "PRODUCT_VIEW", "PRODUCT_UPDATE", "REFERENCE_VIEW",
        "RULE_VIEW", "RULE_MANAGE", "STATUTORY_VIEW", "STATUTORY_MANAGE",
        "REVIEW_VIEW", "REVIEW_DECIDE", "AUDIT_VIEW", "REPORT_VIEW", "REPORT_FINALIZE",
        "SYSTEM_SETTINGS_VIEW", "SYSTEM_SETTINGS_UPDATE", "USER_MANAGE"
    }
}

def require_permission(*required_permissions: str):
    def permission_checker(payload: Dict[str, Any] = Depends(get_current_user_payload)):
        user_role = payload.get("role", "INSPECTOR")
        user_perms = ROLE_PERMISSIONS.get(user_role, set())
        for perm in required_permissions:
            if perm not in user_perms:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={"code": "FORBIDDEN", "message": f"Action requires permission '{perm}' (Role {user_role} not authorized)", "details": None}
                )
        return payload
    return permission_checker

