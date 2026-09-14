import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'reader_controller.dart';
import 'services/tag_scan_service.dart';
import 'services/tier2_repository.dart';
import 'theme/tokens.dart';
import 'widgets/mt_components.dart';

const _issuerPublicKey = String.fromEnvironment('MEDITAG_PUBLIC_KEY');

void main() {
  final config = ApiConfig.fromEnvironment();
  runApp(MediTagApp(
    controller: ReaderController(
      scanner: NfcTagScanService(publicKeyBase64: _issuerPublicKey),
      tier2Repository: Tier2Repository(config),
    ),
    publicKeyBase64: _issuerPublicKey,
  ));
}

enum AppSurface { portal, reader, citizen, doctor }

class MediTagApp extends StatefulWidget {
  const MediTagApp({super.key, required this.controller, this.publicKeyBase64 = '', this.initialSurface = AppSurface.portal});
  final ReaderController controller;
  final String publicKeyBase64;
  final AppSurface initialSurface;

  @override
  State<MediTagApp> createState() => _MediTagAppState();
}

class _MediTagAppState extends State<MediTagApp> {
  late AppSurface _surface = widget.initialSurface;

  void _openDoctorScanner() {
    widget.controller.reset();
    setState(() => _surface = AppSurface.reader);
    widget.controller.scan();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediTag',
        theme: MTTokens.theme(),
        home: switch (_surface) {
          AppSurface.portal => _AccessPortal(onSelect: (surface) => setState(() => _surface = surface)),
          AppSurface.reader => ReaderFlow(controller: widget.controller, publicKeyBase64: widget.publicKeyBase64, onExit: () => setState(() => _surface = AppSurface.portal)),
          AppSurface.citizen => _CitizenLogin(onExit: () => setState(() => _surface = AppSurface.portal)),
          AppSurface.doctor => _DoctorLogin(onExit: () => setState(() => _surface = AppSurface.portal), onScan: _openDoctorScanner),
        },
      );
}

class ReaderFlow extends StatelessWidget {
  const ReaderFlow({super.key, required this.controller, required this.publicKeyBase64, this.onExit});
  final ReaderController controller;
  final String publicKeyBase64;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          body: SafeArea(
            child: switch (controller.view) {
              ReaderView.home => _HomeScreen(controller: controller, onExit: onExit),
              ReaderView.scanning => _ScanningScreen(controller: controller),
              ReaderView.verified => _VerifiedScreen(controller: controller),
              ReaderView.invalid => _InvalidScreen(controller: controller),
              ReaderView.tier2Loading => const _Tier2LoadingScreen(),
              ReaderView.tier2Locked => _Tier2LockedScreen(controller: controller),
              ReaderView.tier2Record => _Tier2RecordScreen(controller: controller),
              ReaderView.issueTag => _IssueTagScreen(controller: controller),
              ReaderView.settings => _SettingsScreen(controller: controller, publicKeyBase64: publicKeyBase64),
            },
          ),
        ),
      );
}

class _Page extends StatelessWidget {
  const _Page({required this.child, this.onBack, this.settings});
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? settings;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth > 640 ? 600 : double.infinity),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (onBack != null || settings != null)
                  Row(children: [
                    if (onBack != null) MTIconButton(icon: PhosphorIconsRegular.arrowLeft, label: 'Back', onPressed: onBack),
                    const Spacer(),
                    if (settings != null) MTIconButton(icon: PhosphorIconsRegular.gear, label: 'Settings', onPressed: settings),
                  ]),
                if (onBack != null || settings != null) const SizedBox(height: 22),
                child,
              ]),
            ),
          ),
        ),
      );
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.controller, this.onExit});
  final ReaderController controller;
  final VoidCallback? onExit;
  @override
  Widget build(BuildContext context) => _Page(
        onBack: onExit,
        settings: () => controller.show(ReaderView.settings),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height - 125,
          child: MTEmptyState(
            icon: PhosphorIconsRegular.contactlessPayment,
            title: 'Tap a MediTag to read it',
            message: controller.scanMessage ?? 'Hold your phone near a MediTag. Critical information is verified on this device, even offline.',
            action: Column(children: [
              MTButton(label: 'Start scan', icon: PhosphorIconsRegular.contactlessPayment, onPressed: controller.scan),
              const SizedBox(height: 10),
              MTButton(label: 'Issue a tag', icon: PhosphorIconsRegular.plus, variant: MTButtonVariant.text, onPressed: () => controller.show(ReaderView.issueTag)),
            ]),
          ),
        ),
      );
}

