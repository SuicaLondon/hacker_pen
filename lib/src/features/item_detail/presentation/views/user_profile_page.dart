import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/api/models/hn_user.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../data/item_detail_repository.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({required this.userId, super.key});

  final String userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<HnUser> _future;
  bool _didInit = false;
  bool _isRefreshing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _future = _loadUser();
    _didInit = true;
  }

  Future<HnUser> _loadUser() {
    return context.read<ItemDetailRepository>().fetchUser(widget.userId);
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    final future = _loadUser();
    setState(() {
      _future = future;
    });

    try {
      await future;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.hpColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 48),
        child: HpTopBar(
          title: widget.userId,
          leading: HpIconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.arrow_back,
          ),
          trailing: _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : HpIconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: Icons.refresh,
                ),
        ),
      ),
      body: FutureBuilder<HnUser>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                spacing: 12,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load user profile.',
                    style: textTheme.bodyLarge?.copyWith(color: colors.ink),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Text(
                'User not found.',
                style: textTheme.bodyLarge?.copyWith(color: colors.inkMuted),
              ),
            );
          }

          final about = TextSanitizer.stripHtml(user.about);
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            user.created * 1000,
          );
          final createdText = DateFormat('yyyy-MM-dd').format(createdAt);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    _ProfileHero(user: user),
                    const SizedBox(height: 12),
                    _StatsCard(
                      rows: [
                        _StatRow(label: 'Joined', value: createdText),
                        _StatRow(label: 'Karma', value: '${user.karma}'),
                        _StatRow(
                          label: 'Submitted',
                          value: '${user.submitted.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AboutCard(about: about),
                  ],
                ),
                if (_isRefreshing)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final HnUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;
    final initial = user.id.isEmpty
        ? '?'
        : user.id.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        borderRadius: context.hpRadii.medium,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          spacing: 12,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.highlight,
              child: Text(
                initial,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    user.id,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Hacker News User',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.rows});

  final List<_StatRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        borderRadius: context.hpRadii.medium,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          spacing: 10,
          children: rows
              .map(
                (row) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                    SelectableText(
                      row.value,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.about});

  final String about;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        borderRadius: context.hpRadii.medium,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: textTheme.titleSmall?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            SelectableText(
              about.isEmpty ? 'No bio.' : about,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;
}
