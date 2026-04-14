// This is a generated file - do not edit.
//
// Generated from debt.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use emptyRequestDescriptor instead')
const EmptyRequest$json = {
  '1': 'EmptyRequest',
};

/// Descriptor for `EmptyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyRequestDescriptor =
    $convert.base64Decode('CgxFbXB0eVJlcXVlc3Q=');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'sub', '3': 2, '4': 1, '5': 9, '10': 'sub'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'email', '17': true},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {
      '1': 'avatar_url',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'avatarUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_email'},
    {'1': '_name'},
    {'1': '_avatar_url'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgDUgJpZBIQCgNzdWIYAiABKAlSA3N1YhIZCgVlbWFpbBgDIAEoCU'
    'gAUgVlbWFpbIgBARIXCgRuYW1lGAQgASgJSAFSBG5hbWWIAQESIgoKYXZhdGFyX3VybBgFIAEo'
    'CUgCUglhdmF0YXJVcmyIAQFCCAoGX2VtYWlsQgcKBV9uYW1lQg0KC19hdmF0YXJfdXJs');

@$core.Deprecated('Use recipientDescriptor instead')
const Recipient$json = {
  '1': 'Recipient',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'owner_id', '3': 3, '4': 1, '5': 3, '10': 'ownerId'},
    {
      '1': 'description',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {'1': 'created_at', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'members',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.debt.User',
      '10': 'members'
    },
    {'1': 'member_ids', '3': 7, '4': 3, '5': 3, '10': 'memberIds'},
  ],
  '8': [
    {'1': '_description'},
  ],
};

/// Descriptor for `Recipient`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recipientDescriptor = $convert.base64Decode(
    'CglSZWNpcGllbnQSDgoCaWQYASABKANSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGQoIb3duZX'
    'JfaWQYAyABKANSB293bmVySWQSJQoLZGVzY3JpcHRpb24YBCABKAlIAFILZGVzY3JpcHRpb26I'
    'AQESHQoKY3JlYXRlZF9hdBgFIAEoCVIJY3JlYXRlZEF0EiQKB21lbWJlcnMYBiADKAsyCi5kZW'
    'J0LlVzZXJSB21lbWJlcnMSHQoKbWVtYmVyX2lkcxgHIAMoA1IJbWVtYmVySWRzQg4KDF9kZXNj'
    'cmlwdGlvbg==');

@$core.Deprecated('Use receiptFileDescriptor instead')
const ReceiptFile$json = {
  '1': 'ReceiptFile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'receipt_id', '3': 2, '4': 1, '5': 3, '10': 'receiptId'},
    {
      '1': 'original_filename',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'originalFilename'
    },
    {
      '1': 'content_type',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'contentType',
      '17': true
    },
    {
      '1': 'size_bytes',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'sizeBytes',
      '17': true
    },
    {'1': 'sha256', '3': 6, '4': 1, '5': 9, '9': 2, '10': 'sha256', '17': true},
    {'1': 'created_at', '3': 7, '4': 1, '5': 9, '10': 'createdAt'},
  ],
  '8': [
    {'1': '_content_type'},
    {'1': '_size_bytes'},
    {'1': '_sha256'},
  ],
};

/// Descriptor for `ReceiptFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptFileDescriptor = $convert.base64Decode(
    'CgtSZWNlaXB0RmlsZRIOCgJpZBgBIAEoA1ICaWQSHQoKcmVjZWlwdF9pZBgCIAEoA1IJcmVjZW'
    'lwdElkEisKEW9yaWdpbmFsX2ZpbGVuYW1lGAMgASgJUhBvcmlnaW5hbEZpbGVuYW1lEiYKDGNv'
    'bnRlbnRfdHlwZRgEIAEoCUgAUgtjb250ZW50VHlwZYgBARIiCgpzaXplX2J5dGVzGAUgASgDSA'
    'FSCXNpemVCeXRlc4gBARIbCgZzaGEyNTYYBiABKAlIAlIGc2hhMjU2iAEBEh0KCmNyZWF0ZWRf'
    'YXQYByABKAlSCWNyZWF0ZWRBdEIPCg1fY29udGVudF90eXBlQg0KC19zaXplX2J5dGVzQgkKB1'
    '9zaGEyNTY=');