class _ScanningScreen extends StatelessWidget {
  const _ScanningScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) => _Page(
        onBack: controller.reset,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height - 125,
          child: MTEnter(
            index: 0,
            child: MTEmptyState(
              icon: PhosphorIconsRegular.contactlessPayment,
              title: 'Scanning for MediTag',
              message: 'Keep the tag close to the back of this device. We will verify its signature before showing any data.',
              action: const MTEmptyNote(icon: PhosphorIconsRegular.wifiSlash, message: 'Verification happens locally and does not need a network connection.'),
            ),
          ),
        ),
      );
}

class _VerifiedScreen extends StatelessWidget {
  const _VerifiedScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) {
    final payload = controller.verification!.payload!;
    final tiles = <Widget>[
      ...payload.allergies.map((value) => MTTintTile(tint: MTTint.amber, icon: PhosphorIconsRegular.warning, label: _readable(value))),
      ...payload.conditions.map((value) => MTTintTile(tint: MTTint.orchid, icon: PhosphorIconsRegular.heartbeat, label: _readable(value))),
    ];
    return _Page(
      onBack: controller.reset,
      settings: () => controller.show(ReaderView.settings),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MTPageHeading(title: 'Emergency profile', subtitle: 'Tier 1 information is available immediately.'),
        const SizedBox(height: 22),
        const MTVerificationBanner(state: MTVerificationState.verified),
        const SizedBox(height: 16),
        MTStatTile(label: 'Blood type', value: payload.bloodTypeName, icon: PhosphorIconsRegular.drop),
        const SizedBox(height: 26),
        const MTSectionHeader(title: 'Allergies & conditions'),
        const SizedBox(height: 12),
        if (tiles.isEmpty)
          const MTEmptyNote(icon: PhosphorIconsRegular.checkCircle, message: 'No allergies or critical conditions are recorded on this tag.')
        else
          Wrap(spacing: 8, runSpacing: 8, children: [for (var index = 0; index < tiles.length; index++) MTEnter(index: index, child: tiles[index])]),
        const SizedBox(height: 24),
        MTCard(
          onTap: () => _call(context, payload.emergencyPhone),
          semanticLabel: 'Call emergency contact at +91 ${payload.emergencyPhone}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const MTCardHeader(title: 'Emergency contact', subtitle: 'Tap to call'),
            const SizedBox(height: 14),
            Row(children: [
              DecoratedBox(decoration: const BoxDecoration(color: MTTokens.mintWash, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(10), child: PhosphorIcon(PhosphorIconsRegular.phone, color: MTTokens.mint))),
              const SizedBox(width: 12),
              Text('+91 ${payload.emergencyPhone}', style: MTTokens.headlineMd),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        MTCard(variant: MTCardVariant.flat, child: Row(children: [PhosphorIcon(PhosphorIconsRegular.identificationCard, color: MTTokens.inkMuted), const SizedBox(width: 10), const Text('Tag ID', style: TextStyle(color: MTTokens.inkMuted)), const Spacer(), MTTag(label: '#${payload.tagId}')])) ,
        const SizedBox(height: 24),
        MTTierLockCard(reason: 'A fuller medical record may be available to authorized clinicians when online.', onRetry: controller.requestTier2),
      ]),
    );
  }
}

