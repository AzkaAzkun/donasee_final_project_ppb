import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/auth_service.dart';
import 'detail_donasi_screen.dart';

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

  String _selectedPaymentMethod = 'transfer_bank_manual'; // default
  bool _isAnonymous = false;

  final _quickAmounts = [50000, 100000, 250000, 500000];

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
    setState(() {
      _selectedAmt = amount;
      _nominalCtrl.text = _formatRupiah(amount.toString());
    });
    _onNominalChanged(amount.toString());
  }

  String _formatRupiah(String raw) {
    final angka = raw.replaceAll('.', '');
    if (angka.isEmpty) return '';
    final number = int.tryParse(angka) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(number);
  }

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
      if (user == null) throw Exception('Pengguna tidak ditemukan');

      final donorName = _isAnonymous ? 'Hamba Allah' : user.nama;
      final supportMessage = _pesanCtrl.text.trim().isNotEmpty ? _pesanCtrl.text.trim() : null;

      // Pre-generate Firebase Doc ID
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('donations').doc();

      // Save to Firestore with status pending (menunggu pembayaran)
      final donasi = DonationModel(
        id: docRef.id,
        kampanyeId: widget.campaign.id,
        kampanyeJudul: widget.campaign.judul,
        donaturId: user.uid,
        donaturNama: donorName,
        nominal: nominal,
        metode: 'transfer_bank_manual',
        status: DonationStatus.pending,
        buktiFotoUrl: null,
        createdAt: DateTime.now(),
        pesan: supportMessage,
        isAnonymous: _isAnonymous,
      );

      await _svcDonasi.createDonationWithId(donasi);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDonasiScreen(donation: donasi),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = 'Gagal memproses donasi: $e');
    } finally {
      if (mounted) setState(() => _loadingSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0050CB),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donasi Sekarang',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Lexend',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Summary Section
              _buildCampaignSummaryCard(),
              const SizedBox(height: 24),

              // Donation Amount Section
              _buildAmountInputSection(),
              const SizedBox(height: 24),

              // Payment Method Section
              _buildPaymentMethodSection(),
              const SizedBox(height: 24),

              // Message & Anonymous Section
              _buildMessageSection(),
              const SizedBox(height: 100), // padding bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildCampaignSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E3E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.campaign.imageUrl != null
                  ? Image.network(
                      widget.campaign.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.campaign,
                        color: Color(0xFF0050CB),
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.campaign,
                      color: Color(0xFF0050CB),
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DF5E1).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.campaign.kategori,
                    style: const TextStyle(
                      color: Color(0xFF006F64),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.campaign.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.campaign.organisasiNama,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF727687),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Pilih Nominal Donasi',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            TextField(
              controller: _nominalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                final formatted = _formatRupiah(val);
                _nominalCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );

                final cleanNum =
                    int.tryParse(val.replaceAll('.', '').replaceAll(',', '')) ??
                        0;
                setState(() {
                  _selectedAmt = cleanNum;
                });
                _onNominalChanged(val);
              },
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(
                  left: 48,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: '0',
                hintStyle: const TextStyle(color: Color(0xFFC2C6D8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E3E5),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E3E5),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF0050CB),
                    width: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 18,
              child: Text(
                'Rp',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0050CB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick select chips
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _quickAmounts.map((amt) {
            final isSelected = _selectedAmt == amt;
            return GestureDetector(
              onTap: () => _pilihNominal(amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0050CB) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0050CB) : const Color(0xFFE0E3E5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _fmt.format(amt),
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF727687),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Conversion USD API display
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: (_loadingRate || _usdEstimasi.isNotEmpty) ? 44 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FFE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.currency_exchange,
                  size: 16,
                  color: Color(0xFF00682C),
                ),
                const SizedBox(width: 8),
                if (_loadingRate)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00682C),
                    ),
                  )
                else
                  Text(
                    'Estimasi: $_usdEstimasi',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005321),
                    ),
                  ),
                const SizedBox(width: 6),
                if (!_loadingRate && _usdEstimasi.isNotEmpty)
                  const Text(
                    '(via Exchange Rate API)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00682C),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodRow(
          title: 'Transfer Bank Manual',
          subtitle: 'Konfirmasi Manual',
          code: 'transfer_bank_manual',
          icon: Icons.account_balance_outlined,
          iconBgColor: const Color(0xFFDAE1FF),
          iconColor: const Color(0xFF0050CB),
        ),
        const SizedBox(height: 12),
        _buildBankInstructionsCard(),
      ],
    );
  }

  Widget _buildBankInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E3E5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Ke Rekening Tujuan:',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424656),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank BCA',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'a.n. Yayasan Donasee',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF727687),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    '1234567890',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0050CB),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Color(0xFF0050CB)),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: '1234567890'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nomor rekening berhasil disalin!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Salin nomor rekening',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildPaymentMethodRow({
    required String title,
    required String subtitle,
    required String code,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0050CB) : const Color(0xFFE0E3E5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF727687),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0050CB) : const Color(0xFFC2C6D8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0050CB),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pesan Dukungan (Opsional)',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF727687),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pesanCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis kata-kata penyemangat untuk mereka...',
              hintStyle: const TextStyle(color: Color(0xFFC2C6D8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF7F9FB),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E3E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E3E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0050CB)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFECEEF0), height: 1),
          const SizedBox(height: 16),

          // Anonymous Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2F4F6),
                    ),
                    child: const Icon(
                      Icons.visibility_off_outlined,
                      color: Color(0xFF727687),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sembunyikan Nama',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      Text(
                        'Donasi sebagai hamba Allah',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _isAnonymous,
                onChanged: (val) {
                  setState(() {
                    _isAnonymous = val;
                  });
                },
                activeThumbColor: const Color(0xFF0050CB),
                activeTrackColor: const Color(0xFF0050CB).withValues(alpha: 0.2),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE0E3E5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMsg != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMsg!,
                style: const TextStyle(
                  color: Color(0xFFBA1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0050CB),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _loadingSubmit ? null : _submit,
            child: _loadingSubmit
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjutkan Pembayaran',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}


