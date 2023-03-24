import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:aipict_win/model/paint_model.dart';
import 'package:aipict_win/widget/carousel_slider.dart';
import 'package:aipict_win/widget/recently_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


FirebaseFirestore firestore = FirebaseFirestore.instance;


class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //안드로이드용 unitId
  final String testUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String realUnitId = 'ca-app-pub-2124338818654953/7696155407';
  //IOS용 unitId

  BannerAd? banner;

  @override
  void initState() {
     banner = BannerAd(
        size: AdSize.banner,
        adUnitId: realUnitId,
        listener: BannerAdListener(),
        request: AdRequest()
    )..load();
    super.initState();
  }


  List<Paint_m> paints = [];

  Widget _fetchData(BuildContext context){
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('paint')
                                        .orderBy('regdate', descending: true)
                                        .snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          print('loading.......');
          return DelayedDisplay(
            delay: Duration(seconds: 0),
            fadeIn: true,
            child: SpinKitChasingDots(
              color: Colors.redAccent.shade400,
              size: 200.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        } else {
          return _buildBody(context, snapshot.data!.docs);
        }
      },
    );
  }

  Widget _buildBody(BuildContext context, List<DocumentSnapshot> snapshot){
    List<Paint_m> paints = snapshot.map((m)=> Paint_m.fromSnapshot(m)).toList();
    List<Paint_m> paints_result=[];
    for(Paint_m p in paints){
      if(p.isA == false){
        paints_result.add(p);
      }
    }
    return ListView(
          children: [
            TopBar(),
            CarouselImage(paints: paints_result),
            /*SizedBox(height:10),
            RecentlySlider(paints: paints_result)*/
            banner == null
                  ? LinearProgressIndicator(color:Colors.white)
                  : Container(
                      color:Colors.transparent,
                      height : 60,
                      child:AdWidget(ad:banner!)
                    )
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _fetchData(context);
  }
}

//TopBar 위젯 (고정)
Widget TopBar(){
  return  Container(
      padding: EdgeInsets.only(top:10, left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('image/icon.png'),
          ),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Ai pict',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows:  [Shadow(
                    color: Colors.white60,
                    offset: Offset(0,1),
                    blurRadius: 5,
                  )]
              ),
            ),
          )
        ],
      ),
    );
}