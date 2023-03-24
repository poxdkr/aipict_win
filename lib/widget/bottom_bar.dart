import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
String uid = "";
String username = "";

class BottomBar extends StatefulWidget {

  final List<Widget> tabs;

  BottomBar({required this.tabs});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {


  DateTime? currentBackPressTime;
  Future<void> getUserInfo() async {

    if(_auth.currentUser != null) {
      print('_auth.currentUser가 null이 아님???');
      uid = _auth.currentUser!.uid;
    }

    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore.collection(
        'user').where('uid', isEqualTo: uid).get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = snapshot.docs;
    // 문서 데이터와 문서 ID 출력 예제
    for (final DocumentSnapshot<Map<String, dynamic>> document in documents) {
      final Map<String, dynamic>? data = document.data();
      final String id = document.id;
      // 문서 데이터 출력
      if (data != null) {
        print('Document data: $data');
        username = data['username'];
      }else{
          username = 'none';
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      return WillPopScope(
          onWillPop: () async {
        final backButtonPressTime = DateTime.now();

        if (currentBackPressTime == null ||
            backButtonPressTime.difference(currentBackPressTime!) >
                Duration(seconds: 2)) {
          currentBackPressTime = backButtonPressTime;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.redAccent.withOpacity(0.5),
              content: Text('한 번 더 누르면 앱이 종료됩니다.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
              ),
              ),
            ),
          );
          return false;
        }
        return true;
      },
    child:Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
              child : Container(
                child: TabBar(
                  indicatorColor: Colors.white60,
                  tabs:widget.tabs
                ),
              ),
        ),
      )
      );
  }
}
