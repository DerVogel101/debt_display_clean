from google.protobuf.internal import containers as _containers
from google.protobuf.internal import enum_type_wrapper as _enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class ReceiptOrderBy(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    RECEIPT_ORDER_BY_UNSPECIFIED: _ClassVar[ReceiptOrderBy]
    RECEIPT_ORDER_BY_ID: _ClassVar[ReceiptOrderBy]
    RECEIPT_ORDER_BY_COST_TOTAL: _ClassVar[ReceiptOrderBy]
    RECEIPT_ORDER_BY_COST_FOR_USER: _ClassVar[ReceiptOrderBy]
    RECEIPT_ORDER_BY_DUE_DATE: _ClassVar[ReceiptOrderBy]
    RECEIPT_ORDER_BY_REMAINING_FOR_USER: _ClassVar[ReceiptOrderBy]

class ReceiptOrderDirection(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    RECEIPT_ORDER_DIRECTION_UNSPECIFIED: _ClassVar[ReceiptOrderDirection]
    RECEIPT_ORDER_DIRECTION_ASC: _ClassVar[ReceiptOrderDirection]
    RECEIPT_ORDER_DIRECTION_DESC: _ClassVar[ReceiptOrderDirection]

class ReceiptActorFilter(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    RECEIPT_ACTOR_FILTER_UNSPECIFIED: _ClassVar[ReceiptActorFilter]
    RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP: _ClassVar[ReceiptActorFilter]
    RECEIPT_ACTOR_FILTER_OWNER: _ClassVar[ReceiptActorFilter]
    RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP: _ClassVar[ReceiptActorFilter]
RECEIPT_ORDER_BY_UNSPECIFIED: ReceiptOrderBy
RECEIPT_ORDER_BY_ID: ReceiptOrderBy
RECEIPT_ORDER_BY_COST_TOTAL: ReceiptOrderBy
RECEIPT_ORDER_BY_COST_FOR_USER: ReceiptOrderBy
RECEIPT_ORDER_BY_DUE_DATE: ReceiptOrderBy
RECEIPT_ORDER_BY_REMAINING_FOR_USER: ReceiptOrderBy
RECEIPT_ORDER_DIRECTION_UNSPECIFIED: ReceiptOrderDirection
RECEIPT_ORDER_DIRECTION_ASC: ReceiptOrderDirection
RECEIPT_ORDER_DIRECTION_DESC: ReceiptOrderDirection
RECEIPT_ACTOR_FILTER_UNSPECIFIED: ReceiptActorFilter
RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP: ReceiptActorFilter
RECEIPT_ACTOR_FILTER_OWNER: ReceiptActorFilter
RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP: ReceiptActorFilter

class EmptyRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class User(_message.Message):
    __slots__ = ("id", "sub", "email", "name", "avatar_url")
    ID_FIELD_NUMBER: _ClassVar[int]
    SUB_FIELD_NUMBER: _ClassVar[int]
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    AVATAR_URL_FIELD_NUMBER: _ClassVar[int]
    id: int
    sub: str
    email: str
    name: str
    avatar_url: str
    def __init__(self, id: _Optional[int] = ..., sub: _Optional[str] = ..., email: _Optional[str] = ..., name: _Optional[str] = ..., avatar_url: _Optional[str] = ...) -> None: ...

class Recipient(_message.Message):
    __slots__ = ("id", "name", "owner_id", "description", "created_at", "members", "member_ids")
    ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    OWNER_ID_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    MEMBERS_FIELD_NUMBER: _ClassVar[int]
    MEMBER_IDS_FIELD_NUMBER: _ClassVar[int]
    id: int
    name: str
    owner_id: int
    description: str
    created_at: str
    members: _containers.RepeatedCompositeFieldContainer[User]
    member_ids: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, id: _Optional[int] = ..., name: _Optional[str] = ..., owner_id: _Optional[int] = ..., description: _Optional[str] = ..., created_at: _Optional[str] = ..., members: _Optional[_Iterable[_Union[User, _Mapping]]] = ..., member_ids: _Optional[_Iterable[int]] = ...) -> None: ...

class ReceiptFile(_message.Message):
    __slots__ = ("id", "receipt_id", "original_filename", "content_type", "size_bytes", "sha256", "created_at")
    ID_FIELD_NUMBER: _ClassVar[int]
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    ORIGINAL_FILENAME_FIELD_NUMBER: _ClassVar[int]
    CONTENT_TYPE_FIELD_NUMBER: _ClassVar[int]
    SIZE_BYTES_FIELD_NUMBER: _ClassVar[int]
    SHA256_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    id: int
    receipt_id: int
    original_filename: str
    content_type: str
    size_bytes: int
    sha256: str
    created_at: str
    def __init__(self, id: _Optional[int] = ..., receipt_id: _Optional[int] = ..., original_filename: _Optional[str] = ..., content_type: _Optional[str] = ..., size_bytes: _Optional[int] = ..., sha256: _Optional[str] = ..., created_at: _Optional[str] = ...) -> None: ...

class TagIndex(_message.Message):
    __slots__ = ("id", "icon", "text", "color")
    ID_FIELD_NUMBER: _ClassVar[int]
    ICON_FIELD_NUMBER: _ClassVar[int]
    TEXT_FIELD_NUMBER: _ClassVar[int]
    COLOR_FIELD_NUMBER: _ClassVar[int]
    id: int
    icon: str
    text: str
    color: str
    def __init__(self, id: _Optional[int] = ..., icon: _Optional[str] = ..., text: _Optional[str] = ..., color: _Optional[str] = ...) -> None: ...

class ReceiptRecipientShareInput(_message.Message):
    __slots__ = ("user_id", "share_percent")
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    SHARE_PERCENT_FIELD_NUMBER: _ClassVar[int]
    user_id: int
    share_percent: float
    def __init__(self, user_id: _Optional[int] = ..., share_percent: _Optional[float] = ...) -> None: ...

class ReceiptSplitInput(_message.Message):
    __slots__ = ("owner_share_percent", "recipient_shares")
    OWNER_SHARE_PERCENT_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_SHARES_FIELD_NUMBER: _ClassVar[int]
    owner_share_percent: float
    recipient_shares: _containers.RepeatedCompositeFieldContainer[ReceiptRecipientShareInput]
    def __init__(self, owner_share_percent: _Optional[float] = ..., recipient_shares: _Optional[_Iterable[_Union[ReceiptRecipientShareInput, _Mapping]]] = ...) -> None: ...

class ReceiptRecipientShare(_message.Message):
    __slots__ = ("user_id", "share_percent", "amount", "user_name", "user_email", "amount_paid")
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    SHARE_PERCENT_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_FIELD_NUMBER: _ClassVar[int]
    USER_NAME_FIELD_NUMBER: _ClassVar[int]
    USER_EMAIL_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    user_id: int
    share_percent: float
    amount: float
    user_name: str
    user_email: str
    amount_paid: float
    def __init__(self, user_id: _Optional[int] = ..., share_percent: _Optional[float] = ..., amount: _Optional[float] = ..., user_name: _Optional[str] = ..., user_email: _Optional[str] = ..., amount_paid: _Optional[float] = ...) -> None: ...

class ReceiptSplit(_message.Message):
    __slots__ = ("owner_share_percent", "owner_amount", "recipient_shares", "owner_amount_paid")
    OWNER_SHARE_PERCENT_FIELD_NUMBER: _ClassVar[int]
    OWNER_AMOUNT_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_SHARES_FIELD_NUMBER: _ClassVar[int]
    OWNER_AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    owner_share_percent: float
    owner_amount: float
    recipient_shares: _containers.RepeatedCompositeFieldContainer[ReceiptRecipientShare]
    owner_amount_paid: float
    def __init__(self, owner_share_percent: _Optional[float] = ..., owner_amount: _Optional[float] = ..., recipient_shares: _Optional[_Iterable[_Union[ReceiptRecipientShare, _Mapping]]] = ..., owner_amount_paid: _Optional[float] = ...) -> None: ...

class Receipt(_message.Message):
    __slots__ = ("id", "title", "description", "amount_owed", "amount_paid", "due_date", "is_paid", "currency", "paid_at", "notes", "created_at", "updated_at", "owner_id", "recipient_id", "recipient_name", "recipient", "files", "tags", "split")
    ID_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_OWED_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    DUE_DATE_FIELD_NUMBER: _ClassVar[int]
    IS_PAID_FIELD_NUMBER: _ClassVar[int]
    CURRENCY_FIELD_NUMBER: _ClassVar[int]
    PAID_AT_FIELD_NUMBER: _ClassVar[int]
    NOTES_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    UPDATED_AT_FIELD_NUMBER: _ClassVar[int]
    OWNER_ID_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_ID_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_NAME_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_FIELD_NUMBER: _ClassVar[int]
    FILES_FIELD_NUMBER: _ClassVar[int]
    TAGS_FIELD_NUMBER: _ClassVar[int]
    SPLIT_FIELD_NUMBER: _ClassVar[int]
    id: int
    title: str
    description: str
    amount_owed: float
    amount_paid: float
    due_date: str
    is_paid: bool
    currency: str
    paid_at: str
    notes: str
    created_at: str
    updated_at: str
    owner_id: int
    recipient_id: int
    recipient_name: str
    recipient: Recipient
    files: _containers.RepeatedCompositeFieldContainer[ReceiptFile]
    tags: _containers.RepeatedCompositeFieldContainer[TagIndex]
    split: ReceiptSplit
    def __init__(self, id: _Optional[int] = ..., title: _Optional[str] = ..., description: _Optional[str] = ..., amount_owed: _Optional[float] = ..., amount_paid: _Optional[float] = ..., due_date: _Optional[str] = ..., is_paid: _Optional[bool] = ..., currency: _Optional[str] = ..., paid_at: _Optional[str] = ..., notes: _Optional[str] = ..., created_at: _Optional[str] = ..., updated_at: _Optional[str] = ..., owner_id: _Optional[int] = ..., recipient_id: _Optional[int] = ..., recipient_name: _Optional[str] = ..., recipient: _Optional[_Union[Recipient, _Mapping]] = ..., files: _Optional[_Iterable[_Union[ReceiptFile, _Mapping]]] = ..., tags: _Optional[_Iterable[_Union[TagIndex, _Mapping]]] = ..., split: _Optional[_Union[ReceiptSplit, _Mapping]] = ...) -> None: ...

class ActionResponse(_message.Message):
    __slots__ = ("success", "message")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ...) -> None: ...

class UserResponse(_message.Message):
    __slots__ = ("success", "message", "user")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    USER_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    user: User
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., user: _Optional[_Union[User, _Mapping]] = ...) -> None: ...

