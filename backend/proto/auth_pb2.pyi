from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class LoginRequest(_message.Message):
    __slots__ = ("access_token", "email", "name", "avatar_url")
    ACCESS_TOKEN_FIELD_NUMBER: _ClassVar[int]
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    AVATAR_URL_FIELD_NUMBER: _ClassVar[int]
    access_token: str
    email: str
    name: str
    avatar_url: str
    def __init__(self, access_token: _Optional[str] = ..., email: _Optional[str] = ..., name: _Optional[str] = ..., avatar_url: _Optional[str] = ...) -> None: ...

class LoginResponse(_message.Message):
    __slots__ = ("success", "user_id", "auth0_sub", "email", "message")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    AUTH0_SUB_FIELD_NUMBER: _ClassVar[int]
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    success: bool
    user_id: str
    auth0_sub: str
    email: str
    message: str
    def __init__(self, success: _Optional[bool] = ..., user_id: _Optional[str] = ..., auth0_sub: _Optional[str] = ..., email: _Optional[str] = ..., message: _Optional[str] = ...) -> None: ...

class TokenVerifyRequest(_message.Message):
    __slots__ = ("access_token",)
    ACCESS_TOKEN_FIELD_NUMBER: _ClassVar[int]
    access_token: str
    def __init__(self, access_token: _Optional[str] = ...) -> None: ...

class TokenVerifyResponse(_message.Message):
    __slots__ = ("valid", "auth0_sub", "email", "expires_at", "message")
    VALID_FIELD_NUMBER: _ClassVar[int]
    AUTH0_SUB_FIELD_NUMBER: _ClassVar[int]
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    EXPIRES_AT_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    valid: bool
    auth0_sub: str
    email: str
    expires_at: int
    message: str
    def __init__(self, valid: _Optional[bool] = ..., auth0_sub: _Optional[str] = ..., email: _Optional[str] = ..., expires_at: _Optional[int] = ..., message: _Optional[str] = ...) -> None: ...
