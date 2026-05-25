import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> _launchPhone(String phone) async {
      final uri = Uri(scheme: 'tel', path: phone);
      if (!await launchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to launch phone dialer.')),
        );
      }
    }

    Future<void> _openUrl(String url) async {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the link.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('About GBV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('About GBV', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Gender-based violence is any harmful act directed at an individual because of their gender. Learn how to recognize abuse, protect your rights, and access trusted support.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            _ArticleCard(
              title: 'What is GBV?',
              description: 'GBV includes physical, sexual, emotional, and economic harm that happens because of gender inequality.',
            ),
            const SizedBox(height: 14),
            _ArticleCard(
              title: 'Signs of Abuse',
              description: 'Look for controlling behavior, isolation, threats, humiliation, physical harm, and coercion.',
            ),
            const SizedBox(height: 14),
            _ArticleCard(
              title: 'Survivor Rights',
              description: 'Every survivor has the right to safety, confidentiality, medical care, and legal support.',
            ),
            const SizedBox(height: 14),
            _ArticleCard(
              title: 'Safety Planning',
              description: 'Develop a plan that includes safe contacts, escape routes, and trusted places to stay.',
            ),
            const SizedBox(height: 14),
            _ArticleCard(
              title: 'How to Seek Help',
              description: 'Report abuse, reach out to trained counsellors, and connect with organizations that protect survivors.',
            ),
            const SizedBox(height: 24),
            Text('Frequently Asked Questions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: const [
                  ExpansionTile(
                    title: Text('What is GBV?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('GBV is violence or abuse that is rooted in gender inequality. It can be physical, sexual, emotional, economic, or online.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('How do I report abuse?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Use trusted hotlines, local authorities, or community support services to report abuse safely.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Can I report anonymously?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Yes. Many services allow anonymous reporting to protect your privacy and safety.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Where can I get help?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Reach out to local shelters, GBV response centers, trusted friends, or crisis hotlines for immediate support.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Legal rights of survivors'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Survivors have a right to protection orders, medical care, legal advice, and access to justice.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Hotline support', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _HotlineButton(
              label: 'National GBV hotline',
              number: '1199',
              onTap: () => _launchPhone('1199'),
            ),
            const SizedBox(height: 12),
            _HotlineButton(
              label: 'Child protection line',
              number: '116',
              onTap: () => _launchPhone('116'),
            ),
            const SizedBox(height: 12),
            _HotlineButton(
              label: 'Emergency services',
              number: '999',
              onTap: () => _launchPhone('999'),
            ),
            const SizedBox(height: 24),
            Text('Legal resources', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ResourceLink(
              title: 'Protection orders and survivor support',
              onTap: () => _openUrl('https://www.womensshelter.org/resources/protection-orders'),
            ),
            const SizedBox(height: 10),
            _ResourceLink(
              title: 'How to report abuse safely',
              onTap: () => _openUrl('https://www.un.org/en/stop-violence-against-women'),
            ),
            const SizedBox(height: 10),
            _ResourceLink(
              title: 'Child protection laws and guidance',
              onTap: () => _openUrl('https://www.unicef.org/child-protection'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _HotlineButton extends StatelessWidget {
  const _HotlineButton({required this.label, required this.number, required this.onTap});

  final String label;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.call),
      label: Text('$label · $number'),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
    );
  }
}

class _ResourceLink extends StatelessWidget {
  const _ResourceLink({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: onTap,
      ),
    );
  }
}
