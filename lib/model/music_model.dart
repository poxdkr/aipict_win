
class Music {
  final String title;
  final String genre;
  final String artist;
  final String album;

  Music.fromMap(Map<String, dynamic> map)
  : title = map['title'],
    genre = map['genre'],
    artist = map['artist'],
    album = map['album'];

  @override
  String toString() => '$title /  $artist / $album _ [$genre]' ;
}