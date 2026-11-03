import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/meditag_api.dart';
import '../theme/tokens.dart';
import 'login_screen.dart';
import 'tag_write_screen.dart';

/// Signed in → the citizen's home; signed out → phone login.
class AccountGate extends StatelessWidget {
  const AccountGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) => snap.data == null ? const LoginScreen() : CitizenHome(user: snap.data!),
      );
}

const _labels = ['Wallet card', 'Car', 'Bracelet', 'Keychain'];

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key, required this.user});
  final User user;

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  String _label = _labels.first;

  Future<void> _open(Widget screen) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => screen));
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Done. Your website dashboard shows the tag too.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MtColors.periwinklePastel,
      appBar: AppBar(
        backgroundColor: MtColors.periwinklePastel,
        title: const Text('Your MediTag'),
        actions: [TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Log out'))],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        Text('Logged in as ${widget.user.phoneNumber ?? ''}', style: text.bodySmall),
        const SizedBox(height: 20),
        _Card(
          dark: true,
          title: 'Program a new tag',
          body: 'Writes your signed emergency info to a blank NTAG216 and locks it so only your account can change it. Up to 3 tags.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in _labels)
                ChoiceChip(
                  label: Text(l),
                  selected: _label == l,
                  onSelected: (_) => setState(() => _label = l),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: _label == l ? MtColors.navy : Colors.white, fontWeight: FontWeight.w600),
                  side: BorderSide.none,
                  showCheckmark: false,
                ),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _open(TagWriteScreen(label: _label)),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: MtColors.navy, minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
              child: Text('Program "$_label" tag', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Update a tag',
          body: 'Changed your allergies or contacts? Hold one of your tags to the phone to rewrite it with your latest profile.',
          child: OutlinedButton(
            onPressed: () => _open(const TagWriteScreen()),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder(), foregroundColor: MtColors.navy),
            child: const Text('Update a tag', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Edit your emergency profile',
          body: 'Blood group, allergies and contacts are edited on the website for now. Update your tags afterwards.',
          child: TextButton(
            onPressed: () => launchUrl(Uri.parse('$apiBaseUrl/citizen/profile'), mode: LaunchMode.externalApplication),
            child: const Text('Open the website'),
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body, required this.child, this.dark = false});
  final String title, body;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: dark ? MtColors.navy : Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark ? Colors.white : MtColors.navy)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 14, height: 1.45, color: dark ? Colors.white.withValues(alpha: 0.8) : MtColors.inkMuted)),
          const SizedBox(height: 16),
          child,
        ]),
      );
}
