import 'package:flutter/material.dart';
import 'package:aipict_win/model/music_model.dart';
import 'package:aipict_win/model/paint_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aipict_win/screen/detail_screen.dart';

final firebaseStorage = FirebaseStorage.instance;
late String imageUrl;

class RecentlySlider extends StatefulWidget {

  final List<Paint_m> paints;

  RecentlySlider({required this.paints});

  @override
  State<RecentlySlider> createState() => _RecentlySliderState();
}

class _RecentlySliderState extends State<RecentlySlider> {

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Released List', style: TextStyle(fontWeight: FontWeight.bold),),
          //실제 리스트 출력
          Container(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: makeImages(context, widget.paints),
            ),
          )
        ],
      ),
    );
  }
}

List<Widget> makeImages(BuildContext context, List<Paint_m> paints){
  List<Widget> results = [];
  for(var i=0; i<paints.length; i++){
    results.add(
      Container(
        padding : EdgeInsets.all(10),
        child: InkWell(
          onTap: (){
            Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) {
                    return DetailScreen(pindex:i,paint: paints[i], paints: paints);
                  },
                )
            );
          },
          child : Container(
            height: 150,
            decoration: BoxDecoration(
            ),
            padding : EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Image.network(
                      paints[i].p_file,
                      height: 130,
                      fit:BoxFit.fitHeight,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null)
                          return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(Colors.redAccent.withOpacity(0.5)),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                  ),
                ),
                SizedBox(height: 5),
                Text(
                    paints[i].cate,
                    style : TextStyle(
                      fontWeight:FontWeight.bold,
                      fontSize: 12,
                      color: Colors.deepOrangeAccent.shade200,
                      shadows: [Shadow(
                        color: Colors.white10,
                        offset:Offset(1,2)
                      )]
                    )
                ),
                Text(
                    paints[i].hashtag.length > 10 ? (paints[i].hashtag).substring(0,9)+'...' : paints[i].hashtag,
                    style : TextStyle(
                        fontWeight:FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white70
                    )
                ),
                SizedBox(height:10),
                //Text(paints[i].artist),
              ],
            ),
          )
        ),
      )
    );
  }
  return results;
}