@$core.Deprecated('Use tagIndexDescriptor instead')
const TagIndex$json = {
  '1': 'TagIndex',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'icon', '3': 2, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'color', '3': 4, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `TagIndex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagIndexDescriptor = $convert.base64Decode(
    'CghUYWdJbmRleBIOCgJpZBgBIAEoA1ICaWQSEgoEaWNvbhgCIAEoCVIEaWNvbhISCgR0ZXh0GA'
    'MgASgJUgR0ZXh0EhQKBWNvbG9yGAQgASgJUgVjb2xvcg==');

@$core.Deprecated('Use receiptDescriptor instead')
const Receipt$json = {
  '1': 'Receipt',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'description',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {'1': 'amount_owed', '3': 4, '4': 1, '5': 1, '10': 'amountOwed'},
    {
      '1': 'amount_paid',
      '3': 5,
      '4': 1,
      '5': 1,
      '9': 1,
      '10': 'amountPaid',
      '17': true
    },
    {
      '1': 'due_date',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'dueDate',
      '17': true
    },
    {'1': 'is_paid', '3': 7, '4': 1, '5': 8, '10': 'isPaid'},
    {'1': 'currency', '3': 8, '4': 1, '5': 9, '10': 'currency'},
    {
      '1': 'paid_at',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'paidAt',
      '17': true
    },
    {'1': 'notes', '3': 10, '4': 1, '5': 9, '9': 4, '10': 'notes', '17': true},
    {'1': 'created_at', '3': 11, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'updated_at',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'updatedAt',
      '17': true
    },
    {'1': 'owner_id', '3': 13, '4': 1, '5': 3, '10': 'ownerId'},
    {
      '1': 'recipient_id',
      '3': 14,
      '4': 1,
      '5': 3,
      '9': 6,
      '10': 'recipientId',
      '17': true
    },
    {
      '1': 'recipient_name',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'recipientName',
      '17': true
    },
    {
      '1': 'recipient',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.debt.Recipient',
      '9': 8,
      '10': 'recipient',
      '17': true
    },
    {
      '1': 'files',
      '3': 17,
      '4': 3,
      '5': 11,
      '6': '.debt.ReceiptFile',
      '10': 'files'
    },
    {
      '1': 'tags',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.debt.TagIndex',
      '10': 'tags'
    },
  ],
  '8': [
    {'1': '_description'},
    {'1': '_amount_paid'},
    {'1': '_due_date'},
    {'1': '_paid_at'},
    {'1': '_notes'},
    {'1': '_updated_at'},
    {'1': '_recipient_id'},
    {'1': '_recipient_name'},
    {'1': '_recipient'},
  ],
};

/// Descriptor for `Receipt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptDescriptor = $convert.base64Decode(
    'CgdSZWNlaXB0Eg4KAmlkGAEgASgDUgJpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSJQoLZGVzY3'
    'JpcHRpb24YAyABKAlIAFILZGVzY3JpcHRpb26IAQESHwoLYW1vdW50X293ZWQYBCABKAFSCmFt'
    'b3VudE93ZWQSJAoLYW1vdW50X3BhaWQYBSABKAFIAVIKYW1vdW50UGFpZIgBARIeCghkdWVfZG'
    'F0ZRgGIAEoCUgCUgdkdWVEYXRliAEBEhcKB2lzX3BhaWQYByABKAhSBmlzUGFpZBIaCghjdXJy'
    'ZW5jeRgIIAEoCVIIY3VycmVuY3kSHAoHcGFpZF9hdBgJIAEoCUgDUgZwYWlkQXSIAQESGQoFbm'
    '90ZXMYCiABKAlIBFIFbm90ZXOIAQESHQoKY3JlYXRlZF9hdBgLIAEoCVIJY3JlYXRlZEF0EiIK'
    'CnVwZGF0ZWRfYXQYDCABKAlIBVIJdXBkYXRlZEF0iAEBEhkKCG93bmVyX2lkGA0gASgDUgdvd2'
    '5lcklkEiYKDHJlY2lwaWVudF9pZBgOIAEoA0gGUgtyZWNpcGllbnRJZIgBARIqCg5yZWNpcGll'
    'bnRfbmFtZRgPIAEoCUgHUg1yZWNpcGllbnROYW1liAEBEjIKCXJlY2lwaWVudBgQIAEoCzIPLm'
    'RlYnQuUmVjaXBpZW50SAhSCXJlY2lwaWVudIgBARInCgVmaWxlcxgRIAMoCzIRLmRlYnQuUmVj'
    'ZWlwdEZpbGVSBWZpbGVzEiIKBHRhZ3MYEiADKAsyDi5kZWJ0LlRhZ0luZGV4UgR0YWdzQg4KDF'
    '9kZXNjcmlwdGlvbkIOCgxfYW1vdW50X3BhaWRCCwoJX2R1ZV9kYXRlQgoKCF9wYWlkX2F0QggK'
    'Bl9ub3Rlc0INCgtfdXBkYXRlZF9hdEIPCg1fcmVjaXBpZW50X2lkQhEKD19yZWNpcGllbnRfbm'
    'FtZUIMCgpfcmVjaXBpZW50');

@$core.Deprecated('Use actionResponseDescriptor instead')
const ActionResponse$json = {
  '1': 'ActionResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ActionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionResponseDescriptor = $convert.base64Decode(
    'Cg5BY3Rpb25SZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2UYAi'
    'ABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use userResponseDescriptor instead')
const UserResponse$json = {
  '1': 'UserResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'user', '3': 3, '4': 1, '5': 11, '6': '.debt.User', '10': 'user'},
  ],
};

