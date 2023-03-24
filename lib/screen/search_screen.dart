
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aipict_win/model/paint_model.dart';
import 'package:aipict_win/screen/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

String sst = "regdate"; //기본 정렬 등록일자 내림순
bool isDesc = true;
bool isRandom = false;

List<Paint_m> plist=[];

class SearchScreen extends StatefulWidget {

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  //안드로이드용 unitId
  final String testUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String realUnitId = 'ca-app-pub-2124338818654953/7696155407';

  //IOS용 unitId
  BannerAd? banner;
  @override
  void initState() {
    super.initState();
    banner = BannerAd(
        size: AdSize.banner,
        adUnitId: realUnitId,
        listener: BannerAdListener(),
        request: AdRequest()
    )..load();
  }
  TextEditingController _controller = TextEditingController();

  FocusNode focusNode = FocusNode();
  String _searchText = "";


  _SearchScreenState(){
    _controller.addListener(() {
      _searchText = _controller.text;
    }
    );
  }

  Widget _buildBody(BuildContext context){
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('paint')
          .orderBy(sst, descending: isDesc)
          .snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
            return DelayedDisplay(
              delay: Duration(seconds: 0),
              fadeIn: true,
              child: Center(
              child:Container(
                height: MediaQuery.of(context).size.height*0.4,
                child: SpinKitChasingDots(
                    color: Colors.redAccent.shade400,
                    size: 200.0,
                    duration: Duration(milliseconds: 1000),
                  ),
              ),
        ),
            );
        }else{
          if(isRandom){
            final docList = snapshot.data!.docs;
            docList.shuffle(); // 리스트를 무작위로 섞음
            return _buildList(context, docList);
          }else{
            return _buildList(context, snapshot.data!.docs);
          }

        }
      } ,
    );
  }


  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot){
    List<DocumentSnapshot> searchResult = [];
    plist =[];
    for(DocumentSnapshot d in snapshot){
      if(d.data().toString().toLowerCase().contains(_searchText)){
        final p_one = Paint_m.fromSnapshot(d);
        if(p_one.isA == false) {
          searchResult.add(d);
          plist.add(p_one);
        }
      }
    }

    return Expanded(
      child: GridView.count(
          controller: _scrollController,
          crossAxisCount: 2,
          childAspectRatio: 1 / 1.7,
          padding: EdgeInsets.all(5),
          children: /*searchResult
                .map((data) => _buildListItem(context ,data))
                .toList()*/
          searchResult
              .asMap()
              .map((index, data) => MapEntry(
              index,
              _buildListItem(context, data, index,searchResult)))
              .values
              .toList()
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data, int index, List<DocumentSnapshot<Object?>> searchResult){
      final paint = Paint_m.fromSnapshot(data);
      return InkWell(
        child: Container(
          padding: EdgeInsets.all(4),
          child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top:0,
                  bottom:0,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.white10,
                        ),
                        color: Colors.white38,
                        gradient: LinearGradient(
                            begin:Alignment.topLeft,
                            end : Alignment.topRight,
                            colors : [Colors.black, Colors.white.withOpacity(0.2)]
                        )
                    ),
                    child: CachedNetworkImage( // Image.network
                      imageUrl: paint.p_file,
                      placeholder: (context, url) => const LinearProgressIndicator(color: Colors.redAccent,),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      fadeOutDuration: const Duration(seconds: 1),
                      fadeInDuration: const Duration(seconds: 2),
                      /*loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent.withOpacity(0.5)),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },*/
                    ),
                  ),
                ),
                Positioned(
                  left:5,
                  top: 5,
                  child: Container(
                    padding : EdgeInsets.fromLTRB(4, 0, 4, 0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.white10,
                        ),
                        gradient: LinearGradient(
                          colors: [Colors.redAccent.withOpacity(0.5), Colors.white.withOpacity(0.2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )

                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            padding : EdgeInsets.all(1),
                            child: Row(
                                children : [
                                  Icon(Icons.favorite,size: 12),
                                  SizedBox(width: 10),
                                  Text(paint.like_cnt.toString(),style: TextStyle(fontSize: 12),)
                                ]
                            )
                        ),
                      ],
                    ),
                  ),
                )
              ]
          ),
        ),
        onTap: (){
          Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) {
                  return DetailScreen(pindex : index, paint: paint, paints:plist);
                },
              )
          );

        },
      );
  }
  //build 함수
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent.shade400.withOpacity(0.5),
        child: Icon(Icons.arrow_upward, color: Colors.white, size:25,fill: 0.5),
        onPressed: () {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
      ),
      body: Column(
        children: [
          Padding(padding:EdgeInsets.all(5)),
          //검색창 일체
          Container(
            color : Colors.black,
            padding : EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Row(
              children: [
                //검색창
                Expanded(
                    flex : 6,
                    child: Container(
                      height: 40,
                      child: TextField(

                        onChanged: (text){
                          setState(() {
                            _searchText = text;
                          });
                        },
                        focusNode: focusNode,
                        style : TextStyle(
                          fontSize: 11,
                        ),
                        //autofocus: true,
                        controller: _controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white12,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white60,
                            size: 15,
                          ),
                          // (x) 버튼
                          suffixIcon: focusNode.hasFocus
                              ? IconButton(
                            icon: Icon(Icons.cancel, size: 15, color: Colors.white60,),
                            onPressed: (){
                              setState( (){
                                _controller.clear();
                                _searchText = "";
                              }
                              );
                            },
                          )
                              : Container(),
                          hintText: '검색',
                          //border Style
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:  BorderRadius.all(Radius.circular(10)),
                          ),
                          enabledBorder:OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:  BorderRadius.all(Radius.circular(10)),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:  BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    )
                ),
                //취소 버튼
                focusNode.hasFocus
                    ? Expanded(
                    child: TextButton(
                        child: Text('취소',style:TextStyle(color:Colors.white60)),
                        onPressed: (){
                          setState(() {
                            _controller.clear();
                            _searchText = "";
                          });
                        }
                    )
                )
                    : Expanded(child: Container(), flex : 0),
              ],
            ),
          ),
          //Sorted Box
          Container(
            padding : EdgeInsets.all(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: (){
                      setState(() {
                        sst = "regdate";
                        isDesc = true;
                        isRandom = false;
                      });
                    },
                    child: Icon(Icons.calendar_month,
                      color: sst == 'regdate' ? Colors.redAccent.shade400 : Colors.white,
                    ),
                    style: TextButton.styleFrom(
                        fixedSize: Size(40, 20),
                        primary: Colors.redAccent.shade400,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.redAccent,
                        elevation: sst == 'regdate' ? 1 : 0,
                        padding: EdgeInsets.all(0)
                    )
                ),
                SizedBox(width : 10),
                ElevatedButton(
                    onPressed: (){
                      setState(() {
                        sst = "like_cnt";
                        isDesc = true;
                        isRandom = false;
                      });
                    },
                    child: Icon(Icons.favorite,
                      color: sst == 'like_cnt' ? Colors.redAccent.shade400 : Colors.white,
                    ),
                    style: TextButton.styleFrom(
                        fixedSize: Size(40, 20),
                        primary: Colors.redAccent.shade400,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.redAccent,
                        elevation: sst == 'like_cnt' ? 1:0,
                        padding: EdgeInsets.all(0)
                    )
                ),
                SizedBox(width : 10),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        sst = "code";
                        isRandom = true;
                      });
                    },
                    child: Icon(Icons.shuffle,
                      size: 20,
                      color : sst == 'code' ? Colors.redAccent.shade400 : Colors.white,
                    ),
                    style: TextButton.styleFrom(
                        fixedSize: Size(40, 20),
                        primary: Colors.redAccent.shade400,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.redAccent,
                        elevation: sst == 'code' ? 1 : 0,
                        padding: EdgeInsets.all(0)
                    )
                ),
              ],
            ),
          ),
          _buildBody(context),

        ],
      ),
      bottomNavigationBar: Container(
          height : 50,
          child : banner == null
              ? SpinKitThreeInOut(color:Colors.white)
              : AdWidget(ad: banner!)
      ),
    );
  }
}
