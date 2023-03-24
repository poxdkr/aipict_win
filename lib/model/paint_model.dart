import 'package:cloud_firestore/cloud_firestore.dart';

class Paint_m {
  final String code;
  final String cate;
  final bool isA;
  final String hashtag;
  final String p_file;
  int like_cnt;
  final String regdate;
  final DocumentReference reference;

  Paint_m.fromMap(Map<dynamic, dynamic> map,{required this.reference})
      : code = map['code'],
        cate = map['cate'],
        isA = map['isA'],
        hashtag = map['hashtag'],
        p_file = map['p_file'],
        like_cnt = map['like_cnt'],
        regdate = map['regdate'];

  Paint_m.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<dynamic,dynamic> , reference : snapshot.reference);

  //Json
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'cate': cate,
      'isA': isA,
      'hashtag': hashtag,
      'p_file': p_file,
      'like_cnt' : like_cnt,
      'regdate': regdate,
    };
  }



  @override
  String toString() => '$code /  $cate / $isA /  _ [$hashtag] / $like_cnt / [$p_file] / [$regdate]' ;
}