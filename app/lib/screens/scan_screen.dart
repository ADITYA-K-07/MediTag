import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config.dart';
import '../tag/envelope.dart';
import '../tag/tag_reader.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/emergency_card.dart';
import '../widgets/motion.dart';

enum _Step { idle, scanning, found, card, error }

/// Bystander "Scan a MediTag" flow. No login: anyone at an accident scene can use it.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _reader = TagReader();
  _Step _step = _Step.idle;
  ReadOk? _result;
  String? _error;

  Future<void> _scan() async {
    if (!await _reader.available) {
      setState(() {
        _step = _Step.error;
        _error = 'Turn on NFC in your phone settings, then try again.';
      });
      return;
    }
    setState(() => _step = _Step.scanning);
    try {
      final tag = await _reader.readOne();
      if (!mounted) return;
      if (tag.envelope == null) {
        setState(() {
          _step = _Step.error;
          _error = "This doesn't look like a MediTag.";
        });
        return;
      }
      await _show(tag.envelope!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.error;
          _error = 'Could not read the tag. Hold it still and try again.';
        });
      }
    }
  }

  Future<void> _show(Uint8List envelope) async {
    final result = readEnvelope(envelope, widget.config.publicKeys);
    if (result is! ReadOk) {
      setState(() {
        _step = _Step.error;
        _error = "This tag's MediTag data is damaged. Look for another tag or a QR card.";
      });
      return;
    }
    setState(() {
      _result = result;
      _step = _Step.found;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _step = _Step.card);
  }

  void _reset() {
    if (_step == _Step.scanning) _reader.cancel();
    setState(() {
      _step = _Step.idle;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_step == _Step.card) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emergency info'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _reset, tooltip: 'Back'),
          backgroundColor: MtColors.background,
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
          EmergencyCard(payload: _result!.payload, trust: _result!.trust),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: _reset, child: const Text('Scan another tag')),
        ]),
      );
    }

    final scanning = _step == _Step.scanning;
    final found = _step == _Step.found;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: MtColors.mintPastel, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.local_offer_outlined, color: MtColors.mintStrong, size: 20),
            ),
            const SizedBox(width: 10),
            Text('MediTag', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800, fontSize: 19)),
          ]),
          const SizedBox(height: 32),
          Text(
            found ? 'Tag found' : (scanning ? 'Ready to scan' : "Medical info that speaks when you can't."),
            style: text.titleLarge!.copyWith(fontSize: found || scanning ? 24 : 32, height: 1.15),
          ),
          const SizedBox(height: 12),
          Text(
            found
                ? 'Reading emergency info…'
                : scanning
                    ? 'Hold the back of your phone near the tag'
                    : "Saw an accident? Scan the person's MediTag to see their blood group and call their family. No login needed.",
            style: text.bodyMedium!.copyWith(color: MtColors.inkMuted, height: 1.5),
          ),
          SizedBox(
            height: 300,
            child: Center(child: found ? const _FoundTick() : _ScanButton(scanning: scanning, onPressed: scanning ? null : _scan)),
          ),
          if (_step == _Step.error)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: MtColors.peachPastel, borderRadius: BorderRadius.circular(16)),
              child: Text(_error!, style: const TextStyle(color: MtColors.peachStrong, fontWeight: FontWeight.w600)),
            ),
          if (scanning) TextButton(onPressed: _reset, child: const Text('Cancel')),
          if (!scanning && !found)
            const Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
              _Pill('Works offline', MtColors.skyPastel, MtColors.skyStrong),
              _Pill('No login needed', MtColors.mintPastel, MtColors.mintStrong),
            ]),
          if (widget.config.demoTags case final demo? when !scanning && !found) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: MtColors.skyPastel, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Demo mode: no tag needed', style: TextStyle(color: MtColors.skyStrong, fontWeight: FontWeight.w700)),
                const Text('Uses a test signing key. Build with --dart-define=TAG_PUBLIC_KEYS for real tags.',
                    style: TextStyle(color: MtColors.skyStrong, fontSize: 12.5)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  FilledButton(
                    onPressed: () => _show(demo.genuine),
                    style: FilledButton.styleFrom(backgroundColor: MtColors.skyStrong),
                    child: const Text('Genuine tag'),
                  ),
                  OutlinedButton(onPressed: () => _show(demo.tampered), child: const Text('Tampered tag')),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.scanning, required this.onPressed});
  final bool scanning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        if (scanning) const PulseRings(color: MtColors.roseStrong),
        Container(
          width: 184,
          height: 184,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: MtColors.rosePastel),
        ),
        Semantics(
          button: true,
          label: 'Scan a MediTag',
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(shape: BoxShape.circle, color: MtColors.roseStrong, boxShadow: glow(MtColors.roseStrong)),
              child: const Icon(Icons.contactless_outlined, color: Colors.white, size: 56),
            ),
          ),
        ),
      ]);
}

class _FoundTick extends StatelessWidget {
  const _FoundTick();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(shape: BoxShape.circle, color: MtColors.mintPastel, boxShadow: glow(MtColors.mintStrong, ring: 10)),
          child: const Icon(Icons.check_rounded, color: MtColors.mintStrong, size: 56),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.background, this.color);
  final String label;
  final Color background, color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );
}