class UsersResponse(_message.Message):
    __slots__ = ("success", "message", "users")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    USERS_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    users: _containers.RepeatedCompositeFieldContainer[User]
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., users: _Optional[_Iterable[_Union[User, _Mapping]]] = ...) -> None: ...

class RecipientResponse(_message.Message):
    __slots__ = ("success", "message", "recipient")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    recipient: Recipient
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., recipient: _Optional[_Union[Recipient, _Mapping]] = ...) -> None: ...

class RecipientsResponse(_message.Message):
    __slots__ = ("success", "message", "recipients")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RECIPIENTS_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    recipients: _containers.RepeatedCompositeFieldContainer[Recipient]
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., recipients: _Optional[_Iterable[_Union[Recipient, _Mapping]]] = ...) -> None: ...

class ReceiptResponse(_message.Message):
    __slots__ = ("success", "message", "receipt")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RECEIPT_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    receipt: Receipt
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., receipt: _Optional[_Union[Receipt, _Mapping]] = ...) -> None: ...

class ReceiptsResponse(_message.Message):
    __slots__ = ("success", "message", "receipts", "next_page_token")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RECEIPTS_FIELD_NUMBER: _ClassVar[int]
    NEXT_PAGE_TOKEN_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    receipts: _containers.RepeatedCompositeFieldContainer[Receipt]
    next_page_token: str
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., receipts: _Optional[_Iterable[_Union[Receipt, _Mapping]]] = ..., next_page_token: _Optional[str] = ...) -> None: ...

class ReceiptUnpaidSummaryRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ReceiptUnpaidSummaryResponse(_message.Message):
    __slots__ = ("success", "message", "unpaid_share_total", "unpaid_bill_count")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    UNPAID_SHARE_TOTAL_FIELD_NUMBER: _ClassVar[int]
    UNPAID_BILL_COUNT_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    unpaid_share_total: float
    unpaid_bill_count: int
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., unpaid_share_total: _Optional[float] = ..., unpaid_bill_count: _Optional[int] = ...) -> None: ...

class FileResponse(_message.Message):
    __slots__ = ("success", "message", "file")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    FILE_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    file: ReceiptFile
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., file: _Optional[_Union[ReceiptFile, _Mapping]] = ...) -> None: ...

class FilesResponse(_message.Message):
    __slots__ = ("success", "message", "files")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    FILES_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    files: _containers.RepeatedCompositeFieldContainer[ReceiptFile]
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., files: _Optional[_Iterable[_Union[ReceiptFile, _Mapping]]] = ...) -> None: ...

class TagResponse(_message.Message):
    __slots__ = ("success", "message", "tag")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    TAG_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    tag: TagIndex
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., tag: _Optional[_Union[TagIndex, _Mapping]] = ...) -> None: ...

class TagsResponse(_message.Message):
    __slots__ = ("success", "message", "tags")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    TAGS_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    tags: _containers.RepeatedCompositeFieldContainer[TagIndex]
    def __init__(self, success: _Optional[bool] = ..., message: _Optional[str] = ..., tags: _Optional[_Iterable[_Union[TagIndex, _Mapping]]] = ...) -> None: ...

