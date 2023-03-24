import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aipict_win/main.dart';
import 'package:aipict_win/screen/login_screen.dart';
import 'package:aipict_win/widget/recently_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;

String uid = "";
String email = "";
String? username="";


class MoreScreen extends StatefulWidget {

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {

  bool isUser = false;

  @override
  void initState() {
    if(_auth.currentUser != null) {
      uid = _auth.currentUser!.uid;
      email = _auth.currentUser!.email!;
      isUser = true;
      getUserInfo();
    }else{
      print(isUser);
      username = '';
      email = '';
    }

    super.initState();

  }

  Future<void> getUserInfo() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore.collection('user').where('uid',isEqualTo: uid).get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = snapshot.docs;
    // 문서 데이터와 문서 ID 출력 예제
    for (final DocumentSnapshot<Map<String, dynamic>> document in documents) {
      final Map<String, dynamic>? data = document.data();
      final String id = document.id;
      // 문서 데이터 출력
      if (data != null) {
        print('Document data: $data');
        setState(() {
          username = data['username'];
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
          child : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding : EdgeInsets.only(top:10),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('image/icon_512.png'),),
                  ),
                  SizedBox(width:30),
                  Column(
                    children: [
                      Container(
                        padding : EdgeInsets.only(top:15,bottom: 10),
                        child: Text(
                          /*username != "" ? '${username}' : '비회원',*/
                            'Ai Pict',
                            style : TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ),
                      Container(
                        padding : EdgeInsets.all(10),
                        width: 140,
                        height: 5,
                        color:Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20,),
              Container(
                  padding : EdgeInsets.all(10),
                  width : MediaQuery.of(context).size.width*0.9,
                  height : MediaQuery.of(context).size.height*0.5,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    border: Border.all(width:3,color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      '안녕하세요. Ai Pict입니다. \n찾아주셔서 감사합니다. \n사용하시기 전에 몇가지 주의사항을 전달드립니다. \n\n 1.해당 앱에 업로드되는 모든 사진은 Ai기술을 사용하여 제작된 사진이며, 1인 특정인물을 학습하여 가공하는 딥페이크 기술을 전혀 사용하지 않습니다. \n\n 2. 해당 사진의 저작권은 Ai Pict에 있습니다. 제3자에게 판매하는 등의 상업적인 이용을 금지합니다. \n\n 3.업로드된 본 앱 내 사진의 재가공등을 금지합니다. \n\n 4.개인적인 용도의 다운로드 및 기타 커뮤니티로의 업로드는 허용합니다. \n\n 5.해당 앱은 음란물 수준의 노출도를 목표하며 제작된 AI사진이 없으며, 그럴 의도도 전혀 없습니다. 앱 이용에 참고해주시기 바랍니다. \n\n 6. 기타 문의사항 및 건의사항은 개발사 E-mail로 연락주시기 바랍니다.\n Developer Email : poxdkrkrkrkr@gmail.com \n\n 즐거운 이용되시기 바랍니다.',
                      style : TextStyle(
                        color : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      )
                    ),
                  ),
              ),
              Container(
                  padding : EdgeInsets.all(10),
                  width : MediaQuery.of(context).size.width*0.9,
                  child : TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      if(isUser) {
                        await _auth.signOut();
                        Navigator.pushAndRemoveUntil(
                            context, MaterialPageRoute(
                            builder: (context) => MyApp()), (
                            route) => false
                        );
                      }else{
                        Navigator.pushAndRemoveUntil(
                            context, MaterialPageRoute(
                            builder: (context) => LoginScreen()), (
                            route) => false
                        );
                      }
                    },
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.white,),
                          SizedBox(width: 10,),
                          Text(
                              isUser ? '로그아웃' : '로그인',
                              style : TextStyle(color : Colors.white)
                          )
                        ],
                      ),
                    ),

                  )
              )
            ],
          )
      ),
    );
  }
}
