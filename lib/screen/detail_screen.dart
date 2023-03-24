import 'dart:math';
import 'package:aipict_win/firebase_options.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aipict_win/model/comment_model.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:aipict_win/model/paint_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';




FirebaseFirestore fstore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
String uid = "";
var fcmToken = FirebaseMessaging.instance.getToken(vapidKey: "BNZniSDCR04atJgpU2IzjfejWr6Ydwwd5ZXFabwpMtDz9djwdAcGyw_iM_hP3xHdcE2l6Do1KIfb9vdpP7TVGGw");

bool isUser = false;
String comment_txt = "";

//권한요청 함수
Future<void> _requestPermission() async {
  final status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    throw Exception('Permission denied');
  }
}

class DetailScreen extends StatefulWidget {
  final int pindex;
  final Paint_m paint;
  final List<Paint_m> paints;

  DetailScreen({required this.pindex, required this.paint, required this.paints});
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {

  //댓글 작성
  final _formKey = GlobalKey<FormState>();
  TextEditingController _controller = TextEditingController();

  //validation Method 제작
  void _tryValidation(){
    final isValid = _formKey.currentState!.validate();
    if(isValid){
      _formKey.currentState!.save();
    }
    print('comment_txt : $comment_txt');

  }

  //좋아요 기능
  bool like = false;
  int like_cnt = 0;

  //다운로드 기능
  String _imagePath = "";
  bool _isLoading = false;

  //공유하기
  Future<void> share() async {
    String address = widget.paint.p_file.replaceAll(' ', '_');
    List<String> addrArr = address.split('image/');
    String imageNo = addrArr[1];
    String url = 'http://lhg.happytester.co.kr/shareApp.php?image=$imageNo';
    await FlutterShare.share(
        linkUrl:url,
        title: 'Sharing Ai_Pict App'
    );

    Clipboard.setData(ClipboardData(text: url));
  }

  //위치 애니메이션
  late double _dx;
  late double _dy;

  @override
  void initState() {

    if(_auth.currentUser != null){
      uid = _auth.currentUser!.uid;
      isUser = true;
    }
    like_cnt = widget.paint.like_cnt;
    super.initState();
    _dx = 0;
    _dy = 0;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    getlikeInfo();

  }

  Future<void> likeEdit(like) async {

    //var fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: "BNZniSDCR04atJgpU2IzjfejWr6Ydwwd5ZXFabwpMtDz9djwdAcGyw_iM_hP3xHdcE2l6Do1KIfb9vdpP7TVGGw");
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MM/dd HH:mm').format(now);

    final prefs = await SharedPreferences.getInstance();
    var fcmToken = prefs.getString("token");

    if(like) {
      await fstore.collection('like').doc().set({
        // 필드와 값 추가
        'uid': fcmToken,
        'code': widget.paint.code,
        'regdate' : formattedDate
      });
    }else{
      var querySnapshot = await fstore.collection('like').where('uid',isEqualTo: fcmToken).where('code',isEqualTo: widget.paint.code).get();
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete()
            .then((value) =>
            print("문서 삭제 완료"))
            .catchError((error) =>
            print("문서 삭제 중 에러 발생: $error"));
      });
    }
  }

  Future<void> getlikeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    var fcmToken = prefs.getString("token");

    QuerySnapshot<Map<String, dynamic>> snapshot = await fstore.collection('like').where('uid',isEqualTo: fcmToken).where('code',isEqualTo: widget.paint.code).get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = snapshot.docs;
    // 문서 데이터와 문서 ID 출력 예제
    for (final DocumentSnapshot<Map<String, dynamic>> document in documents) {
      final Map<String, dynamic>? data = document.data();
      // 문서 데이터 출력
      if (data != null) {
        setState(() {
          like = true;
        });
      }else{
        like = false;
      }
    }
  }

  Future<void> openChrome(down_url) async {
    print('Download started');
    try {
      //await _requestPermission();
      var time = DateTime.now().millisecondsSinceEpoch;
      var path = "C:/image-$time.jpg";
      var file = File(path);

      Uri url = Uri.parse(path);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }

    } catch (e) {
      print(e);
    }
  }

  void _submitComment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 댓글 데이터베이스에 저장
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('MM/dd HH:mm').format(now);

      await FirebaseFirestore.instance.collection('comments').add({
        'code': widget.paint.code,
        'uid' : uid,
        'comment': comment_txt,
        'regdate': formattedDate,
      });

      // 입력 필드 초기화
      _controller.clear();
      comment_txt = "";
    }
  }

  Widget _buildBody(BuildContext context, List<DocumentSnapshot> snapshot){


    List<Comment_m> comment = snapshot.map((m)=> Comment_m.fromSnapshot(m)).toList();

    List<Widget> commentResult = [];

    for(Comment_m cmt in comment){
      Widget cmt_widget =  Container(
        padding: EdgeInsets.all(5),
        child: Row(
          children: [
            Expanded(
              flex : 3,
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding : EdgeInsets.all(10),
                  child: Text(cmt.comment,
                      style : TextStyle(
                        fontWeight: FontWeight.bold,
                        color : Colors.black,
                        shadows: [Shadow(color: Colors.white, offset: Offset(1,1))],
                        fontSize: 11,
                      )
                  )
              ),
            ),
            Expanded(
              flex : 1,
              child: Container(
                  padding : EdgeInsets.all(5),
                  child: Text('(${cmt.regdate})',
                      style : TextStyle(
                        fontWeight: FontWeight.bold,
                        color : Colors.black12,
                        shadows: [Shadow(color: Colors.white, offset: Offset(1,2))],
                        fontSize: 11,
                      )
                  )
              ),
            )
          ],
        ),
      );
      commentResult.add(cmt_widget);
    }

    return Container(
      child: Column(
        children: commentResult,
      ),
    );
  }

  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    print('index는 ${widget.pindex}');
    print('index는 ${widget.paints[widget.pindex]}');
      return WillPopScope(
          onWillPop: () async {
            /*final backButtonPressTime = DateTime.now();

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
            }*/
            return true;
          },
      child : Scaffold(
      body : GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
        },
        onPanUpdate: (detail){
          print('드래그 이벤트 발생: ${detail.delta.dx}, ${detail.delta.dy}');
          var move_dir = "";

          if(detail.delta.dx > 0 && detail.delta.dx > 10){
            if(widget.pindex > 0){
              move_dir = "left";
              var move_idx = widget.pindex-1;

              print('move_idx :: ${move_idx}');
              print('pindex :: ${widget.pindex} / length ::${widget.paints.length-1}');

              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => DetailScreen(pindex: move_idx, paint: widget.paints[move_idx], paints: widget.paints))
              );
            }
          }else if(detail.delta.dx < -10){

            if(widget.pindex < widget.paints.length-1){

              move_dir = "right";
              var move_idx = widget.pindex+1;

              print('move_idx :: ${move_idx}');
              print('pindex :: ${widget.pindex} / length ::${widget.paints.length-1}');

              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => DetailScreen(pindex: move_idx, paint: widget.paints[move_idx], paints: widget.paints))
              );
            }
          }
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final double maxSlide = 200;
            double slide = _dx.abs() / maxSlide;
            slide = slide.clamp(0.0, 1.0);
            final double angle = slide * pi / 6;

            return Transform(
              transform: Matrix4.identity()
                ..translate(_dx)
                ..rotateZ(angle),
              alignment: Alignment.center,
              child: child,
            );
          },

          child: Container(
              child : SafeArea(
                child: ListView(
                  children: [
                    Stack(
                      children: [
                        Container(width: double.maxFinite,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image:CachedNetworkImageProvider(widget.paint.p_file,),
                                fit: BoxFit.cover
                            ),
                          ),
                          child: ClipRect(
                              child : BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10,sigmaY: 10),
                                child: Container(
                                  alignment: Alignment.center,
                                  color : Colors.black.withOpacity(0.1),
                                  child: Container(
                                    child: Column(
                                      children: [
                                        Container(
                                            padding : EdgeInsets.fromLTRB(0, 60, 0, 10),
                                            child :Stack(
                                              children: [
                                                CachedNetworkImage( // Image.network
                                                    imageUrl: widget.paint.p_file,
                                                    placeholder: (context, url) => Container(
                                                      height : MediaQuery.of(context).size.height*0.7,
                                                      child: const SpinKitWave(
                                                        color: Colors.redAccent,
                                                        size: 200,
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                                    fadeOutDuration: const Duration(seconds: 1),
                                                    fadeInDuration: const Duration(seconds: 1),
                                                    fit: BoxFit.fitWidth),
                                                Positioned(
                                                  bottom: 5,
                                                  left: 5,
                                                  child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor: Colors.transparent,
                                                          backgroundImage: AssetImage('image/icon.png',),
                                                        ),
                                                        SizedBox(width:5),
                                                        Text(
                                                          "Ai_pict",
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12.0,
                                                              fontWeight: FontWeight.bold,
                                                              shadows: [Shadow(color: Colors.black26,offset: Offset(1,1))]
                                                          ),
                                                        ),
                                                      ]
                                                  ),
                                                ),
                                              ],
                                            )
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6)
                                          ),
                                          padding : EdgeInsets.all(7),
                                          child: Text(
                                            widget.paint.cate,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16
                                            ),
                                          ),
                                        ),

                                        Container(
                                          decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6)
                                          ),
                                          padding : EdgeInsets.all(7),
                                          child: Text(widget.paint.hashtag, style: TextStyle(overflow: TextOverflow.fade),),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                          ),
                        ),
                        Positioned(
                          child: AppBar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            elevation: 0,
                            actions: [
                              SizedBox(height: 10,),
                              // 상단 툴바
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    //좋아요 버튼
                                    Container(
                                      padding : EdgeInsets.fromLTRB(5, 5, 0, 5),
                                      child:ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,elevation: 0),
                                        onPressed: (){

                                          setState((){
                                            //현재 like 상태의 반대
                                            like = !like;

                                            if(like) {
                                              like_cnt++;
                                              //현재 객체의 like_cnt와 현재 리스트객체의 pindex번째 객체의 like_cnt를 변경
                                              widget.paint.like_cnt = like_cnt;
                                              widget.paints[widget.pindex].like_cnt =like_cnt;
                                              widget.paint.reference.update(
                                                  {"like_cnt" : like_cnt}
                                              );
                                              likeEdit(like);

                                            }else{
                                              like_cnt--;
                                              //현재 객체의 like_cnt와 현재 리스트객체의 pindex번째 객체의 like_cnt를 변경
                                              widget.paint.like_cnt = like_cnt;
                                              widget.paints[widget.pindex].like_cnt =like_cnt;
                                              widget.paint.reference.update(
                                                  {"like_cnt" : like_cnt}
                                              );
                                              likeEdit(like);
                                            }
                                            /*print(like);
                                              print(like_cnt);*/
                                          });
                                        },
                                        child: Container(
                                          height: 48,
                                          child: Row(
                                            children: [
                                              Icon(
                                                like
                                                    ? Icons.favorite
                                                    : Icons.favorite_border_outlined,
                                                color:
                                                like
                                                    ? Colors.redAccent.shade400
                                                    : Colors.white,
                                                size: 30,
                                              ),
                                              SizedBox(width: 10,),
                                              Text(
                                                (like_cnt).toString(),
                                                style: TextStyle(
                                                    color:
                                                    like
                                                        ? Colors.redAccent.shade400
                                                        : Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              SizedBox(width: 40,),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    //다운로드 버튼

                                    /*Container(
                                      padding : EdgeInsets.fromLTRB(5, 10, 5, 10),
                                      child : ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,elevation: 0),
                                        onPressed: (){
                                          *//*if(!isUser){
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    duration: Duration(milliseconds: 700),
                                                    content: Text(
                                                      '다운로드는 회원가입이 필요합니다',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold
                                                      ),
                                                    ),
                                                    backgroundColor: Colors.redAccent.shade200,
                                                  )
                                              );
                                              return null;
                                            }*//*
                                          //이미지 다운로드 시작
                                          openChrome(widget.paint.p_file);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                duration: Duration(milliseconds: 500),
                                                content: Text(
                                                  '이미지를 다운로드 합니다.',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                backgroundColor: Colors.redAccent.shade200,
                                              )
                                          );

                                        },
                                        child:Icon(Icons.download),
                                      ),
                                    ),*/
                                    //공유하기 버튼
                                    /*Container(
                                      padding : EdgeInsets.fromLTRB(5, 10, 5, 10),
                                      child : ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,elevation: 0),
                                        onPressed: share,
                                        child: Icon(Icons.copy, color: Colors.transparent),
                                      ),
                                    ),*/
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
 /*                   Container(
                      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      height : 80,
                      child: Form(
                        key: _formKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  labelText: 'Reply',
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  focusedBorder:OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  enabledBorder:OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '댓글을 입력하세요';
                                  }
                                  if(!isUser){
                                    return '댓글 작성은 로그인이 필요합니다.';
                                  }

                                },
                                onSaved: (value) {
                                  comment_txt = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(50, 50),
                                elevation: 0,
                                primary: Colors.black,
                              ),
                              onPressed: () async {
                                _submitComment();
                              },
                              child: Icon(Icons.subdirectory_arrow_left),
                            ),
                          ],
                        ),
                      ),
                    ),*/
                    //댓글 보여주기 창
/*                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('comments')
                          .where('code',isEqualTo: widget.paint.code)
                          .snapshots(),
                      builder: (context, snapshot){
                        if(!snapshot.hasData){
                          print('loading.......');
                          return LinearProgressIndicator();
                        }else{
                          return _buildBody(context,snapshot.data!.docs);
                        }
                      },
                    ),*/

                  ],
                ),
              )
          ),
        ),
      ),
    )
      );



  }

}

