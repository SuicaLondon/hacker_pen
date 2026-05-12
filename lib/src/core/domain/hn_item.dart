import 'package:equatable/equatable.dart';

class HnItem extends Equatable {
  const HnItem({
    required this.id,
    required this.type,
    required this.time,
    required this.by,
    required this.title,
    required this.score,
    required this.descendants,
    this.url,
    this.text,
    this.parent,
    this.kids = const <int>[],
    this.deleted = false,
    this.dead = false,
  });

  factory HnItem.fromJson(Map<String, dynamic> json) {
    return HnItem(
      id: (json['id'] as int?) ?? 0,
      type: (json['type'] as String?) ?? 'story',
      time: (json['time'] as int?) ?? 0,
      by: (json['by'] as String?) ?? 'unknown',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String)
          : 'Untitled',
      score: (json['score'] as int?) ?? 0,
      descendants: (json['descendants'] as int?) ?? 0,
      url: json['url'] as String?,
      text: json['text'] as String?,
      parent: json['parent'] as int?,
      kids: ((json['kids'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
      deleted: (json['deleted'] as bool?) ?? false,
      dead: (json['dead'] as bool?) ?? false,
    );
  }

  final int id;
  final String type;
  final int time;
  final String by;
  final String title;
  final int score;
  final int descendants;
  final String? url;
  final String? text;
  final int? parent;
  final List<int> kids;
  final bool deleted;
  final bool dead;

  bool get isStory => type == 'story';

  bool get isComment => type == 'comment';

  @override
  List<Object?> get props => [
    id,
    type,
    time,
    by,
    title,
    score,
    descendants,
    url,
    text,
    parent,
    kids,
    deleted,
    dead,
  ];
}
