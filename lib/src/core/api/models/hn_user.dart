import 'package:equatable/equatable.dart';

class HnUser extends Equatable {
  const HnUser({
    required this.id,
    required this.created,
    required this.karma,
    this.about,
    this.submitted = const <int>[],
  });

  factory HnUser.fromJson(Map<String, dynamic> json) {
    return HnUser(
      id: (json['id'] as String?) ?? '',
      created: (json['created'] as int?) ?? 0,
      karma: (json['karma'] as int?) ?? 0,
      about: json['about'] as String?,
      submitted: ((json['submitted'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
    );
  }

  final String id;
  final int created;
  final int karma;
  final String? about;
  final List<int> submitted;

  @override
  List<Object?> get props => [id, created, karma, about, submitted];
}
