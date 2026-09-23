part of '../../main.dart';

class ReaderFlow extends StatelessWidget {
  const ReaderFlow({
    super.key,
    required this.controller,
    required this.publicKeyBase64,
    this.onExit,
  });
  final ReaderController controller;
  final String publicKeyBase64;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: switch (controller.view) {
          ReaderView.home => _HomeScreen(
            controller: controller,
            onExit: onExit,
          ),
          ReaderView.scanning => _ScanningScreen(controller: controller),
          ReaderView.verified => _VerifiedScreen(controller: controller),
          ReaderView.invalid => _InvalidScreen(controller: controller),
          ReaderView.tier2Loading => const _Tier2LoadingScreen(),
          ReaderView.tier2Locked => _Tier2LockedScreen(controller: controller),
          ReaderView.tier2Record => _Tier2RecordScreen(controller: controller),
          ReaderView.issueTag => _IssueTagScreen(controller: controller),
          ReaderView.settings => _SettingsScreen(
            controller: controller,
            publicKeyBase64: publicKeyBase64,
          ),
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
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth > 760 ? 32 : 20,
        20,
        constraints.maxWidth > 760 ? 32 : 20,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    MTIconButton(
                      icon: PhosphorIconsRegular.arrowLeft,
                      label: 'Back',
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 12),
                  ],
                  const MTBrand(compact: true),
                  const Spacer(),
                  if (settings != null)
                    MTIconButton(
                      icon: PhosphorIconsRegular.gear,
                      label: 'Settings',
                      onPressed: settings,
                    ),
                ],
              ),
              const SizedBox(height: 32),
              child,
            ],
          ),
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
        message:
            controller.scanMessage ??
            'Hold your phone near a MediTag. Critical information is verified on this device, even offline.',
        action: Column(
          children: [
            MTButton(
              label: 'Start scan',
              icon: PhosphorIconsRegular.contactlessPayment,
              onPressed: controller.scan,
            ),
            const SizedBox(height: 10),
            MTButton(
              label: 'Issue a tag',
              icon: PhosphorIconsRegular.plus,
              variant: MTButtonVariant.text,
              onPressed: () => controller.show(ReaderView.issueTag),
            ),
          ],
        ),
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
          message:
              'Keep the tag close to the back of this device. We will verify its signature before showing any data.',
          action: const MTEmptyNote(
            icon: PhosphorIconsRegular.wifiSlash,
            message:
                'Verification happens locally and does not need a network connection.',
          ),
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
      ...payload.allergies.map(
        (value) => MTTintTile(
          tint: MTTint.amber,
          icon: PhosphorIconsRegular.warning,
          label: _readable(value),
        ),
      ),
      ...payload.conditions.map(
        (value) => MTTintTile(
          tint: MTTint.orchid,
          icon: PhosphorIconsRegular.heartbeat,
          label: _readable(value),
        ),
      ),
    ];
    return _Page(
      onBack: controller.reset,
      settings: () => controller.show(ReaderView.settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MTOverline(
            label: 'Emergency access',
            tone: MTBadgeTone.success,
          ),
          const SizedBox(height: 10),
          const MTPageHeading(
            title: 'Emergency profile',
            subtitle:
                'Critical Tier 1 information is available immediately, with no sign-in required.',
          ),
          const SizedBox(height: 22),
          const MTVerificationBanner(state: MTVerificationState.verified),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final essentials = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MTStatTile(
                    label: 'Blood type',
                    value: payload.bloodTypeName,
                    icon: PhosphorIconsRegular.drop,
                  ),
                  const SizedBox(height: 18),
                  MTCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTSectionHeader(title: 'Allergies & conditions'),
                        const SizedBox(height: 14),
                        if (tiles.isEmpty)
                          const MTEmptyNote(
                            icon: PhosphorIconsRegular.checkCircle,
                            message:
                                'No allergies or critical conditions are recorded on this tag.',
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var index = 0; index < tiles.length; index++)
                                MTEnter(index: index, child: tiles[index]),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
              final actions = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MTCard(
                    onTap: () => _call(context, payload.emergencyPhone),
                    semanticLabel:
                        'Call emergency contact at +91 ${payload.emergencyPhone}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MTOverline(
                          label: 'Tap to call',
                          tone: MTBadgeTone.success,
                        ),
                        const SizedBox(height: 10),
                        const MTCardHeader(title: 'Emergency contact'),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const MTIconTile(
                              icon: PhosphorIconsRegular.phone,
                              tint: MTTint.mint,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '+91 ${payload.emergencyPhone}',
                                style: MTTokens.headlineMd,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MTCard(
                    variant: MTCardVariant.flat,
                    child: Row(
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.identificationCard,
                          color: MTTokens.inkMuted,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tag ID',
                          style: TextStyle(color: MTTokens.inkMuted),
                        ),
                        const Spacer(),
                        MTTag(label: '#${payload.tagId}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MTTierLockCard(
                    reason:
                        'A fuller medical record may be available to authorized clinicians when online.',
                    onRetry: controller.requestTier2,
                  ),
                ],
              );
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [essentials, const SizedBox(height: 16), actions],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: essentials),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: actions),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InvalidScreen extends StatelessWidget {
  const _InvalidScreen({required this.controller});
  final ReaderController controller;
  @override
  Widget build(BuildContext context) => _Page(
    onBack: controller.reset,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MTPageHeading(
          title: 'Tag cannot be trusted',
          subtitle: 'Do not act on the data stored on this tag.',
        ),
        const SizedBox(height: 22),
        MTVerificationBanner(
          state: MTVerificationState.invalid,
          detail: controller.verification?.error,
        ),
        const SizedBox(height: 20),
        const MTEmptyNote(
          icon: PhosphorIconsRegular.info,
          message:
              "This tag's data doesn't match its signature â€” it may have been altered. Use established emergency procedures instead.",
        ),
        const SizedBox(height: 24),
        MTButton(
          label: 'Scan another tag',
          icon: PhosphorIconsRegular.arrowClockwise,
          onPressed: controller.scan,
        ),
      ],
    ),
  );
}

