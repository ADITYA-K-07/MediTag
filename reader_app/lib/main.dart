import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'nfc_reader.dart';
import 'tag_verifier.dart';

void main() => runApp(const MediTagApp());

const _brand = Color(0xFF2563EB);
const _brandDark = Color(0xFF1D4ED8);
const _brandSoft = Color(0xFFEAF3FF);
const _allergy = Color(0xFFCC3D58);
const _ink = Color(0xFF1F2937);

class MediTagApp extends StatelessWidget {
  const MediTagApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediTag',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _brand, brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
        home: const LoginPage(),
      );
}

enum AppRole { patient, doctor }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AppRole _role = AppRole.patient;
  bool _hidePassword = true;

  void _continueToDashboard() {
    final destination = _role == AppRole.patient ? const PatientShell() : const DoctorShell();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 40),
                    const Text('Welcome to MediTag', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 8),
                    Text(_role == AppRole.patient ? 'Your medical ID, ready when it matters.' : 'Secure access for verified medical professionals.', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                    const SizedBox(height: 28),
                    SegmentedButton<AppRole>(
                      segments: const [
                        ButtonSegment(value: AppRole.patient, icon: Icon(Icons.person_outline), label: Text('Patient')),
                        ButtonSegment(value: AppRole.doctor, icon: Icon(Icons.medical_services_outlined), label: Text('Doctor')),
                      ],
                      selected: {_role},
                      onSelectionChanged: (value) => setState(() => _role = value.first),
                    ),
                    const SizedBox(height: 24),
                    TextField(keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))),
                    const SizedBox(height: 14),
                    TextField(
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hidePassword = !_hidePassword)),
                      ),
                    ),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _notice(context, 'Password recovery will be connected to the secure account service.'), child: const Text('Forgot password?'))),
                    const SizedBox(height: 6),
                    FilledButton(onPressed: _continueToDashboard, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), child: Text('Continue as ${_role == AppRole.patient ? 'Patient' : 'Doctor'}')),
                    const SizedBox(height: 18),
                    Center(child: TextButton(onPressed: () => _notice(context, 'Patient registration is the next account feature to connect.'), child: const Text('New to MediTag? Create an account'))),
                    const SizedBox(height: 20),
                    const _PrivacyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PatientHome(
        onViewMedicalId: () => setState(() => _tab = 1),
      ),
      const MedicalIdPage(),
      const PatientProfilePage(),
    ];
    return _Shell(
      currentIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'My ID'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
      child: pages[_tab],
    );
  }
}

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [DoctorHome(), ScanTagPage(), PatientLookupPage(), DoctorProfilePage()];
    return _Shell(
      currentIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.nfc), label: 'Scan'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Patients'),
        NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Profile'),
      ],
      child: pages[_tab],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, required this.currentIndex, required this.onDestinationSelected, required this.destinations});
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(selectedIndex: currentIndex, onDestinationSelected: onDestinationSelected, destinations: destinations),
      );
}

