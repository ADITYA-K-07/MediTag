part of '../../main.dart';

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
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_identity.text.trim().isEmpty || _password.text.isEmpty) return;
    await MTModal.show<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile pairing', style: MTTokens.headlineLg),
          const SizedBox(height: 10),
          const Text(
            'The production app will check the signed-in email and phone-number pairing with the account service. Choose a state to preview this frontend flow.',
            style: TextStyle(color: MTTokens.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 20),
          MTButton(
            label: 'I already have a MediTag',
            icon: PhosphorIconsRegular.identificationCard,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _newProfile = false;
                _signedIn = true;
              });
            },
          ),
          const SizedBox(height: 8),
          MTButton(
            label: 'I am new to MediTag',
            icon: PhosphorIconsRegular.plus,
            variant: MTButtonVariant.secondary,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _newProfile = true;
                _signedIn = true;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) {
      return _CitizenShell(onExit: widget.onExit, startOnCreate: _newProfile);
    }
    return Scaffold(
      body: SafeArea(
        child: _Page(
          onBack: widget.onExit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MTOverline(label: 'Citizen access', tone: MTBadgeTone.info),
              const SizedBox(height: 10),
              const MTPageHeading(
                title: 'Citizen sign in',
                subtitle:
                    'Manage your MediTag profile and private medical history.',
              ),
              const SizedBox(height: 26),
              MTCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MTIconTile(
                      icon: PhosphorIconsRegular.user,
                      tint: MTTint.blue,
                    ),
                    const SizedBox(height: 18),
                    const MTCardHeader(
                      title: 'Welcome back',
                      subtitle: 'Use your email address or phone number.',
                    ),
                    const SizedBox(height: 20),
                    MTTextField(
                      label: 'Email or phone',
                      controller: _identity,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'you@example.com or +91 98765 43210',
                    ),
                    const SizedBox(height: 16),
                    MTTextField(
                      label: 'Password',
                      controller: _password,
                      obscureText: true,
                      hint: 'Your password',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MTButton(
                        label: 'Forgot password?',
                        expand: false,
                        variant: MTButtonVariant.text,
                        onPressed: () => _notice(
                          context,
                          'Password reset will be connected to the citizen account service.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    MTButton(
                      label: 'Sign in',
                      icon: PhosphorIconsRegular.arrowRight,
                      onPressed: _continue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const MTEmptyNote(
                icon: PhosphorIconsRegular.lockKey,
                message:
                    'Your detailed health history stays private and is not stored on the NFC tag.',
              ),
            ],
          ),
        ),
      ),
    );
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
    body: SafeArea(
      child: switch (_tab) {
        0 => const _CitizenHome(),
        1 => const _CitizenProfileEditor(),
        _ => _CitizenSettings(onExit: widget.onExit),
      },
    ),
    bottomNavigationBar: MTBottomNav(
      currentIndex: _tab,
      onChanged: (value) => setState(() => _tab = value),
      items: const [
        MTNavItem(icon: PhosphorIconsRegular.house, label: 'Home'),
        MTNavItem(icon: PhosphorIconsRegular.notePencil, label: 'Create'),
        MTNavItem(icon: PhosphorIconsRegular.gear, label: 'Settings'),
      ],
    ),
  );
}

