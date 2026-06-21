# Flutter Mobile App ↔ Backend API Security Guide

## Overview

The Sikizwa mobile app uses a secure, token-based authentication pattern with the backend API. This guide documents current security measures and best practices for hardening mobile-to-backend communication.

---

## 1. Current Security Architecture ✅

### 1.1 Transport Layer Security
- **HTTPS/TLS**: All communication uses HTTPS (default base URL: `https://sikizwa-voice-360.onrender.com`)
- **TLS Termination**: External reverse proxy (Nginx/Render) terminates TLS; backend uses plain HTTP internally
- **Configuration**: Base URL set via build-time constant `API_BASE_URL` in `AppConfig`

### 1.2 Authentication Flow
```
1. User logs in or signs up
2. Backend returns access_token (short-lived, ~15 min) + refresh_token (long-lived, ~30 days)
3. Mobile app stores both tokens in secure storage (flutter_secure_storage)
4. Subsequent requests attach access_token in Authorization header: "Bearer <token>"
5. When access_token expires, app auto-refreshes using refresh_token
6. Tokens stored in secure enclave (iOS Keychain, Android Keystore)
```

### 1.3 Token Storage
**Location**: Secure OS-level storage via `SecureStorageService`
- Access token: `access_token`
- Refresh token: `refresh_token`
- CSRF token: `csrf_token` (for form-based endpoints)

**Security**:
- Tokens are never stored in SharedPreferences or plain files
- Tokens are not passed through URL parameters
- Tokens are removed on logout via `clearSession()`

### 1.4 CORS & Origin Validation
**Backend Configuration** (`app.js`):
```javascript
const corsOrigins = [
  'https://sikizwa.com',
  'https://app.sikizwa.com',
  'http://localhost:3000',
  // + env-driven origins
];
```
- Requests from non-whitelisted origins are rejected
- Mobile clients bypass CORS (different protocol stack)

### 1.5 Session Cookie Hardening
Backend session cookies are configured with:
- `secure: true` - Only sent over HTTPS
- `httpOnly: true` - Inaccessible to JavaScript (XSS protection)
- `sameSite: 'Lax'` - CSRF protection
- Max age: 24 hours (configurable via `SESSION_COOKIE_MAX_AGE`)

---

## 2. Enhanced Security Practices

### 2.1 Certificate Pinning (Recommended)
**Purpose**: Prevent man-in-the-middle (MITM) attacks by pinning the server's TLS certificate.

**Implementation** (add to `ApiService`):

```dart
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

Future<Dio> _createSecureDio(String baseUrl) async {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  // Add certificate pinning
  final SecurityContext securityContext = SecurityContext.defaultContext;
  
  // Load your server certificate (save as asset)
  final certificatePem = await rootBundle.loadString('assets/certs/server.pem');
  securityContext.setTrustedCertificates(
    certificatePem.codeUnits.cast<int>(),
  );

  // Apply to HTTP client
  final httpClient = HttpClient(context: securityContext);
  httpClient.badCertificateCallback = (cert, host, port) {
    // Optionally: only accept your pinned certificate
    return host == 'sikizwa-voice-360.onrender.com';
  };

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => httpClient,
  );

  return dio;
}
```

### 2.2 Request Signing for Sensitive Operations
**Purpose**: Prevent tampering with sensitive payloads (emergency SOS, location updates).

**Example**: Sign emergency SOS payload with timestamp + device key

```dart
import 'package:crypto/crypto.dart';

String signRequest({
  required String payload,
  required String deviceSecret,
  required String timestamp,
}) {
  final message = '$payload|$timestamp';
  final hmac = Hmac(sha256, utf8.encode(deviceSecret));
  final signature = hmac.convert(utf8.encode(message));
  return signature.toString();
}

// Usage in emergency SOS
final payload = json.encode({
  'latitude': position.latitude,
  'longitude': position.longitude,
  'pendantId': deviceId,
});

final timestamp = DateTime.now().toIso8601String();
final signature = signRequest(
  payload: payload,
  deviceSecret: deviceSecret, // from secure storage
  timestamp: timestamp,
);

await api.post(
  '/api/emergency/pendant-sos',
  data: {
    'payload': payload,
    'timestamp': timestamp,
    'signature': signature,
  },
);
```