/// Descriptor for `UserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userResponseDescriptor = $convert.base64Decode(
    'CgxVc2VyUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYWdlGAIgAS'
    'gJUgdtZXNzYWdlEh4KBHVzZXIYAyABKAsyCi5kZWJ0LlVzZXJSBHVzZXI=');

@$core.Deprecated('Use usersResponseDescriptor instead')
const UsersResponse$json = {
  '1': 'UsersResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'users', '3': 3, '4': 3, '5': 11, '6': '.debt.User', '10': 'users'},
  ],
};

/// Descriptor for `UsersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List usersResponseDescriptor = $convert.base64Decode(
    'Cg1Vc2Vyc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZRgCIA'
    'EoCVIHbWVzc2FnZRIgCgV1c2VycxgDIAMoCzIKLmRlYnQuVXNlclIFdXNlcnM=');

@$core.Deprecated('Use recipientResponseDescriptor instead')
const RecipientResponse$json = {
  '1': 'RecipientResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'recipient',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.debt.Recipient',
      '10': 'recipient'
    },
  ],
};

/// Descriptor for `RecipientResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recipientResponseDescriptor = $convert.base64Decode(
    'ChFSZWNpcGllbnRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USLQoJcmVjaXBpZW50GAMgASgLMg8uZGVidC5SZWNpcGllbnRSCXJl'
    'Y2lwaWVudA==');

@$core.Deprecated('Use recipientsResponseDescriptor instead')
const RecipientsResponse$json = {
  '1': 'RecipientsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'recipients',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.debt.Recipient',
      '10': 'recipients'
    },
  ],
};

/// Descriptor for `RecipientsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recipientsResponseDescriptor = $convert.base64Decode(
    'ChJSZWNpcGllbnRzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdlEi8KCnJlY2lwaWVudHMYAyADKAsyDy5kZWJ0LlJlY2lwaWVudFIK'
    'cmVjaXBpZW50cw==');

@$core.Deprecated('Use receiptResponseDescriptor instead')
const ReceiptResponse$json = {
  '1': 'ReceiptResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'receipt',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.debt.Receipt',
      '10': 'receipt'
    },
  ],
};

