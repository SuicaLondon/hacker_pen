import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';

void main() {
  CachedQuery.instance.config(
    config: const GlobalQueryConfig(
      staleDuration: Duration(minutes: 1),
      cacheDuration: Duration(minutes: 30),
      shouldRethrow: true,
    ),
  );

  runApp(const HackerPenApp());
}
