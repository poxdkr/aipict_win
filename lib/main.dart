import 'dart:html' as html;
import 'package:aipict_win/firebase_options.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:aipict_win/screen/home_screen.dart';
import 'package:aipict_win/screen/more_screen.dart';
import 'package:aipict_win/screen/search_screen.dart';
import 'package:aipict_win/screen/upload_screen.dart';
import 'package:aipict_win/widget/bottom_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;

String uid = "";
String username = "";
String userToken="";


/*
String unitId = 'ca-app-pub-2124338818654953/4064980277'; //실제 광고 ID
String testUnitId = 'ca-app-pub-3940256099942544/1033173712'; //테스트 유닛 ID
*/

Future<String?> getUserToken() async {

  final prefs = await SharedPreferences.getInstance();
  print('실행됨');
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  String nowTime = formatter.format(now);

  //PC환경이기 때문에 FCM토큰 말고 쿠키에 유저정보를 남긴다.
  //UUID를 통해 사용자를 식별하고자 한다.
  var fcmToken = prefs.getString("token");

  //먼저 저장된 쿠키가 있는지 확인한다.
  if (fcmToken != null) {
    print('fcmToken OO :: $fcmToken');
    print('해당 사용자 토큰이 존재합니다.');
  } else {
      print('fcmToken XX :: $fcmToken');
      print('해당 사용자 토큰이 존재하지 않습니다.');

      String uuid = Uuid().v4();
      await prefs.setString("token", uuid);
      print('새로운 이용자의 토큰이 등록되었습니다.');
  }
  return fcmToken;
}

Future<void> main() async {

  //FlutterBinding 초기화
  WidgetsFlutterBinding.ensureInitialized();
  //showInterstitialAd();
  //FireBase초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //구글애드 초기화
  //MobileAds.instance.initialize();

  //브라우저 종류 식별
  if (html.window.navigator.userAgent.contains('Chrome') ||
      html.window.navigator.userAgent.contains('Edge')) {
      print('${html.window.navigator.userAgent}');
      print('현재 환경은 웹브라우저');
  }

  //App 시작
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  void initState() {
    if(_auth.currentUser != null) {
      uid = _auth.currentUser!.uid;
      getUserInfo();
    }

    //유저의 토큰등록 여부를 판단후 없으면 등록
    super.initState();
    getUserToken();
  }

  Future<void> getUserInfo() async {
    print('main uid : $uid');
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

    return MaterialApp(
      title: 'Ai_pict',
      theme: ThemeData(primaryColor: Colors.black, brightness: Brightness.dark,fontFamily: 'NotoSans',),

      home :AnimatedSplashScreen(
        splashIconSize: 300,
        curve: Curves.bounceIn,
        backgroundColor: Colors.black.withOpacity(0.5),
        splash : Container(
          child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('image/main_icon.png'),
                  radius: 75,
                ),
                SizedBox(height: 40,),
                Text(
                  'Now on Loading',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold
                  ),
                ),
                SpinKitThreeInOut(
                  color: Colors.redAccent,
                  size: 40,
                  duration: Duration(seconds: 1),
                )
              ]
          ),
        ),
        splashTransition: SplashTransition.fadeTransition,
        nextScreen: StreamBuilder(
                  //로그아웃이나 뒤로가기를 시도하여 이 페이지를 올 경우
                  //FirebaseAuth.instance가 변화했는지를 체크하여 페이지를 이동시켜주기 위해 StreamBuilder를 사용
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot){
                      /*if(snapshot.hasData){
                      print('main _ username :: $username');*/
                      return TabControl_pad();
                      /*}else{
                      return LoginScreen();
                    }*/
                    }
                ),
        ),
      //TabController()
    );
  }
}

Widget TabControl_pad(){

  /*print('unitId :: $unitId');
  print('testUnitId :: $testUnitId');
*/
  List<Widget> tabs = [];
  List<Widget> tabViewList = [];
  if(_auth.currentUser!=null){
    print("auth 살아있음!!");
  }
  print('username :::::: $username');

  if(username == "admin" && _auth.currentUser!=null) {
    tabs = [
      Tab(
        icon: Icon(Icons.home),
        text: '홈',
      ),
      Tab(
        icon: Icon(Icons.menu),
        text: '전체'        
      ),
      Tab(
        icon: Icon(Icons.info_outline),
        text: '정보'
      ),
      Tab(icon: Icon(Icons.settings),
      text: '관리'
      )
    ];
    tabViewList= [
      HomeScreen(),
      SearchScreen(),
      MoreScreen(),
      UploadScreen(),
    ];
  }else{
    tabs = [
      Tab(
        icon: Icon(Icons.home),
        text: '홈',
      ),
      Tab(
        icon: Icon(Icons.menu),
        text: '전체'
      ),
      Tab(
        icon: Icon(Icons.info_outline),
        text: '정보'
      )
    ];
    tabViewList= [
      HomeScreen(),
      SearchScreen(),
      MoreScreen(),
    ];
  }
  return DefaultTabController(
    length: tabs.length,
    animationDuration: Duration(milliseconds: 50),
    child: Scaffold(
      body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: tabViewList
        ),
      bottomNavigationBar: BottomBar(tabs : tabs)
      ),
  );
}


