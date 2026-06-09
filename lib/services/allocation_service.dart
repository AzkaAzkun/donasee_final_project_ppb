import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/allocation_model.dart';

class AllocationService {
  final _col = FirebaseFirestore.instance.collection('allocations');

  Future<void> createAllocation(AllocationModel a) async {
    await _col.add(a.toFirestore());
  }

  // Untuk tab "Kabar Penggunaan Dana" di dalam detail kampanye
  Stream<List<AllocationModel>> getAllocationsByCampaignStream(
    String campaignId,
  ) {
    return _col
        .where('kampanyeId', isEqualTo: campaignId)
        .snapshots()
        .map(
          (s) {
            final list = s.docs
                .map((d) => AllocationModel.fromFirestore(d.data(), d.id))
                .toList();
            // Sort client-side (no composite index needed)
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  // Untuk tab "Kabar Baik" global
  Stream<List<AllocationModel>> getAllAllocationsStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AllocationModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Stream<AllocationModel?> getAllocationByIdStream(String id) {
    return _col.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AllocationModel.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> updateAllocation(String id, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await _col.doc(id).update(fields);
  }

  Future<void> deleteAllocation(String id) async {
    await _col.doc(id).delete();
  }
}
