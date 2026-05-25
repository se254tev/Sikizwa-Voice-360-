import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/emergency'),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text('Emergency SOS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroSection(onSettingsTap: () => context.go('/settings')),
                  const SizedBox(height: 18),
                  _SupportSummaryCard(theme: theme),
                  const SizedBox(height: 22),
                  _SectionHeader(title: 'Immediate support'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Emergency response',
                    description: 'Reach help quickly and share your current situation with confidence.',
                    actionLabel: 'Open emergency support',
                    onTap: () => context.go('/emergency'),
                    variant: _ActionVariant.urgent,
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'Report a problem',
                    description: 'Share what is happening safely and get support when you need it most.',
                    actionLabel: 'Report a problem',
                    onTap: () => context.go('/reports'),
                    variant: _ActionVariant.primary,
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'GBV support',
                    description: 'Find safe guidance and resources for gender-based violence concerns.',
                    actionLabel: 'Open GBV support',
                    onTap: () => context.go('/reports'),
                    variant: _ActionVariant.primary,
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(title: 'Care and guidance'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Emotional wellness',
                    description: 'Drop into calming routines and supportive practices whenever you need a reset.',
                    actionLabel: 'Explore wellness',
                    onTap: () => context.go('/wellness'),
                    variant: _ActionVariant.calm,
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'Talk to Sikizwa Care',
                    description: 'Get thoughtful guidance and a calm companion for your next step in the moment.',
                    actionLabel: 'Open chat',
                    onTap: () => context.go('/ai-chat'),
                    variant: _ActionVariant.soft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B2DA4), Color(0xFF7C3AED), Color(0xFF9F7AEA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B2DA4).withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sikizwa Care',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Material(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onSettingsTap,
                      splashColor: Colors.white.withOpacity(0.18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          'Settings',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'You are safe here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Voice reporting, wellness resources, and rapid help are all designed to feel calm, clear, and emotionally supportive.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportSummaryCard extends StatelessWidget {
  const _SupportSummaryCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support snapshot',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'A calmer path to help, with the most important actions grouped in one place for fast decision-making.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SupportPill(label: 'Calm guidance'),
              _SupportPill(label: 'Quick help'),
              _SupportPill(label: 'Emergency readiness'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    );
  }
}

enum _ActionVariant { urgent, primary, calm, soft }

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    required this.variant,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final _ActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSurfaceTone = variant == _ActionVariant.calm || variant == _ActionVariant.soft;

    final gradient = switch (variant) {
      _ActionVariant.urgent => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB42318), Color(0xFFF85B66)],
        ),
      _ActionVariant.primary => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B2DA4), Color(0xFF7C3AED)],
        ),
      _ActionVariant.calm => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9D5FF), Color(0xFFFDF2F8)],
        ),
      _ActionVariant.soft => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDD6FE), Color(0xFFE0F2FE)],
        ),
    };

    final textColor = isSurfaceTone ? Colors.black87 : Colors.white;
    final accentColor = isSurfaceTone ? theme.colorScheme.primary : Colors.white.withOpacity(0.2);
    final borderColor = isSurfaceTone ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent;
    final shadowColor = isSurfaceTone ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        splashColor: textColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: gradient,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: textColor.withOpacity(isSurfaceTone ? 0.8 : 0.92),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
