part of '../../main.dart';

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
  void dispose() {
    _doctorId.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) {
      return _DoctorHome(onExit: widget.onExit, onScan: widget.onScan);
    }
    return Scaffold(
      body: SafeArea(
        child: _Page(
          onBack: widget.onExit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MTOverline(
                label: 'Clinical access',
                tone: MTBadgeTone.info,
              ),
              const SizedBox(height: 10),
              const MTPageHeading(
                title: 'Doctor sign in',
                subtitle:
                    'Verified clinician access to structured patient records.',
              ),
              const SizedBox(height: 26),
              MTCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MTIconTile(
                      icon: PhosphorIconsRegular.stethoscope,
                      tint: MTTint.orchid,
                    ),
                    const SizedBox(height: 18),
                    const MTBadge(
                      label: 'Clinician ID verification required',
                      tone: MTBadgeTone.info,
                      icon: PhosphorIconsRegular.identificationBadge,
                    ),
                    const SizedBox(height: 18),
                    MTTextField(
                      label: 'Doctor ID',
                      controller: _doctorId,
                      hint: 'Registration or clinician ID',
                    ),
                    const SizedBox(height: 16),
                    MTTextField(
                      label: 'Password',
                      controller: _password,
                      obscureText: true,
                      hint: 'Your password',
                    ),
                    const SizedBox(height: 20),
                    MTButton(
                      label: 'Verify and sign in',
                      icon: PhosphorIconsRegular.shieldCheck,
                      onPressed: () {
                        if (_doctorId.text.trim().isNotEmpty &&
                            _password.text.isNotEmpty) {
                          setState(() => _signedIn = true);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const MTEmptyNote(
                icon: PhosphorIconsRegular.lockKey,
                message:
                    'Production doctor identity verification will be enforced by the backend.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorHome extends StatelessWidget {
  const _DoctorHome({required this.onExit, required this.onScan});
  final VoidCallback onExit;
  final VoidCallback onScan;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: _Page(
        onBack: onExit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MTOverline(
              label: 'Clinician workspace',
              tone: MTBadgeTone.info,
            ),
            const SizedBox(height: 10),
            const MTPageHeading(
              title: 'Patient access',
              subtitle: 'Signed in as Dr. Meera Iyer Â· NMC verified',
              trailing: MTBadge(
                label: 'Identity verified',
                tone: MTBadgeTone.success,
                icon: PhosphorIconsRegular.sealCheck,
              ),
            ),
            const SizedBox(height: 26),
            MTCard(
              variant: MTCardVariant.dark,
              padding: const EdgeInsets.all(26),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final intro = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: MTTokens.periwinkle,
                          borderRadius: MTTokens.shapeMd,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(13),
                          child: PhosphorIcon(
                            PhosphorIconsRegular.stethoscope,
                            color: MTTokens.card,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open a patient profile',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: MTTokens.card,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap the MediTag to verify its emergency profile before requesting protected data.',
                              style: TextStyle(
                                color: MTTokens.onDarkMuted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final action = MTButton(
                    label: 'Tap to Scan',
                    icon: PhosphorIconsRegular.contactlessPayment,
                    variant: MTButtonVariant.accent,
                    onPressed: onScan,
                    expand: constraints.maxWidth < 680,
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [intro, const SizedBox(height: 22), action],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: intro),
                      const SizedBox(width: 26),
                      action,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                const recent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MTSectionHeader(
                      title: 'Recent access',
                      action: MTBadge(
                        label: 'Audit logged',
                        tone: MTBadgeTone.neutral,
                        icon: PhosphorIconsRegular.clock,
                      ),
                    ),
                    SizedBox(height: 12),
                    MTCard(
                      child: Row(
                        children: [
                          MTAvatar(initials: 'AS'),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aanya Sharma',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'MT-4829 Â· Emergency profile',
                                  style: TextStyle(
                                    color: MTTokens.inkMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MTBadge(
                            label: 'Tier 1',
                            tone: MTBadgeTone.success,
                            icon: PhosphorIconsRegular.shieldCheck,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    MTEmptyNote(
                      icon: PhosphorIconsRegular.clock,
                      message: 'No other recent patient access.',
                    ),
                  ],
                );
                const privacy = MTCard(
                  variant: MTCardVariant.orchid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MTIconTile(
                        icon: PhosphorIconsRegular.lockKey,
                        tint: MTTint.orchid,
                      ),
                      SizedBox(height: 18),
                      MTOverline(
                        label: 'Protected access',
                        tone: MTBadgeTone.info,
                        dot: false,
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Tier 2 requires consent',
                        style: MTTokens.headlineMd,
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Request access from the patient or an authorized representative before opening detailed records.',
                        style: TextStyle(
                          color: MTTokens.inkMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth < 720) {
                  return const Column(
                    children: [recent, SizedBox(height: 18), privacy],
                  );
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: recent),
                    SizedBox(width: 18),
                    Expanded(flex: 2, child: privacy),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