/// Descriptor for `ReceiptResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptResponseDescriptor = $convert.base64Decode(
    'Cg9SZWNlaXB0UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYWdlGA'
    'IgASgJUgdtZXNzYWdlEicKB3JlY2VpcHQYAyABKAsyDS5kZWJ0LlJlY2VpcHRSB3JlY2VpcHQ=');

@$core.Deprecated('Use receiptsResponseDescriptor instead')
const ReceiptsResponse$json = {
  '1': 'ReceiptsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'receipts',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.debt.Receipt',
      '10': 'receipts'
    },
  ],
};

/// Descriptor for `ReceiptsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptsResponseDescriptor = $convert.base64Decode(
    'ChBSZWNlaXB0c1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZRIpCghyZWNlaXB0cxgDIAMoCzINLmRlYnQuUmVjZWlwdFIIcmVjZWlw'
    'dHM=');

@$core.Deprecated('Use fileResponseDescriptor instead')
const FileResponse$json = {
  '1': 'FileResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'file',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.debt.ReceiptFile',
      '10': 'file'
    },
  ],
};

/// Descriptor for `FileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileResponseDescriptor = $convert.base64Decode(
    'CgxGaWxlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYWdlGAIgAS'
    'gJUgdtZXNzYWdlEiUKBGZpbGUYAyABKAsyES5kZWJ0LlJlY2VpcHRGaWxlUgRmaWxl');

@$core.Deprecated('Use filesResponseDescriptor instead')
const FilesResponse$json = {
  '1': 'FilesResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'files',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.debt.ReceiptFile',
      '10': 'files'
    },
  ],
};

/// Descriptor for `FilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filesResponseDescriptor = $convert.base64Decode(
    'Cg1GaWxlc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZRgCIA'
    'EoCVIHbWVzc2FnZRInCgVmaWxlcxgDIAMoCzIRLmRlYnQuUmVjZWlwdEZpbGVSBWZpbGVz');

@$core.Deprecated('Use tagResponseDescriptor instead')
const TagResponse$json = {
  '1': 'TagResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'tag', '3': 3, '4': 1, '5': 11, '6': '.debt.TagIndex', '10': 'tag'},
  ],
};

/// Descriptor for `TagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagResponseDescriptor = $convert.base64Decode(
    'CgtUYWdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2UYAiABKA'
    'lSB21lc3NhZ2USIAoDdGFnGAMgASgLMg4uZGVidC5UYWdJbmRleFIDdGFn');

@$core.Deprecated('Use tagsResponseDescriptor instead')
const TagsResponse$json = {
  '1': 'TagsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'tags', '3': 3, '4': 3, '5': 11, '6': '.debt.TagIndex', '10': 'tags'},
  ],
};

/// Descriptor for `TagsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagsResponseDescriptor = $convert.base64Decode(
    'CgxUYWdzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYWdlGAIgAS'
    'gJUgdtZXNzYWdlEiIKBHRhZ3MYAyADKAsyDi5kZWJ0LlRhZ0luZGV4UgR0YWdz');

@$core.Deprecated('Use updateUserRequestDescriptor instead')
const UpdateUserRequest$json = {
  '1': 'UpdateUserRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'email', '17': true},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {
      '1': 'avatar_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'avatarUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_email'},
    {'1': '_name'},
    {'1': '_avatar_url'},
  ],
};

/// Descriptor for `UpdateUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVVc2VyUmVxdWVzdBIZCgVlbWFpbBgBIAEoCUgAUgVlbWFpbIgBARIXCgRuYW1lGA'
    'IgASgJSAFSBG5hbWWIAQESIgoKYXZhdGFyX3VybBgDIAEoCUgCUglhdmF0YXJVcmyIAQFCCAoG'
    'X2VtYWlsQgcKBV9uYW1lQg0KC19hdmF0YXJfdXJs');

@$core.Deprecated('Use createRecipientRequestDescriptor instead')
const CreateRecipientRequest$json = {
  '1': 'CreateRecipientRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'description',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {'1': 'member_ids', '3': 3, '4': 3, '5': 3, '10': 'memberIds'},
  ],
  '8': [
    {'1': '_description'},
  ],
};

