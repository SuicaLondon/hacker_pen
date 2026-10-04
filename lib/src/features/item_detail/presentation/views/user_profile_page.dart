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
  HnUser? _lastUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _future = _loadUser();
    _didInit = true;
  }

  Future<HnUser> _loadUser() async {
    final user = await context.read<ItemDetailRepository>().fetchUser(
      widget.userId,
    );
    _lastUser = user;
    return user;
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
    } catch (_) {
      if (mounted && _lastUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh. Pull down to try again.'),
          ),
        );
      }
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
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 52),
        child: HpTopBar(
          title: 'Profile',
          leading: HpIconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.arrow_back,
          ),
          trailing: _isRefreshing
              ? const SizedBox.square(
                  dimension: 44,
                  child: Center(child: HpActivityIndicator(size: 16)),
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              _lastUser == null) {
            return const HpLoadingView(label: 'Loading profile');
          }

          if (snapshot.hasError && _lastUser == null) {
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

          final user = snapshot.data ?? _lastUser;
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              HpSliverRefreshControl(onRefresh: _refresh),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                sliver: SliverList.list(
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
              ),
            ],
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
        color: colors.surface.withValues(alpha: 0.52),
        border: Border(
          left: BorderSide(color: colors.brand, width: 2),
          top: BorderSide(color: colors.rule),
          right: BorderSide(color: colors.rule),
          bottom: BorderSide(color: colors.rule),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.highlight,
                border: Border.all(color: colors.brand),
                borderRadius: context.hpRadii.small,
              ),
              child: SizedBox.square(
                dimension: 42,
                child: Center(
                  child: Text(
                    initial,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.brand,
                      fontFamily: context.hpText.monoFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                    'HACKER NEWS USER',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.inkMuted,
                      fontFamily: context.hpText.monoFamily,
                      letterSpacing: 1,
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
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              'ACCOUNT',
              style: textTheme.labelLarge?.copyWith(
                color: colors.brand,
                fontFamily: context.hpText.monoFamily,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const HpDivider(),
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[index].label.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.inkMuted,
                        fontFamily: context.hpText.monoFamily,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SelectableText(
                    rows[index].value,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.ink,
                      fontFamily: context.hpText.monoFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (index < rows.length - 1) const HpDivider(),
          ],
        ],
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
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              'ABOUT',
              style: textTheme.labelLarge?.copyWith(
                color: colors.brand,
                fontFamily: context.hpText.monoFamily,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const HpDivider(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              about.isEmpty ? 'No bio.' : about,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.inkMuted,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;
}
