import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/meditag_api.dart';
import '../tag/ndef_encoder.dart';
import '../tag/ntag216.dart';
import '../tag/tag_session.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';

enum _Step { preparing, waiting, done, error }

/// Programs a new MediTag ([label] given) or rewrites one of the user's tags ([label] null).
class TagWriteScreen extends StatefulWidget {
  const TagWriteScreen({super.key, this.label});

  final String? label;

  @override
  State<TagWriteScreen> createState() => _TagWriteScreenState();
}

class _TagWriteScreenState extends State<TagWriteScreen> {
  final _api = MeditagApi();
  _Step _step = _Step.preparing;
  String? _error;

  bool get _isNew => widget.label != null;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    if (_step == _Step.waiting) cancelHeldTag();
    super.dispose();
  }

  Uint8List _bytesFor(TagWritePlan plan) =>
      meditagTagBytes(uri: plan.uri, mimeType: plan.mimeType, envelope: plan.envelope, androidPackage: plan.androidPackage);

  Future<void> _run() async {
    setState(() {
      _step = _Step.preparing;
      _error = null;
    });
    try {
      if (_isNew) {
        // The server signs the profile and issues this tag's password before the tag is touched.
        final plan = await _api.prepareNewTag(widget.label!);
        setState(() => _step = _Step.waiting);
        final uid = await withHeldTag((tag) async {
          await programNewTag(tag.chip, _bytesFor(plan), plan.password);
          return tag.read.uid;
        });
        await _api.confirmWritten(plan.tagId, uid);
      } else {
        setState(() => _step = _Step.waiting);
        final (tagId, uid) = await withHeldTag((tag) async {
          final tagId = tagIdFromUrl(tag.read.url);
          if (tagId == null) throw TagException("This isn't a MediTag. To set up a blank tag, use \"Program a new tag\".");
          final plan = await _api.prepareRewrite(tagId);
          await rewriteTag(tag.chip, _bytesFor(plan), plan.password);
          return (tagId, tag.read.uid);
        });
        await _api.confirmWritten(tagId, uid);
      }
      if (mounted) setState(() => _step = _Step.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.error;
          _error = e is TagException || e is ApiException ? e.toString() : 'The tag moved away before it finished. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (title, body) = switch (_step) {
      _Step.preparing => ('Getting ready…', 'Signing your latest emergency profile.'),
      _Step.waiting => ('Hold the tag to your phone', 'Keep it on the back of the phone until this screen changes. It takes about two seconds.'),
      _Step.done => (_isNew ? 'Your ${widget.label} tag is ready' : 'Tag updated', 'It now shows your latest emergency info, and only your account can change it.'),
      _Step.error => ("That didn't work", _error ?? ''),
    };
    return Scaffold(
      backgroundColor: MtColors.periwinklePastel,
      appBar: AppBar(backgroundColor: MtColors.periwinklePastel, title: Text(_isNew ? 'Program a new tag' : 'Update a tag')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(children: [
            Expanded(child: Center(child: _Visual(step: _step))),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge!.copyWith(color: MtColors.navy, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(body, textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(color: MtColors.inkMuted, height: 1.5)),
            const SizedBox(height: 28),
            if (_step == _Step.done || _step == _Step.error)
              FilledButton(
                onPressed: _step == _Step.done ? () => Navigator.of(context).pop(true) : _run,
                style: FilledButton.styleFrom(backgroundColor: MtColors.navy, minimumSize: const Size.fromHeight(56), shape: const StadiumBorder()),
                child: Text(_step == _Step.done ? 'Done' : 'Try again', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (step) {
      _Step.done => (MtColors.mintPastel, MtColors.mintStrong, Icons.check_rounded),
      _Step.error => (MtColors.peachPastel, MtColors.peachStrong, Icons.priority_high_rounded),
      _ => (MtColors.navy, Colors.white, Icons.contactless_outlined),
    };
    return Stack(alignment: Alignment.center, children: [
      if (step == _Step.waiting) const PulseRings(color: MtColors.navy, size: 170),
      Container(width: 200, height: 200, decoration: const BoxDecoration(shape: BoxShape.circle, color: MtColors.periwinkleStrong)),
      Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg, boxShadow: glow(fg)),
        child: step == _Step.preparing
            ? const Padding(padding: EdgeInsets.all(44), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Icon(icon, color: fg, size: 60),
      ),
    ]);
  }
}