/// Descriptor for `CreateRecipientRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createRecipientRequestDescriptor = $convert.base64Decode(
    'ChZDcmVhdGVSZWNpcGllbnRSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSJQoLZGVzY3JpcH'
    'Rpb24YAiABKAlIAFILZGVzY3JpcHRpb26IAQESHQoKbWVtYmVyX2lkcxgDIAMoA1IJbWVtYmVy'
    'SWRzQg4KDF9kZXNjcmlwdGlvbg==');

@$core.Deprecated('Use recipientLookupRequestDescriptor instead')
const RecipientLookupRequest$json = {
  '1': 'RecipientLookupRequest',
  '2': [
    {'1': 'recipient_id', '3': 1, '4': 1, '5': 3, '10': 'recipientId'},
  ],
};

/// Descriptor for `RecipientLookupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recipientLookupRequestDescriptor =
    $convert.base64Decode(
        'ChZSZWNpcGllbnRMb29rdXBSZXF1ZXN0EiEKDHJlY2lwaWVudF9pZBgBIAEoA1ILcmVjaXBpZW'
        '50SWQ=');

@$core.Deprecated('Use updateRecipientRequestDescriptor instead')
const UpdateRecipientRequest$json = {
  '1': 'UpdateRecipientRequest',
  '2': [
    {'1': 'recipient_id', '3': 1, '4': 1, '5': 3, '10': 'recipientId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'description',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'description',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_description'},
  ],
};

/// Descriptor for `UpdateRecipientRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateRecipientRequestDescriptor = $convert.base64Decode(
    'ChZVcGRhdGVSZWNpcGllbnRSZXF1ZXN0EiEKDHJlY2lwaWVudF9pZBgBIAEoA1ILcmVjaXBpZW'
    '50SWQSFwoEbmFtZRgCIAEoCUgAUgRuYW1liAEBEiUKC2Rlc2NyaXB0aW9uGAMgASgJSAFSC2Rl'
    'c2NyaXB0aW9uiAEBQgcKBV9uYW1lQg4KDF9kZXNjcmlwdGlvbg==');

@$core.Deprecated('Use recipientMemberRequestDescriptor instead')
const RecipientMemberRequest$json = {
  '1': 'RecipientMemberRequest',
  '2': [
    {'1': 'recipient_id', '3': 1, '4': 1, '5': 3, '10': 'recipientId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 3, '10': 'userId'},
  ],
};

/// Descriptor for `RecipientMemberRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recipientMemberRequestDescriptor =
    $convert.base64Decode(
        'ChZSZWNpcGllbnRNZW1iZXJSZXF1ZXN0EiEKDHJlY2lwaWVudF9pZBgBIAEoA1ILcmVjaXBpZW'
        '50SWQSFwoHdXNlcl9pZBgCIAEoA1IGdXNlcklk');

@$core.Deprecated('Use createReceiptRequestDescriptor instead')
const CreateReceiptRequest$json = {
  '1': 'CreateReceiptRequest',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'amount_owed', '3': 2, '4': 1, '5': 1, '10': 'amountOwed'},
    {
      '1': 'currency',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'currency',
      '17': true
    },
    {
      '1': 'recipient_id',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'recipientId',
      '17': true
    },
    {
      '1': 'description',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'description',
      '17': true
    },
    {
      '1': 'due_date',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'dueDate',
      '17': true
    },
    {'1': 'notes', '3': 7, '4': 1, '5': 9, '9': 4, '10': 'notes', '17': true},
  ],
  '8': [
    {'1': '_currency'},
    {'1': '_recipient_id'},
    {'1': '_description'},
    {'1': '_due_date'},
    {'1': '_notes'},
  ],
};