class UpdateUserRequest(_message.Message):
    __slots__ = ("email", "name", "avatar_url")
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    AVATAR_URL_FIELD_NUMBER: _ClassVar[int]
    email: str
    name: str
    avatar_url: str
    def __init__(self, email: _Optional[str] = ..., name: _Optional[str] = ..., avatar_url: _Optional[str] = ...) -> None: ...

class UserSearchRequest(_message.Message):
    __slots__ = ("query", "limit")
    QUERY_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    query: str
    limit: int
    def __init__(self, query: _Optional[str] = ..., limit: _Optional[int] = ...) -> None: ...

class CreateRecipientRequest(_message.Message):
    __slots__ = ("name", "description", "member_ids")
    NAME_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    MEMBER_IDS_FIELD_NUMBER: _ClassVar[int]
    name: str
    description: str
    member_ids: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, name: _Optional[str] = ..., description: _Optional[str] = ..., member_ids: _Optional[_Iterable[int]] = ...) -> None: ...

class RecipientLookupRequest(_message.Message):
    __slots__ = ("recipient_id",)
    RECIPIENT_ID_FIELD_NUMBER: _ClassVar[int]
    recipient_id: int
    def __init__(self, recipient_id: _Optional[int] = ...) -> None: ...

class UpdateRecipientRequest(_message.Message):
    __slots__ = ("recipient_id", "name", "description")
    RECIPIENT_ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    recipient_id: int
    name: str
    description: str
    def __init__(self, recipient_id: _Optional[int] = ..., name: _Optional[str] = ..., description: _Optional[str] = ...) -> None: ...

class RecipientMemberRequest(_message.Message):
    __slots__ = ("recipient_id", "user_id")
    RECIPIENT_ID_FIELD_NUMBER: _ClassVar[int]
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    recipient_id: int
    user_id: int
    def __init__(self, recipient_id: _Optional[int] = ..., user_id: _Optional[int] = ...) -> None: ...

