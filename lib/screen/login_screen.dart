import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aipict_win/main.dart';
import 'package:blurry_modal_progress_hud/blurry_modal_progress_hud.dart';

class LoginScreen extends StatefulWidget {

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin{

  //배경 애니메이션
  late AnimationController _controller;
  late Animation<double> _animation;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool showSpinner = false;

  //Sign up 화면인지 확인
  bool isSignupScreen = false;

  //form을 지정할 formkey
  final _formKey = GlobalKey<FormState>();

  //onSaved시 적용될 변수
  String userName = "";
  String userMail = "";
  String userPassword = "";

  //validation Method 제작
  void _tryValidation(){
    final isValid = _formKey.currentState!.validate();
    if(isValid){
      _formKey.currentState!.save();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return BlurryModalProgressHUD(
      color: Colors.redAccent.shade200.withOpacity(0.5),
      progressIndicator: CircularProgressIndicator(
        color: Colors.black,
      ),
      inAsyncCall: showSpinner,
      child: Material(
        child: Stack(
          children: [
            //배경 포지션
            Positioned(
              top: 0,
              right :0,
              left : 0,
              child: AnimatedBuilder(
                  animation: _animation,
                  builder: (BuildContext context, Widget? child) {
                    return Container(
                      decoration: BoxDecoration(
                          image :DecorationImage(
                              opacity: 0.3,
                              image: AssetImage('image/image2.jpg'),
                              fit : BoxFit.cover
                          )
                      ),
                      padding: EdgeInsets.only(top: 90, left: 20),
                      height: MediaQuery
                          .of(context)
                          .size
                          .height,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                              text: TextSpan(
                                  text: 'Welcome',
                                  style: TextStyle(
                                      letterSpacing: 1.0,
                                      fontSize: 25,
                                      color: Colors.white,
                                      shadows: [Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.white60,
                                      )
                                      ]
                                  ),
                                  children: [
                                    TextSpan(
                                        text: isSignupScreen
                                            ? ' to Ai_pict'
                                            : ' Ai_pict Back!',
                                        style: TextStyle(
                                            letterSpacing: 1.0,
                                            fontSize: 25,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                              color: Colors.white60,
                                            )
                                            ]
                                        )
                                    )
                                  ]
                              )
                          ),
                          SizedBox(height: 8),
                          Text(
                              isSignupScreen
                                  ? 'Sign up to continue'
                                  : 'sign in to continue',
                              style: TextStyle(
                                  letterSpacing: 1.0,
                                  fontSize: 12,
                                  color: Colors.white,
                                  shadows: [Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.white60,
                                  )
                                  ]
                              )
                          )
                        ],
                      ),
                    );
                  }
              ),
            ),
            //텍스트 폼 포지션
            AnimatedPositioned(
              duration : Duration(milliseconds: 300),
              curve : Curves.easeIn,
              top : 180,
              child: AnimatedContainer(
                duration : Duration(milliseconds: 300),
                curve : Curves.easeIn,
                width : MediaQuery.of(context).size.width-40,
                margin : EdgeInsets.symmetric(horizontal: 20), padding : EdgeInsets.all(20),
                height : isSignupScreen ? 480 : 430,
                decoration:
                BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow:[
                    BoxShadow(
                      color : Colors.white.withOpacity(0.1),
                      //blurRadius: 15,
                      //spreadRadius: 5
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        //로그인 탭
                        Column(
                          children: [
                            TextButton(
                              child: Text('Login', style: TextStyle(fontSize: 18, color : isSignupScreen ? Colors.black54 : Colors.redAccent.shade700,)),
                              onPressed: (){
                                setState(() {
                                  isSignupScreen = false;
                                });
                              },
                            ),
                            if(!isSignupScreen)
                              Container(
                                margin : EdgeInsets.only(top:3),
                                height : 2,
                                width : 55,
                                color : Colors.redAccent.shade700,
                              )
                          ],
                        ),
                        Column(
                          children: [
                            TextButton(
                              child: Text('Sign up', style: TextStyle(fontSize: 18, color : !isSignupScreen ? Colors.black54 : Colors.redAccent.shade700,)),
                              onPressed: (){
                                setState(() {
                                  isSignupScreen = true;
                                });
                              },
                            ),
                            if(isSignupScreen)
                              Container(
                                margin : EdgeInsets.only(top:3),
                                height : 2,
                                width : 55,
                                color : Colors.redAccent.shade700,
                              )
                          ],
                        ),
                      ],
                    ),

                    //Login 메뉴 텍스트폼
                    if(!isSignupScreen)
                      Container(
                        margin: EdgeInsets.only(top:8),
                        child: Form(
                          key : _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color : Colors.blueGrey, fontWeight: FontWeight.bold),
                                key : ValueKey(1),
                                validator: (value){
                                  if(value!.isEmpty || value!.length <5){
                                    return 'you neeto input more than 5 Characters!';
                                  }
                                  return null;
                                },
                                onSaved: (value){
                                  userMail = value!;
                                },
                                onChanged: (value){
                                  userMail = value;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.alternate_email,
                                      color : Colors.redAccent.shade700
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  hintText: 'E-Mail Address',
                                  hintStyle: TextStyle(
                                    color : Colors.redAccent.shade700,
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              ),
                              SizedBox(height:8),
                              TextFormField(
                                style: TextStyle(color : Colors.blueGrey, fontWeight: FontWeight.bold),
                                key : ValueKey(2),
                                obscureText: true,
                                validator: (value){
                                  if(value!.isEmpty || value!.length < 5 ){
                                    return "you need to input more than 6 Characters";
                                  }
                                  return null;
                                },
                                onSaved:(value){
                                  userPassword=value!;
                                },
                                onChanged: (value){
                                  userPassword = value;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock,
                                      color : Colors.redAccent.shade700
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color : Colors.redAccent.shade700,
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    //Sign up 메뉴 텍스트폼
                    if(isSignupScreen)
                      Container(
                        margin: EdgeInsets.only(top:8),
                        child: Form(
                          key : _formKey,
                          child: Column(
                            children: [
                              //username TextForm
                              TextFormField(
                                style: TextStyle(color : Colors.blueGrey, fontWeight: FontWeight.bold),
                                key : ValueKey(3),
                                validator: (value){
                                  if(value!.isEmpty || value!.length <3){
                                    return 'Input more than 3 Characters';
                                  }
                                  if(value! == 'admin'){
                                    return 'this nickname is incorrect. check again';
                                  }
                                  return null;
                                },
                                onSaved: (value){
                                  userName = value!;
                                },
                                onChanged: (value){
                                  userName = value;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.account_circle,
                                      color : Colors.redAccent.shade700
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  hintText: 'NickName',
                                  hintStyle: TextStyle(
                                    color : Colors.redAccent.shade700,
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              ),
                              SizedBox(height:8),
                              //email TextForm
                              TextFormField(
                                style: TextStyle(color : Colors.blueGrey, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.emailAddress,
                                key : ValueKey(4),
                                validator: (value){
                                  if(value!.isEmpty || !value!.contains('@')){
                                    return "input validable E-Mail address!";
                                  }
                                  return null;
                                },
                                onSaved : (value){
                                  userMail = value!;
                                },
                                onChanged: (value){
                                  userMail = value;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email,
                                      color : Colors.redAccent.shade700
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  hintText: 'E-Mail Address',
                                  hintStyle: TextStyle(
                                    color : Colors.redAccent.shade700,
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              ),
                              SizedBox(height:8),
                              //Password TextForm
                              TextFormField(
                                style: TextStyle(color : Colors.blueGrey, fontWeight: FontWeight.bold),
                                obscureText: true,
                                key : ValueKey(5),
                                validator: (value){
                                  if(value!.isEmpty || value!.length < 5){
                                    return 'you need to input more than 6 Characters';
                                  }
                                  return null;
                                },
                                onSaved: (value){
                                  userPassword = value!;
                                },
                                onChanged: (value){
                                  userPassword = value;
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock,
                                      color : Colors.redAccent.shade700
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color : Colors.redAccent.shade700,
                                      ),
                                      borderRadius:BorderRadius.all(
                                        Radius.circular(35),
                                      )
                                  ),
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color : Colors.redAccent.shade700,
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
            //Submit Btn 포지션
            AnimatedPositioned(
              duration : Duration(milliseconds: 300),
              curve : Curves.easeIn,
              top : isSignupScreen ? 500 : 450,
              right : 0,
              left :0,
              child: Center(
                  child: Container(
                    height : 56,
                    width : 200,
                    decoration: BoxDecoration(
                        color : Colors.transparent,
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child : GestureDetector(
                      onTap: () async{
                        setState(() {
                          showSpinner = true;
                        });
                        _tryValidation();
                        if(isSignupScreen){
                          try {
                            final newUser = await _auth
                                .createUserWithEmailAndPassword(
                              email: userMail,
                              password: userPassword,
                            );

                            await FirebaseFirestore.instance.collection('user')
                                .doc(newUser.user!.uid)
                                .set({
                              'uid' : newUser.user!.uid,
                              'username' : userName,
                              'email' : userMail
                            });

                            if(newUser.user != null){
                              /*Navigator.push(context,
                                  MaterialPageRoute(builder: (context){
                                    return TabControl_pad();
                                  })
                              );*/
                              Navigator.pushAndRemoveUntil(
                                  context, MaterialPageRoute(
                                  builder: (context) => MyApp()
                              ), (route) => false
                              );
                            }
                            setState(() {
                              showSpinner = false;
                            });
                          }catch(e){
                            print(e);
                            Alert('SignUp has problem!', 'this mail address exists already or Has badly Formmating');
                            setState(() {
                              showSpinner = false;
                            });
                            FocusScope.of(context).unfocus();
                            return;
                          }
                        }else if(!isSignupScreen){
                          _tryValidation();
                          setState(() {
                            showSpinner = true;
                          });
                          try {
                            //로그인을 시도할 것이나, 결과가 없으면 else문으로 보낸다.
                            final newUser = await _auth.signInWithEmailAndPassword(
                                email: userMail,
                                password: userPassword
                            );
                            if (newUser.user != null) {
                              Navigator.pushAndRemoveUntil(
                                  context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false
                              );
                            }else{
                              return;
                            }
                            setState(() {
                              showSpinner = false;
                            });
                          }catch(e){
                            showSpinner=false;
                            Alert('Login has problem!', 'Check your Mail & Password');
                            FocusScope.of(context).unfocus();
                          }
                        }

                      },
                      child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular((50),
                              ),
                              gradient: LinearGradient(
                                colors : [Colors.redAccent.shade700, Colors.black26],
                                begin : Alignment.topLeft,
                                end : Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color : Colors.black.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset:Offset(0,1)
                                )
                              ]
                          ),
                          child : Text(
                            !isSignupScreen
                                ?'LOGIN'
                                :'SIGN UP',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                shadows: [Shadow(
                                    color: Colors.white38,
                                    offset: Offset(0,1)
                                )]
                            ),
                            textAlign: TextAlign.center,
                          )
                      ),
                    ),
                  )
              ),
            ),
            //without Login 포지션
            AnimatedPositioned(
                curve : Curves.easeIn,
                top : isSignupScreen ? 570 : 520,
                right : 0,
                left :0,
                duration: Duration(milliseconds: 300),
                child: Center(
                  child: GestureDetector(
                    onTap: (){
                      showSpinner = true;
                      _auth.signOut();
                      Navigator.pushAndRemoveUntil(
                          context, MaterialPageRoute(builder: (context) => TabControl_pad()), (route) => false
                      );
                      showSpinner = false;
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular((50),
                          ),
                          border: Border.all(color: Colors.redAccent.shade700)
                      ),
                      height : 50,
                      width : 200,
                      child: Text('Go without Login',
                        style: TextStyle(
                            color: Colors.redAccent.shade700,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(
                                color: Colors.black26,
                                offset: Offset(0,1)
                            )]
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ))
          ],
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
                  setState(() {
                    showSpinner = false;
                  });
                },
              ),
            ],
          );
        });
  }

}
