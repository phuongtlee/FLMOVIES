import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký tài khoản
  Future<String?> registerWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  // Đăng nhập
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', userCredential.user!.uid);
      return userCredential.user?.uid;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print("Error: $e");
    }
  }

  // Thêm vào lịch sử (addHis)
  Future<void> addHistory(String userId, String movieSlug, String movieName,
      String posterUrl, String episodeSlug) async {
    try {
      final currentTime = Timestamp.now();

      // Thêm vào lịch sử phim
      await _firestore.collection('HISTORY').doc('$userId$movieSlug').set({
        'userId': userId,
        'movieSlug': movieSlug,
        'movieName': movieName,
        'posterUrl': posterUrl,
        'episodeSlug': episodeSlug,
        'datetime': currentTime,
      });

      // Thêm vào lịch sử tập phim
      await _firestore
          .collection('EPHISTORY')
          .doc('$userId$movieSlug$episodeSlug')
          .set({
        'userId': userId,
        'movieSlug': movieSlug,
        'episodeSlug': episodeSlug,
      });

      print('Lưu phim vào danh sách lịch sử thành công');
    } catch (e) {
      print('Error adding history: $e');
    }
  }

  // Cập nhật lịch sử (updateHis)
  Future<void> updateHistory(
      String userId, String movieSlug, String episodeSlug) async {
    try {
      final currentTime = Timestamp.now();

      // Cập nhật thông tin lịch sử phim
      await _firestore.collection('HISTORY').doc('$userId$movieSlug').update({
        'episodeSlug': episodeSlug,
        'datetime': currentTime,
      });

      // Kiểm tra nếu tập phim chưa có trong lịch sử tập phim, thêm vào
      final epHistoryRef = _firestore
          .collection('EPHISTORY')
          .doc('$userId$movieSlug$episodeSlug');
      final epHistoryDoc = await epHistoryRef.get();

      if (!epHistoryDoc.exists) {
        await epHistoryRef.set({
          'userId': userId,
          'movieSlug': movieSlug,
          'episodeSlug': episodeSlug,
        });
      }

      print('Lưu tập phim vào danh sách lịch sử thành công: $episodeSlug');
    } catch (e) {
      print('Error updating history: $e');
    }
  }

  // Kiểm tra tập phim đã xem (checkEPHis)
  Future<bool> checkEpisodeHistory(
      String userId, String movieSlug, String episodeSlug) async {
    try {
      final doc = await _firestore
          .collection('EPHISTORY')
          .doc('$userId$movieSlug$episodeSlug')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking episode history: $e');
      return false;
    }
  }
}
