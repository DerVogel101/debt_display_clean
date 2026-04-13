//
//  Generated code. Do not modify.
//  source: auth.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? accessToken,
  }) {
    final $result = create();
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  LoginRequest._() : super();
  factory LoginRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LoginRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'auth'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LoginRequest clone() => LoginRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  LoginRequest createEmptyInstance() => create();
  static $pb.PbList<LoginRequest> createRepeated() =>
      $pb.PbList<LoginRequest>();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accessToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set accessToken($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAccessToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccessToken() => clearField(1);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.bool? success,
    $core.String? userId,
    $core.String? auth0Sub,
    $core.String? email,
    $core.String? message,
  }) {
    final $result = create();
    if (success != null) {
      $result.success = success;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (auth0Sub != null) {
      $result.auth0Sub = auth0Sub;
    }
    if (email != null) {
      $result.email = email;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  LoginResponse._() : super();
  factory LoginResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LoginResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'auth'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'auth0Sub')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LoginResponse clone() => LoginResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginResponse create() => LoginResponse._();
  LoginResponse createEmptyInstance() => create();
  static $pb.PbList<LoginResponse> createRepeated() =>
      $pb.PbList<LoginResponse>();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginResponse>(create);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get auth0Sub => $_getSZ(2);
  @$pb.TagNumber(3)
  set auth0Sub($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAuth0Sub() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuth0Sub() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(3);
  @$pb.TagNumber(4)
  set email($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => clearField(5);
}

class TokenVerifyRequest extends $pb.GeneratedMessage {
  factory TokenVerifyRequest({
    $core.String? accessToken,
  }) {
    final $result = create();
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  TokenVerifyRequest._() : super();
  factory TokenVerifyRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TokenVerifyRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TokenVerifyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'auth'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TokenVerifyRequest clone() => TokenVerifyRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TokenVerifyRequest copyWith(void Function(TokenVerifyRequest) updates) =>
      super.copyWith((message) => updates(message as TokenVerifyRequest))
          as TokenVerifyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TokenVerifyRequest create() => TokenVerifyRequest._();
  TokenVerifyRequest createEmptyInstance() => create();
  static $pb.PbList<TokenVerifyRequest> createRepeated() =>
      $pb.PbList<TokenVerifyRequest>();
  @$core.pragma('dart2js:noInline')
  static TokenVerifyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TokenVerifyRequest>(create);
  static TokenVerifyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accessToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set accessToken($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAccessToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccessToken() => clearField(1);
}

class TokenVerifyResponse extends $pb.GeneratedMessage {
  factory TokenVerifyResponse({
    $core.bool? valid,
    $core.String? auth0Sub,
    $core.String? email,
    $core.int? expiresAt,
    $core.String? message,
  }) {
    final $result = create();
    if (valid != null) {
      $result.valid = valid;
    }
    if (auth0Sub != null) {
      $result.auth0Sub = auth0Sub;
    }
    if (email != null) {
      $result.email = email;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  TokenVerifyResponse._() : super();
  factory TokenVerifyResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TokenVerifyResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TokenVerifyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'auth'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'valid')
    ..aOS(2, _omitFieldNames ? '' : 'auth0Sub')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aInt64(4, _omitFieldNames ? '' : 'expiresAt')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TokenVerifyResponse clone() =>
      TokenVerifyResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TokenVerifyResponse copyWith(void Function(TokenVerifyResponse) updates) =>
      super.copyWith((message) => updates(message as TokenVerifyResponse))
          as TokenVerifyResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TokenVerifyResponse create() => TokenVerifyResponse._();
  TokenVerifyResponse createEmptyInstance() => create();
  static $pb.PbList<TokenVerifyResponse> createRepeated() =>
      $pb.PbList<TokenVerifyResponse>();
  @$core.pragma('dart2js:noInline')
  static TokenVerifyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TokenVerifyResponse>(create);
  static TokenVerifyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get valid => $_getBF(0);
  @$pb.TagNumber(1)
  set valid($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearValid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get auth0Sub => $_getSZ(1);
  @$pb.TagNumber(2)
  set auth0Sub($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAuth0Sub() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuth0Sub() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get expiresAt => $_getIZ(3);
  @$pb.TagNumber(4)
  set expiresAt($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => clearField(5);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