class _InvalidScreen extends StatelessWidget {
  const _InvalidScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) => _Page(
        onBack: controller.reset,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MTPageHeading(title: 'Tag cannot be trusted', subtitle: 'Do not act on the data stored on this tag.'),
          const SizedBox(height: 22),
          MTVerificationBanner(state: MTVerificationState.invalid, detail: controller.verification?.error),
          const SizedBox(height: 20),
          const MTEmptyNote(icon: PhosphorIconsRegular.info, message: "This tag's data doesn't match its signature — it may have been altered. Use established emergency procedures instead."),
          const SizedBox(height: 24),
          MTButton(label: 'Scan another tag', icon: PhosphorIconsRegular.arrowClockwise, onPressed: controller.scan),
        ]),
      );
}

class _Tier2LoadingScreen extends StatelessWidget {
  const _Tier2LoadingScreen();
  @override
  Widget build(BuildContext context) => const _Page(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MTPageHeading(title: 'Loading full record', subtitle: 'Checking authorized online access.'),
          SizedBox(height: 24), MTSkeleton(height: 118), SizedBox(height: 12), MTSkeleton(height: 156), SizedBox(height: 12), MTSkeleton(height: 104),
        ]),
      );
}

class _Tier2LockedScreen extends StatelessWidget {
  const _Tier2LockedScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) {
    final lock = controller.tier2 as Tier2Locked;
    final offline = lock.reason == Tier2LockReason.offline;
    return _Page(
      onBack: () => controller.show(ReaderView.verified),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MTPageHeading(title: 'Full record', subtitle: 'Tier 2 is separate from the verified emergency profile.'),
        const SizedBox(height: 24),
        MTTierLockCard(reason: offline ? 'No connection or clinician configuration is available. The verified offline emergency profile is still available.' : 'Your current account is not authorized to view this patient’s full record.', onRetry: offline ? controller.requestTier2 : null),
        const SizedBox(height: 20),
        MTButton(label: 'Back to emergency profile', icon: PhosphorIconsRegular.arrowLeft, variant: MTButtonVariant.secondary, onPressed: () => controller.show(ReaderView.verified)),
      ]),
    );
  }
}

class _Tier2RecordScreen extends StatelessWidget {
  const _Tier2RecordScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) {
    final record = (controller.tier2 as Tier2Record).values;
    final entries = record.entries.toList();
    return _Page(
      onBack: () => controller.show(ReaderView.verified),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MTPageHeading(title: 'Full medical record', subtitle: 'Authorized Tier 2 access'),
        const SizedBox(height: 18),
        const MTBadge(label: 'Authorized online record', tone: MTBadgeTone.success, icon: PhosphorIconsRegular.shieldCheck),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          const MTEmptyNote(icon: PhosphorIconsRegular.fileText, message: 'No additional medical record has been added yet.')
        else
          ...entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [MTCardHeader(title: _readable(entry.key)), const SizedBox(height: 10), Text(_recordValue(entry.value), style: const TextStyle(color: MTTokens.inkMuted, height: 1.45))])))),
      ]),
    );
  }
}

class _IssueTagScreen extends StatefulWidget {
  const _IssueTagScreen({required this.controller});
  final ReaderController controller;
  @override
  State<_IssueTagScreen> createState() => _IssueTagScreenState();
}