class PatientHome extends StatelessWidget {
  const PatientHome({super.key, required this.onViewMedicalId});
  final VoidCallback onViewMedicalId;

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Hello, Aanya',
        subtitle: 'Your emergency medical information is up to date.',
        children: [
          const _StatusCard(icon: Icons.verified_user_outlined, title: 'MediTag is protected', subtitle: 'Your emergency profile is signed and ready for offline verification.', color: Color(0xFF087F5B)),
          const SizedBox(height: 24),
          const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionTile(icon: Icons.badge_outlined, label: 'View medical ID', onTap: onViewMedicalId)),
            const SizedBox(width: 12),
            Expanded(child: _ActionTile(icon: Icons.contact_phone_outlined, label: 'Emergency contacts', onTap: () => _showEmergencyContacts(context))),
          ]),
          const SizedBox(height: 26),
          const Text('Your tag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _InfoCard(title: 'MediTag #1001', subtitle: 'Last profile update: today', leading: Icon(Icons.nfc, color: _brand), trailing: Chip(label: Text('Active'))),
          const SizedBox(height: 26),
          const Text('Health profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _EditableCard(icon: Icons.warning_amber_outlined, title: 'Allergies', value: 'Penicillin, Latex', color: _allergy),
          _EditableCard(icon: Icons.favorite_outline, title: 'Critical conditions', value: 'Diabetes', color: const Color(0xFF8B5CF6)),
          _EditableCard(icon: Icons.medication_outlined, title: 'Medications', value: 'Add medications for clinician access', color: const Color(0xFF0F766E)),
          _EditableCard(icon: Icons.contact_phone_outlined, title: 'Emergency contacts', value: 'Rohan Sharma · +91 98765 43210', color: _brand),
          const SizedBox(height: 12),
          const _StatusCard(icon: Icons.info_outline, title: 'What is stored on your tag?', subtitle: 'Blood type, selected allergies/conditions, one contact number and a signed tag ID. Detailed records remain private online.', color: Color(0xFF1D4ED8)),
          const SizedBox(height: 26),
          const Text('How MediTag helps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const _FeatureRow(icon: Icons.wifi_off_outlined, title: 'Works offline', subtitle: 'Critical information can be verified without internet.'),
          const _FeatureRow(icon: Icons.lock_outline, title: 'Private full record', subtitle: 'Detailed records stay gated to authorized clinicians.'),
        ],
      );
}

class MedicalIdPage extends StatelessWidget {
  const MedicalIdPage({super.key});

  @override
  Widget build(BuildContext context) => _Page(
        title: 'My medical ID',
        subtitle: 'This is what an emergency responder sees after a verified scan.',
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _brandDark, borderRadius: BorderRadius.circular(24)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.verified, color: Colors.white), SizedBox(width: 8), Text('VERIFIED OFFLINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              SizedBox(height: 24), Text('Aanya Sharma', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 16), Text('Blood type', style: TextStyle(color: Color(0xFFDBEAFE))), Text('O−', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              SizedBox(height: 16), Text('Emergency contact', style: TextStyle(color: Color(0xFFDBEAFE))), Text('+91 98765 43210', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 24),
          const _InfoCard(title: 'Allergies', subtitle: 'Penicillin, Latex', leading: Icon(Icons.warning_amber_rounded, color: _allergy)),
          const SizedBox(height: 12),
          const _InfoCard(title: 'Critical conditions', subtitle: 'Diabetes', leading: Icon(Icons.monitor_heart_outlined, color: _brand)),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => _notice(context, 'A shareable emergency-card image can be added after profile syncing.'), icon: const Icon(Icons.share_outlined), label: const Text('Share emergency card')),
        ],
      );
}

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Profile & privacy',
        subtitle: 'Manage your account and data-sharing preferences.',
        children: [
          const _InfoCard(title: 'Aanya Sharma', subtitle: 'aanya@example.com', leading: CircleAvatar(backgroundColor: Color(0xFFDBEAFE), child: Text('AS', style: TextStyle(color: _brand, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 20),
          _MenuRow(icon: Icons.security_outlined, label: 'Privacy & consent', onTap: () => _notice(context, 'Consent controls will decide which clinicians can request Tier 2 records.')),
          _MenuRow(icon: Icons.history_outlined, label: 'Access history', onTap: () => _notice(context, 'This screen will list authorized Tier 2 record access events.')),
          _MenuRow(icon: Icons.help_outline, label: 'Help & support', onTap: () => _notice(context, 'Help centre coming in the next frontend pass.')),
          _MenuRow(icon: Icons.logout, label: 'Sign out', destructive: true, onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false)),
        ],
      );
}

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Good morning, Dr. Mehta',
        subtitle: 'Verified clinician workspace',
        children: [
          const _StatusCard(icon: Icons.verified_outlined, title: 'Clinician access verified', subtitle: 'You can scan a MediTag and request its detailed record when online.', color: Color(0xFF087F5B)),
          const SizedBox(height: 24),
          const Text('Clinical tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ActionTile(icon: Icons.nfc, label: 'Scan emergency tag', onTap: () => _notice(context, 'Open the Scan tab and hold the device near an NTAG213.')),
          const SizedBox(height: 12),
          _ActionTile(icon: Icons.add_card_outlined, label: 'Issue a new MediTag', onTap: () => _notice(context, 'The issuing form is the next UI screen; the backend endpoint is already ready.')),
          const SizedBox(height: 26),
          const Text('Safety workflow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.nfc, title: '1. Scan', subtitle: 'Read the signed emergency payload from the NFC tag.'),
          const _FeatureRow(icon: Icons.verified_user_outlined, title: '2. Verify offline', subtitle: 'The app confirms that the data has not been altered.'),
          const _FeatureRow(icon: Icons.lock_open_outlined, title: '3. Request Tier 2', subtitle: 'Detailed records require authenticated, online authorization.'),
        ],
      );
}