### 2.3 Request & Response Encryption
**Purpose**: End-to-end encryption for highly sensitive data (mental health data, location history).

**Option A: Field-Level Encryption** (minimal overhead)
```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptedPayload {
  final String iv;
  final String encryptedData;
  final String algorithm = 'aes-256-cbc';

  Map<String, dynamic> toJson() => {
    'iv': iv,
    'data': encryptedData,
    'alg': algorithm,
  };
}

EncryptedPayload encryptField(String plaintext, String keyHex) {
  final key = encrypt.Key.fromBase64(keyHex);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final encrypted = encrypter.encrypt(plaintext, iv: iv);
  return EncryptedPayload(
    iv: iv.base64,
    encryptedData: encrypted.base64,
  );
}
```

### 2.4 Token Refresh Strategy
**Current Implementation**: Automatic refresh via `ApiService` interceptor

**Enhanced Pattern**:
```dart
// In ApiService._attachHeaders()
Future<void> _attachHeaders(RequestOptions options) async {
  // Check if token will expire before request completes
  if (!await hasValidAccessToken()) {
    // Refresh proactively
    await _refreshAccessToken();
  }

  final token = await _storage.readAccessToken();
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
}

Future<void> _refreshAccessToken() async {
  if (_refreshing) {
    await _refreshCompleter?.future;
    return;
  }

  _refreshing = true;
  _refreshCompleter = Completer<void>();

  try {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException(statusCode: 401, message: 'No refresh token');
    }

    // POST to /api/auth/refresh (no auth required, but token needed)
    final response = await _dio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );

    final newAccess = response.data['accessToken'];
    final newRefresh = response.data['refreshToken'];

    await setSession(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );
  } catch (error) {
    await clearSession();
    rethrow;
  } finally {
    _refreshing = false;
    _refreshCompleter?.complete();
    _refreshCompleter = null;
  }
}
```

---

## 3. API Endpoint Classification

### 3.1 Authentication Endpoints (No Auth Required)
```
POST   /api/auth/anonymous           → Register anonymous user
POST   /api/auth/signup              → Create account
POST   /api/auth/login               → Login
POST   /api/auth/refresh             → Refresh access token (refresh_token required)
POST   /api/auth/forgot-password     → Request OTP
POST   /api/auth/verify-otp          → Verify OTP
POST   /api/auth/reset-password      → Reset password
```

### 3.2 Protected Endpoints (JWT Required)
```
GET    /api/user/profile             → Fetch user details
PUT    /api/user/profile             → Update profile
POST   /api/emergency/pendant-sos    → Report emergency (pendant/mobile)
POST   /api/emergency/location-update → Send real-time location
POST   /api/ai/chat                  → Chat with AI companion
POST   /api/reports/create           → File incident report
GET    /api/counsellors              → List counsellors
```