class _IssueTagScreenState extends State<_IssueTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagId = TextEditingController();
  final _phone = TextEditingController();
  String _bloodType = 'O+';
  bool _valid = false;
  @override
  void dispose() { _tagId.dispose(); _phone.dispose(); super.dispose(); }
  void _validate() => setState(() => _valid = _formKey.currentState?.validate() ?? false);
  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await MTModal.show<void>(context: context, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Confirm tag write', style: MTTokens.headlineLg), const SizedBox(height: 10),
      const Text('Writing replaces any existing data on a tag. This rebuilt reader demonstrates the confirmation flow only; it will not write to NFC hardware.', style: TextStyle(color: MTTokens.inkMuted, height: 1.45)), const SizedBox(height: 22),
      MTButton(label: 'I understand', icon: PhosphorIconsRegular.check, onPressed: () => Navigator.of(context).pop()), const SizedBox(height: 8), MTButton(label: 'Cancel', variant: MTButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
    ]));
  }
  @override
  Widget build(BuildContext context) => _Page(
        onBack: widget.controller.reset,
        child: Form(key: _formKey, onChanged: _validate, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MTPageHeading(title: 'Issue a MediTag', subtitle: 'Prepare a signed emergency profile for a blank tag.'), const SizedBox(height: 24),
          MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const MTCardHeader(title: 'Emergency information', subtitle: 'Only this compact, signed data belongs on the tag.'), const SizedBox(height: 20),
            MTTextField(label: 'Tag ID', controller: _tagId, keyboardType: TextInputType.number, hint: 'e.g. 1001', validator: (value) => (value == null || int.tryParse(value) == null) ? 'Enter a numeric tag ID.' : null), const SizedBox(height: 16),
            MTSelect<String>(label: 'Blood type', value: _bloodType, items: const [DropdownMenuItem(value: 'A+', child: Text('A+')), DropdownMenuItem(value: 'A-', child: Text('A-')), DropdownMenuItem(value: 'B+', child: Text('B+')), DropdownMenuItem(value: 'B-', child: Text('B-')), DropdownMenuItem(value: 'AB+', child: Text('AB+')), DropdownMenuItem(value: 'AB-', child: Text('AB-')), DropdownMenuItem(value: 'O+', child: Text('O+')), DropdownMenuItem(value: 'O-', child: Text('O-'))], onChanged: (value) => setState(() => _bloodType = value ?? _bloodType)), const SizedBox(height: 16),
            MTTextField(label: 'Emergency phone', controller: _phone, keyboardType: TextInputType.phone, hint: '+91 98765 43210', validator: (value) => RegExp(r'^\\+?91?[0-9 -]{10,14}$').hasMatch(value?.trim() ?? '') ? null : 'Enter a valid Indian emergency number.'),
          ])), const SizedBox(height: 18),
          const MTEmptyNote(icon: PhosphorIconsRegular.lockKey, message: 'Signing and NFC writing are intentionally not enabled in this app build.'), const SizedBox(height: 24),
          MTButton(label: 'Review tag write', icon: PhosphorIconsRegular.penNib, onPressed: _valid ? _confirm : null),
        ])),
      );
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen({required this.controller, required this.publicKeyBase64});
  final ReaderController controller;
  final String publicKeyBase64;
  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  String _language = 'English';
  @override
  Widget build(BuildContext context) => _Page(
        onBack: widget.controller.reset,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MTPageHeading(title: 'Settings', subtitle: 'Transparency and reader preferences.'), const SizedBox(height: 24),
          MTCard(child: MTSelect<String>(label: 'Language', value: _language, items: const [DropdownMenuItem(value: 'English', child: Text('English'))], onChanged: (value) => setState(() => _language = value ?? _language))), const SizedBox(height: 12),
          MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const MTCardHeader(title: 'Trusted public key', subtitle: 'Used only to verify; it cannot issue tags.'), const SizedBox(height: 12), Text(widget.publicKeyBase64.isEmpty ? 'Not provisioned in this build' : '${widget.publicKeyBase64.substring(0, widget.publicKeyBase64.length.clamp(0, 16))}…', style: MTTokens.monoData), const SizedBox(height: 4), const Text('Format version 1 · ECDSA P-256', style: TextStyle(color: MTTokens.inkMuted))])), const SizedBox(height: 12),
          const MTCard(child: MTCardHeader(title: 'About MediTag', subtitle: 'Offline-verifying NFC emergency medical IDs. Tier 2 information is always gated online.')),
        ]),
      );
}

