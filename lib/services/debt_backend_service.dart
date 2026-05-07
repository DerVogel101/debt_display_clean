import 'dart:typed_data';

import 'package:debt_display/config/app_config.dart';
import 'package:debt_display/generated/debt.pb.dart';
import 'package:dio/dio.dart';

class DebtBackendService {
  DebtBackendService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.backendUrl,
              headers: {'Content-Type': 'application/x-protobuf'},
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            ),
          );

  final Dio _dio;

  T _parseProtobufResponse<T>(
    Response<dynamic> response,
    T Function(List<int> bytes) fromBuffer,
  ) {
    final data = response.data;
    if (data is Uint8List) {
      return fromBuffer(data);
    }
    if (data is List<int>) {
      return fromBuffer(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Backend returned non-protobuf response',
    );
  }

  Options _withAuthToken(String accessToken, {Options? options}) {
    final headers = <String, dynamic>{
      ...?options?.headers,
      'Authorization': 'Bearer $accessToken',
    };
    return (options ?? Options()).copyWith(headers: headers);
  }

  Uint8List _bytesFromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Backend returned non-binary response',
    );
  }

  Future<ReceiptResponse> createReceipt(
    String accessToken,
    CreateReceiptRequest request,
  ) async {
    final response = await _dio.post(
      '/api/receipts/create',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ReceiptResponse.fromBuffer);
  }

  Future<ReceiptResponse> updateReceipt(
    String accessToken,
    UpdateReceiptRequest request,
  ) async {
    final response = await _dio.post(
      '/api/receipts/update',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ReceiptResponse.fromBuffer);
  }

  Future<ReceiptsResponse> listReceipts(
    String accessToken,
    ReceiptListRequest request,
  ) async {
    final response = await _dio.post(
      '/api/receipts/list',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ReceiptsResponse.fromBuffer);
  }

  Future<ReceiptUnpaidSummaryResponse> getUnpaidReceiptSummary(
    String accessToken,
  ) async {
    final response = await _dio.post(
      '/api/receipts/unpaid-summary',
      data: ReceiptUnpaidSummaryRequest().writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(
      response,
      ReceiptUnpaidSummaryResponse.fromBuffer,
    );
  }

  Future<TagsResponse> listTags(String accessToken) async {
    final response = await _dio.post(
      '/api/tags/list',
      data: EmptyRequest().writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, TagsResponse.fromBuffer);
  }

  Future<TagsResponse> listRecommendedTags(String accessToken) async {
    final response = await _dio.post(
      '/api/tags/recommended',
      data: EmptyRequest().writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, TagsResponse.fromBuffer);
  }

  Future<TagResponse> getOrCreateTag(
    String accessToken,
    TagUpsertRequest request,
  ) async {
    final response = await _dio.post(
      '/api/tags/get-or-create',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, TagResponse.fromBuffer);
  }

  Future<ActionResponse> setReceiptTags(
    String accessToken,
    SetReceiptTagsRequest request,
  ) async {
    final response = await _dio.post(
      '/api/receipt-tags/set',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ActionResponse.fromBuffer);
  }

  Future<UsersResponse> searchUsers(
    String accessToken,
    UserSearchRequest request,
  ) async {
    final response = await _dio.post(
      '/api/users/search',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, UsersResponse.fromBuffer);
  }

  Future<ReceiptResponse> setReceiptPayments(
    String accessToken,
    SetReceiptPaymentsRequest request,
  ) async {
    final response = await _dio.post(
      '/api/receipts/set-payments',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ReceiptResponse.fromBuffer);
  }

  Future<RecipientsResponse> listRecipients(String accessToken) async {
    final response = await _dio.post(
      '/api/recipients/list',
      data: EmptyRequest().writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, RecipientsResponse.fromBuffer);
  }

  Future<RecipientResponse> createRecipient(
    String accessToken,
    CreateRecipientRequest request,
  ) async {
    final response = await _dio.post(
      '/api/recipients/create',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, RecipientResponse.fromBuffer);
  }

  Future<RecipientResponse> updateRecipient(
    String accessToken,
    UpdateRecipientRequest request,
  ) async {
    final response = await _dio.post(
      '/api/recipients/update',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, RecipientResponse.fromBuffer);
  }

  Future<ActionResponse> addRecipientMember(
    String accessToken,
    RecipientMemberRequest request,
  ) async {
    final response = await _dio.post(
      '/api/recipients/add-member',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ActionResponse.fromBuffer);
  }

  Future<ActionResponse> removeRecipientMember(
    String accessToken,
    RecipientMemberRequest request,
  ) async {
    final response = await _dio.post(
      '/api/recipients/remove-member',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ActionResponse.fromBuffer);
  }

  Future<ActionResponse> deleteRecipient(
    String accessToken,
    RecipientLookupRequest request,
  ) async {
    final response = await _dio.post(
      '/api/recipients/delete',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ActionResponse.fromBuffer);
  }

  Future<FilesResponse> listFiles(
    String accessToken,
    FileListRequest request,
  ) async {
    final response = await _dio.post(
      '/api/files/list',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, FilesResponse.fromBuffer);
  }

  Future<FileResponse> attachFile(
    String accessToken,
    ReceiptFileRequest request,
  ) async {
    final response = await _dio.post(
      '/api/files/attach',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, FileResponse.fromBuffer);
  }

  Future<FileResponse> uploadReceiptFile(
    String accessToken, {
    required int receiptId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final mediaType = contentType == null || contentType.isEmpty
        ? null
        : DioMediaType.parse(contentType);
    final response = await _dio.post(
      '/api/files/upload',
      data: FormData.fromMap({
        'receipt_id': receiptId.toString(),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      }),
      options: _withAuthToken(
        accessToken,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {'Content-Type': Headers.multipartFormDataContentType},
        ),
      ),
    );
    return _parseProtobufResponse(response, FileResponse.fromBuffer);
  }

  Future<ReceiptFileDownload> downloadReceiptFile(
    String accessToken,
    ReceiptFile file,
  ) async {
    final response = await _dio.get(
      '/api/files/${file.id.toInt()}/content',
      options: _withAuthToken(
        accessToken,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    return ReceiptFileDownload(
      file: file.deepCopy(),
      bytes: _bytesFromResponse(response),
      contentType:
          response.headers.value(Headers.contentTypeHeader) ??
          (file.hasContentType() ? file.contentType : null) ??
          'application/octet-stream',
    );
  }

  Future<ActionResponse> deleteFile(
    String accessToken,
    FileLookupRequest request,
  ) async {
    final response = await _dio.post(
      '/api/files/delete',
      data: request.writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, ActionResponse.fromBuffer);
  }
}

class ReceiptFileDownload {
  const ReceiptFileDownload({
    required this.file,
    required this.bytes,
    required this.contentType,
  });

  final ReceiptFile file;
  final Uint8List bytes;
  final String contentType;
}
