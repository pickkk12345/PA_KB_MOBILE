// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Gunakan dart-define untuk override base URL saat run/build:
/// flutter run --dart-define=API_BASE_URL=https://xxx.ngrok-free.dev
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://monohydroxy-noncrystallized-lavonna.ngrok-free.dev',
);

/// (Dev only) boleh true kalau perlu mengabaikan SSL error ngrok.
/// Jangan aktifkan di production.
bool _allowBadCertificate = false;

/// Internal cached client (bisa IOClient untuk kontrol SSL)
http.Client? _clientInternal;

http.Client _getClient() {
  if (_clientInternal != null) return _clientInternal!;
  if (_allowBadCertificate) {
    final ioc = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    _clientInternal = IOClient(ioc);
  } else {
    _clientInternal = http.Client();
  }
  return _clientInternal!;
}

void setAllowBadCertificate(bool allow) {
  _allowBadCertificate = allow;
  _clientInternal?.close();
  _clientInternal = null;
}

void disposeApiService() {
  _clientInternal?.close();
  _clientInternal = null;
}

/// Helper function untuk membuat headers yang konsisten
/// PENTING: Tambahkan ngrok-skip-browser-warning untuk bypass ngrok free
Map<String, String> _getHeaders() {
  return {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // FIX: Bypass ngrok browser warning
    'User-Agent': 'RekomendasiMatkul-Mobile', // Optional: Identifikasi aplikasi
  };
}

class ApiService {
  // ------------------ AUTH & PROFILE ------------------

  static Future<Map<String, dynamic>> login(String nim, String password) async {
    final uri = Uri.parse('$_baseUrl/login');
    final res = await _getClient().post(
      uri,
      headers: _getHeaders(), // FIXED: Gunakan helper function
      body: jsonEncode({'nim': nim, 'password': password}),
    );
    return _processResponse(res);
  }

  static Future<Map<String, dynamic>> getMahasiswaByNim(String nim) async {
    final uri = Uri.parse('$_baseUrl/mahasiswa/$nim');
    final res = await _getClient().get(
      uri,
      headers: _getHeaders(), // FIXED: Tambahkan headers
    );
    return _processResponse(res);
  }

  // ------------------ PERFORMA (METRIK AGREGAT) ------------------

  /// Ambil metrik agregat yang diimport dari CSV (attendance, midterm_score, dst).
  static Future<Map<String, dynamic>> getPerforma(String nim) async {
    final uri = Uri.parse('$_baseUrl/performa/$nim');
    final res = await _getClient().get(
      uri,
      headers: _getHeaders(), // FIXED: Tambahkan headers
    );
    // Mengembalikan langsung map field performa
    return _processResponse(res);
  }

  // ------------------ REKOMENDASI ------------------

  /// Standar baru: backend kirim { nim, nama, department, rekomendasi: [ {kode,nama,sks,...} ] }
  static Future<List<Map<String, dynamic>>> getRecommendations(String nim) async {
    final uri = Uri.parse('$_baseUrl/recommend/$nim');
    final res = await _getClient().get(
      uri,
      headers: _getHeaders(), // FIXED: Tambahkan headers
    );

    final parsed = _processResponse(res);
    final list = parsed['rekomendasi'];
    if (list is List) {
      return List<Map<String, dynamic>>.from(list);
    }
    // Fallback aman: kalau backend berubah bungkusannya
    if (parsed['data'] is Map && parsed['data']['rekomendasi'] is List) {
      return List<Map<String, dynamic>>.from(parsed['data']['rekomendasi']);
    }
    return <Map<String, dynamic>>[];
  }

  // ------------------ RESPONSE HELPER ------------------

  static Map<String, dynamic> _processResponse(http.Response response) {
    final status = response.statusCode;
    final bodyText = response.body;

    dynamic bodyJson;
    if (bodyText.isNotEmpty) {
      try {
        bodyJson = jsonDecode(bodyText);
      } catch (_) {
        // Response bukan JSON
        if (status >= 200 && status < 300) {
          return {'data': bodyText};
        } else {
          throw Exception('HTTP $status: ${response.reasonPhrase}');
        }
      }
    }

    if (status >= 200 && status < 300) {
      if (bodyJson is Map<String, dynamic>) return bodyJson;
      return {'data': bodyJson};
    } else {
      // Ambil pesan error dari body jika ada
      if (bodyJson is Map<String, dynamic>) {
        final detail = bodyJson['detail'] ?? bodyJson['message'] ?? bodyJson;
        throw Exception('$detail');
      }
      throw Exception('HTTP $status: ${response.reasonPhrase}');
    }
  }
}