class _AccessPortal extends StatelessWidget {
  const _AccessPortal({required this.onSelect});
  final ValueChanged<AppSurface> onSelect;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: _Page(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 26),
              const Text('MediTag', style: MTTokens.displayXl),
              const SizedBox(height: 10),
              const Text('Medical information that is ready when it matters.', style: TextStyle(color: MTTokens.inkMuted, fontSize: 17, height: 1.4)),
              const SizedBox(height: 40),
              _PortalCard(icon: PhosphorIconsRegular.user, title: 'Citizen', message: 'Sign in to manage your MediTag profile and health history.', onTap: () => onSelect(AppSurface.citizen)),
              const SizedBox(height: 14),
              _PortalCard(icon: PhosphorIconsRegular.stethoscope, title: 'Doctor', message: 'Verified clinician access for structured patient records.', onTap: () => onSelect(AppSurface.doctor)),
              const SizedBox(height: 14),
              _PortalCard(icon: PhosphorIconsRegular.contactlessPayment, title: 'Read a MediTag', message: 'Emergency access. No login, no connection required.', onTap: () => onSelect(AppSurface.reader)),
              const SizedBox(height: 28),
              const MTEmptyNote(icon: PhosphorIconsRegular.shieldCheck, message: 'Only signed emergency data is available without an account.'),
            ]),
          ),
        ),
      );
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({required this.icon, required this.title, required this.message, required this.onTap});
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => MTCard(
        variant: MTCardVariant.emphasised,
        onTap: onTap,
        semanticLabel: title,
        child: Row(children: [
          DecoratedBox(decoration: const BoxDecoration(color: MTTokens.blueWash, borderRadius: MTTokens.shapeMd), child: Padding(padding: const EdgeInsets.all(13), child: PhosphorIcon(icon, size: 26, color: MTTokens.periwinkle))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MTTokens.headlineMd), const SizedBox(height: 4), Text(message, style: const TextStyle(color: MTTokens.inkMuted, height: 1.35))])),
          const SizedBox(width: 8),
          PhosphorIcon(PhosphorIconsRegular.caretRight, color: MTTokens.inkMuted),
        ]),
      );
}

class _CitizenLogin extends StatefulWidget {
  const _CitizenLogin({required this.onExit});
  final VoidCallback onExit;
  @override
  State<_CitizenLogin> createState() => _CitizenLoginState();
}

class _CitizenLoginState extends State<_CitizenLogin> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _signedIn = false;
  bool _newProfile = false;
  @override
  void dispose() { _identity.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _continue() async {
    if (_identity.text.trim().isEmpty || _password.text.isEmpty) return;
    await MTModal.show<void>(context: context, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Profile pairing', style: MTTokens.headlineLg), const SizedBox(height: 10),
      const Text('The production app will check the signed-in email and phone-number pairing with the account service. Choose a state to preview this frontend flow.', style: TextStyle(color: MTTokens.inkMuted, height: 1.45)), const SizedBox(height: 20),
      MTButton(label: 'I already have a MediTag', icon: PhosphorIconsRegular.identificationCard, onPressed: () { Navigator.pop(context); setState(() { _newProfile = false; _signedIn = true; }); }), const SizedBox(height: 8),
      MTButton(label: 'I am new to MediTag', icon: PhosphorIconsRegular.plus, variant: MTButtonVariant.secondary, onPressed: () { Navigator.pop(context); setState(() { _newProfile = true; _signedIn = true; }); }),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) return _CitizenShell(onExit: widget.onExit, startOnCreate: _newProfile);
    return Scaffold(body: SafeArea(child: _Page(onBack: widget.onExit, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const MTPageHeading(title: 'Citizen sign in', subtitle: 'Manage your MediTag profile and private medical history.'), const SizedBox(height: 30),
      MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MTCardHeader(title: 'Welcome back', subtitle: 'Use your email address or phone number.'), const SizedBox(height: 20),
        MTTextField(label: 'Email or phone', controller: _identity, keyboardType: TextInputType.emailAddress, hint: 'you@example.com or +91 98765 43210'), const SizedBox(height: 16),
        MTTextField(label: 'Password', controller: _password, obscureText: true, hint: 'Your password'), const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: MTButton(label: 'Forgot password?', expand: false, variant: MTButtonVariant.text, onPressed: () => _notice(context, 'Password reset will be connected to the citizen account service.'))), const SizedBox(height: 10),
        MTButton(label: 'Sign in', icon: PhosphorIconsRegular.arrowRight, onPressed: _continue),
      ])), const SizedBox(height: 16),
      const MTEmptyNote(icon: PhosphorIconsRegular.lockKey, message: 'Your detailed health history stays private and is not stored on the NFC tag.'),
    ]))));
  }
}