class _Tier2LoadingScreen extends StatelessWidget {
  const _Tier2LoadingScreen();
  @override
  Widget build(BuildContext context) => const _Page(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MTPageHeading(
          title: 'Loading full record',
          subtitle: 'Checking authorized online access.',
        ),
        SizedBox(height: 24),
        MTSkeleton(height: 118),
        SizedBox(height: 12),
        MTSkeleton(height: 156),
        SizedBox(height: 12),
        MTSkeleton(height: 104),
      ],
    ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MTPageHeading(
            title: 'Full record',
            subtitle: 'Tier 2 is separate from the verified emergency profile.',
          ),
          const SizedBox(height: 24),
          MTTierLockCard(
            reason: offline
                ? 'No connection or clinician configuration is available. The verified offline emergency profile is still available.'
                : 'Your current account is not authorized to view this patientâ€™s full record.',
            onRetry: offline ? controller.requestTier2 : null,
          ),
          const SizedBox(height: 20),
          MTButton(
            label: 'Back to emergency profile',
            icon: PhosphorIconsRegular.arrowLeft,
            variant: MTButtonVariant.secondary,
            onPressed: () => controller.show(ReaderView.verified),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MTPageHeading(
            title: 'Full medical record',
            subtitle: 'Authorized Tier 2 access',
          ),
          const SizedBox(height: 18),
          const MTBadge(
            label: 'Authorized online record',
            tone: MTBadgeTone.success,
            icon: PhosphorIconsRegular.shieldCheck,
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            const MTEmptyNote(
              icon: PhosphorIconsRegular.fileText,
              message: 'No additional medical record has been added yet.',
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MTCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MTCardHeader(title: _readable(entry.key)),
                      const SizedBox(height: 10),
                      Text(
                        _recordValue(entry.value),
                        style: const TextStyle(
                          color: MTTokens.inkMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
  void dispose() {
    _tagId.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _validate() =>
      setState(() => _valid = _formKey.currentState?.validate() ?? false);
  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await MTModal.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm tag write', style: MTTokens.headlineLg),
          const SizedBox(height: 10),
          const Text(
            'Writing replaces any existing data on a tag. This rebuilt reader demonstrates the confirmation flow only; it will not write to NFC hardware.',
            style: TextStyle(color: MTTokens.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 22),
          MTButton(
            label: 'I understand',
            icon: PhosphorIconsRegular.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          MTButton(
            label: 'Cancel',
            variant: MTButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    onBack: widget.controller.reset,
    child: Form(
      key: _formKey,
      onChanged: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MTPageHeading(
            title: 'Issue a MediTag',
            subtitle: 'Prepare a signed emergency profile for a blank tag.',
          ),
          const SizedBox(height: 24),
          MTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MTCardHeader(
                  title: 'Emergency information',
                  subtitle:
                      'Only this compact, signed data belongs on the tag.',
                ),
                const SizedBox(height: 20),
                MTTextField(
                  label: 'Tag ID',
                  controller: _tagId,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. 1001',
                  validator: (value) =>
                      (value == null || int.tryParse(value) == null)
                      ? 'Enter a numeric tag ID.'
                      : null,
                ),
                const SizedBox(height: 16),
                MTSelect<String>(
                  label: 'Blood type',
                  value: _bloodType,
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: (value) =>
                      setState(() => _bloodType = value ?? _bloodType),
                ),
                const SizedBox(height: 16),
                MTTextField(
                  label: 'Emergency phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  hint: '+91 98765 43210',
                  validator: (value) =>
                      RegExp(
                        r'^\+?(?:91)?[0-9 -]{10,14}$',
                      ).hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid Indian emergency number.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const MTEmptyNote(
            icon: PhosphorIconsRegular.lockKey,
            message:
                'Signing and NFC writing are intentionally not enabled in this app build.',
          ),
          const SizedBox(height: 24),
          MTButton(
            label: 'Review tag write',
            icon: PhosphorIconsRegular.penNib,
            onPressed: _valid ? _confirm : null,
          ),
        ],
      ),
    ),
  );
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen({
    required this.controller,
    required this.publicKeyBase64,
  });
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MTPageHeading(
          title: 'Settings',
          subtitle: 'Transparency and reader preferences.',
        ),
        const SizedBox(height: 24),
        MTCard(
          child: MTSelect<String>(
            label: 'Language',
            value: _language,
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
            ],
            onChanged: (value) =>
                setState(() => _language = value ?? _language),
          ),
        ),
        const SizedBox(height: 12),
        MTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MTCardHeader(
                title: 'Trusted public key',
                subtitle: 'Used only to verify; it cannot issue tags.',
              ),
              const SizedBox(height: 12),
              Text(
                widget.publicKeyBase64.isEmpty
                    ? 'Not provisioned in this build'
                    : '${widget.publicKeyBase64.substring(0, widget.publicKeyBase64.length.clamp(0, 16))}â€¦',
                style: MTTokens.monoData,
              ),
              const SizedBox(height: 4),
              const Text(
                'Format version 1 Â· ECDSA P-256',
                style: TextStyle(color: MTTokens.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const MTCard(
          child: MTCardHeader(
            title: 'About MediTag',
            subtitle:
                'Offline-verifying NFC emergency medical IDs. Tier 2 information is always gated online.',
          ),
        ),
      ],
    ),
  );
}

String _readable(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
String _recordValue(Object? value) =>
    value is String ? value : const JsonEncoder.withIndent('  ').convert(value);
Future<void> _call(BuildContext context, String phone) async {
  final success = await launchUrl(Uri(scheme: 'tel', path: '+91$phone'));
  if (!context.mounted || success) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Calling is unavailable on this device.')),
  );
}

void _notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
