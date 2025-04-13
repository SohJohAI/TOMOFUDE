class PlotBooster {
  String genre = '';
  String style = '';
  String logline = '';
  List<String> themes = [];
  String worldSetting = '';
  List<KeySetting> keySettings = [];
  Character protagonist = Character();
  Character antagonist = Character();
  List<ChapterOutline> chapterOutlines = [];
  String aiSupportMaterial = '';
}

class KeySetting {
  String name;
  String effect;
  String limitation;

  KeySetting({
    this.name = '',
    this.effect = '',
    this.limitation = '',
  });
}

class Character {
  String name;
  String description;
  String motivation;
  String conflict;

  Character({
    this.name = '',
    this.description = '',
    this.motivation = '',
    this.conflict = '',
  });
}

class ChapterOutline {
  String title;
  String content;

  ChapterOutline({
    this.title = '',
    this.content = '',
  });
}