class _CitizenShell extends StatefulWidget {
  const _CitizenShell({required this.onExit, required this.startOnCreate});
  final VoidCallback onExit;
  final bool startOnCreate;
  @override
  State<_CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<_CitizenShell> {
  late int _tab = widget.startOnCreate ? 1 : 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: switch (_tab) { 0 => const _CitizenHome(), 1 => const _CitizenProfileEditor(), _ => _CitizenSettings(onExit: widget.onExit) }),
        bottomNavigationBar: MTBottomNav(currentIndex: _tab, onChanged: (value) => setState(() => _tab = value), items: const [MTNavItem(icon: PhosphorIconsRegular.house, label: 'Home'), MTNavItem(icon: PhosphorIconsRegular.notePencil, label: 'Create'), MTNavItem(icon: PhosphorIconsRegular.gear, label: 'Settings')]),
      );
}

class _CitizenHome extends StatelessWidget {
  const _CitizenHome();
  @override
  Widget build(BuildContext context) => const _Page(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    MTPageHeading(title: 'Your MediTag', subtitle: 'Your emergency information, ready offline.'), SizedBox(height: 22),
    MTVerificationBanner(state: MTVerificationState.verified), SizedBox(height: 16),
    MTStatTile(label: 'Blood type', value: 'O-', icon: PhosphorIconsRegular.drop), SizedBox(height: 22),
    MTCard(child: MTCardHeader(title: 'Emergency profile', subtitle: 'Penicillin, Latex · Diabetes · +91 98765 43210')), SizedBox(height: 12),
    MTCard(variant: MTCardVariant.flat, child: MTCardHeader(title: 'Your private record', subtitle: 'Update medical history and documents from the Create tab.')),
  ]));
}

class _CitizenProfileEditor extends StatefulWidget {
  const _CitizenProfileEditor();
  @override
  State<_CitizenProfileEditor> createState() => _CitizenProfileEditorState();
}

class _CitizenProfileEditorState extends State<_CitizenProfileEditor> {
  final _conditions = TextEditingController();
  final _medications = TextEditingController();
  @override
  void dispose() { _conditions.dispose(); _medications.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _Page(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const MTPageHeading(title: 'Create or update', subtitle: 'Keep your medical profile current. Extra history is saved privately in Tier 2.'), const SizedBox(height: 22),
    MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const MTCardHeader(title: 'Medical profile'), const SizedBox(height: 18), MTTextField(label: 'Conditions', controller: _conditions, hint: 'e.g. Diabetes'), const SizedBox(height: 16), MTTextField(label: 'Medications', controller: _medications, hint: 'e.g. Insulin'), const SizedBox(height: 18), MTButton(label: 'Save profile', icon: PhosphorIconsRegular.floppyDisk, onPressed: () => _notice(context, 'Profile saving will connect to the citizen service.'))])), const SizedBox(height: 14),
    MTCard(onTap: () => _notice(context, 'Document upload will connect to secure cloud storage.'), child: const MTCardHeader(title: 'Upload medical history', subtitle: 'Add reports, prescriptions, or other documents for authorized clinicians.', trailing: MTBadge(label: 'Private cloud', tone: MTBadgeTone.info, icon: PhosphorIconsRegular.uploadSimple))),
  ]));
}