**Header Format**:
```http
GET /api/user/profile HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

---

## 4. JWT Payload Structure

### 4.1 Access Token (Short-lived, ~15 minutes)
```json
{
  "sub": "user_mongodb_id",
  "role": "user|counsellor|admin",
  "iat": 1717776000,
  "exp": 1717776900,
  "iss": "sikizwa-backend"
}
```

### 4.2 Refresh Token (Long-lived, ~30 days)
```json
{
  "sub": "user_mongodb_id",
  "role": "user|counsellor|admin",
  "iat": 1717776000,
  "exp": 1720454400,
  "iss": "sikizwa-backend",
  "type": "refresh"
}
```

**Security Notes**:
- Payloads contain **only** `sub` and `role` (no sensitive user data)
- Device ID, email, phone removed from tokens
- Backend verifies token signature with `JWT_SECRET` / `JWT_REFRESH_SECRET`
- Tokens are **not** encrypted (JWT is integrity-verified, not confidential)

---

## 5. Error Handling & Security

### 5.1 Token Expiry Handling
```dart
try {
  await api.post('/api/user/profile');
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Try refresh
    try {
      await authSessionManager.refreshToken();
      // Retry request
      await api.post('/api/user/profile');
    } catch (_) {
      // Refresh failed → redirect to login
      navigateTo(LoginScreen);
    }
  }
}
```

### 5.2 Prevent Token Leakage
- ❌ **Never** log tokens
- ❌ **Never** include tokens in URL parameters
- ❌ **Never** send tokens in request body for GET requests
- ✅ **Always** use `Authorization: Bearer <token>` header
- ✅ **Always** clear tokens on logout
- ✅ **Always** use secure storage (Keychain/Keystore)

### 5.3 Handle Rate Limiting
Backend implements exponential backoff via rate limiters:

```dart
Future<T> _requestWithRetry<T>({
  required Future<T> Function() request,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await request();
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        // Rate limited
        final delay = initialDelay * (2 ^ attempt);
        await Future.delayed(delay);
        continue;
      }
      rethrow;
    }
  }
  throw ApiException(statusCode: 503, message: 'Request failed after $maxAttempts attempts');
}
```

---

## 6. Security Headers

### 6.1 Client-Side Headers
The `ApiService` should attach:

```dart
Future<void> _attachHeaders(RequestOptions options) async {
  options.headers.addAll({
    'User-Agent': 'Sikizwa-Mobile/1.0 (Flutter)',
    'X-Client-Version': '1.0.0',
    'X-Request-ID': _generateRequestId(),
  });
}

String _generateRequestId() => const Uuid().v4(); // Unique per request
```

### 6.2 Server-Side Headers (Already in place)
Backend returns via Helmet:
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
```

---

## 7. Device Fingerprinting (Optional)

For high-security operations (emergency SOS), include device fingerprint:

```dart
import 'package:device_info_plus/device_info_plus.dart';

class DeviceFingerprint {
  static Future<String> generate() async {
    final deviceInfo = DeviceInfoPlugin();
    late String fingerprint;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      fingerprint = '${info.device}-${info.model}-${info.id}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      fingerprint = '${info.model}-${info.identifierForVendor}';
    }

    return sha256.convert(utf8.encode(fingerprint)).toString();
  }
}

// Attach to sensitive requests
final fingerprint = await DeviceFingerprint.generate();
await api.post(
  '/api/emergency/pendant-sos',
  data: {
    'location': {'lat': lat, 'lng': lng},
    'deviceFingerprint': fingerprint,
  },
);
```

---

## 8. Backend Validation

### 8.1 Access Token Validation Middleware
(Current implementation in `middleware/auth.js`):

```javascript
async function requireAuth(req, res, next) {
  let token = null;
  
  // Extract from Authorization header
  const auth = req.headers.authorization;
  if (auth && auth.startsWith('Bearer ')) {
    token = auth.split(' ')[1];
  }

  if (!token) {
    return next(new ApiError({
      statusCode: 401,
      message: 'Missing authorization token',
      errorCode: 'AUTH_TOKEN_MISSING',
    }));
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub).select('-passwordHash');
    
    if (!user || !user.isActive) {
      throw new Error('Invalid user');
    }

    if (isTokenRevoked(user, payload.iat)) {
      throw new Error('Token revoked (password changed)');
    }

    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch (error) {
    // Token invalid, expired, or signature mismatch
    return next(new ApiError({
      statusCode: 401,
      message: 'Invalid or expired token',
      errorCode: 'AUTH_INVALID_TOKEN',
    }));
  }
}
```

### 8.2 Refresh Token Validation
```javascript
async function refreshAccessToken(req, res) {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new ApiError({
      statusCode: 400,
      message: 'Refresh token required',
      errorCode: 'REFRESH_TOKEN_MISSING',
    });
  }

  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    
    if (payload.type !== 'refresh') {
      throw new Error('Token type mismatch');
    }

    const user = await User.findById(payload.sub);
    if (!user) throw new Error('User not found');

    // Issue new access token
    const newAccessToken = signToken(
      { sub: user._id, role: user.role },
      process.env.JWT_SECRET,
      '15m'
    );

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    throw new ApiError({
      statusCode: 401,
      message: 'Invalid refresh token',
      errorCode: 'REFRESH_TOKEN_INVALID',
    });
  }
}
```

