import 'package:cloud_firestore/cloud_firestore.dart';

class Comment_m{
  final String code;
  final String comment;
  final String regdate;
  final String uid;
  final DocumentReference reference;

  Comment_m.fromMap(Map<dynamic, dynamic> map,{required this.reference})
      : code = map['code'],
        comment = map['comment'],
        uid = map['uid'],
        regdate = map['regdate'];

  Comment_m.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<dynamic,dynamic> , reference : snapshot.reference);

  //Json
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'comment': comment,
      'uid': uid,
      'regdate': regdate,
    };
  }



  @override
  String toString() => '$code /  $comment / $uid /  _  / [$regdate]' ;
}