class ScanTagPage extends StatefulWidget {
  const ScanTagPage({super.key});

  @override
  State<ScanTagPage> createState() => _ScanTagPageState();
}

class _ScanTagPageState extends State<ScanTagPage> {
  final _reader = NfcReader();
  bool _scanning = false;
  VerificationResult? _result;
  String? _message;

  // Provision this once from GET /public-key. It is deliberately local so a
  // scan never downloads a key or needs a connection to verify Tier 1.
  static const _provisionedPublicKey = '';

  Future<void> _scan() async {
    if (_provisionedPublicKey.isEmpty) {
      setState(() => _message = 'This demo build needs the issuer public key before it can verify real tags. See reader_app/README.md.');
      return;
    }
    setState(() { _scanning = true; _result = null; _message = 'Hold the phone near the MediTag...'; });
    try {
      final key = TagVerifier.publicKeyFromUncompressed(Uint8List.fromList(base64Decode(_provisionedPublicKey)));
      final result = await TagVerifier(key).verify(await _reader.scanOne());
      if (mounted) setState(() { _result = result; _message = null; });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Scan MediTag',
        subtitle: 'Tier 1 data is verified locally before it is shown.',
        children: [
          Container(
            height: 190,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _brandSoft, borderRadius: BorderRadius.circular(28)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.nfc, size: 72, color: _brand), SizedBox(height: 12), Text('Hold a tag near this device', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17))]),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _scanning ? null : _scan, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), icon: const Icon(Icons.nfc), label: Text(_scanning ? 'Scanning...' : 'Start scan')),
          const SizedBox(height: 18),
          if (_message != null) _StatusCard(icon: Icons.info_outline, title: 'Scan status', subtitle: _message!, color: const Color(0xFF1D4ED8)),
          if (_result != null) _ScanResult(result: _result!),
          const SizedBox(height: 20),
          const _FeatureRow(icon: Icons.wifi_off_outlined, title: 'Offline by design', subtitle: 'A valid signature means emergency data can be trusted without internet.'),
        ],
      );
}

class PatientLookupPage extends StatelessWidget {
  const PatientLookupPage({super.key});

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Patient records',
        subtitle: 'Search is available only after verified clinician sign-in.',
        children: [
          const TextField(decoration: InputDecoration(hintText: 'Search patient name or tag ID', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 24),
          const _StatusCard(icon: Icons.lock_outline, title: 'Consent-protected access', subtitle: 'This list will contain only records you are permitted to access. Emergency Tier 1 data remains available through NFC scan.', color: Color(0xFF1D4ED8)),
          const SizedBox(height: 24),
          const Text('Recent verified scans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _InfoCard(title: 'No verified scans yet', subtitle: 'Scan a MediTag to begin an emergency-record workflow.', leading: Icon(Icons.nfc)),
        ],
      );
}

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) => _Page(
        title: 'Clinician profile',
        subtitle: 'Your identity and access status.',
        children: [
          const _InfoCard(title: 'Dr. Arjun Mehta', subtitle: 'Emergency Medicine · Verified clinician', leading: CircleAvatar(backgroundColor: Color(0xFFDCEAFE), child: Icon(Icons.medical_services, color: Color(0xFF1D4ED8))), trailing: Icon(Icons.verified, color: Color(0xFF087F5B))),
          const SizedBox(height: 20),
          _MenuRow(icon: Icons.badge_outlined, label: 'Professional verification', onTap: () => _notice(context, 'Credential verification will be connected to the production identity provider.')),
          _MenuRow(icon: Icons.history_outlined, label: 'Access audit trail', onTap: () => _notice(context, 'Every Tier 2 access event will be shown here.')),
          _MenuRow(icon: Icons.logout, label: 'Sign out', destructive: true, onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false)),
        ],
      );
}