class CreateReceiptRequest(_message.Message):
    __slots__ = ("title", "amount_owed", "currency", "recipient_id", "description", "due_date", "notes", "split")
    TITLE_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_OWED_FIELD_NUMBER: _ClassVar[int]
    CURRENCY_FIELD_NUMBER: _ClassVar[int]
    RECIPIENT_ID_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    DUE_DATE_FIELD_NUMBER: _ClassVar[int]
    NOTES_FIELD_NUMBER: _ClassVar[int]
    SPLIT_FIELD_NUMBER: _ClassVar[int]
    title: str
    amount_owed: float
    currency: str
    recipient_id: int
    description: str
    due_date: str
    notes: str
    split: ReceiptSplitInput
    def __init__(self, title: _Optional[str] = ..., amount_owed: _Optional[float] = ..., currency: _Optional[str] = ..., recipient_id: _Optional[int] = ..., description: _Optional[str] = ..., due_date: _Optional[str] = ..., notes: _Optional[str] = ..., split: _Optional[_Union[ReceiptSplitInput, _Mapping]] = ...) -> None: ...

class ReceiptLookupRequest(_message.Message):
    __slots__ = ("receipt_id",)
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    def __init__(self, receipt_id: _Optional[int] = ...) -> None: ...

class ReceiptListRequest(_message.Message):
    __slots__ = ("is_paid", "tag_ids", "cursor", "limit", "order_by", "order_direction", "actor_filter", "page_token")
    IS_PAID_FIELD_NUMBER: _ClassVar[int]
    TAG_IDS_FIELD_NUMBER: _ClassVar[int]
    CURSOR_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    ORDER_BY_FIELD_NUMBER: _ClassVar[int]
    ORDER_DIRECTION_FIELD_NUMBER: _ClassVar[int]
    ACTOR_FILTER_FIELD_NUMBER: _ClassVar[int]
    PAGE_TOKEN_FIELD_NUMBER: _ClassVar[int]
    is_paid: bool
    tag_ids: _containers.RepeatedScalarFieldContainer[int]
    cursor: int
    limit: int
    order_by: ReceiptOrderBy
    order_direction: ReceiptOrderDirection
    actor_filter: ReceiptActorFilter
    page_token: str
    def __init__(self, is_paid: _Optional[bool] = ..., tag_ids: _Optional[_Iterable[int]] = ..., cursor: _Optional[int] = ..., limit: _Optional[int] = ..., order_by: _Optional[_Union[ReceiptOrderBy, str]] = ..., order_direction: _Optional[_Union[ReceiptOrderDirection, str]] = ..., actor_filter: _Optional[_Union[ReceiptActorFilter, str]] = ..., page_token: _Optional[str] = ...) -> None: ...

class UpdateReceiptRequest(_message.Message):
    __slots__ = ("receipt_id", "title", "description", "amount_owed", "amount_paid", "due_date", "notes", "currency", "split", "clear_split")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_OWED_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    DUE_DATE_FIELD_NUMBER: _ClassVar[int]
    NOTES_FIELD_NUMBER: _ClassVar[int]
    CURRENCY_FIELD_NUMBER: _ClassVar[int]
    SPLIT_FIELD_NUMBER: _ClassVar[int]
    CLEAR_SPLIT_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    title: str
    description: str
    amount_owed: float
    amount_paid: float
    due_date: str
    notes: str
    currency: str
    split: ReceiptSplitInput
    clear_split: bool
    def __init__(self, receipt_id: _Optional[int] = ..., title: _Optional[str] = ..., description: _Optional[str] = ..., amount_owed: _Optional[float] = ..., amount_paid: _Optional[float] = ..., due_date: _Optional[str] = ..., notes: _Optional[str] = ..., currency: _Optional[str] = ..., split: _Optional[_Union[ReceiptSplitInput, _Mapping]] = ..., clear_split: _Optional[bool] = ...) -> None: ...

class MarkReceiptPaidRequest(_message.Message):
    __slots__ = ("receipt_id", "amount_paid")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    amount_paid: float
    def __init__(self, receipt_id: _Optional[int] = ..., amount_paid: _Optional[float] = ...) -> None: ...

