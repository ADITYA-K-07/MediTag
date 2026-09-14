import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';

enum MTCardVariant { plain, flat, emphasised }
enum MTButtonVariant { primary, secondary, text }
enum MTBadgeTone { neutral, info, success, warning, critical, gold }
enum MTVerificationState { verified, invalid }
enum MTTint { navy, orchid, amber, blue, clay, mint }

Color _toneColor(MTBadgeTone tone) => switch (tone) {
      MTBadgeTone.neutral => MTTokens.inkMuted,
      MTBadgeTone.info => MTTokens.periwinkle,
      MTBadgeTone.success => MTTokens.mint,
      MTBadgeTone.warning => MTTokens.clay,
      MTBadgeTone.critical => MTTokens.criticalRed,
      MTBadgeTone.gold => MTTokens.amber,
    };

Color _toneWash(MTBadgeTone tone) => switch (tone) {
      MTBadgeTone.neutral => MTTokens.container,
      MTBadgeTone.info => MTTokens.blueWash,
      MTBadgeTone.success => MTTokens.mintWash,
      MTBadgeTone.warning => MTTokens.clayWash,
      MTBadgeTone.critical => MTTokens.criticalWash,
      MTBadgeTone.gold => MTTokens.amberWash,
    };

class MTFocusRing extends StatefulWidget {
  const MTFocusRing({super.key, required this.child, this.borderRadius = MTTokens.shapeMd});
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<MTFocusRing> createState() => _MTFocusRingState();
}

class _MTFocusRingState extends State<MTFocusRing> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: widget.borderRadius, boxShadow: _focused ? MTTokens.focusGlow : const []),
          child: widget.child,
        ),
      );
}

class MTCard extends StatelessWidget {
  const MTCard({super.key, required this.child, this.variant = MTCardVariant.plain, this.padding = const EdgeInsets.all(20), this.onTap, this.semanticLabel});
  final Widget child;
  final MTCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shadows = switch (variant) { MTCardVariant.plain => MTTokens.level1, MTCardVariant.flat => const <BoxShadow>[], MTCardVariant.emphasised => MTTokens.level2 };
    final content = DecoratedBox(
      decoration: BoxDecoration(color: variant == MTCardVariant.flat ? MTTokens.cardMuted : MTTokens.card, borderRadius: MTTokens.shapeLg, boxShadow: shadows),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return MTFocusRing(
      borderRadius: MTTokens.shapeLg,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(borderRadius: MTTokens.shapeLg, onTap: onTap, child: content),
      ),
    );
  }
}

class MTCardHeader extends StatelessWidget {
  const MTCardHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MTTokens.headlineMd), if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: MTTokens.inkMuted))]])),
        if (trailing case final trailing?) ...[const SizedBox(width: 12), trailing],
      ]);
}

class MTSectionHeader extends StatelessWidget {
  const MTSectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: MTTokens.headlineMd)), if (action != null) action!]);
}

class MTPageHeading extends StatelessWidget {
  const MTPageHeading({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MTTokens.headlineXl), if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: const TextStyle(color: MTTokens.inkMuted, fontSize: 16, height: 1.4))]])),
        if (trailing case final trailing?) ...[const SizedBox(width: 12), trailing],
      ]);
}

class MTButton extends StatelessWidget {
  const MTButton({super.key, required this.label, required this.onPressed, this.icon, this.variant = MTButtonVariant.primary, this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MTButtonVariant variant;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final primary = variant == MTButtonVariant.primary;
    final text = variant == MTButtonVariant.text;
    final button = TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : PhosphorIcon(icon!, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        foregroundColor: primary ? MTTokens.card : MTTokens.inkBrand,
        backgroundColor: primary ? MTTokens.periwinkle : (text ? null : MTTokens.card),
        disabledForegroundColor: MTTokens.inkFaint,
        disabledBackgroundColor: MTTokens.containerHigh,
        shape: const RoundedRectangleBorder(borderRadius: MTTokens.shapeMd),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
    return MTFocusRing(borderRadius: MTTokens.shapeMd, child: expand ? SizedBox(width: double.infinity, child: button) : button);
  }
}

class MTIconButton extends StatelessWidget {
  const MTIconButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => MTFocusRing(
        borderRadius: MTTokens.shapeSm,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: PhosphorIcon(icon, size: 22, color: MTTokens.inkBrand),
          style: IconButton.styleFrom(backgroundColor: MTTokens.card, shape: const RoundedRectangleBorder(borderRadius: MTTokens.shapeSm)),
        ),
      );
}

class MTNavItem {
  const MTNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class MTBottomNav extends StatelessWidget {
  const MTBottomNav({super.key, required this.currentIndex, required this.items, required this.onChanged});
  final int currentIndex;
  final List<MTNavItem> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: MTTokens.card, boxShadow: MTTokens.level2),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onChanged,
          backgroundColor: MTTokens.card,
          indicatorColor: MTTokens.blueWash,
          labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: MTTokens.inkBrand, fontWeight: FontWeight.w700, fontSize: 12)),
          destinations: [for (final item in items) NavigationDestination(icon: PhosphorIcon(item.icon, color: MTTokens.inkMuted), selectedIcon: PhosphorIcon(item.icon, color: MTTokens.periwinkle), label: item.label)],
        ),
      );
}

