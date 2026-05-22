import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
	final storage = ref.read(secureStorageProvider);
	// initialize ApiService with token if present (async read not awaited here)
	final api = ApiService();
	storage.readAuthToken().then((token) {
		if (token != null && token.isNotEmpty) api.setAuthToken(token);
	});
	return api;
});

