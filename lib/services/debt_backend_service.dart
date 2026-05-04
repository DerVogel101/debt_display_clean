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

  Future<TagsResponse> listTags(String accessToken) async {
    final response = await _dio.post(
      '/api/tags/list',
      data: EmptyRequest().writeToBuffer(),
      options: _withAuthToken(accessToken),
    );
    return _parseProtobufResponse(response, TagsResponse.fromBuffer);
  }
}
