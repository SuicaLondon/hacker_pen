import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 52),
        child: HpTopBar(
          title: 'Privacy Policy',
          leading: HpIconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.chevron_left,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox.expand(child: const PrivacyPolicyBody()),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyBody extends StatefulWidget {
  const PrivacyPolicyBody({super.key});

  @override
  State<PrivacyPolicyBody> createState() => _PrivacyPolicyBodyState();
}

class _PrivacyPolicyBodyState extends State<PrivacyPolicyBody> {
  late final Future<String> _policy = rootBundle.loadString(
    'assets/privacy_policy.txt',
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _policy,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load privacy policy.'));
        }
        final policy = snapshot.data;
        if (policy == null) {
          return const HpLoadingView(label: 'Loading privacy policy');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            policy,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: context.hpColors.ink,
            ),
          ),
        );
      },
    );
  }
}
