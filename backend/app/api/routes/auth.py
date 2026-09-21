from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.domain import LoginRequest, TokenResponse, UserResponse
from app.repositories import get_repository
from app.core.security import verify_password, create_access_token, get_current_user_payload
from app.core.logging import logger
from app.services.audit.audit_service import audit_service

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    repo = get_repository()
    user = await repo.get_by_email(req.email)
    if not user:
        await audit_service.record_event(
            action="LOGIN_FAILED",
            actor_id="anonymous",
            actor_name=req.email,
            role="UNKNOWN",
            resource_type="AUTH",
            resource_id=req.email,
            result="FAILURE",
            description=f"Failed login attempt: email '{req.email}' not recognized.",
            metadata={"email": req.email}
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_CREDENTIALS", "message": "Invalid officer email or password", "details": None}
        )

    if not verify_password(req.password, user["hashed_password"]):
        await audit_service.record_event(
            action="LOGIN_FAILED",
            actor_id=user["id"],
            actor_name=user.get("full_name") or req.email,
            role=user.get("role", "INSPECTOR"),
            resource_type="AUTH",
            resource_id=user["id"],
            result="FAILURE",
            description=f"Failed login attempt: invalid credentials for officer {user.get('full_name', req.email)}.",
            metadata={"email": req.email, "officer_id": user.get("officer_id")}
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_CREDENTIALS", "message": "Invalid officer email or password", "details": None}
        )

    token = create_access_token({
        "sub": user["id"],
        "email": user["email"],
        "role": user["role"],
        "officer_id": user["officer_id"],
        "full_name": user["full_name"]
    })

    # Log authoritative audit event
    await audit_service.record_event(
        action="USER_LOGIN",
        actor_id=user["id"],
        actor_name=user.get("full_name"),
        role=user.get("role", "INSPECTOR"),
        resource_type="AUTH",
        resource_id=user["id"],
        result="SUCCESS",
        description=f"Officer {user.get('full_name', user['email'])} ({user.get('officer_id', 'N/A')}) authenticated session.",
        metadata={"officer_id": user.get("officer_id"), "department": user.get("department")}
    )

    user_out = {k: v for k, v in user.items() if k != "hashed_password"}
    return TokenResponse(access_token=token, user=user_out)

@router.get("/me", response_model=UserResponse)
async def get_me(payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    user = await repo.get_by_id(payload["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        officer_id=user["officer_id"],
        department=user["department"],
        role=user["role"],
        active=user["active"]
    )

@router.post("/logout")
async def logout(payload: dict = Depends(get_current_user_payload)):
    """
    Terminates session and records authoritative USER_LOGOUT audit event.
    """
    user_id = payload.get("sub", "unknown")
    full_name = payload.get("full_name") or payload.get("email") or "Officer"
    role = payload.get("role", "INSPECTOR")
    officer_id = payload.get("officer_id", "N/A")

    await audit_service.record_event(
        action="USER_LOGOUT",
        actor_id=user_id,
        actor_name=full_name,
        role=role,
        resource_type="AUTH",
        resource_id=user_id,
        result="SUCCESS",
        description=f"Officer {full_name} ({officer_id}) terminated authenticated session.",
        metadata={"officer_id": officer_id, "email": payload.get("email")}
    )

    return {"message": "Session successfully terminated", "status": "LOGGED_OUT"}

