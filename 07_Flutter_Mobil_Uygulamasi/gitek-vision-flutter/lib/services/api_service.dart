// Flutter uygulaması ile FastAPI backend arasındaki tüm HTTP iletişimini merkezileştirir.
// Tahmin, sağlık kontrolü, geçmiş, ayrıntı, silme ve rapor indirme işlemlerini yürütür.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/analiz_detayi.dart';
import '../models/analiz_sonucu.dart';
import '../models/gecmis_analiz.dart';
import '../models/sistem_bilgisi.dart';

class ApiHatasi implements Exception {
  const ApiHatasi(this.kullaniciMesaji);

  final String kullaniciMesaji;

  @override
  String toString() => kullaniciMesaji;
}

// Bu sınıf durum tutmaz; ağ işlemleri tek bir servis arabirimi altında toplanır.
class ApiService {
  const ApiService();

  Future<AnalizSonucu> analizEt({
    required String dosyaYolu,
    required String dosyaAdi,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      ApiConfig.endpoint('/tahmin'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('dosya', dosyaYolu, filename: dosyaAdi),
    );

    try {
      final streamed = await request.send().timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(ApiConfig.requestTimeout);

      final data = _decodeObject(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Backend hata ${response.statusCode}: ${response.body}');
        if (response.statusCode >= 500) {
          throw const ApiHatasi('Sunucuda analiz sırasında hata oluştu.');
        }
        final detail = data?['detail']?.toString();
        throw ApiHatasi(
          detail?.isNotEmpty == true ? detail! : 'Fotoğraf gönderilemedi.',
        );
      }

      if (data == null) {
        throw const ApiHatasi('Sunucudan gelen cevap okunamadı.');
      }
      return AnalizSonucu.fromJson(data);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('İstek zaman aşımı: $error\n$stackTrace');
      throw const ApiHatasi('İstek zaman aşımına uğradı.');
    } on SocketException catch (error, stackTrace) {
      debugPrint('Socket hatası: $error\n$stackTrace');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('HTTP bağlantı hatası: $error\n$stackTrace');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on ApiHatasi {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      debugPrint('JSON hatası: $error\n$stackTrace');
      throw const ApiHatasi('Sunucudan gelen cevap okunamadı.');
    } catch (error, stackTrace) {
      debugPrint('Beklenmeyen analiz hatası: $error\n$stackTrace');
      throw const ApiHatasi('Analiz sırasında beklenmeyen bir hata oluştu.');
    }
  }

  Future<SistemBilgisi> sistemBilgisiGetir() async {
    try {
      final response = await http
          .get(ApiConfig.endpoint('/saglik'))
          .timeout(ApiConfig.healthTimeout);

      final data = _decodeObject(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiHatasi('Sistem bilgisi alınamadı.');
      }
      final rawSistem = data?['sistem'];
      if (rawSistem is! Map) {
        throw const ApiHatasi('Sistem bilgisi okunamadı.');
      }

      return SistemBilgisi.fromJson(Map<String, dynamic>.from(rawSistem));
    } on TimeoutException {
      throw const ApiHatasi('Jetson sağlık kontrolü zaman aşımına uğradı.');
    } on SocketException {
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on http.ClientException {
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on ApiHatasi {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Sistem bilgisi hatası: $error\n$stackTrace');
      throw const ApiHatasi('Sistem bilgisi okunamadı.');
    }
  }

  Future<List<GecmisAnaliz>> analizleriGetir() async {
    try {
      final response = await http
          .get(ApiConfig.endpoint('/analizler'))
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Geçmiş endpoint hata ${response.statusCode}: ${response.body}',
        );
        throw const ApiHatasi('Geçmiş analizler alınamadı.');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic rows = decoded is List
          ? decoded
          : decoded is Map
          ? decoded['analizler']
          : null;
      if (rows is! List) return const [];

      return rows
          .whereType<Map>()
          .map((item) => GecmisAnaliz.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on TimeoutException catch (error) {
      debugPrint('Geçmiş zaman aşımı: $error');
      throw const ApiHatasi('İstek zaman aşımına uğradı.');
    } on SocketException catch (error) {
      debugPrint('Geçmiş socket hatası: $error');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on http.ClientException catch (error) {
      debugPrint('Geçmiş bağlantı hatası: $error');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on ApiHatasi {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Geçmiş okuma hatası: $error\n$stackTrace');
      throw const ApiHatasi('Geçmiş analizler okunamadı.');
    }
  }

  Future<AnalizDetayi> analizDetayiGetir(int analizId) async {
    try {
      final response = await http
          .get(ApiConfig.endpoint('/analizler/$analizId'))
          .timeout(ApiConfig.requestTimeout);

      final data = _decodeObject(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Analiz detay endpoint hata ${response.statusCode}: '
          '${response.body}',
        );
        final detail = data?['detail']?.toString();
        throw ApiHatasi(
          detail?.isNotEmpty == true
              ? detail!
              : 'Analiz ayrıntıları alınamadı.',
        );
      }

      if (data == null) {
        throw const ApiHatasi('Sunucudan gelen cevap okunamadı.');
      }

      return AnalizDetayi.fromJson(data);
    } on TimeoutException catch (error) {
      debugPrint('Analiz detay zaman aşımı: $error');
      throw const ApiHatasi('İstek zaman aşımına uğradı.');
    } on SocketException catch (error) {
      debugPrint('Analiz detay socket hatası: $error');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on http.ClientException catch (error) {
      debugPrint('Analiz detay bağlantı hatası: $error');
      throw const ApiHatasi('Jetson sunucusuna bağlanılamadı.');
    } on ApiHatasi {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Analiz detay okuma hatası: $error\n$stackTrace');
      throw const ApiHatasi('Analiz ayrıntıları okunamadı.');
    }
  }

  Map<String, dynamic>? _decodeObject(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) rethrow;
      return null;
    }
  }
}