/// Descriptor for `CreateReceiptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createReceiptRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVSZWNlaXB0UmVxdWVzdBIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSHwoLYW1vdW50X2'
    '93ZWQYAiABKAFSCmFtb3VudE93ZWQSHwoIY3VycmVuY3kYAyABKAlIAFIIY3VycmVuY3mIAQES'
    'JgoMcmVjaXBpZW50X2lkGAQgASgDSAFSC3JlY2lwaWVudElkiAEBEiUKC2Rlc2NyaXB0aW9uGA'
    'UgASgJSAJSC2Rlc2NyaXB0aW9uiAEBEh4KCGR1ZV9kYXRlGAYgASgJSANSB2R1ZURhdGWIAQES'
    'GQoFbm90ZXMYByABKAlIBFIFbm90ZXOIAQFCCwoJX2N1cnJlbmN5Qg8KDV9yZWNpcGllbnRfaW'
    'RCDgoMX2Rlc2NyaXB0aW9uQgsKCV9kdWVfZGF0ZUIICgZfbm90ZXM=');

@$core.Deprecated('Use receiptLookupRequestDescriptor instead')
const ReceiptLookupRequest$json = {
  '1': 'ReceiptLookupRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
  ],
};

/// Descriptor for `ReceiptLookupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptLookupRequestDescriptor = $convert.base64Decode(
    'ChRSZWNlaXB0TG9va3VwUmVxdWVzdBIdCgpyZWNlaXB0X2lkGAEgASgDUglyZWNlaXB0SWQ=');

@$core.Deprecated('Use receiptListRequestDescriptor instead')
const ReceiptListRequest$json = {
  '1': 'ReceiptListRequest',
  '2': [
    {
      '1': 'is_paid',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'isPaid',
      '17': true
    },
    {'1': 'tag_ids', '3': 2, '4': 3, '5': 3, '10': 'tagIds'},
    {'1': 'cursor', '3': 3, '4': 1, '5': 3, '9': 1, '10': 'cursor', '17': true},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '9': 2, '10': 'limit', '17': true},
  ],
  '8': [
    {'1': '_is_paid'},
    {'1': '_cursor'},
    {'1': '_limit'},
  ],
};

/// Descriptor for `ReceiptListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptListRequestDescriptor = $convert.base64Decode(
    'ChJSZWNlaXB0TGlzdFJlcXVlc3QSHAoHaXNfcGFpZBgBIAEoCEgAUgZpc1BhaWSIAQESFwoHdG'
    'FnX2lkcxgCIAMoA1IGdGFnSWRzEhsKBmN1cnNvchgDIAEoA0gBUgZjdXJzb3KIAQESGQoFbGlt'
    'aXQYBCABKAVIAlIFbGltaXSIAQFCCgoIX2lzX3BhaWRCCQoHX2N1cnNvckIICgZfbGltaXQ=');

@$core.Deprecated('Use updateReceiptRequestDescriptor instead')
const UpdateReceiptRequest$json = {
  '1': 'UpdateReceiptRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'title', '17': true},
    {
      '1': 'description',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'description',
      '17': true
    },
    {
      '1': 'amount_owed',
      '3': 4,
      '4': 1,
      '5': 1,
      '9': 2,
      '10': 'amountOwed',
      '17': true
    },
    {
      '1': 'amount_paid',
      '3': 5,
      '4': 1,
      '5': 1,
      '9': 3,
      '10': 'amountPaid',
      '17': true
    },
    {
      '1': 'due_date',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'dueDate',
      '17': true
    },
    {'1': 'notes', '3': 7, '4': 1, '5': 9, '9': 5, '10': 'notes', '17': true},
    {
      '1': 'currency',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'currency',
      '17': true
    },
  ],
  '8': [
    {'1': '_title'},
    {'1': '_description'},
    {'1': '_amount_owed'},
    {'1': '_amount_paid'},
    {'1': '_due_date'},
    {'1': '_notes'},
    {'1': '_currency'},
  ],
};