class MTBadge extends StatelessWidget {
  const MTBadge({super.key, required this.label, required this.tone, this.icon});
  final String label;
  final MTBadgeTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _toneWash(tone), borderRadius: MTTokens.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[PhosphorIcon(icon!, size: 16, color: _toneColor(tone)), const SizedBox(width: 5)], Text(label, style: TextStyle(color: _toneColor(tone), fontSize: 12, fontWeight: FontWeight.w700))]),
          ),
        ),
      );
}

class MTVerificationBanner extends StatelessWidget {
  const MTVerificationBanner({super.key, required this.state, this.detail});
  final MTVerificationState state;
  final String? detail;
  @override
  Widget build(BuildContext context) {
    final valid = state == MTVerificationState.verified;
    final tone = valid ? MTBadgeTone.success : MTBadgeTone.critical;
    final title = valid ? 'Verified offline' : 'Signature invalid — do not trust this tag';
    return Semantics(
      liveRegion: !valid,
      label: valid ? 'Verified offline' : 'Urgent: signature invalid. Do not trust this tag.',
      child: MTCard(
        variant: MTCardVariant.emphasised,
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DecoratedBox(decoration: BoxDecoration(color: _toneWash(tone), shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(10), child: PhosphorIcon(valid ? PhosphorIconsRegular.shieldCheck : PhosphorIconsRegular.warningOctagon, color: _toneColor(tone), size: 24))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: _toneColor(tone), fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 4), Text(detail ?? (valid ? 'This emergency information matches its issuer signature.' : "This tag's data doesn't match its signature — it may have been altered."), style: const TextStyle(color: MTTokens.ink, height: 1.35))])),
        ]),
      ),
    );
  }
}

class MTTag extends StatelessWidget {
  const MTTag({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: MTTokens.monoData);
}

class MTStatTile extends StatelessWidget {
  const MTStatTile({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => MTCard(child: Row(children: [DecoratedBox(decoration: const BoxDecoration(color: MTTokens.blueWash, borderRadius: MTTokens.shapeMd), child: Padding(padding: const EdgeInsets.all(13), child: PhosphorIcon(icon, color: MTTokens.periwinkle, size: 24))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: MTTokens.labelCaps), const SizedBox(height: 2), Text(value, style: MTTokens.statNumber)]))]));
}

class MTTintTile extends StatelessWidget {
  const MTTintTile({super.key, required this.tint, required this.icon, required this.label, this.critical = false});
  final MTTint tint;
  final IconData icon;
  final String label;
  final bool critical;
  Color get _wash => switch (tint) { MTTint.navy => MTTokens.navyWash, MTTint.orchid => MTTokens.orchidWash, MTTint.amber => MTTokens.amberWash, MTTint.blue => MTTokens.blueWash, MTTint.clay => MTTokens.clayWash, MTTint.mint => MTTokens.mintWash };
  @override
  Widget build(BuildContext context) => Semantics(
        label: '${critical ? 'Severe: ' : ''}$label',
        child: DecoratedBox(decoration: BoxDecoration(color: critical ? _toneWash(MTBadgeTone.critical) : _wash, borderRadius: MTTokens.shapeMd), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), child: Row(mainAxisSize: MainAxisSize.min, children: [PhosphorIcon(icon, size: 19, color: critical ? MTTokens.criticalRed : MTTokens.inkBrand), const SizedBox(width: 8), Flexible(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: critical ? MTTokens.criticalRed : MTTokens.inkBrand)))]))),
      );
}

