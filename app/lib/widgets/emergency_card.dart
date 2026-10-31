import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../tag/envelope.dart';
import '../tag/payload.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'motion.dart';

String _formatPhone(String p) => p.startsWith('+91') && p.length == 13 ? '+91 ${p.substring(3, 8)} ${p.substring(8)}' : p;

Future<void> _call(String number) => launchUrl(Uri(scheme: 'tel', path: number));

/// SMS works without mobile data. GPS coordinates are added once location permission is wired in.
Future<void> _smsFamily(TagPayload p) => launchUrl(Uri(
      scheme: 'sms',
      path: p.contacts.map((c) => c.phone).join(','),
      queryParameters: {'body': 'MediTag alert: ${p.name} may need help. Their MediTag was just scanned. Please call back.'},
    ));

/// Tier-1 emergency card, readable offline straight from the tag.
class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key, required this.payload, required this.trust});

  final TagPayload payload;
  final TagTrust trust;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final primary = payload.contacts.firstOrNull;
    final others = payload.contacts.skip(1);
    return Stagger(children: [
      trust == TagTrust.unverified
          ? const _Banner(
              color: MtColors.peachStrong,
              background: MtColors.peachPastel,
              icon: Icons.warning_amber_rounded,
              title: 'Unverified tag',
              body: 'This info may not be genuine. Confirm at the hospital.',
            )
          : const _Banner(
              color: MtColors.mintStrong,
              background: MtColors.mintPastel,
              icon: Icons.verified_user_outlined,
              title: 'Verified MediTag',
              body: 'Signed by MediTag · info is genuine',
            ),
      Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: MtColors.lavenderPastel,
          child: Text(payload.initials, style: const TextStyle(color: MtColors.lavenderStrong, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payload.name, style: text.titleLarge),
            Text(payload.describe(DateTime.now()), style: text.bodySmall),
          ]),
        ),
      ]),
      if (payload.bloodGroup != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(color: MtColors.rosePastel, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Text(payload.bloodGroup!,
                style: const TextStyle(fontSize: 56, height: 1, fontWeight: FontWeight.w800, color: MtColors.roseStrong)),
            const SizedBox(width: 18),
            Text('BLOOD GROUP', style: text.labelSmall!.copyWith(color: MtColors.roseStrong)),
          ]),
        ),
      if (payload.allergies.isNotEmpty)
        _Section(
          title: 'ALLERGIES',
          color: MtColors.roseStrong,
          border: MtColors.rosePastel,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in payload.allergies)
              Chip(
                label: Text(a, style: const TextStyle(color: MtColors.roseStrong, fontWeight: FontWeight.w600)),
                backgroundColor: MtColors.rosePastel,
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
          ]),
        ),
      if (payload.conditions.isNotEmpty || payload.medications.isNotEmpty)
        _Section(
          title: 'CONDITIONS & MEDICINES',
          color: MtColors.lavenderStrong,
          border: MtColors.line,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final c in payload.conditions) Text(c, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            for (final m in payload.medications) Text(m, style: text.bodySmall),
          ]),
        ),
      if (primary != null) ...[
        Text('EMERGENCY CONTACTS', style: text.labelSmall),
        _CallButton(contact: primary, filled: true),
        for (final c in others) _CallButton(contact: c, filled: false),
      ],
      Row(children: [
        Expanded(child: _ServiceButton(number: '108', label: 'Ambulance')),
        const SizedBox(width: 10),
        Expanded(child: _ServiceButton(number: '112', label: 'Emergency')),
      ]),
      if (primary != null)
        FilledButton.icon(
          onPressed: () => _smsFamily(payload),
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Send my location to family'),
          style: FilledButton.styleFrom(
            backgroundColor: MtColors.mintPastel,
            foregroundColor: MtColors.mintStrong,
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
        ),
      Text(
        'Last updated ${MaterialLocalizations.of(context).formatMediumDate(payload.signedAt.toLocal())}',
        textAlign: TextAlign.center,
        style: text.bodySmall,
      ),
    ]);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.background, required this.icon, required this.title, required this.body});
  final Color color, background;
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(body, style: TextStyle(color: color, fontSize: 12.5)),
            ]),
          ),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.color, required this.border, required this.child});
  final String title;
  final Color color, border;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MtColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.contact, required this.filled});
  final TagContact contact;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : MtColors.roseStrong;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: filled ? glow(MtColors.roseStrong, ring: 4, blur: 24) : null),
      child: Material(
        color: filled ? MtColors.roseStrong : MtColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: filled ? BorderSide.none : const BorderSide(color: MtColors.rosePastel, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _call(contact.phone),
          child: SizedBox(
            height: MtTouch.emergencyButton + 4,
            child: Row(children: [
              const SizedBox(width: 18),
              CircleAvatar(
                radius: 20,
                backgroundColor: filled ? Colors.white24 : MtColors.rosePastel,
                child: Icon(Icons.phone_outlined, color: fg, size: 20),
              ),
              const SizedBox(width: 14),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Call ${contact.relation ?? contact.name}', style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w700)),
                Text('${contact.name} · ${_formatPhone(contact.phone)}',
                    style: TextStyle(color: filled ? Colors.white : MtColors.inkMuted, fontSize: 13)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({required this.number, required this.label});
  final String number, label;

  @override
  Widget build(BuildContext context) => Material(
        color: MtColors.rosePastel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _call(number),
          child: SizedBox(
            height: MtTouch.emergencyButton,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Call $number', style: const TextStyle(color: MtColors.roseStrong, fontSize: 17, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: MtColors.roseStrong, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