/// Descriptor for `UpdateReceiptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateReceiptRequestDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVSZWNlaXB0UmVxdWVzdBIdCgpyZWNlaXB0X2lkGAEgASgDUglyZWNlaXB0SWQSGQ'
    'oFdGl0bGUYAiABKAlIAFIFdGl0bGWIAQESJQoLZGVzY3JpcHRpb24YAyABKAlIAVILZGVzY3Jp'
    'cHRpb26IAQESJAoLYW1vdW50X293ZWQYBCABKAFIAlIKYW1vdW50T3dlZIgBARIkCgthbW91bn'
    'RfcGFpZBgFIAEoAUgDUgphbW91bnRQYWlkiAEBEh4KCGR1ZV9kYXRlGAYgASgJSARSB2R1ZURh'
    'dGWIAQESGQoFbm90ZXMYByABKAlIBVIFbm90ZXOIAQESHwoIY3VycmVuY3kYCCABKAlIBlIIY3'
    'VycmVuY3mIAQFCCAoGX3RpdGxlQg4KDF9kZXNjcmlwdGlvbkIOCgxfYW1vdW50X293ZWRCDgoM'
    'X2Ftb3VudF9wYWlkQgsKCV9kdWVfZGF0ZUIICgZfbm90ZXNCCwoJX2N1cnJlbmN5');

@$core.Deprecated('Use markReceiptPaidRequestDescriptor instead')
const MarkReceiptPaidRequest$json = {
  '1': 'MarkReceiptPaidRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
    {
      '1': 'amount_paid',
      '3': 2,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'amountPaid',
      '17': true
    },
  ],
  '8': [
    {'1': '_amount_paid'},
  ],
};

/// Descriptor for `MarkReceiptPaidRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReceiptPaidRequestDescriptor = $convert.base64Decode(
    'ChZNYXJrUmVjZWlwdFBhaWRSZXF1ZXN0Eh0KCnJlY2VpcHRfaWQYASABKANSCXJlY2VpcHRJZB'
    'IkCgthbW91bnRfcGFpZBgCIAEoAUgAUgphbW91bnRQYWlkiAEBQg4KDF9hbW91bnRfcGFpZA==');

@$core.Deprecated('Use receiptFileRequestDescriptor instead')
const ReceiptFileRequest$json = {
  '1': 'ReceiptFileRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
    {
      '1': 'original_filename',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'originalFilename'
    },
    {
      '1': 'content_type',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'contentType',
      '17': true
    },
    {
      '1': 'size_bytes',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'sizeBytes',
      '17': true
    },
    {'1': 'sha256', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'sha256', '17': true},
  ],
  '8': [
    {'1': '_content_type'},
    {'1': '_size_bytes'},
    {'1': '_sha256'},
  ],
};

/// Descriptor for `ReceiptFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptFileRequestDescriptor = $convert.base64Decode(
    'ChJSZWNlaXB0RmlsZVJlcXVlc3QSHQoKcmVjZWlwdF9pZBgBIAEoA1IJcmVjZWlwdElkEisKEW'
    '9yaWdpbmFsX2ZpbGVuYW1lGAIgASgJUhBvcmlnaW5hbEZpbGVuYW1lEiYKDGNvbnRlbnRfdHlw'
    'ZRgDIAEoCUgAUgtjb250ZW50VHlwZYgBARIiCgpzaXplX2J5dGVzGAQgASgDSAFSCXNpemVCeX'
    'Rlc4gBARIbCgZzaGEyNTYYBSABKAlIAlIGc2hhMjU2iAEBQg8KDV9jb250ZW50X3R5cGVCDQoL'
    'X3NpemVfYnl0ZXNCCQoHX3NoYTI1Ng==');

@$core.Deprecated('Use fileLookupRequestDescriptor instead')
const FileLookupRequest$json = {
  '1': 'FileLookupRequest',
  '2': [
    {'1': 'file_id', '3': 1, '4': 1, '5': 3, '10': 'fileId'},
  ],
};

/// Descriptor for `FileLookupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileLookupRequestDescriptor = $convert.base64Decode(
    'ChFGaWxlTG9va3VwUmVxdWVzdBIXCgdmaWxlX2lkGAEgASgDUgZmaWxlSWQ=');

@$core.Deprecated('Use fileListRequestDescriptor instead')
const FileListRequest$json = {
  '1': 'FileListRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
  ],
};

