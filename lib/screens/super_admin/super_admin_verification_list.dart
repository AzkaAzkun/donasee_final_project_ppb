import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/services/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'super_admin_panti_detail.dart';

class SuperAdminVerificationList extends StatefulWidget {
  const SuperAdminVerificationList({super.key});

  @override
  State<SuperAdminVerificationList> createState() => _SuperAdminVerificationListState();
}

class _SuperAdminVerificationListState extends State<SuperAdminVerificationList> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Semua, 1: Menunggu Verifikasi, 2: Terverifikasi
  int _currentPage = 1;
  final int _pageSize = 5;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  Future<void> _approvePanti(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Panti?'),
        content: Text('Apakah Anda yakin menyetujui pendaftaran panti "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentAdminUid = AuthService().currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': currentAdminUid,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panti "$name" berhasil disetujui!'),
            backgroundColor: const Color(0xFF00682C),
          ),
        );
      }
    }
  }

  Future<void> _unverifyPanti(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cabut Verifikasi?'),
        content: Text('Apakah Anda yakin ingin mencabut verifikasi untuk "$name"? Institusi ini akan kehilangan akses publik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cabut Verifikasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': false,
        'verifiedAt': null,
        'verifiedBy': null,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verifikasi panti "$name" berhasil dicabut.'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }




  void _showTambahPantiDialog() {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final orgNamaCtrl = TextEditingController();
    final orgAlamatCtrl = TextEditingController();
    final orgTelpCtrl = TextEditingController();
    
    PlatformFile? pickedFile;
    Uint8List? pdfBytes;
    File? pdfFile;
    bool dialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> pickPDF() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null) {
                  setDialogState(() {
                    pickedFile = result.files.first;
                    if (kIsWeb) {
                      pdfBytes = pickedFile!.bytes;
                    } else {
                      if (pickedFile!.path != null) {
                        pdfFile = File(pickedFile!.path!);
                        pdfBytes = pdfFile!.readAsBytesSync();
                      } else {
                        pdfBytes = pickedFile!.bytes;
                      }
                    }
                    dialogError = null;
                  });
                }
              } catch (e) {
                setDialogState(() {
                  dialogError = 'Gagal memilih file: $e';
                });
              }
            }

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              
              setDialogState(() {
                dialogLoading = true;
                dialogError = null;
              });

              try {
                // Initialize secondary app
                final secondaryApp = await Firebase.initializeApp(
                  name: 'secondaryRegisterApp',
                  options: Firebase.app().options,
                );
                final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
                
                final cred = await secondaryAuth.createUserWithEmailAndPassword(
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                );
                final newUid = cred.user!.uid;

                String? pdfUrl;
                if (pdfBytes != null || pdfFile != null) {
                  pdfUrl = await ImageUploadService().uploadSuratResmi(
                    uid: newUid,
                    bytes: pdfBytes,
                    file: pdfFile,
                  );
                }

                final currentAdminUid = AuthService().currentUser?.uid ?? '';
                final user = UserModel(
                  uid: newUid,
                  email: emailCtrl.text.trim(),
                  nama: namaCtrl.text.trim(),
                  role: 'admin',
                  createdAt: DateTime.now(),
                  organisasiNama: orgNamaCtrl.text.trim(),
                  organisasiAlamat: orgAlamatCtrl.text.trim(),
                  organisasiTelepon: orgTelpCtrl.text.trim(),
                  suratResmiUrl: pdfUrl,
                  isVerified: true, // Auto-verify since manually created by Super Admin
                  verifiedAt: DateTime.now(),
                  verifiedBy: currentAdminUid,
                );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(newUid)
                    .set(user.toFirestore());

                await secondaryAuth.signOut();
                await secondaryApp.delete();

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Panti "${user.organisasiNama}" berhasil didaftarkan & diverifikasi!'),
                      backgroundColor: const Color(0xFF00682C),
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() {
                  dialogLoading = false;
                  dialogError = e.toString().replaceAll('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.only(top: 20, left: 24, right: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tambah Panti Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  )
                ],
              ),
              content: dialogLoading
                  ? SizedBox(
                      height: 200,
                      width: 380,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Color(0xFF0066FF)),
                            SizedBox(height: 16),
                            Text('Mendaftarkan panti baru...', style: TextStyle(color: Color(0xFF727687))),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 380,
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dialogError != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.15)),
                                  ),
                                  child: Text(dialogError!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12)),
                                ),
                              ],
                              const Text('Detail Akun Pengurus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0066FF))),
                              const Divider(height: 16),
                              
                              _buildFieldLabel('Nama Lengkap Admin'),
                              TextFormField(
                                controller: namaCtrl,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Nama admin wajib diisi' : null,
                                decoration: _inputDecor('Masukkan nama lengkap', Icons.person_outline_rounded),
                              ),
                              const SizedBox(height: 12),

                              _buildFieldLabel('Alamat Email'),
                              TextFormField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email wajib diisi';
                                  if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                                  return null;
                                },
                                decoration: _inputDecor('contoh@email.com', Icons.mail_outline_rounded),
                              ),
                              const SizedBox(height: 12),

                              _buildFieldLabel('Password'),
                              TextFormField(
                                controller: passCtrl,
                                obscureText: true,
                                validator: (v) => v == null || v.isEmpty || v.length < 6 ? 'Password minimal 6 karakter' : null,
                                decoration: _inputDecor('Minimal 6 karakter', Icons.lock_outline_rounded),
                              ),
                              const SizedBox(height: 20),

                              const Text('Detail Panti Asuhan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0066FF))),
                              const Divider(height: 16),

                              _buildFieldLabel('Nama Panti Asuhan'),
                              TextFormField(
                                controller: orgNamaCtrl,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Nama panti wajib diisi' : null,
                                decoration: _inputDecor('Masukkan nama resmi panti', Icons.corporate_fare_rounded),
                              ),
                              const SizedBox(height: 12),

                              _buildFieldLabel('Alamat Lengkap Panti'),
                              TextFormField(
                                controller: orgAlamatCtrl,
                                maxLines: 2,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Alamat panti wajib diisi' : null,
                                decoration: _inputDecor('Jalan, RT/RW, Kelurahan, Kecamatan, Kota', Icons.location_on_outlined),
                              ),
                              const SizedBox(height: 12),

                              _buildFieldLabel('Nomor Telepon Panti'),
                              TextFormField(
                                controller: orgTelpCtrl,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                                decoration: _inputDecor('Contoh: 081234567890', Icons.phone_outlined),
                              ),
                              const SizedBox(height: 16),

                              _buildFieldLabel('Dokumen Legalitas (PDF) - Opsional'),
                              GestureDetector(
                                onTap: pickPDF,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: pickedFile != null ? const Color(0xFF0066FF) : const Color(0xFFC2C6D8),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        pickedFile != null ? Icons.picture_as_pdf_rounded : Icons.cloud_upload_outlined,
                                        color: pickedFile != null ? const Color(0xFF0066FF) : const Color(0xFF727687),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          pickedFile != null ? pickedFile!.name : 'Unggah Surat Resmi PDF',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: pickedFile != null ? const Color(0xFF0066FF) : const Color(0xFF191C1E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              actions: dialogLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan & Verifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191C1E)),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF727687)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahPantiDialog,
        backgroundColor: const Color(0xFF0066FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Panti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final users = docs.map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

          // Calculate counts
          final totalAntrian = users.where((u) => !u.isVerified).length;
          final totalTerdaftar = users.where((u) => u.isVerified).length;
          final semuaInstitusi = users.length;

          // Apply filters
          List<UserModel> filteredUsers = users;
          
          // Tab filter
          if (_selectedTab == 1) {
            filteredUsers = filteredUsers.where((u) => !u.isVerified).toList();
          } else if (_selectedTab == 2) {
            filteredUsers = filteredUsers.where((u) => u.isVerified).toList();
          }

          // Search query filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredUsers = filteredUsers.where((u) {
              final nama = u.nama.toLowerCase();
              final panti = (u.organisasiNama ?? '').toLowerCase();
              final alamat = (u.organisasiAlamat ?? '').toLowerCase();
              return nama.contains(query) || panti.contains(query) || alamat.contains(query);
            }).toList();
          }

          // In-memory pagination calculation
          final totalPages = (filteredUsers.length / _pageSize).ceil();
          final resolvedTotalPages = totalPages == 0 ? 1 : totalPages;
          if (_currentPage > resolvedTotalPages) {
            _currentPage = resolvedTotalPages;
          }

          final startIndex = (_currentPage - 1) * _pageSize;
          final endIndex = startIndex + _pageSize;
          final pageUsers = filteredUsers.sublist(
            startIndex,
            endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                const Text(
                  'Manajemen & Verifikasi Panti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau, verifikasi, dan kelola basis data institusi panti asuhan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF727687),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFE65100),
                        bgColor: const Color(0xFFFF9800).withValues(alpha: 0.08),
                        borderColor: const Color(0xFFFF9800).withValues(alpha: 0.15),
                        label: 'Total Antrian',
                        value: '$totalAntrian Panti',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF00682C),
                        bgColor: const Color(0xFF4AE176).withValues(alpha: 0.08),
                        borderColor: const Color(0xFF4AE176).withValues(alpha: 0.15),
                        label: 'Total Terdaftar',
                        value: '$totalTerdaftar Panti',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.business_rounded,
                        color: Colors.black,
                        bgColor: const Color(0xFFECEEF0),
                        borderColor: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
                        label: 'Semua Institusi',
                        value: '$semuaInstitusi',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari nama panti, pengurus, atau lokasi...',
                          hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF727687), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _currentPage = 1;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF7F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Segmented custom tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentButton(0, 'Semua'),
                            _buildSegmentButton(1, 'Menunggu'),
                            _buildSegmentButton(2, 'Terverifikasi'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cards list
                if (pageUsers.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Color(0xFFC2C6D8),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Panti asuhan tidak ditemukan.',
                            style: TextStyle(color: Color(0xFF727687), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pageUsers.length,
                    itemBuilder: (context, index) => _buildCard(pageUsers[index]),
                  ),
                  
                  // Pagination controls
                  _buildPagination(resolvedTotalPages),
                ],
                
                const SizedBox(height: 80), // spacer for FAB overlapping avoidance
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF727687), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color == Colors.black ? const Color(0xFF191C1E) : color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
            _currentPage = 1;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF727687),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(UserModel user) {
    final isVerified = user.isVerified;
    
    Widget statusBadge;
    if (isVerified) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4AE176).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_rounded, size: 12, color: Color(0xFF005321)),
            SizedBox(width: 4),
            Text(
              'VERIFIED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005321),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.pending_rounded, size: 12, color: Color(0xFFE65100)),
            SizedBox(width: 4),
            Text(
              'PENDING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    
    final formattedDate = DateFormat('dd MMM yyyy').format(user.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                    ? Image.network(
                        user.fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_rounded,
                          color: Color(0xFF727687),
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color: Color(0xFF727687),
                        size: 32,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            user.organisasiNama ?? 'Tidak ada nama panti',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMetaRow(Icons.person_outline_rounded, 'Pengurus: ${user.nama}'),
                    const SizedBox(height: 4),
                    _buildMetaRow(Icons.calendar_today_outlined, 'Daftar: $formattedDate'),
                    const SizedBox(height: 4),
                    _buildMetaRow(Icons.location_on_outlined, user.organisasiAlamat ?? 'Tidak ada alamat'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isVerified) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuperAdminPantiDetail(user: user),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0066FF),
                      side: const BorderSide(color: Color(0xFF0066FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approvePanti(context, user.uid, user.organisasiNama ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Verifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _unverifyPanti(context, user.uid, user.organisasiNama ?? ''),
                    icon: const Icon(Icons.gpp_bad_rounded, size: 16),
                    label: const Text('Unverify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBA1A1A),
                      side: BorderSide(color: const Color(0xFFBA1A1A).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuperAdminPantiDetail(user: user),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0066FF),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF727687)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF424656)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC2C6D8)),
                color: _currentPage > 1 ? Colors.white : Colors.transparent,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: _currentPage > 1 ? const Color(0xFF191C1E) : const Color(0xFFC2C6D8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_currentPage / $totalPages',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF191C1E)),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC2C6D8)),
                color: _currentPage < totalPages ? Colors.white : Colors.transparent,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _currentPage < totalPages ? const Color(0xFF191C1E) : const Color(0xFFC2C6D8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
