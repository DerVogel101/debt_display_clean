// This is a generated file - do not edit.
//
// Generated from debt.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class EmptyRequest extends $pb.GeneratedMessage {
  factory EmptyRequest() => create();

  EmptyRequest._();

  factory EmptyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EmptyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmptyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyRequest copyWith(void Function(EmptyRequest) updates) =>
      super.copyWith((message) => updates(message as EmptyRequest))
          as EmptyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmptyRequest create() => EmptyRequest._();
  @$core.override
  EmptyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EmptyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmptyRequest>(create);
  static EmptyRequest? _defaultInstance;
}

class User extends $pb.GeneratedMessage {
  factory User({
    $fixnum.Int64? id,
    $core.String? sub,
    $core.String? email,
    $core.String? name,
    $core.String? avatarUrl,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sub != null) result.sub = sub;
    if (email != null) result.email = email;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    return result;
  }

  User._();

  factory User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'User',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sub')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'avatarUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) =>
      super.copyWith((message) => updates(message as User)) as User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  @$core.override
  User createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static User getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sub => $_getSZ(1);
  @$pb.TagNumber(2)
  set sub($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSub() => $_has(1);
  @$pb.TagNumber(2)
  void clearSub() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set avatarUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatarUrl() => $_clearField(5);
}

class Recipient extends $pb.GeneratedMessage {
  factory Recipient({
    $fixnum.Int64? id,
    $core.String? name,
    $fixnum.Int64? ownerId,
    $core.String? description,
    $core.String? createdAt,
    $core.Iterable<User>? members,
    $core.Iterable<$fixnum.Int64>? memberIds,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (ownerId != null) result.ownerId = ownerId;
    if (description != null) result.description = description;
    if (createdAt != null) result.createdAt = createdAt;
    if (members != null) result.members.addAll(members);
    if (memberIds != null) result.memberIds.addAll(memberIds);
    return result;
  }

  Recipient._();

  factory Recipient.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Recipient.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Recipient',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerId')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOS(5, _omitFieldNames ? '' : 'createdAt')
    ..pPM<User>(6, _omitFieldNames ? '' : 'members', subBuilder: User.create)
    ..p<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'memberIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Recipient clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Recipient copyWith(void Function(Recipient) updates) =>
      super.copyWith((message) => updates(message as Recipient)) as Recipient;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Recipient create() => Recipient._();
  @$core.override
  Recipient createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Recipient getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Recipient>(create);
  static Recipient? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerId => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<User> get members => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$fixnum.Int64> get memberIds => $_getList(6);
}