class _ScanResult extends StatelessWidget {
  const _ScanResult({required this.result});
  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.isVerified) return _StatusCard(icon: Icons.error_outline, title: 'Untrusted tag', subtitle: result.error ?? 'Signature verification failed.', color: const Color(0xFFB42318));
    final data = result.payload!;
    return Card(
      color: const Color(0xFFECFDF3),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.verified, color: Color(0xFF087F5B)), SizedBox(width: 8), Text('VERIFIED OFFLINE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF087F5B)))]),
          const Divider(height: 28),
          _dataRow('Blood type', data.bloodTypeName),
          _dataRow('Allergies', data.allergies.isEmpty ? 'None recorded' : data.allergies.join(', ')),
          _dataRow('Critical conditions', data.conditions.isEmpty ? 'None recorded' : data.conditions.join(', ')),
          _dataRow('Emergency contact', '+91 ${data.emergencyPhone}'),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _notice(context, 'Tier 2 will request online, consent-aware access to this patient record.'), icon: const Icon(Icons.lock_open_outlined), label: const Text('Request full record (Tier 2)')),
        ]),
      ),
    );
  }

  Widget _dataRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('$label\n$value', style: const TextStyle(fontSize: 16)));
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.subtitle, required this.children});
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
          const SizedBox(height: 26),
          ...children,
        ]),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 23, backgroundColor: _brand, child: Icon(Icons.favorite, color: Colors.white)),
        SizedBox(width: 10),
        Text('MediTag', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _ink)),
      ]);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.22))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(height: 1.35))]))]),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, required this.leading, this.trailing});
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), leading: leading, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: trailing));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCEAFE))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _brand), const SizedBox(height: 12), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
        ),
      );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 19, backgroundColor: _brandSoft, child: Icon(icon, color: _brand, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), height: 1.3))]))]),
      );
}

class _EditableCard extends StatelessWidget {
  const _EditableCard({required this.icon, required this.title, required this.value, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(value), trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _notice(context, 'Editing will update the backend record and issue a freshly signed tag payload.'))));
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.destructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: destructive ? const Color(0xFFB42318) : _ink), title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: destructive ? const Color(0xFFB42318) : _ink)), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) => const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lock_outline, size: 18, color: Color(0xFF6B7280)), SizedBox(width: 8), Expanded(child: Text('MediTag stores only emergency data on the tag. Detailed medical information is consent-protected.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.35)))]);
}

void _notice(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

void _showEmergencyContacts(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Emergency contacts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          const Text('The first contact is included in your signed NFC emergency profile.'),
          const SizedBox(height: 18),
          const _InfoCard(title: 'Rohan Sharma', subtitle: '+91 98765 43210 · Primary contact', leading: CircleAvatar(backgroundColor: _brandSoft, child: Icon(Icons.person, color: _brand))),
          const SizedBox(height: 10),
          const _InfoCard(title: 'Meera Sharma', subtitle: '+91 91234 56789 · Secondary contact', leading: CircleAvatar(backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.person, color: Color(0xFF7C3AED)))),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () { Navigator.of(sheetContext).pop(); _notice(context, 'Adding contacts will be connected to your profile service.'); }, icon: const Icon(Icons.add), label: const Text('Add emergency contact')),
        ]),
      ),
    );