class MTTierLockCard extends StatelessWidget {
  const MTTierLockCard({super.key, required this.reason, this.onRetry});
  final String reason;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => MTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [DecoratedBox(decoration: const BoxDecoration(color: MTTokens.orchidWash, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(10), child: PhosphorIcon(PhosphorIconsRegular.lockKey, color: MTTokens.orchid))), const SizedBox(width: 12), Expanded(child: Text('More information is protected', style: MTTokens.headlineMd))]), const SizedBox(height: 12), Text(reason, style: const TextStyle(color: MTTokens.inkMuted, height: 1.4)), if (onRetry != null) ...[const SizedBox(height: 16), MTButton(label: 'Try again', icon: PhosphorIconsRegular.arrowClockwise, onPressed: onRetry)] ]));
}

class MTEmptyState extends StatelessWidget {
  const MTEmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [DecoratedBox(decoration: const BoxDecoration(color: MTTokens.containerHigh, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(22), child: PhosphorIcon(icon, color: MTTokens.periwinkle, size: 30))), const SizedBox(height: 18), Text(title, style: MTTokens.headlineLg, textAlign: TextAlign.center), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MTTokens.inkMuted, height: 1.4)), if (action != null) ...[const SizedBox(height: 20), action!]])));
}

class MTEmptyNote extends StatelessWidget {
  const MTEmptyNote({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => MTCard(variant: MTCardVariant.flat, child: Row(children: [PhosphorIcon(icon, color: MTTokens.inkMuted), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: MTTokens.inkMuted)))]));
}

class MTSkeleton extends StatelessWidget {
  const MTSkeleton({super.key, this.height = 88});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(label: 'Loading full record', child: MTCard(variant: MTCardVariant.flat, child: SizedBox(height: height, width: double.infinity)));
}

class MTToggle extends StatelessWidget {
  const MTToggle({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Switch(value: value, onChanged: onChanged, activeTrackColor: MTTokens.periwinkle)]);
}

class MTSelect<T> extends StatelessWidget {
  const MTSelect({super.key, required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: MTTokens.labelCaps), const SizedBox(height: 7), DecoratedBox(decoration: const BoxDecoration(color: MTTokens.cardMuted, borderRadius: MTTokens.shapeMd), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: DropdownButton<T>(value: value, isExpanded: true, underline: const SizedBox.shrink(), items: items, onChanged: onChanged)))]);
}

class MTTextField extends StatelessWidget {
  const MTTextField({super.key, required this.label, this.controller, this.keyboardType, this.validator, this.hint, this.obscureText = false});
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hint;
  final bool obscureText;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: MTTokens.labelCaps),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: MTTokens.cardMuted,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: const OutlineInputBorder(borderRadius: MTTokens.shapeMd, borderSide: BorderSide.none),
              enabledBorder: const OutlineInputBorder(borderRadius: MTTokens.shapeMd, borderSide: BorderSide.none),
              focusedBorder: const OutlineInputBorder(borderRadius: MTTokens.shapeMd, borderSide: BorderSide(color: MTTokens.periwinkle, width: 2)),
            ),
          ),
        ],
      );
}

class MTModal {
  static Future<T?> show<T>({required BuildContext context, required Widget child}) => showDialog<T>(context: context, builder: (_) => Dialog(backgroundColor: MTTokens.card, elevation: 0, shape: const RoundedRectangleBorder(borderRadius: MTTokens.shapeXl), child: DecoratedBox(decoration: const BoxDecoration(borderRadius: MTTokens.shapeXl, boxShadow: MTTokens.level3), child: Padding(padding: const EdgeInsets.all(24), child: child))));
}

class MTEnter extends StatelessWidget {
  const MTEnter({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.08), end: Offset.zero),
      duration: reduced ? Duration.zero : MTTokens.medium + Duration(milliseconds: (index.clamp(0, 5)) * 60),
      curve: MTTokens.curve,
      child: child,
      builder: (_, value, child) => FractionalTranslation(translation: value, child: child),
    );
  }
}