class ReceiptFile extends $pb.GeneratedMessage {
  factory ReceiptFile({
    $fixnum.Int64? id,
    $fixnum.Int64? receiptId,
    $core.String? storageKey,
    $core.String? originalFilename,
    $core.String? contentType,
    $fixnum.Int64? sizeBytes,
    $core.String? sha256,
    $core.String? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (receiptId != null) result.receiptId = receiptId;
    if (storageKey != null) result.storageKey = storageKey;
    if (originalFilename != null) result.originalFilename = originalFilename;
    if (contentType != null) result.contentType = contentType;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (sha256 != null) result.sha256 = sha256;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  ReceiptFile._();

  factory ReceiptFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'receiptId')
    ..aOS(3, _omitFieldNames ? '' : 'storageKey')
    ..aOS(4, _omitFieldNames ? '' : 'originalFilename')
    ..aOS(5, _omitFieldNames ? '' : 'contentType')
    ..aInt64(6, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(7, _omitFieldNames ? '' : 'sha256')
    ..aOS(8, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptFile copyWith(void Function(ReceiptFile) updates) =>
      super.copyWith((message) => updates(message as ReceiptFile))
          as ReceiptFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptFile create() => ReceiptFile._();
  @$core.override
  ReceiptFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptFile>(create);
  static ReceiptFile? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get receiptId => $_getI64(1);
  @$pb.TagNumber(2)
  set receiptId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReceiptId() => $_has(1);
  @$pb.TagNumber(2)
  void clearReceiptId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get storageKey => $_getSZ(2);
  @$pb.TagNumber(3)
  set storageKey($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStorageKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearStorageKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get originalFilename => $_getSZ(3);
  @$pb.TagNumber(4)
  set originalFilename($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOriginalFilename() => $_has(3);
  @$pb.TagNumber(4)
  void clearOriginalFilename() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get contentType => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContentType() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentType() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get sizeBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSizeBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearSizeBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get sha256 => $_getSZ(6);
  @$pb.TagNumber(7)
  set sha256($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSha256() => $_has(6);
  @$pb.TagNumber(7)
  void clearSha256() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get createdAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set createdAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);
}

class TagIndex extends $pb.GeneratedMessage {
  factory TagIndex({
    $fixnum.Int64? id,
    $core.String? icon,
    $core.String? text,
    $core.String? color,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (icon != null) result.icon = icon;
    if (text != null) result.text = text;
    if (color != null) result.color = color;
    return result;
  }

  TagIndex._();

  factory TagIndex.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagIndex.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagIndex',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'icon')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOS(4, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagIndex clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagIndex copyWith(void Function(TagIndex) updates) =>
      super.copyWith((message) => updates(message as TagIndex)) as TagIndex;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagIndex create() => TagIndex._();
  @$core.override
  TagIndex createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagIndex getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TagIndex>(create);
  static TagIndex? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get icon => $_getSZ(1);
  @$pb.TagNumber(2)
  set icon($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIcon() => $_has(1);
  @$pb.TagNumber(2)
  void clearIcon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get color => $_getSZ(3);
  @$pb.TagNumber(4)
  set color($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColor() => $_has(3);
  @$pb.TagNumber(4)
  void clearColor() => $_clearField(4);
}

class Receipt extends $pb.GeneratedMessage {
  factory Receipt({
    $fixnum.Int64? id,
    $core.String? title,
    $core.String? description,
    $core.double? amountOwed,
    $core.double? amountPaid,
    $core.String? dueDate,
    $core.bool? isPaid,
    $core.String? currency,
    $core.String? paidAt,
    $core.String? notes,
    $core.String? createdAt,
    $core.String? updatedAt,
    $fixnum.Int64? ownerId,
    $fixnum.Int64? recipientId,
    $core.String? recipientName,
    Recipient? recipient,
    $core.Iterable<ReceiptFile>? files,
    $core.Iterable<TagIndex>? tags,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (amountOwed != null) result.amountOwed = amountOwed;
    if (amountPaid != null) result.amountPaid = amountPaid;
    if (dueDate != null) result.dueDate = dueDate;
    if (isPaid != null) result.isPaid = isPaid;
    if (currency != null) result.currency = currency;
    if (paidAt != null) result.paidAt = paidAt;
    if (notes != null) result.notes = notes;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (ownerId != null) result.ownerId = ownerId;
    if (recipientId != null) result.recipientId = recipientId;
    if (recipientName != null) result.recipientName = recipientName;
    if (recipient != null) result.recipient = recipient;
    if (files != null) result.files.addAll(files);
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  Receipt._();

  factory Receipt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Receipt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Receipt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aD(4, _omitFieldNames ? '' : 'amountOwed')
    ..aD(5, _omitFieldNames ? '' : 'amountPaid')
    ..aOS(6, _omitFieldNames ? '' : 'dueDate')
    ..aOB(7, _omitFieldNames ? '' : 'isPaid')
    ..aOS(8, _omitFieldNames ? '' : 'currency')
    ..aOS(9, _omitFieldNames ? '' : 'paidAt')
    ..aOS(10, _omitFieldNames ? '' : 'notes')
    ..aOS(11, _omitFieldNames ? '' : 'createdAt')
    ..aOS(12, _omitFieldNames ? '' : 'updatedAt')
    ..aInt64(13, _omitFieldNames ? '' : 'ownerId')
    ..aInt64(14, _omitFieldNames ? '' : 'recipientId')
    ..aOS(15, _omitFieldNames ? '' : 'recipientName')
    ..aOM<Recipient>(16, _omitFieldNames ? '' : 'recipient',
        subBuilder: Recipient.create)
    ..pPM<ReceiptFile>(17, _omitFieldNames ? '' : 'files',
        subBuilder: ReceiptFile.create)
    ..pPM<TagIndex>(18, _omitFieldNames ? '' : 'tags',
        subBuilder: TagIndex.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Receipt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Receipt copyWith(void Function(Receipt) updates) =>
      super.copyWith((message) => updates(message as Receipt)) as Receipt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Receipt create() => Receipt._();
  @$core.override
  Receipt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Receipt getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Receipt>(create);
  static Receipt? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountOwed => $_getN(3);
  @$pb.TagNumber(4)
  set amountOwed($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmountOwed() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountOwed() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get amountPaid => $_getN(4);
  @$pb.TagNumber(5)
  set amountPaid($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAmountPaid() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmountPaid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get dueDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set dueDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDueDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearDueDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isPaid => $_getBF(6);
  @$pb.TagNumber(7)
  set isPaid($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsPaid() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsPaid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get currency => $_getSZ(7);
  @$pb.TagNumber(8)
  set currency($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCurrency() => $_has(7);
  @$pb.TagNumber(8)
  void clearCurrency() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get paidAt => $_getSZ(8);
  @$pb.TagNumber(9)
  set paidAt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPaidAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearPaidAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get notes => $_getSZ(9);
  @$pb.TagNumber(10)
  set notes($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasNotes() => $_has(9);
  @$pb.TagNumber(10)
  void clearNotes() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get createdAt => $_getSZ(10);
  @$pb.TagNumber(11)
  set createdAt($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAt() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get updatedAt => $_getSZ(11);
  @$pb.TagNumber(12)
  set updatedAt($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAt() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get ownerId => $_getI64(12);
  @$pb.TagNumber(13)
  set ownerId($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasOwnerId() => $_has(12);
  @$pb.TagNumber(13)
  void clearOwnerId() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get recipientId => $_getI64(13);
  @$pb.TagNumber(14)
  set recipientId($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasRecipientId() => $_has(13);
  @$pb.TagNumber(14)
  void clearRecipientId() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get recipientName => $_getSZ(14);
  @$pb.TagNumber(15)
  set recipientName($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasRecipientName() => $_has(14);
  @$pb.TagNumber(15)
  void clearRecipientName() => $_clearField(15);

  @$pb.TagNumber(16)
  Recipient get recipient => $_getN(15);
  @$pb.TagNumber(16)
  set recipient(Recipient value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasRecipient() => $_has(15);
  @$pb.TagNumber(16)
  void clearRecipient() => $_clearField(16);
  @$pb.TagNumber(16)
  Recipient ensureRecipient() => $_ensure(15);

  @$pb.TagNumber(17)
  $pb.PbList<ReceiptFile> get files => $_getList(16);

  @$pb.TagNumber(18)
  $pb.PbList<TagIndex> get tags => $_getList(17);
}

class ActionResponse extends $pb.GeneratedMessage {
  factory ActionResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  ActionResponse._();

  factory ActionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActionResponse copyWith(void Function(ActionResponse) updates) =>
      super.copyWith((message) => updates(message as ActionResponse))
          as ActionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActionResponse create() => ActionResponse._();
  @$core.override
  ActionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActionResponse>(create);
  static ActionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class UserResponse extends $pb.GeneratedMessage {
  factory UserResponse({
    $core.bool? success,
    $core.String? message,
    User? user,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (user != null) result.user = user;
    return result;
  }

  UserResponse._();

  factory UserResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<User>(3, _omitFieldNames ? '' : 'user', subBuilder: User.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserResponse copyWith(void Function(UserResponse) updates) =>
      super.copyWith((message) => updates(message as UserResponse))
          as UserResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserResponse create() => UserResponse._();
  @$core.override
  UserResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserResponse>(create);
  static UserResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  User get user => $_getN(2);
  @$pb.TagNumber(3)
  set user(User value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUser() => $_has(2);
  @$pb.TagNumber(3)
  void clearUser() => $_clearField(3);
  @$pb.TagNumber(3)
  User ensureUser() => $_ensure(2);
}

class UsersResponse extends $pb.GeneratedMessage {
  factory UsersResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<User>? users,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (users != null) result.users.addAll(users);
    return result;
  }

  UsersResponse._();

  factory UsersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UsersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UsersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<User>(3, _omitFieldNames ? '' : 'users', subBuilder: User.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UsersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UsersResponse copyWith(void Function(UsersResponse) updates) =>
      super.copyWith((message) => updates(message as UsersResponse))
          as UsersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UsersResponse create() => UsersResponse._();
  @$core.override
  UsersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UsersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UsersResponse>(create);
  static UsersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<User> get users => $_getList(2);
}

class RecipientResponse extends $pb.GeneratedMessage {
  factory RecipientResponse({
    $core.bool? success,
    $core.String? message,
    Recipient? recipient,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (recipient != null) result.recipient = recipient;
    return result;
  }

  RecipientResponse._();

  factory RecipientResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecipientResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecipientResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<Recipient>(3, _omitFieldNames ? '' : 'recipient',
        subBuilder: Recipient.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientResponse copyWith(void Function(RecipientResponse) updates) =>
      super.copyWith((message) => updates(message as RecipientResponse))
          as RecipientResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecipientResponse create() => RecipientResponse._();
  @$core.override
  RecipientResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecipientResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecipientResponse>(create);
  static RecipientResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  Recipient get recipient => $_getN(2);
  @$pb.TagNumber(3)
  set recipient(Recipient value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRecipient() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecipient() => $_clearField(3);
  @$pb.TagNumber(3)
  Recipient ensureRecipient() => $_ensure(2);
}

class RecipientsResponse extends $pb.GeneratedMessage {
  factory RecipientsResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<Recipient>? recipients,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (recipients != null) result.recipients.addAll(recipients);
    return result;
  }

  RecipientsResponse._();

  factory RecipientsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecipientsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecipientsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<Recipient>(3, _omitFieldNames ? '' : 'recipients',
        subBuilder: Recipient.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientsResponse copyWith(void Function(RecipientsResponse) updates) =>
      super.copyWith((message) => updates(message as RecipientsResponse))
          as RecipientsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecipientsResponse create() => RecipientsResponse._();
  @$core.override
  RecipientsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecipientsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecipientsResponse>(create);
  static RecipientsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Recipient> get recipients => $_getList(2);
}

class ReceiptResponse extends $pb.GeneratedMessage {
  factory ReceiptResponse({
    $core.bool? success,
    $core.String? message,
    Receipt? receipt,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (receipt != null) result.receipt = receipt;
    return result;
  }

  ReceiptResponse._();

  factory ReceiptResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<Receipt>(3, _omitFieldNames ? '' : 'receipt',
        subBuilder: Receipt.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptResponse copyWith(void Function(ReceiptResponse) updates) =>
      super.copyWith((message) => updates(message as ReceiptResponse))
          as ReceiptResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptResponse create() => ReceiptResponse._();
  @$core.override
  ReceiptResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptResponse>(create);
  static ReceiptResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  Receipt get receipt => $_getN(2);
  @$pb.TagNumber(3)
  set receipt(Receipt value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReceipt() => $_has(2);
  @$pb.TagNumber(3)
  void clearReceipt() => $_clearField(3);
  @$pb.TagNumber(3)
  Receipt ensureReceipt() => $_ensure(2);
}

class ReceiptsResponse extends $pb.GeneratedMessage {
  factory ReceiptsResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<Receipt>? receipts,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (receipts != null) result.receipts.addAll(receipts);
    return result;
  }

  ReceiptsResponse._();

  factory ReceiptsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<Receipt>(3, _omitFieldNames ? '' : 'receipts',
        subBuilder: Receipt.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptsResponse copyWith(void Function(ReceiptsResponse) updates) =>
      super.copyWith((message) => updates(message as ReceiptsResponse))
          as ReceiptsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptsResponse create() => ReceiptsResponse._();
  @$core.override
  ReceiptsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptsResponse>(create);
  static ReceiptsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Receipt> get receipts => $_getList(2);
}

class FileResponse extends $pb.GeneratedMessage {
  factory FileResponse({
    $core.bool? success,
    $core.String? message,
    ReceiptFile? file,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (file != null) result.file = file;
    return result;
  }

  FileResponse._();

  factory FileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<ReceiptFile>(3, _omitFieldNames ? '' : 'file',
        subBuilder: ReceiptFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileResponse copyWith(void Function(FileResponse) updates) =>
      super.copyWith((message) => updates(message as FileResponse))
          as FileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileResponse create() => FileResponse._();
  @$core.override
  FileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileResponse>(create);
  static FileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  ReceiptFile get file => $_getN(2);
  @$pb.TagNumber(3)
  set file(ReceiptFile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearFile() => $_clearField(3);
  @$pb.TagNumber(3)
  ReceiptFile ensureFile() => $_ensure(2);
}

class FilesResponse extends $pb.GeneratedMessage {
  factory FilesResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<ReceiptFile>? files,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (files != null) result.files.addAll(files);
    return result;
  }

  FilesResponse._();

  factory FilesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<ReceiptFile>(3, _omitFieldNames ? '' : 'files',
        subBuilder: ReceiptFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilesResponse copyWith(void Function(FilesResponse) updates) =>
      super.copyWith((message) => updates(message as FilesResponse))
          as FilesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilesResponse create() => FilesResponse._();
  @$core.override
  FilesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilesResponse>(create);
  static FilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ReceiptFile> get files => $_getList(2);
}

class TagResponse extends $pb.GeneratedMessage {
  factory TagResponse({
    $core.bool? success,
    $core.String? message,
    TagIndex? tag,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (tag != null) result.tag = tag;
    return result;
  }

  TagResponse._();

  factory TagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<TagIndex>(3, _omitFieldNames ? '' : 'tag',
        subBuilder: TagIndex.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagResponse copyWith(void Function(TagResponse) updates) =>
      super.copyWith((message) => updates(message as TagResponse))
          as TagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagResponse create() => TagResponse._();
  @$core.override
  TagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagResponse>(create);
  static TagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  TagIndex get tag => $_getN(2);
  @$pb.TagNumber(3)
  set tag(TagIndex value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTag() => $_has(2);
  @$pb.TagNumber(3)
  void clearTag() => $_clearField(3);
  @$pb.TagNumber(3)
  TagIndex ensureTag() => $_ensure(2);
}

class TagsResponse extends $pb.GeneratedMessage {
  factory TagsResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<TagIndex>? tags,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  TagsResponse._();

  factory TagsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<TagIndex>(3, _omitFieldNames ? '' : 'tags',
        subBuilder: TagIndex.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagsResponse copyWith(void Function(TagsResponse) updates) =>
      super.copyWith((message) => updates(message as TagsResponse))
          as TagsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagsResponse create() => TagsResponse._();
  @$core.override
  TagsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagsResponse>(create);
  static TagsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<TagIndex> get tags => $_getList(2);
}

class UpdateUserRequest extends $pb.GeneratedMessage {
  factory UpdateUserRequest({
    $core.String? email,
    $core.String? name,
    $core.String? avatarUrl,
  }) {
    final result = create();
    if (email != null) result.email = email;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    return result;
  }

  UpdateUserRequest._();

  factory UpdateUserRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateUserRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateUserRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'email')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'avatarUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserRequest copyWith(void Function(UpdateUserRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateUserRequest))
          as UpdateUserRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateUserRequest create() => UpdateUserRequest._();
  @$core.override
  UpdateUserRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateUserRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateUserRequest>(create);
  static UpdateUserRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get email => $_getSZ(0);
  @$pb.TagNumber(1)
  set email($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEmail() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmail() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarUrl() => $_clearField(3);
}

class CreateRecipientRequest extends $pb.GeneratedMessage {
  factory CreateRecipientRequest({
    $core.String? name,
    $core.String? description,
    $core.Iterable<$fixnum.Int64>? memberIds,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (memberIds != null) result.memberIds.addAll(memberIds);
    return result;
  }

  CreateRecipientRequest._();

  factory CreateRecipientRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateRecipientRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRecipientRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..p<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'memberIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRecipientRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRecipientRequest copyWith(
          void Function(CreateRecipientRequest) updates) =>
      super.copyWith((message) => updates(message as CreateRecipientRequest))
          as CreateRecipientRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateRecipientRequest create() => CreateRecipientRequest._();
  @$core.override
  CreateRecipientRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateRecipientRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRecipientRequest>(create);
  static CreateRecipientRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$fixnum.Int64> get memberIds => $_getList(2);
}

class RecipientLookupRequest extends $pb.GeneratedMessage {
  factory RecipientLookupRequest({
    $fixnum.Int64? recipientId,
  }) {
    final result = create();
    if (recipientId != null) result.recipientId = recipientId;
    return result;
  }

  RecipientLookupRequest._();

  factory RecipientLookupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecipientLookupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecipientLookupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'recipientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientLookupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientLookupRequest copyWith(
          void Function(RecipientLookupRequest) updates) =>
      super.copyWith((message) => updates(message as RecipientLookupRequest))
          as RecipientLookupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecipientLookupRequest create() => RecipientLookupRequest._();
  @$core.override
  RecipientLookupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecipientLookupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecipientLookupRequest>(create);
  static RecipientLookupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get recipientId => $_getI64(0);
  @$pb.TagNumber(1)
  set recipientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecipientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecipientId() => $_clearField(1);
}

class UpdateRecipientRequest extends $pb.GeneratedMessage {
  factory UpdateRecipientRequest({
    $fixnum.Int64? recipientId,
    $core.String? name,
    $core.String? description,
  }) {
    final result = create();
    if (recipientId != null) result.recipientId = recipientId;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    return result;
  }

  UpdateRecipientRequest._();

  factory UpdateRecipientRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateRecipientRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateRecipientRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'recipientId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRecipientRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRecipientRequest copyWith(
          void Function(UpdateRecipientRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateRecipientRequest))
          as UpdateRecipientRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateRecipientRequest create() => UpdateRecipientRequest._();
  @$core.override
  UpdateRecipientRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateRecipientRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateRecipientRequest>(create);
  static UpdateRecipientRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get recipientId => $_getI64(0);
  @$pb.TagNumber(1)
  set recipientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecipientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecipientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);
}

class RecipientMemberRequest extends $pb.GeneratedMessage {
  factory RecipientMemberRequest({
    $fixnum.Int64? recipientId,
    $fixnum.Int64? userId,
  }) {
    final result = create();
    if (recipientId != null) result.recipientId = recipientId;
    if (userId != null) result.userId = userId;
    return result;
  }

  RecipientMemberRequest._();

  factory RecipientMemberRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecipientMemberRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecipientMemberRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'recipientId')
    ..aInt64(2, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientMemberRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecipientMemberRequest copyWith(
          void Function(RecipientMemberRequest) updates) =>
      super.copyWith((message) => updates(message as RecipientMemberRequest))
          as RecipientMemberRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecipientMemberRequest create() => RecipientMemberRequest._();
  @$core.override
  RecipientMemberRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecipientMemberRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecipientMemberRequest>(create);
  static RecipientMemberRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get recipientId => $_getI64(0);
  @$pb.TagNumber(1)
  set recipientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecipientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecipientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get userId => $_getI64(1);
  @$pb.TagNumber(2)
  set userId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);
}

class CreateReceiptRequest extends $pb.GeneratedMessage {
  factory CreateReceiptRequest({
    $core.String? title,
    $core.double? amountOwed,
    $core.String? currency,
    $fixnum.Int64? recipientId,
    $core.String? description,
    $core.String? dueDate,
    $core.String? notes,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (amountOwed != null) result.amountOwed = amountOwed;
    if (currency != null) result.currency = currency;
    if (recipientId != null) result.recipientId = recipientId;
    if (description != null) result.description = description;
    if (dueDate != null) result.dueDate = dueDate;
    if (notes != null) result.notes = notes;
    return result;
  }

  CreateReceiptRequest._();

  factory CreateReceiptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateReceiptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateReceiptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aD(2, _omitFieldNames ? '' : 'amountOwed')
    ..aOS(3, _omitFieldNames ? '' : 'currency')
    ..aInt64(4, _omitFieldNames ? '' : 'recipientId')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aOS(6, _omitFieldNames ? '' : 'dueDate')
    ..aOS(7, _omitFieldNames ? '' : 'notes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateReceiptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateReceiptRequest copyWith(void Function(CreateReceiptRequest) updates) =>
      super.copyWith((message) => updates(message as CreateReceiptRequest))
          as CreateReceiptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateReceiptRequest create() => CreateReceiptRequest._();
  @$core.override
  CreateReceiptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateReceiptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateReceiptRequest>(create);
  static CreateReceiptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountOwed => $_getN(1);
  @$pb.TagNumber(2)
  set amountOwed($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAmountOwed() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountOwed() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currency => $_getSZ(2);
  @$pb.TagNumber(3)
  set currency($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrency() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrency() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get recipientId => $_getI64(3);
  @$pb.TagNumber(4)
  set recipientId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRecipientId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipientId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get dueDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set dueDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDueDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearDueDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get notes => $_getSZ(6);
  @$pb.TagNumber(7)
  set notes($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNotes() => $_has(6);
  @$pb.TagNumber(7)
  void clearNotes() => $_clearField(7);
}

class ReceiptLookupRequest extends $pb.GeneratedMessage {
  factory ReceiptLookupRequest({
    $fixnum.Int64? receiptId,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    return result;
  }

  ReceiptLookupRequest._();

  factory ReceiptLookupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptLookupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptLookupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptLookupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptLookupRequest copyWith(void Function(ReceiptLookupRequest) updates) =>
      super.copyWith((message) => updates(message as ReceiptLookupRequest))
          as ReceiptLookupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptLookupRequest create() => ReceiptLookupRequest._();
  @$core.override
  ReceiptLookupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptLookupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptLookupRequest>(create);
  static ReceiptLookupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);
}

class ReceiptListRequest extends $pb.GeneratedMessage {
  factory ReceiptListRequest({
    $core.bool? isPaid,
    $core.Iterable<$fixnum.Int64>? tagIds,
    $fixnum.Int64? cursor,
    $core.int? limit,
  }) {
    final result = create();
    if (isPaid != null) result.isPaid = isPaid;
    if (tagIds != null) result.tagIds.addAll(tagIds);
    if (cursor != null) result.cursor = cursor;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReceiptListRequest._();

  factory ReceiptListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isPaid')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'tagIds', $pb.PbFieldType.K6)
    ..aInt64(3, _omitFieldNames ? '' : 'cursor')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptListRequest copyWith(void Function(ReceiptListRequest) updates) =>
      super.copyWith((message) => updates(message as ReceiptListRequest))
          as ReceiptListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptListRequest create() => ReceiptListRequest._();
  @$core.override
  ReceiptListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptListRequest>(create);
  static ReceiptListRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isPaid => $_getBF(0);
  @$pb.TagNumber(1)
  set isPaid($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsPaid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsPaid() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get tagIds => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get cursor => $_getI64(2);
  @$pb.TagNumber(3)
  set cursor($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class UpdateReceiptRequest extends $pb.GeneratedMessage {
  factory UpdateReceiptRequest({
    $fixnum.Int64? receiptId,
    $core.String? title,
    $core.String? description,
    $core.double? amountOwed,
    $core.double? amountPaid,
    $core.String? dueDate,
    $core.String? notes,
    $core.String? currency,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (amountOwed != null) result.amountOwed = amountOwed;
    if (amountPaid != null) result.amountPaid = amountPaid;
    if (dueDate != null) result.dueDate = dueDate;
    if (notes != null) result.notes = notes;
    if (currency != null) result.currency = currency;
    return result;
  }

  UpdateReceiptRequest._();

  factory UpdateReceiptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateReceiptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateReceiptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aD(4, _omitFieldNames ? '' : 'amountOwed')
    ..aD(5, _omitFieldNames ? '' : 'amountPaid')
    ..aOS(6, _omitFieldNames ? '' : 'dueDate')
    ..aOS(7, _omitFieldNames ? '' : 'notes')
    ..aOS(8, _omitFieldNames ? '' : 'currency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReceiptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReceiptRequest copyWith(void Function(UpdateReceiptRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateReceiptRequest))
          as UpdateReceiptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateReceiptRequest create() => UpdateReceiptRequest._();
  @$core.override
  UpdateReceiptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateReceiptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateReceiptRequest>(create);
  static UpdateReceiptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountOwed => $_getN(3);
  @$pb.TagNumber(4)
  set amountOwed($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmountOwed() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountOwed() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get amountPaid => $_getN(4);
  @$pb.TagNumber(5)
  set amountPaid($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAmountPaid() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmountPaid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get dueDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set dueDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDueDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearDueDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get notes => $_getSZ(6);
  @$pb.TagNumber(7)
  set notes($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNotes() => $_has(6);
  @$pb.TagNumber(7)
  void clearNotes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get currency => $_getSZ(7);
  @$pb.TagNumber(8)
  set currency($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCurrency() => $_has(7);
  @$pb.TagNumber(8)
  void clearCurrency() => $_clearField(8);
}

class MarkReceiptPaidRequest extends $pb.GeneratedMessage {
  factory MarkReceiptPaidRequest({
    $fixnum.Int64? receiptId,
    $core.double? amountPaid,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (amountPaid != null) result.amountPaid = amountPaid;
    return result;
  }

  MarkReceiptPaidRequest._();

  factory MarkReceiptPaidRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MarkReceiptPaidRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkReceiptPaidRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..aD(2, _omitFieldNames ? '' : 'amountPaid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReceiptPaidRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReceiptPaidRequest copyWith(
          void Function(MarkReceiptPaidRequest) updates) =>
      super.copyWith((message) => updates(message as MarkReceiptPaidRequest))
          as MarkReceiptPaidRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MarkReceiptPaidRequest create() => MarkReceiptPaidRequest._();
  @$core.override
  MarkReceiptPaidRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MarkReceiptPaidRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkReceiptPaidRequest>(create);
  static MarkReceiptPaidRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountPaid => $_getN(1);
  @$pb.TagNumber(2)
  set amountPaid($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAmountPaid() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountPaid() => $_clearField(2);
}

class ReceiptFileRequest extends $pb.GeneratedMessage {
  factory ReceiptFileRequest({
    $fixnum.Int64? receiptId,
    $core.String? storageKey,
    $core.String? originalFilename,
    $core.String? contentType,
    $fixnum.Int64? sizeBytes,
    $core.String? sha256,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (storageKey != null) result.storageKey = storageKey;
    if (originalFilename != null) result.originalFilename = originalFilename;
    if (contentType != null) result.contentType = contentType;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  ReceiptFileRequest._();

  factory ReceiptFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceiptFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..aOS(2, _omitFieldNames ? '' : 'storageKey')
    ..aOS(3, _omitFieldNames ? '' : 'originalFilename')
    ..aOS(4, _omitFieldNames ? '' : 'contentType')
    ..aInt64(5, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(6, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptFileRequest copyWith(void Function(ReceiptFileRequest) updates) =>
      super.copyWith((message) => updates(message as ReceiptFileRequest))
          as ReceiptFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceiptFileRequest create() => ReceiptFileRequest._();
  @$core.override
  ReceiptFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReceiptFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceiptFileRequest>(create);
  static ReceiptFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get storageKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set storageKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStorageKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearStorageKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get originalFilename => $_getSZ(2);
  @$pb.TagNumber(3)
  set originalFilename($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOriginalFilename() => $_has(2);
  @$pb.TagNumber(3)
  void clearOriginalFilename() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get contentType => $_getSZ(3);
  @$pb.TagNumber(4)
  set contentType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContentType() => $_has(3);
  @$pb.TagNumber(4)
  void clearContentType() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get sha256 => $_getSZ(5);
  @$pb.TagNumber(6)
  set sha256($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSha256() => $_has(5);
  @$pb.TagNumber(6)
  void clearSha256() => $_clearField(6);
}

class FileLookupRequest extends $pb.GeneratedMessage {
  factory FileLookupRequest({
    $fixnum.Int64? fileId,
    $core.String? storageKey,
  }) {
    final result = create();
    if (fileId != null) result.fileId = fileId;
    if (storageKey != null) result.storageKey = storageKey;
    return result;
  }

  FileLookupRequest._();

  factory FileLookupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileLookupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileLookupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fileId')
    ..aOS(2, _omitFieldNames ? '' : 'storageKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileLookupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileLookupRequest copyWith(void Function(FileLookupRequest) updates) =>
      super.copyWith((message) => updates(message as FileLookupRequest))
          as FileLookupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileLookupRequest create() => FileLookupRequest._();
  @$core.override
  FileLookupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileLookupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileLookupRequest>(create);
  static FileLookupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fileId => $_getI64(0);
  @$pb.TagNumber(1)
  set fileId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get storageKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set storageKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStorageKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearStorageKey() => $_clearField(2);
}

class FileListRequest extends $pb.GeneratedMessage {
  factory FileListRequest({
    $fixnum.Int64? receiptId,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    return result;
  }

  FileListRequest._();

  factory FileListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileListRequest copyWith(void Function(FileListRequest) updates) =>
      super.copyWith((message) => updates(message as FileListRequest))
          as FileListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileListRequest create() => FileListRequest._();
  @$core.override
  FileListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileListRequest>(create);
  static FileListRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);
}

class TagUpsertRequest extends $pb.GeneratedMessage {
  factory TagUpsertRequest({
    $core.String? text,
    $core.String? icon,
    $core.String? color,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (icon != null) result.icon = icon;
    if (color != null) result.color = color;
    return result;
  }

  TagUpsertRequest._();

  factory TagUpsertRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagUpsertRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagUpsertRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'icon')
    ..aOS(3, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagUpsertRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagUpsertRequest copyWith(void Function(TagUpsertRequest) updates) =>
      super.copyWith((message) => updates(message as TagUpsertRequest))
          as TagUpsertRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagUpsertRequest create() => TagUpsertRequest._();
  @$core.override
  TagUpsertRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagUpsertRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagUpsertRequest>(create);
  static TagUpsertRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get icon => $_getSZ(1);
  @$pb.TagNumber(2)
  set icon($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIcon() => $_has(1);
  @$pb.TagNumber(2)
  void clearIcon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get color => $_getSZ(2);
  @$pb.TagNumber(3)
  set color($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => $_clearField(3);
}

class TagLookupRequest extends $pb.GeneratedMessage {
  factory TagLookupRequest({
    $fixnum.Int64? tagId,
    $core.String? text,
  }) {
    final result = create();
    if (tagId != null) result.tagId = tagId;
    if (text != null) result.text = text;
    return result;
  }

  TagLookupRequest._();

  factory TagLookupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagLookupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagLookupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'tagId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagLookupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagLookupRequest copyWith(void Function(TagLookupRequest) updates) =>
      super.copyWith((message) => updates(message as TagLookupRequest))
          as TagLookupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagLookupRequest create() => TagLookupRequest._();
  @$core.override
  TagLookupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagLookupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagLookupRequest>(create);
  static TagLookupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tagId => $_getI64(0);
  @$pb.TagNumber(1)
  set tagId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTagId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTagId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class UpdateTagRequest extends $pb.GeneratedMessage {
  factory UpdateTagRequest({
    $fixnum.Int64? tagId,
    $core.String? icon,
    $core.String? color,
  }) {
    final result = create();
    if (tagId != null) result.tagId = tagId;
    if (icon != null) result.icon = icon;
    if (color != null) result.color = color;
    return result;
  }

  UpdateTagRequest._();

  factory UpdateTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateTagRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'tagId')
    ..aOS(2, _omitFieldNames ? '' : 'icon')
    ..aOS(3, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagRequest copyWith(void Function(UpdateTagRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateTagRequest))
          as UpdateTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateTagRequest create() => UpdateTagRequest._();
  @$core.override
  UpdateTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateTagRequest>(create);
  static UpdateTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tagId => $_getI64(0);
  @$pb.TagNumber(1)
  set tagId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTagId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTagId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get icon => $_getSZ(1);
  @$pb.TagNumber(2)
  set icon($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIcon() => $_has(1);
  @$pb.TagNumber(2)
  void clearIcon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get color => $_getSZ(2);
  @$pb.TagNumber(3)
  set color($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => $_clearField(3);
}

class TagReceiptRequest extends $pb.GeneratedMessage {
  factory TagReceiptRequest({
    $fixnum.Int64? receiptId,
    $fixnum.Int64? tagId,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (tagId != null) result.tagId = tagId;
    return result;
  }

  TagReceiptRequest._();

  factory TagReceiptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TagReceiptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagReceiptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..aInt64(2, _omitFieldNames ? '' : 'tagId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagReceiptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagReceiptRequest copyWith(void Function(TagReceiptRequest) updates) =>
      super.copyWith((message) => updates(message as TagReceiptRequest))
          as TagReceiptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagReceiptRequest create() => TagReceiptRequest._();
  @$core.override
  TagReceiptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TagReceiptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagReceiptRequest>(create);
  static TagReceiptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get tagId => $_getI64(1);
  @$pb.TagNumber(2)
  set tagId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTagId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTagId() => $_clearField(2);
}

class SetReceiptTagsRequest extends $pb.GeneratedMessage {
  factory SetReceiptTagsRequest({
    $fixnum.Int64? receiptId,
    $core.Iterable<$fixnum.Int64>? tagIds,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (tagIds != null) result.tagIds.addAll(tagIds);
    return result;
  }

  SetReceiptTagsRequest._();

  factory SetReceiptTagsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetReceiptTagsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetReceiptTagsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'debt'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receiptId')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'tagIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetReceiptTagsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetReceiptTagsRequest copyWith(
          void Function(SetReceiptTagsRequest) updates) =>
      super.copyWith((message) => updates(message as SetReceiptTagsRequest))
          as SetReceiptTagsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetReceiptTagsRequest create() => SetReceiptTagsRequest._();
  @$core.override
  SetReceiptTagsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetReceiptTagsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetReceiptTagsRequest>(create);
  static SetReceiptTagsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptId => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get tagIds => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
