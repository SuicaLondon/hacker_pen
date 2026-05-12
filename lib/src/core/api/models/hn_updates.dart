import 'package:equatable/equatable.dart';

class HnUpdates extends Equatable {
  const HnUpdates({required this.items, required this.profiles});

  factory HnUpdates.fromJson(Map<String, dynamic> json) {
    return HnUpdates(
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
      profiles: ((json['profiles'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final List<int> items;
  final List<String> profiles;

  @override
  List<Object?> get props => [items, profiles];
}
