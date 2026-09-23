part of '../../main.dart';

class _AccessPortal extends StatelessWidget {
  const _AccessPortal({required this.onSelect});
  final ValueChanged<AppSurface> onSelect;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: _Page(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            const MTOverline(
              label: 'Emergency information, instantly',
              tone: MTBadgeTone.success,
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: const Text(
                'Medical information, ready when it matters.',
                style: MTTokens.displayXl,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: const Text(
                'One secure MediTag keeps essential medical details available in an emergencyâ€”verified on the device, even without internet.',
                style: TextStyle(
                  color: MTTokens.inkMuted,
                  fontSize: 17,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 34),
            MTCard(
              variant: MTCardVariant.dark,
              padding: const EdgeInsets.all(26),
              onTap: () => onSelect(AppSurface.reader),
              semanticLabel: 'Read a MediTag',
              child: Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: MTTokens.periwinkle,
                      borderRadius: MTTokens.shapeMd,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.contactlessPayment,
                        color: MTTokens.card,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MTOverline(
                          label: 'No sign-in required',
                          tone: MTBadgeTone.info,
                          onDark: true,
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Read a MediTag',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: MTTokens.card,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap for verified emergency access, online or offline.',
                          style: TextStyle(
                            color: MTTokens.onDarkMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const PhosphorIcon(
                    PhosphorIconsRegular.arrowRight,
                    color: MTTokens.card,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _PortalCard(
                    icon: PhosphorIconsRegular.user,
                    tint: MTTint.blue,
                    title: 'Citizen',
                    eyebrow: 'Manage your profile',
                    message:
                        'Keep emergency details and private health history current.',
                    onTap: () => onSelect(AppSurface.citizen),
                  ),
                  _PortalCard(
                    icon: PhosphorIconsRegular.stethoscope,
                    tint: MTTint.orchid,
                    title: 'Doctor',
                    eyebrow: 'Verified access',
                    message:
                        'Open structured patient records with clinician authorization.',
                    onTap: () => onSelect(AppSurface.doctor),
                  ),
                ];
                if (constraints.maxWidth < 680) {
                  return Column(
                    children: [cards[0], const SizedBox(height: 14), cards[1]],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 18),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Signed emergency data only Â· Privacy-first by design',
                style: TextStyle(color: MTTokens.inkMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.eyebrow,
    required this.message,
    required this.onTap,
  });
  final IconData icon;
  final MTTint tint;
  final String title;
  final String eyebrow;
  final String message;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => MTCard(
    variant: MTCardVariant.emphasised,
    onTap: onTap,
    semanticLabel: title,
    child: Row(
      children: [
        MTIconTile(icon: icon, tint: tint),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: MTTokens.labelCaps),
              const SizedBox(height: 4),
              Text(title, style: MTTokens.headlineMd),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(color: MTTokens.inkMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PhosphorIcon(PhosphorIconsRegular.caretRight, color: MTTokens.inkMuted),
      ],
    ),
  );
}
