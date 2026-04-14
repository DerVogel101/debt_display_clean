import 'package:dio/dio.dart';
import 'package:debt_display/generated/auth.pb.dart';
import 'package:debt_display/config/app_config.dart';

class AuthBackendService {
  static final AuthBackendService _instance = AuthBackendService._internal();
  late final Dio _dio;

  factory AuthBackendService() => _instance;

  AuthBackendService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.backendUrl,
      headers: {'Content-Type': 'application/x-protobuf'},
      responseType: ResponseType.bytes,
    ));
  }

  Options withAuthToken(
    String accessToken, {
    Options? options,
  }) {
    final headers = <String, dynamic>{
      ...?options?.headers,
      'Authorization': 'Bearer $accessToken',
    };

    return (options ?? Options()).copyWith(headers: headers);
  }

  /// Call after a successful Auth0 login to register/sync the user in the DB.
  Future<LoginResponse> login(
    String accessToken, {
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    final req = LoginRequest()
      ..accessToken = accessToken
      ..email = email ?? ''
      ..name = name ?? ''
      ..avatarUrl = avatarUrl ?? '';
    final response = await _dio.post(
      '/api/auth/login',
      data: req.writeToBuffer(),
    );
    return LoginResponse.fromBuffer(response.data as List<int>);
  }

  /// Check token validity before any protected API call.
  Future<TokenVerifyResponse> verifyToken(String accessToken) async {
    final req = TokenVerifyRequest()..accessToken = accessToken;
    final response = await _dio.post(
      '/api/auth/verify',
      data: req.writeToBuffer(),
    );
    return TokenVerifyResponse.fromBuffer(response.data as List<int>);
  }
}
