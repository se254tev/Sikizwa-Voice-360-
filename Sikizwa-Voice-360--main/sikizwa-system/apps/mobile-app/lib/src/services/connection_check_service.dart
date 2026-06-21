import 'dart:async';
import 'dart:developer';

import 'api_service.dart';

class ConnectionCheckService {
  ConnectionCheckService({required this.backendApi, required this.aiApi});

  final ApiService backendApi;
  final ApiService aiApi;

  /// Check the Render backend by calling `/health` (or base route).
  /// Returns `true` when reachable and responding within timeout.
  Future<bool> checkBackendConnection({int timeoutMs = 15000}) async {
    try {
      final response = await backendApi.get('/health', timeoutMs: timeoutMs);
      log('Backend health check success: ${response ?? '<no-body>'}', name: 'ConnectionCheckService');
      return true;
    } catch (error) {
      log('Backend /health failed: $error', name: 'ConnectionCheckService');

      // Fallback: try base route
      try {
        final response = await backendApi.get('', timeoutMs: timeoutMs);
        log('Backend base-route check success: ${response ?? '<no-body>'}', name: 'ConnectionCheckService');
        return true;
      } catch (error2) {
        log('Backend base-route check failed: $error2', name: 'ConnectionCheckService');
        return false;
      }
    }
  }

  /// Check the AI service `/health` endpoint and verify expected payload.
  /// Expects a JSON like: {"status": "healthy"}
  Future<bool> checkAIConnection({int timeoutMs = 15000}) async {
    try {
      final response = await aiApi.get('/health', timeoutMs: timeoutMs);
      if (response is Map && response['status'] == 'healthy') {
        log('AI service health check success: $response', name: 'ConnectionCheckService');
        return true;
      }

      log('AI service /health returned unexpected payload: $response', name: 'ConnectionCheckService');
      return false;
    } catch (error) {
      log('AI service health check failed: $error', name: 'ConnectionCheckService');
      return false;
    }
  }

  /// Combined check: backend first, then AI service only if backend is ok.
  Future<Map<String, bool>> checkAllConnections({int timeoutMs = 15000}) async {
    final backendOk = await checkBackendConnection(timeoutMs: timeoutMs);
    final aiOk = backendOk ? await checkAIConnection(timeoutMs: timeoutMs) : false;
    return {
      'backend': backendOk,
      'ai_service': aiOk,
    };
  }
}
