// This is a generated file - do not edit.
//
// Generated from auth.proto.

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

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSIQoMYWNjZXNzX3Rva2VuGAEgASgJUgthY2Nlc3NUb2tlbhIUCgVlbW'
    'FpbBgCIAEoCVIFZW1haWwSEgoEbmFtZRgDIAEoCVIEbmFtZRIdCgphdmF0YXJfdXJsGAQgASgJ'
    'UglhdmF0YXJVcmw=');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'auth0_sub', '3': 3, '4': 1, '5': 9, '10': 'auth0Sub'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFwoHdXNlcl9pZBgCIA'
    'EoCVIGdXNlcklkEhsKCWF1dGgwX3N1YhgDIAEoCVIIYXV0aDBTdWISFAoFZW1haWwYBCABKAlS'
    'BWVtYWlsEhgKB21lc3NhZ2UYBSABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use tokenVerifyRequestDescriptor instead')
const TokenVerifyRequest$json = {
  '1': 'TokenVerifyRequest',
  '2': [
    {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `TokenVerifyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenVerifyRequestDescriptor = $convert.base64Decode(
    'ChJUb2tlblZlcmlmeVJlcXVlc3QSIQoMYWNjZXNzX3Rva2VuGAEgASgJUgthY2Nlc3NUb2tlbg'
    '==');

@$core.Deprecated('Use tokenVerifyResponseDescriptor instead')
const TokenVerifyResponse$json = {
  '1': 'TokenVerifyResponse',
  '2': [
    {'1': 'valid', '3': 1, '4': 1, '5': 8, '10': 'valid'},
    {'1': 'auth0_sub', '3': 2, '4': 1, '5': 9, '10': 'auth0Sub'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'expires_at', '3': 4, '4': 1, '5': 3, '10': 'expiresAt'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `TokenVerifyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenVerifyResponseDescriptor = $convert.base64Decode(
    'ChNUb2tlblZlcmlmeVJlc3BvbnNlEhQKBXZhbGlkGAEgASgIUgV2YWxpZBIbCglhdXRoMF9zdW'
    'IYAiABKAlSCGF1dGgwU3ViEhQKBWVtYWlsGAMgASgJUgVlbWFpbBIdCgpleHBpcmVzX2F0GAQg'
    'ASgDUglleHBpcmVzQXQSGAoHbWVzc2FnZRgFIAEoCVIHbWVzc2FnZQ==');
