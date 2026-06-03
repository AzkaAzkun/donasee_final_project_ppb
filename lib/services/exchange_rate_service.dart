import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const _url = 'https://open.er-api.com/v6/latest/IDR';

  // Ambil rate IDR → USD
  // Response API: { "rates": { "USD": 0.000062, ... } }
  Future<double?> getUsdRate() async {
    try {
      final res = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return (rates['USD'] as num).toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Konversi nominal Rupiah ke string USD
  // Contoh: 50000 → "$3.15 USD"
  Future<String> convertToUsd(int rupiah) async {
    final rate = await getUsdRate();
    if (rate == null) return 'Tidak tersedia';
    final usd = rupiah * rate;
    return '\$${usd.toStringAsFixed(2)} USD';
  }
}
