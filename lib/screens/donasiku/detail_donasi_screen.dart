import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donation_model.dart';
import '../../models/campaign_model.dart';
import '../../models/allocation_model.dart';
import '../../services/donation_service.dart';
import '../../services/campaign_service.dart';
import '../../services/allocation_service.dart';
import '../kabar/detail_alokasi_screen.dart';
import '../home/main_navigation.dart';
import 'donasiku_screen.dart';

class DetailDonasiScreen extends StatefulWidget {
  final DonationModel donation;
  const DetailDonasiScreen({required this.donation, super.key});

  @override
  State<DetailDonasiScreen> createState() => _DetailDonasiScreenState();
}

class _DetailDonasiScreenState extends State<DetailDonasiScreen> {
  final _svc = DonationService();
  final _campaignSvc = CampaignService();
  final _allocationSvc = AllocationService();

  bool _uploading = false;
  bool _canceling = false;

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  Future<void> _uploadBukti() async {
    setState(() => _uploading = true);
    try {
      final berhasil = await _svc.uploadBuktiFoto(widget.donation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              berhasil
                  ? 'Bukti transfer berhasil diupload!'
                  : 'Upload dibatalkan',
            ),
            backgroundColor: berhasil ? const Color(0xFF00682C) : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _batalkan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batalkan Donasi?',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
        ),
        content: const Text('Transaksi ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Tidak',
              style: TextStyle(color: Color(0xFF727687)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _canceling = true);
    try {
      await _svc.batalkanDonasi(widget.donation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donasi berhasil dibatalkan'),
            backgroundColor: Colors.grey,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal batalkan: $e')));
      }
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  void _showBuktiDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text(
                'Bukti Transfer',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 24,
                top: 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHubungiBantuanSheet(String donationId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hubungi Bantuan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lexend',
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jika Anda mengalami kendala saat melakukan transfer atau verifikasi, silakan hubungi tim dukungan kami melalui kontak berikut:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF424656),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7FFE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF00682C),
                ),
              ),
              title: const Text(
                'WhatsApp Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('+62 812-3456-7890'),
              onTap: () async {
                final url = Uri.parse(
                  'https://wa.me/6281234567890?text=Halo%20Donasee,%20saya%20butuh%20bantuan%20terkait%20transaksi%20ID%20$donationId',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDAE1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF0050CB),
                ),
              ),
              title: const Text(
                'Email Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('support@donasee.org'),
              onTap: () async {
                final url = Uri.parse(
                  'mailto:support@donasee.org?subject=Bantuan%20Transaksi%20ID%20$donationId',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DonationModel?>(
      stream: _svc.getDonationByIdStream(widget.donation.id),
      initialData: widget.donation,
      builder: (context, snapshot) {
        final d = snapshot.data ?? widget.donation;

        final isVerified = d.status == DonationStatus.berhasil;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              final isVerified = d.status == DonationStatus.berhasil;
              DonasikuScreen.activeTab = isVerified ? 'riwayat' : 'aktif';
              MainNavigation.navigationKey.currentState?.setIndex(1);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FB),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF7F9FB),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isVerified
                      ? const Color(0xFF0050CB)
                      : const Color(0xFF191C1E),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Detail Donasi',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0050CB),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: isVerified
                        ? const Color(0xFF0050CB)
                        : const Color(0xFF191C1E),
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'Saya telah berdonasi sebesar ${_fmt.format(d.nominal)} untuk kampanye "${d.kampanyeJudul}" melalui Donasee! Mari ikut berbagi kebaikan.',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pesan kebaikan berhasil disalin ke papan klip!',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: StreamBuilder<CampaignModel?>(
              stream: _campaignSvc.getCampaignByIdStream(d.kampanyeId),
              builder: (context, campaignSnapshot) {
                final campaign = campaignSnapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isVerified)
                        _buildVerifiedContent(d, campaign)
                      else
                        _buildUnverifiedContent(d, campaign),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifiedContent(DonationModel d, CampaignModel? campaign) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Celebration Section
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FFE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Color(0xFF00682C),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Donasi Berhasil',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00682C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jumlah Donasi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF424656),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt.format(d.nominal),
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0050CB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Campaign Card (Anchor)
        _buildCampaignCard(d, campaign),
        const SizedBox(height: 24),

        // Transaction Details Bento Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final hasPesan = d.pesan != null && d.pesan!.trim().isNotEmpty;
            if (constraints.maxWidth > 600 && hasPesan) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildTransactionDetailsCard(d)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSupportMessageCard(d)),
                  ],
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTransactionDetailsCard(d),
                  if (hasPesan) ...[
                    const SizedBox(height: 16),
                    _buildSupportMessageCard(d),
                  ],
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),

        // Impact Section
        _buildImpactSection(d.kampanyeId),
        const SizedBox(height: 24),

        // Final CTA
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0050CB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    'Saya telah berdonasi sebesar ${_fmt.format(d.nominal)} untuk kampanye "${d.kampanyeJudul}" melalui Donasee! Mari ikut berbagi kebaikan.',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesan kebaikan berhasil disalin ke papan klip!'),
              ),
            );
          },
          icon: const Icon(Icons.share, size: 20),
          label: const Text(
            'Bagikan Kebaikan Ini',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Terima kasih atas kontribusimu. Donasee menjamin transparansi 100% untuk setiap dana yang disalurkan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF727687),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUnverifiedContent(DonationModel d, CampaignModel? campaign) {
    final isWaiting = d.status == DonationStatus.menungguVerifikasi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status & Amount Card
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pending,
                        size: 18,
                        color: Color(0xFF7A5A00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isWaiting ? 'Menunggu Verifikasi' : 'Menunggu Transfer',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A5A00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isWaiting ? 'Jumlah Kontribusi' : 'Total Transfer',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF424656),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt.format(d.nominal),
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0050CB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Progress/Information Alert Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F6),
            border: Border.all(
              color: const Color(0xFFC2C6D8).withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0050CB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF0050CB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tahap Verifikasi',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWaiting
                          ? 'Tim kami sedang memverifikasi bukti transfer Anda. Proses ini biasanya memakan waktu 1-24 jam. Kami akan mengirimkan notifikasi setelah status berubah.'
                          : 'Silakan lakukan transfer ke rekening bank di bawah ini, kemudian upload bukti transfer Anda agar tim kami dapat memverifikasi donasi Anda.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF424656),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Transaction Details Section
        _buildTransactionDetailsCard(d),
        const SizedBox(height: 24),

        // Info Rekening (Jika status pending)
        if (!isWaiting) ...[
          _buildBankInstructionsCard(),
          const SizedBox(height: 24),
        ],

        // Campaign Visual Card
        _buildCampaignVisualCard(d, campaign),
        const SizedBox(height: 24),

        // CTA Buttons
        if (!isWaiting) ...[
          // Pending actions
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0050CB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _uploading ? null : _uploadBukti,
            icon: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.upload_file),
            label: Text(
              _uploading ? 'Mengupload...' : 'Upload Bukti Transfer',
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              side: const BorderSide(color: Color(0xFFBA1A1A)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _canceling ? null : _batalkan,
            icon: _canceling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFFBA1A1A),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text(
              'Batalkan Donasi',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          // Waiting actions
          if (d.buktiFotoUrl != null) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0050CB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showBuktiDialog(d.buktiFotoUrl!),
              icon: const Icon(Icons.image_search),
              label: const Text(
                'Lihat Bukti Transfer',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0050CB),
              side: const BorderSide(color: Color(0xFF0050CB), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showHubungiBantuanSheet(d.id),
            icon: const Icon(Icons.support_agent),
            label: const Text(
              'Hubungi Bantuan',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCampaignCard(DonationModel d, CampaignModel? campaign) {
    final String kategori = campaign?.kategori ?? 'Lainnya';
    final String deskripsi =
        campaign?.deskripsi ??
        'Memastikan setiap kontribusi disalurkan dengan transparansi penuh.';
    final String? imgUrl = campaign?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;

          final imageWidget = Container(
            width: isWide ? 150 : double.infinity,
            height: isWide ? double.infinity : 150,
            color: const Color(0xFFE0E3E5),
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.campaign, size: 40, color: Colors.grey),
                  ),
          );

          final contentWidget = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00682C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    kategori.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00682C),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.kampanyeJudul,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  imageWidget,
                  Expanded(child: contentWidget),
                ],
              ),
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [imageWidget, contentWidget],
            );
          }
        },
      ),
    );
  }

  Widget _buildTransactionDetailsCard(DonationModel d) {
    final isVerified = d.status == DonationStatus.berhasil;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isVerified ? 'Informasi Transaksi' : 'Rincian Transaksi',
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFECEEF0), height: 1),
          const SizedBox(height: 12),

          _buildDetailRow('Tanggal & Waktu', _dateFmt.format(d.createdAt)),
          _buildDetailRow('ID Transaksi', d.id, isMono: true),
          _buildDetailRow('Metode Pembayaran', 'Transfer Bank Manual'),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFECEEF0), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Transfer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                Text(
                  _fmt.format(d.nominal),
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0050CB),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportMessageCard(DonationModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0050CB).withValues(alpha: 0.05),
        border: Border.all(
          color: const Color(0xFF0050CB).withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.format_quote,
              size: 48,
              color: const Color(0xFF0050CB).withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0050CB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pesan Kamu',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${d.pesan}"',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF001849),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(String campaignId) {
    return StreamBuilder<List<AllocationModel>>(
      stream: _allocationSvc.getAllocationsByCampaignStream(campaignId),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final latestUpdate = hasData ? snapshot.data!.first : null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F6),
            border: Border.all(
              color: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6DF5E1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Color(0xFF006F64),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Dampak Donasimu',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Kabar Terbaru',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF424656),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      latestUpdate != null
                          ? latestUpdate.deskripsi
                          : 'Terima kasih atas kontribusi Anda! Tim kami sedang mempersiapkan penyaluran dana. Kabar terbaru akan diperbarui secara real-time di sini.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF424656),
                        height: 1.5,
                      ),
                    ),
                    if (latestUpdate != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0050CB),
                          side: const BorderSide(color: Color(0xFF0050CB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailAlokasiScreen(
                                allocationId: latestUpdate.id,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat Detail Kabar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekening Tujuan Transfer',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFECEEF0), height: 1),
          const SizedBox(height: 12),
          _buildBankInfoRow('Bank', 'BCA'),
          _buildBankInfoRow('No. Rekening', '1234567890', canCopy: true),
          _buildBankInfoRow('Atas Nama', 'Yayasan Donasi'),
        ],
      ),
    );
  }

  Widget _buildCampaignVisualCard(DonationModel d, CampaignModel? campaign) {
    final String? imgUrl = campaign?.imageUrl;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imgUrl != null
              ? Image.network(imgUrl, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0050CB), Color(0xFF006B5F)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.campaign,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006B5F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'KAMPANYE TERKAIT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.kampanyeJudul,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF424656),
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: isMono ? 'monospace' : 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF424656),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nomor rekening berhasil disalin!'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0050CB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.copy,
                        size: 14,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
