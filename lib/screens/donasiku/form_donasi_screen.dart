import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/auth_service.dart';

class FormDonasiScreen extends StatefulWidget {
  final CampaignModel campaign;
  const FormDonasiScreen({required this.campaign, super.key});

  @override
  State<FormDonasiScreen> createState() => _FormDonasiScreenState();
}

class _FormDonasiScreenState extends State<FormDonasiScreen> {
  final _nominalCtrl = TextEditingController();
  final _pesanCtrl = TextEditingController();
  final _svcDonasi = DonationService();
  final _svcRate = ExchangeRateService();
  final _authSvc = AuthService();
  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Timer? _debounce;
  String _usdEstimasi = '';
  bool _loadingRate = false;
  bool _loadingSubmit = false;
  int _selectedAmt = 0;
  String? _errorMsg;

  final _quickAmounts = [20000, 50000, 100000, 200000];

  @override
  void dispose() {
    _debounce?.cancel();
    _nominalCtrl.dispose();
    _pesanCtrl.dispose();
    super.dispose();
  }

  void _onNominalChanged(String value) {
    _debounce?.cancel();

    final raw = value.replaceAll('.', '').replaceAll(',', '');
    final nominal = int.tryParse(raw) ?? 0;

    if (nominal <= 0) {
      setState(() {
        _usdEstimasi = '';
        _loadingRate = false;
      });
      return;
    }

    setState(() => _loadingRate = true);

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final usd = await _svcRate.convertToUsd(nominal);
      if (mounted) {
        setState(() {
          _usdEstimasi = usd;
          _loadingRate = false;
        });
      }
    });
  }

  void _pilihNominal(int amount) {
    setState(() => _selectedAmt = amount);
    _nominalCtrl.text = amount.toString();
    _onNominalChanged(amount.toString());
  }

  String _formatRupiah(String raw) {
    final angka = raw.replaceAll('.', '');
    if (angka.isEmpty) return '';
    final number = int.tryParse(angka) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(number);
  }

  // ─── Submit donasi ────────────────────────────────────────
  Future<void> _submit() async {
    final rawText = _nominalCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final nominal = int.tryParse(rawText) ?? 0;

    if (nominal < 1000) {
      setState(() => _errorMsg = 'Nominal minimal Rp 1.000');
      return;
    }

    setState(() {
      _loadingSubmit = true;
      _errorMsg = null;
    });

    try {
      final user = await _authSvc.getCurrentUserModel();
      if (user == null) throw Exception('User tidak ditemukan');

      final donasi = DonationModel(
        id: '',
        kampanyeId: widget.campaign.id,
        kampanyeJudul: widget.campaign.judul,
        donaturId: user.uid,
        donaturNama: user.nama,
        nominal: nominal,
        metode: 'transfer_bank_manual',
        status: DonationStatus.pending,
        createdAt: DateTime.now(),
      );

      await _svcDonasi.createDonation(donasi);

      if (mounted) {
        // Tampilkan dialog sukses
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1F5EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF1D9E75),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Donasi Berhasil Dibuat!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan transfer ${_fmt.format(nominal)} ke rekening berikut dan upload bukti transfer.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Info rekening
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      _RekeningRow(label: 'Bank', value: 'BCA'),
                      _RekeningRow(label: 'No. Rek', value: '1234567890'),
                      _RekeningRow(label: 'a.n.', value: 'Yayasan Donasi'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // tutup dialog
                      Navigator.pop(context); // kembali ke detail kampanye
                    },
                    child: const Text('Oke, Mengerti'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = 'Gagal membuat donasi: $e');
    } finally {
      if (mounted) setState(() => _loadingSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtTarget = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Form Donasi'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info kampanye
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home, color: Color(0xFF1D9E75)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.campaign.judul,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.campaign.organisasiNama,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0F6E56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pilih nominal cepat
            const Text(
              'Pilih Nominal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _quickAmounts.map((amt) {
                final selected = _selectedAmt == amt;
                return GestureDetector(
                  onTap: () => _pilihNominal(amt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1D9E75) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        fmtTarget.format(amt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Input nominal manual
            const Text(
              'Atau Masukkan Nominal Lain',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nominalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                // final cursor = _nominalCtrl.selection;
                final formatted = _formatRupiah(val);
                _nominalCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
                setState(() => _selectedAmt = 0);
                _onNominalChanged(val);
              },
              decoration: InputDecoration(
                prefixText: 'Rp  ',
                prefixStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                hintText: '0',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1D9E75),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Konversi USD dari External API
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: (_loadingRate || _usdEstimasi.isNotEmpty) ? 44 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange,
                      size: 16,
                      color: Color(0xFF1D9E75),
                    ),
                    const SizedBox(width: 8),
                    if (_loadingRate)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1D9E75),
                        ),
                      )
                    else
                      Text(
                        'Estimasi: $_usdEstimasi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF085041),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (!_loadingRate && _usdEstimasi.isNotEmpty)
                      const Text(
                        '(via Exchange Rate API)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0F6E56),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Metode pembayaran
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D9E75), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Color(0xFF1D9E75),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer Bank Manual',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Transfer ke rekening, lalu upload bukti',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Color(0xFF1D9E75)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info rekening
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Info Rekening Tujuan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  _RekeningRow(label: 'Bank', value: 'BCA'),
                  _RekeningRow(label: 'No. Rek', value: '1234567890'),
                  _RekeningRow(label: 'a.n.', value: 'Yayasan Donasi'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMsg != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(
                    color: Color(0xFFA32D2D),
                    fontSize: 13,
                  ),
                ),
              ),

            // Tombol donasi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadingSubmit ? null : _submit,
                child: _loadingSubmit
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Donasi Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Helper widget info rekening
class _RekeningRow extends StatelessWidget {
  final String label;
  final String value;
  const _RekeningRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