---

## 9. Deployment Checklist

### 9.1 Mobile App
- [ ] Set `API_BASE_URL` to production domain via build flavor
- [ ] Enable certificate pinning for production
- [ ] Use HTTPS-only connections
- [ ] Implement token refresh before expiry
- [ ] Test logout clears all tokens
- [ ] Enable ProGuard/R8 obfuscation for release build
- [ ] Disable debug logging in release builds
- [ ] Use Code Push or equivalent for security patches

### 9.2 Backend (Already Hardened)
- [ ] Set `JWT_SECRET` and `JWT_REFRESH_SECRET` to strong random values
- [ ] Configure `CORS_ORIGINS` to allowed domains only
- [ ] Set `SESSION_COOKIE_SECURE=true` in production
- [ ] Use `SESSION_SECRET` >= 32 random characters
- [ ] Enable HTTPS at reverse proxy (Render/Nginx)
- [ ] Implement rate limiting (currently in place)
- [ ] Monitor failed auth attempts

### 9.3 Network
- [ ] Enforce TLS 1.2+ at edge proxy
- [ ] Use strong ciphers (ECDHE + AES-GCM)
- [ ] Enable HSTS header (already in place via Helmet)
- [ ] Monitor API traffic for anomalies

---

## 10. Incident Response

### 10.1 Suspected Token Compromise
1. **Immediate**: Invalidate all refresh tokens for affected user
2. **Admin Action**: Implement token revocation list (if needed for high-volume)
3. **User Notification**: Force logout and re-authentication
4. **Backend Change**: Rotate `JWT_SECRET` (invalidates all existing tokens)

### 10.2 Man-in-the-Middle (MITM) Detection
- Certificate pinning alerts invalid certificates
- Log mismatched `X-Request-ID` values
- Monitor unusual token refresh patterns

### 10.3 Account Takeover
- User changes password → all tokens revoked
- Backend sets `user.passwordChangedAt`
- `isTokenRevoked()` checks `iat` vs `passwordChangedAt`

---

## 11. Compliance

- **GDPR**: Tokens are not PII; separate consent for location data
- **HIPAA** (if applicable): Implement encrypted field storage for health data
- **Data Retention**: Delete tokens after logout; implement audit logs

---

## 12. References & Tools

### Testing
- **Postman**: Test endpoints with Bearer tokens
- **Charles Proxy**: Intercept HTTP/HTTPS (for debugging only)
- **Burp Suite**: Security scanning & MITM testing

### Libraries
```yaml
dependencies:
  dio: ^5.3.0              # HTTP client with interceptors
  flutter_secure_storage: ^9.0.0  # OS-level token storage
  device_info_plus: ^9.0.0        # Device fingerprinting
  encrypt: ^5.0.0                 # End-to-end encryption (optional)
  json_serializable: ^6.7.0       # JSON serialization
```

---

## Summary

| Layer | Mechanism | Status |
|-------|-----------|--------|
| **Transport** | HTTPS/TLS 1.2+ | ✅ In place |
| **Authentication** | JWT (access + refresh) | ✅ In place |
| **Token Storage** | Secure enclave (Keychain/Keystore) | ✅ In place |
| **Token Refresh** | Automatic before expiry | ✅ In place |
| **CORS** | Allow-list based | ✅ In place |
| **Sessions** | Secure cookie config | ✅ In place |
| **Request Signing** | Optional for sensitive ops | 🔄 Recommended |
| **Certificate Pinning** | Pin server certificate | 🔄 Recommended |
| **Encryption** | Field-level (optional) | 🔄 Optional |
| **Rate Limiting** | Exponential backoff | ✅ In place |
| **Error Handling** | Safe token expiry flow | ✅ In place |

---

**Last Updated**: 2026-06-07  
**Version**: 1.0
