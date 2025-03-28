import 'work.dart';

class WorkList {
  List<Work> works;

  WorkList({required this.works});

  factory WorkList.empty() {
    return WorkList(works: []);
  }
}