class ReceiptPaymentInput(_message.Message):
    __slots__ = ("user_id", "amount_paid")
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    AMOUNT_PAID_FIELD_NUMBER: _ClassVar[int]
    user_id: int
    amount_paid: float
    def __init__(self, user_id: _Optional[int] = ..., amount_paid: _Optional[float] = ...) -> None: ...

class SetReceiptPaymentsRequest(_message.Message):
    __slots__ = ("receipt_id", "payments")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    PAYMENTS_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    payments: _containers.RepeatedCompositeFieldContainer[ReceiptPaymentInput]
    def __init__(self, receipt_id: _Optional[int] = ..., payments: _Optional[_Iterable[_Union[ReceiptPaymentInput, _Mapping]]] = ...) -> None: ...

class ReceiptFileRequest(_message.Message):
    __slots__ = ("receipt_id", "original_filename", "content_type", "size_bytes", "sha256")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    ORIGINAL_FILENAME_FIELD_NUMBER: _ClassVar[int]
    CONTENT_TYPE_FIELD_NUMBER: _ClassVar[int]
    SIZE_BYTES_FIELD_NUMBER: _ClassVar[int]
    SHA256_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    original_filename: str
    content_type: str
    size_bytes: int
    sha256: str
    def __init__(self, receipt_id: _Optional[int] = ..., original_filename: _Optional[str] = ..., content_type: _Optional[str] = ..., size_bytes: _Optional[int] = ..., sha256: _Optional[str] = ...) -> None: ...

class FileLookupRequest(_message.Message):
    __slots__ = ("file_id",)
    FILE_ID_FIELD_NUMBER: _ClassVar[int]
    file_id: int
    def __init__(self, file_id: _Optional[int] = ...) -> None: ...

class FileListRequest(_message.Message):
    __slots__ = ("receipt_id",)
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    def __init__(self, receipt_id: _Optional[int] = ...) -> None: ...

class TagUpsertRequest(_message.Message):
    __slots__ = ("text", "icon", "color")
    TEXT_FIELD_NUMBER: _ClassVar[int]
    ICON_FIELD_NUMBER: _ClassVar[int]
    COLOR_FIELD_NUMBER: _ClassVar[int]
    text: str
    icon: str
    color: str
    def __init__(self, text: _Optional[str] = ..., icon: _Optional[str] = ..., color: _Optional[str] = ...) -> None: ...

class TagLookupRequest(_message.Message):
    __slots__ = ("tag_id", "text")
    TAG_ID_FIELD_NUMBER: _ClassVar[int]
    TEXT_FIELD_NUMBER: _ClassVar[int]
    tag_id: int
    text: str
    def __init__(self, tag_id: _Optional[int] = ..., text: _Optional[str] = ...) -> None: ...

class UpdateTagRequest(_message.Message):
    __slots__ = ("tag_id", "icon", "color")
    TAG_ID_FIELD_NUMBER: _ClassVar[int]
    ICON_FIELD_NUMBER: _ClassVar[int]
    COLOR_FIELD_NUMBER: _ClassVar[int]
    tag_id: int
    icon: str
    color: str
    def __init__(self, tag_id: _Optional[int] = ..., icon: _Optional[str] = ..., color: _Optional[str] = ...) -> None: ...

class TagReceiptRequest(_message.Message):
    __slots__ = ("receipt_id", "tag_id")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    TAG_ID_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    tag_id: int
    def __init__(self, receipt_id: _Optional[int] = ..., tag_id: _Optional[int] = ...) -> None: ...

class SetReceiptTagsRequest(_message.Message):
    __slots__ = ("receipt_id", "tag_ids")
    RECEIPT_ID_FIELD_NUMBER: _ClassVar[int]
    TAG_IDS_FIELD_NUMBER: _ClassVar[int]
    receipt_id: int
    tag_ids: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, receipt_id: _Optional[int] = ..., tag_ids: _Optional[_Iterable[int]] = ...) -> None: ...
