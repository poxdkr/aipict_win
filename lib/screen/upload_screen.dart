import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as Img;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

List<String> selList = <String>["Stable","Chill_Out_Mix", "Basil_Mix", "Mixed", "Etc"];
Uuid uuid = Uuid();
String code = "";

FirebaseFirestore firestore = FirebaseFirestore.instance;

//권한요청 함수
Future<void> _requestPermission() async {
  final status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    throw Exception('Permission denied');
  }
}

class UploadScreen extends StatefulWidget {

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {

  //FireBase_store 관련 선언
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addData(Map<String, dynamic> paintJson) async {
    try {
      await _firestore.collection('paint').doc().set(paintJson);
      print('Data added successfully');
    } catch (e) {
      print(e.toString());
    }
  }


  String cate = selList.first;
  bool isA = false;
  String hashtag = "";
  List<String> hashList = [];

  bool isUploaded = false;
  String p_file= "";
  String p_file_downUrl = "";
  File? _file;

  String regdate = "";

  TextEditingController _hashtag_ctrl= TextEditingController();

  //FCM Text controller
  TextEditingController _fcm_title= TextEditingController();
  TextEditingController _fcm_body= TextEditingController();

  //날짜 확인
  String getToday(){
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String nowTime = formatter.format(now);
    return nowTime;
  }

  //이미지 압축
  Future<File> compressAndGetFile(File file, String targetPath) async {
    var image = Img.decodeImage(file.readAsBytesSync());
    var compressedImage = Img.encodeJpg(image!, quality: 75);
    return File(targetPath)..writeAsBytesSync(compressedImage);
  }

  // 파일 선택을 위한 함수
  Future<void> _pickFile() async {
    try {
      await _requestPermission();

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final compressedFile = await compressAndGetFile(File(pickedFile.path), pickedFile.path);
        setState(() {
          _file = compressedFile;
        });
      } else {
          _file = null;
          print('No image selected.');
        }
    }on PlatformException catch (e){
      // 에러 핸들링 코드
      print("Failed to pick image: $e");
    }
  }
// 파일 업로드 함수
  Future<String?> uploadImage(File file) async {
    try {
      String url = 'http://lhg.happytester.co.kr/saveImage.php';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 파일 추가;
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      // 파일 업로드
      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.transform(utf8.decoder).join();
        print('Image uploaded!');
        print('????'+responseString);
        p_file = responseString;
        //업로드된 파일의 다운로드 URL 반환
        String downloadUrl = await response.stream.bytesToString();
        p_file = downloadUrl;
        p_file_downUrl = downloadUrl;
        print('downloadUrl :: $downloadUrl');
        return downloadUrl;
      } else {
        print('Image upload failed!');
      }
    } catch (e) {
      // 파일 업로드 실패 시 예외 처리
      print(e);
      return null;
    }
  }

  //전체 유저에게 파이어베이스 메시지 보내기
  Future<void> sendPushNotification(String title, String body) async {

    List<String> tokensList = [];

    await FirebaseFirestore.instance
        .collection('tokens')
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        tokensList.add(doc.data()['token']);
      });
    });

    for(var i=0; i< tokensList.length; i++){
      var token = tokensList[i];
      var message = {
        'notification': {
          'title' : title,
          'body': body,
        },
        'to': token,
      };
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAAbe25idw:APA91bGet_gc6ChRwjI_EHHmFYFoNEnGF_j8ka22oYYML_BFl5H_g86Ize2wfkMRVCY-_kyVt63oRcf4RlkUyFwvkMlTM-xRjXYi8PGZe-n8Jid-V4mN_miUX97OPubGx49nXn7tGJGh',
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        // 성공
        final responseBody = jsonDecode(response.body);
        print('푸시 발송 성공!!!');

      } else {
        print('푸시 발송 실패.....');
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: GestureDetector(
            onTap: (){
              FocusScope.of(context).unfocus();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height:20),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children : [
                      //카테고리
                      Container(color: Colors.white60, width: double.infinity,height: 2,),
                      Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Container(
                                  child:Text('Category', style: TextStyle(color: Colors.white38.withOpacity(0.8), fontWeight: FontWeight.bold),textAlign: TextAlign.center),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(2)
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                child: DropdownButton<String>(
                                  value: cate,
                                  dropdownColor: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  icon: const Icon(Icons.open_in_full, color: Colors.white,),
                                  elevation: 20,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  underline: Container(
                                    height: 1,
                                    color: Colors.white,
                                  ),
                                  onChanged: (String? value) {
                                    setState(() {
                                      cate = value!;
                                    });
                                  },
                                  items: selList.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          )
                      ),
                      //isA
                      Container(color: Colors.white60, width: double.infinity,height: 2,),
                      Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Container(
                                  child:Text('Adult only', style: TextStyle(color: Colors.white38.withOpacity(0.8), fontWeight: FontWeight.bold),textAlign: TextAlign.center),
                                  decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(2)
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                child: Switch(
                                    value: isA,
                                    activeColor: Colors.redAccent.shade200,
                                    onChanged: (value){
                                      setState(() {
                                        isA = value!;
                                      });
                                }),
                              )
                            ],
                          )
                      ),
                      //해시태그
                      Container(color: Colors.white60, width: double.infinity,height: 2,),
                      Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Container(
                                      child:Text('Hashtags', style: TextStyle(color: Colors.white38.withOpacity(0.8), fontWeight: FontWeight.bold),textAlign: TextAlign.center),
                                      decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(2)
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(top : 20),
                                    child: Column(
                                      children: makeHashs(hashList),
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                    Container(
                                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                      child: SizedBox(
                                        width: 150,
                                        child : TextField(
                                          controller: _hashtag_ctrl,
                                          decoration: InputDecoration(
                                              focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.white, width: 3)
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.white, width: 3),
                                              ),
                                              border: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.transparent)
                                              ),

                                              //HASH태그 추가하기
                                              suffixIcon: IconButton(
                                                icon: Icon(Icons.transit_enterexit_rounded),
                                                onPressed: (){
                                                  setState(() {
                                                    if(hashList.length>4){
                                                      return null;
                                                    }
                                                    if(_hashtag_ctrl.text != "") {
                                                      hashList.add('#'+_hashtag_ctrl.text);
                                                      _hashtag_ctrl.text = "";
                                                    }
                                                    FocusScope.of(context).unfocus();
                                                  });
                                                },
                                              ),
                                              labelText: 'Hashtags',
                                              labelStyle: TextStyle(color : Colors.white)
                                          ),
                                        ),
                                      ),
                                    ),
                                    //Hash태그 전부 삭제하기
                                    IconButton(
                                        onPressed: (){
                                          setState(() {
                                            hashList = [];
                                          });
                                        },
                                        icon: Icon(Icons.cancel)
                                    )
                                  ],
                                ),
                            ],
                          ),
                      ),
                      //파일 옮기기 컨테이너
                      Container(color: Colors.white60, width: double.infinity,height: 2,),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                SizedBox(
                                width: 100,
                                  child: Container(
                                    child:Text('File', style: TextStyle(color: Colors.white38.withOpacity(0.8), fontWeight: FontWeight.bold),textAlign: TextAlign.center),
                                    decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(2)
                                    ),
                                  ),
                                ),
                                _file == null
                                    ? Container(
                                        padding: EdgeInsets.only(left: 20),
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 200,
                                          height: 250,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.white, width: 10)
                                          ),
                                          child: IconButton(
                                              icon: Icon(Icons.upload_file, size: 50),
                                              onPressed: () {
                                                _pickFile();
                                              }
                                          ),
                                        ),
                                    )
                                    : Container(
                                  padding: EdgeInsets.only(left: 20),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 200,
                                    height: 250,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white, width: 2)
                                    ),
                                    child: InkWell(
                                      onTap: (){
                                        _pickFile();
                                      },
                                      child: Image.file(_file!),
                                    ),
                                  ),
                                )
                          ],
                        ),
                      ),
                      //!!!!!!seqnum 부여와 regdate부여는 업로드하기를 누르면 부여
                    ]
                  ),
                ),
                //최하단 Confirm Tap
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      //업로드하기
                      TextButton(
                          onPressed: () async {
                            //업로드 시작
                            //0. 무결성 체크

                            print('code : $code');
                            print('cate : $cate');
                            print('isA : $isA');
                            isUploaded = _file != null ? true : false;
                            print('isUploaded : $isUploaded');
                            if(!isUploaded){
                              Alert("File checked", 'Cant find any files');
                              return null;
                            }
                            hashtag = "";
                            if(hashList.length<1){
                              Alert("Hashtag checked", 'Cant find any Hashtags');
                              return null;
                            }else {
                              for (var i = 0; i < hashList.length; i++) {
                                hashtag += hashList[i];
                              }
                            }

                            if(_file != null) {
                              try {
                                p_file = (await uploadImage(_file!))!;
                              }catch(e){
                                print('upload failed by $e');
                              }
                            }else {
                              return;
                            }

                            print('p_file : $p_file');

                            regdate = "";
                            regdate = getToday();

                            print('regdate : $regdate');

                            //파일 저장 및 모두 다운로드 완료 model에 맵으로 담아서 firebase data에 저장.
                            try {
                              await _firestore.collection('paint').doc().set({
                                // 필드와 값 추가
                                'code': uuid.v1(),
                                'cate': cate,
                                'isA': isA,
                                'hashtag': hashtag,
                                'p_file': p_file,
                                'p_file_downUrl' : p_file,
                                'like_cnt' : 0,
                                'regdate': regdate,
                              });
                              print('Data added successfully');
                              setState(() {
                                code = "";
                                hashtag= "";
                                hashList = [];
                                _file = null;
                              });

                              //저장되어 있던 모든 정보 삭제

                            } catch (e) {
                              print(e.toString());
                            }

                          },
                          child: Text('Upload', style : TextStyle(fontSize: 15, fontWeight: FontWeight.bold,color:Colors.white)),
                          style : TextButton.styleFrom(backgroundColor: Colors.blueAccent,)
                      ),

                      //취소하기
                      TextButton(
                          onPressed: (){
                            setState(() {
                              //모든 기록 삭제
                              _file = null;
                              isA = false;
                              isUploaded = false;

                            });
                          },
                          child: Text('Cancel', style : TextStyle(fontSize: 15, fontWeight: FontWeight.bold,color:Colors.white)),
                          style : TextButton.styleFrom(backgroundColor: Colors.grey,)
                      )
                    ],
                  ),
                ),
                SizedBox(height:20),
                Container(
                  padding : EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white,width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding : EdgeInsets.all(8),
                        child: Text('PUSH 알림 보내기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        ),
                        ),
                      ),
                      SizedBox(height: 20,),
                      Row(
                       children: [
                         Expanded(
                            flex:4,
                             child: Container(
                               padding: EdgeInsets.all(5),
                               height: 200,
                               child: Column(
                                 children: [
                                   Text('Title', style: TextStyle(color: Colors.white, fontSize: 15,fontWeight: FontWeight.bold),),
                                   TextField(
                                     controller: _fcm_title,
                                     decoration: InputDecoration(
                                       border: OutlineInputBorder(
                                           borderSide: BorderSide(color: Colors.redAccent.shade400),
                                       ),
                                       enabledBorder: OutlineInputBorder(
                                         borderSide: BorderSide(color: Colors.redAccent.shade400),
                                       ),
                                       focusedBorder: OutlineInputBorder(
                                         borderSide: BorderSide(color: Colors.redAccent.shade400),
                                       )
                                     ),
                                   ),
                                   SizedBox(height:10),
                                   Text('Content', style: TextStyle(color: Colors.white, fontSize: 15,fontWeight: FontWeight.bold),),
                                   TextField(
                                     controller: _fcm_body,
                                     decoration: InputDecoration(
                                         border: OutlineInputBorder(
                                           borderSide: BorderSide(color: Colors.redAccent.shade400),
                                         ),
                                         enabledBorder: OutlineInputBorder(
                                           borderSide: BorderSide(color: Colors.redAccent.shade400),
                                         ),
                                         focusedBorder: OutlineInputBorder(
                                           borderSide: BorderSide(color: Colors.redAccent.shade400),
                                         )
                                     ),
                                   )
                                 ],
                               ),
                             ),
                         ),
                         Expanded(
                             flex:1,
                             child: Container(
                               child: TextButton(
                                 child: Text('Push'),
                                 onPressed: (){
                                    var title = _fcm_title.text;
                                    var body = _fcm_body.text;
                                    if(title == "" || body == ""){
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('제목이나 내용이 비어있습니다.',
                                          style: TextStyle(color:Colors.white)),
                                          duration: Duration(milliseconds: 500),
                                          backgroundColor: Colors.redAccent.shade100,
                                        )
                                      );
                                      return;
                                    }else{
                                      print('title :: $title');
                                      print('body :: $body');
                                      sendPushNotification(title, body);
                                    }
                                 },
                               ),
                             )
                         ),
                           ],
                          ),
                    ],
                  ),
                ),
                //FCM 발송해보기
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Dialog
  void Alert(String title,String message){
    showDialog(
        context: context,
        //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            //Dialog Main Title
            title: Column(
              children: <Widget>[
                Icon(Icons.lock_outlined,color: Colors.redAccent.shade700),
                Text(title),
              ],
            ),
            //
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message, style : TextStyle(color: Colors.redAccent.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
}

}

List<Widget> makeHashs(List<String> hashlist){
  List<Widget> results = [];
  for(var i=0; i<hashlist.length; i++){
    results.add(
      InkWell(
        child: TextButton(

          child: Text(hashlist[i], style: TextStyle(color : Colors.white, fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis),
          onPressed: (){},
          style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), primary: Colors.black, minimumSize: Size(10, 10), maximumSize: Size(100,30))
        ),
      )
    );
  }

  return results;
}