class _CitizenSettings extends StatelessWidget {
  const _CitizenSettings({required this.onExit});
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => _Page(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const MTPageHeading(title: 'Settings', subtitle: 'Your account and privacy.'), const SizedBox(height: 22),
    const MTCard(child: MTCardHeader(title: 'Account', subtitle: 'aanya@example.com · +91 98765 43210')), const SizedBox(height: 12),
    MTCard(onTap: onExit, child: MTCardHeader(title: 'Sign out', subtitle: 'Return to MediTag access options', trailing: PhosphorIcon(PhosphorIconsRegular.signOut, color: MTTokens.criticalRed))),
  ]));
}

class _DoctorLogin extends StatefulWidget {
  const _DoctorLogin({required this.onExit, required this.onScan});
  final VoidCallback onExit;
  final VoidCallback onScan;
  @override
  State<_DoctorLogin> createState() => _DoctorLoginState();
}

class _DoctorLoginState extends State<_DoctorLogin> {
  final _doctorId = TextEditingController();
  final _password = TextEditingController();
  bool _signedIn = false;
  @override
  void dispose() { _doctorId.dispose(); _password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (_signedIn) return _DoctorHome(onExit: widget.onExit, onScan: widget.onScan);
    return Scaffold(body: SafeArea(child: _Page(onBack: widget.onExit, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const MTPageHeading(title: 'Doctor sign in', subtitle: 'Verified clinician access to structured patient records.'), const SizedBox(height: 30),
      MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const MTBadge(label: 'Clinician ID verification required', tone: MTBadgeTone.info, icon: PhosphorIconsRegular.identificationBadge), const SizedBox(height: 18), MTTextField(label: 'Doctor ID', controller: _doctorId, hint: 'Registration or clinician ID'), const SizedBox(height: 16), MTTextField(label: 'Password', controller: _password, obscureText: true, hint: 'Your password'), const SizedBox(height: 20), MTButton(label: 'Verify and sign in', icon: PhosphorIconsRegular.shieldCheck, onPressed: () { if (_doctorId.text.trim().isNotEmpty && _password.text.isNotEmpty) setState(() => _signedIn = true); })])), const SizedBox(height: 16),
      const MTEmptyNote(icon: PhosphorIconsRegular.lockKey, message: 'Production doctor identity verification will be enforced by the backend.'),
    ]))));
  }
}

class _DoctorHome extends StatelessWidget {
  const _DoctorHome({required this.onExit, required this.onScan});
  final VoidCallback onExit;
  final VoidCallback onScan;
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: _Page(onBack: onExit, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const MTPageHeading(title: 'Clinician workspace', subtitle: 'Tap a patient tag to begin a verified emergency workflow.'), const SizedBox(height: 36),
    MTCard(variant: MTCardVariant.emphasised, onTap: onScan, semanticLabel: 'Tap to scan a MediTag', child: SizedBox(width: double.infinity, height: 245, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [DecoratedBox(decoration: const BoxDecoration(color: MTTokens.blueWash, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(22), child: PhosphorIcon(PhosphorIconsRegular.contactlessPayment, color: MTTokens.periwinkle, size: 46))), const SizedBox(height: 18), Text('Tap to Scan', style: MTTokens.headlineLg), const SizedBox(height: 6), const Text('Read Tier 1 locally, then request the authorized Tier 2 record.', textAlign: TextAlign.center, style: TextStyle(color: MTTokens.inkMuted))]))), const SizedBox(height: 20),
    const MTEmptyNote(icon: PhosphorIconsRegular.shieldCheck, message: 'A valid signature is required before any patient data is trusted.'),
  ]))));
}

String _readable(String value) => value.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
String _recordValue(Object? value) => value is String ? value : const JsonEncoder.withIndent('  ').convert(value);
Future<void> _call(BuildContext context, String phone) async {
  final success = await launchUrl(Uri(scheme: 'tel', path: '+91$phone'));
  if (!context.mounted || success) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling is unavailable on this device.')));
}

void _notice(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