/// Descriptor for `FileListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileListRequestDescriptor = $convert.base64Decode(
    'Cg9GaWxlTGlzdFJlcXVlc3QSHQoKcmVjZWlwdF9pZBgBIAEoA1IJcmVjZWlwdElk');

@$core.Deprecated('Use tagUpsertRequestDescriptor instead')
const TagUpsertRequest$json = {
  '1': 'TagUpsertRequest',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'icon', '3': 2, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'color', '3': 3, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `TagUpsertRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagUpsertRequestDescriptor = $convert.base64Decode(
    'ChBUYWdVcHNlcnRSZXF1ZXN0EhIKBHRleHQYASABKAlSBHRleHQSEgoEaWNvbhgCIAEoCVIEaW'
    'NvbhIUCgVjb2xvchgDIAEoCVIFY29sb3I=');

@$core.Deprecated('Use tagLookupRequestDescriptor instead')
const TagLookupRequest$json = {
  '1': 'TagLookupRequest',
  '2': [
    {'1': 'tag_id', '3': 1, '4': 1, '5': 3, '9': 0, '10': 'tagId', '17': true},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'text', '17': true},
  ],
  '8': [
    {'1': '_tag_id'},
    {'1': '_text'},
  ],
};

/// Descriptor for `TagLookupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagLookupRequestDescriptor = $convert.base64Decode(
    'ChBUYWdMb29rdXBSZXF1ZXN0EhoKBnRhZ19pZBgBIAEoA0gAUgV0YWdJZIgBARIXCgR0ZXh0GA'
    'IgASgJSAFSBHRleHSIAQFCCQoHX3RhZ19pZEIHCgVfdGV4dA==');

@$core.Deprecated('Use updateTagRequestDescriptor instead')
const UpdateTagRequest$json = {
  '1': 'UpdateTagRequest',
  '2': [
    {'1': 'tag_id', '3': 1, '4': 1, '5': 3, '10': 'tagId'},
    {'1': 'icon', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'icon', '17': true},
    {'1': 'color', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'color', '17': true},
  ],
  '8': [
    {'1': '_icon'},
    {'1': '_color'},
  ],
};

/// Descriptor for `UpdateTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTagRequestDescriptor = $convert.base64Decode(
    'ChBVcGRhdGVUYWdSZXF1ZXN0EhUKBnRhZ19pZBgBIAEoA1IFdGFnSWQSFwoEaWNvbhgCIAEoCU'
    'gAUgRpY29uiAEBEhkKBWNvbG9yGAMgASgJSAFSBWNvbG9yiAEBQgcKBV9pY29uQggKBl9jb2xv'
    'cg==');

@$core.Deprecated('Use tagReceiptRequestDescriptor instead')
const TagReceiptRequest$json = {
  '1': 'TagReceiptRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
    {'1': 'tag_id', '3': 2, '4': 1, '5': 3, '10': 'tagId'},
  ],
};

/// Descriptor for `TagReceiptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagReceiptRequestDescriptor = $convert.base64Decode(
    'ChFUYWdSZWNlaXB0UmVxdWVzdBIdCgpyZWNlaXB0X2lkGAEgASgDUglyZWNlaXB0SWQSFQoGdG'
    'FnX2lkGAIgASgDUgV0YWdJZA==');

@$core.Deprecated('Use setReceiptTagsRequestDescriptor instead')
const SetReceiptTagsRequest$json = {
  '1': 'SetReceiptTagsRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 3, '10': 'receiptId'},
    {'1': 'tag_ids', '3': 2, '4': 3, '5': 3, '10': 'tagIds'},
  ],
};

/// Descriptor for `SetReceiptTagsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setReceiptTagsRequestDescriptor = $convert.base64Decode(
    'ChVTZXRSZWNlaXB0VGFnc1JlcXVlc3QSHQoKcmVjZWlwdF9pZBgBIAEoA1IJcmVjZWlwdElkEh'
    'cKB3RhZ19pZHMYAiADKANSBnRhZ0lkcw==');
