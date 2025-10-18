import 'package:dio/dio.dart';

class ApiProxyService {
  final Dio _dio = Dio();
  final String _base = 'https://us-central1-SEU-PROJETO.cloudfunctions.net';

  Future<dynamic> getProxied({
    required String service,
    required String targetUrl,
  }) async {
    final encoded = Uri.encodeComponent(targetUrl);
    final proxyUrl = '$_base/proxy$service?url=$encoded';
    final response = await _dio.get(proxyUrl);
    return response.data;
  }
}
