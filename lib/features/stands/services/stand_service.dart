import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/stand.dart';

class StandService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Stand>> fetchStands(List<String> standIds) async {
    try {
      final docs = await Future.wait(
        standIds.map((id) => _firestore.collection('stands').doc(id).get()),
      );
      return docs.map((doc) => Stand.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching stands: $e');
      return [];
    }
  }
}