class _CitizenHome extends StatelessWidget {
  const _CitizenHome();
  @override
  Widget build(BuildContext context) => _Page(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MTOverline(
          label: 'Good morning, Aanya',
          tone: MTBadgeTone.success,
        ),
        const SizedBox(height: 10),
        const MTPageHeading(
          title: 'Your MediTag profile',
          subtitle:
              'Keep the details people need in an emergency accurate and easy to understand.',
          trailing: MTBadge(
            label: 'Profile active',
            tone: MTBadgeTone.success,
            icon: PhosphorIconsRegular.check,
          ),
        ),
        const SizedBox(height: 24),
        const MTCard(
          child: Row(
            children: [
              MTAvatar(initials: 'AS', large: true),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONNECTED TAG Â· MT-4829', style: MTTokens.labelCaps),
                    SizedBox(height: 5),
                    Text('Aanya Sharma', style: MTTokens.headlineMd),
                    SizedBox(height: 3),
                    Text(
                      'Updated 12 September 2026',
                      style: TextStyle(color: MTTokens.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              MTTag(label: 'Oâˆ’'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const emergency = MTCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MTOverline(
                    label: 'Shown without sign-in',
                    tone: MTBadgeTone.info,
                  ),
                  SizedBox(height: 8),
                  MTCardHeader(
                    title: 'Emergency details',
                    trailing: PhosphorIcon(
                      PhosphorIconsRegular.shieldCheck,
                      color: MTTokens.periwinkle,
                    ),
                  ),
                  SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MTTintTile(
                        tint: MTTint.amber,
                        icon: PhosphorIconsRegular.warning,
                        label: 'Penicillin Â· severe',
                        critical: true,
                      ),
                      MTTintTile(
                        tint: MTTint.clay,
                        icon: PhosphorIconsRegular.warning,
                        label: 'Latex',
                      ),
                      MTTintTile(
                        tint: MTTint.orchid,
                        icon: PhosphorIconsRegular.heartbeat,
                        label: 'Diabetes',
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  MTEmptyNote(
                    icon: PhosphorIconsRegular.phone,
                    message: '+91 98765 43210 Â· Emergency contact',
                  ),
                ],
              ),
            );
            const status = MTCard(
              variant: MTCardVariant.dark,
              padding: EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: MTTokens.periwinkle,
                      borderRadius: MTTokens.shapeMd,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(13),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.heartbeat,
                        color: MTTokens.card,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(height: 22),
                  MTOverline(label: 'Your MediTag', onDark: true, dot: false),
                  SizedBox(height: 7),
                  Text(
                    'Ready for emergencies',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: MTTokens.card,
                      fontWeight: FontWeight.w700,
                      fontSize: 23,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Emergency details are available through your NFC tag and printed QR.',
                    style: TextStyle(color: MTTokens.onDarkMuted, height: 1.5),
                  ),
                  SizedBox(height: 18),
                  _DarkCheck(label: 'Profile linked'),
                  SizedBox(height: 10),
                  _DarkCheck(label: 'Signature current'),
                  SizedBox(height: 10),
                  _DarkCheck(label: 'Web access active'),
                ],
              ),
            );
            if (constraints.maxWidth < 720) {
              return const Column(
                children: [emergency, SizedBox(height: 16), status],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: emergency),
                SizedBox(width: 18),
                Expanded(flex: 2, child: status),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const MTCard(
          variant: MTCardVariant.flat,
          child: MTCardHeader(
            title: 'Your private record',
            subtitle: '1 medication Â· 2 documents Â· 1 physician',
            trailing: MTBadge(
              label: 'Private',
              tone: MTBadgeTone.info,
              icon: PhosphorIconsRegular.lockKey,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DarkCheck extends StatelessWidget {
  const _DarkCheck({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const PhosphorIcon(
        PhosphorIconsRegular.checkCircle,
        color: MTTokens.mint,
        size: 17,
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: MTTokens.onDarkMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
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
  void dispose() {
    _conditions.dispose();
    _medications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Page(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MTPageHeading(
          title: 'Create or update',
          subtitle:
              'Keep your medical profile current. Extra history is saved privately in Tier 2.',
        ),
        const SizedBox(height: 22),
        MTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MTCardHeader(title: 'Medical profile'),
              const SizedBox(height: 18),
              MTTextField(
                label: 'Conditions',
                controller: _conditions,
                hint: 'e.g. Diabetes',
              ),
              const SizedBox(height: 16),
              MTTextField(
                label: 'Medications',
                controller: _medications,
                hint: 'e.g. Insulin',
              ),
              const SizedBox(height: 18),
              MTButton(
                label: 'Save profile',
                icon: PhosphorIconsRegular.floppyDisk,
                onPressed: () => _notice(
                  context,
                  'Profile saving will connect to the citizen service.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MTCard(
          onTap: () => _notice(
            context,
            'Document upload will connect to secure cloud storage.',
          ),
          child: const MTCardHeader(
            title: 'Upload medical history',
            subtitle:
                'Add reports, prescriptions, or other documents for authorized clinicians.',
            trailing: MTBadge(
              label: 'Private cloud',
              tone: MTBadgeTone.info,
              icon: PhosphorIconsRegular.uploadSimple,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CitizenSettings extends StatelessWidget {
  const _CitizenSettings({required this.onExit});
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => _Page(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MTPageHeading(
          title: 'Settings',
          subtitle: 'Your account and privacy.',
        ),
        const SizedBox(height: 22),
        const MTCard(
          child: MTCardHeader(
            title: 'Account',
            subtitle: 'aanya@example.com Â· +91 98765 43210',
          ),
        ),
        const SizedBox(height: 12),
        MTCard(
          onTap: onExit,
          child: MTCardHeader(
            title: 'Sign out',
            subtitle: 'Return to MediTag access options',
            trailing: PhosphorIcon(
              PhosphorIconsRegular.signOut,
              color: MTTokens.criticalRed,
            ),
          ),
        ),
      ],
    ),
  );
}
