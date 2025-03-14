import 'novel.dart';

class NovelList {
  List<Novel> novels;

  NovelList({required this.novels});

  factory NovelList.empty() {
    return NovelList(novels: []);
  }
}
