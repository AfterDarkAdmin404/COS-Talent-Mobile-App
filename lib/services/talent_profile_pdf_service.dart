import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job_posting.dart' show engagementTypeLabels;
import '../models/talent_profile.dart';

const _navy = PdfColor.fromInt(0xFF0B2545);
const _muted = PdfColor.fromInt(0xFF475569);
const _border = PdfColor.fromInt(0xFFE2E8F0);

/// Renders the candidate's own profile -- every Tier 1 and Tier 2 field on
/// [TalentProfile] -- as a PDF, and hands it to the OS share sheet. Backs
/// the "Download my data" row in `account_screen.dart`; there's no
/// server-side export endpoint, this composes the document on-device from
/// whatever the signed-in candidate already has loaded.
class TalentProfilePdfService {
  TalentProfilePdfService._();

  static Future<void> downloadAndShare(TalentProfile profile, {String? email}) async {
    final bytes = await _build(profile, email: email);
    final name = profile.firstName.trim().isEmpty ? 'profile' : profile.firstName.trim().toLowerCase();
    await Printing.sharePdf(bytes: bytes, filename: 'cos-talent-profile-$name.pdf');
  }

  static Future<Uint8List> _build(TalentProfile profile, {String? email}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        build: (context) => [
          _header(profile, email),
          pw.SizedBox(height: 18),
          if ((profile.summary ?? '').trim().isNotEmpty) ...[
            _sectionTitle('Summary'),
            pw.Text(profile.summary!.trim(), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2)),
            pw.SizedBox(height: 14),
          ],
          _sectionTitle('Overview'),
          _kv('Rate', profile.rateLabel),
          _kv('Availability', profile.availability.label),
          if (profile.engagementTypes.isNotEmpty)
            _kv('Engagement types', profile.engagementTypes.map((t) => engagementTypeLabels[t] ?? t).join(', ')),
          if (profile.categories.isNotEmpty) _kv('Categories', profile.categories.map((c) => c.name).join(', ')),
          if (profile.skills.isNotEmpty) _kv('Skills', profile.skills.map((s) => s.name).join(', ')),
          pw.SizedBox(height: 14),
          if (profile.workHistory.isNotEmpty) ...[
            _sectionTitle('Work history'),
            for (final w in profile.workHistory) _workHistoryItem(w),
            pw.SizedBox(height: 4),
          ],
          if (profile.education.isNotEmpty) ...[
            _sectionTitle('Education'),
            for (final e in profile.education) _educationItem(e),
            pw.SizedBox(height: 4),
          ],
          if (profile.certifications.isNotEmpty) ...[
            _sectionTitle('Certifications'),
            for (final c in profile.certifications) _certificationItem(c),
            pw.SizedBox(height: 4),
          ],
          if (profile.links.isNotEmpty) ...[
            _sectionTitle('Links'),
            for (final l in profile.links) _kv(l.kind.label, l.url),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(TalentProfile profile, String? email) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          profile.displayName.trim().isEmpty ? 'Talent profile' : profile.displayName,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy),
        ),
        if (profile.professionalTitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(profile.professionalTitle, style: const pw.TextStyle(fontSize: 13, color: _muted)),
        ],
        pw.SizedBox(height: 6),
        pw.Text(
          [
            if (profile.city != null && profile.city!.trim().isNotEmpty) profile.city!.trim(),
            profile.countryName,
            ?email,
            '${profile.yearsExperience} yr${profile.yearsExperience == 1 ? '' : 's'} experience',
            '${profile.englishLevel.label} English',
          ].join('  ·  '),
          style: const pw.TextStyle(fontSize: 9.5, color: _muted),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _border, thickness: 1),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(title, style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: _navy)),
  );

  static pw.Widget _kv(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );

  static pw.Widget _workHistoryItem(WorkHistoryEntry w) {
    final dates = '${formatMonthYear(w.startedOn)} – ${w.isCurrent ? 'Present' : (w.endedOn != null ? formatMonthYear(w.endedOn!) : '')}';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${w.jobTitle} — ${w.companyName}', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
          pw.Text(dates, style: const pw.TextStyle(fontSize: 9, color: _muted)),
          if ((w.description ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(w.description!.trim(), style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.5)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _educationItem(TalentEducationEntry e) {
    final years = [
      if (e.startedYear != null) e.startedYear.toString(),
      if (e.completedYear != null) e.completedYear.toString(),
    ].join(' – ');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${e.level.label} — ${e.institution}',
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            [if ((e.fieldOfStudy ?? '').trim().isNotEmpty) e.fieldOfStudy!.trim(), if (years.isNotEmpty) years].join('  ·  '),
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _certificationItem(CertificationEntry c) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(c.name, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            [
              if ((c.issuer ?? '').trim().isNotEmpty) c.issuer!.trim(),
              if (c.issuedOn != null) formatMonthYear(c.issuedOn!),
              if ((c.credentialUrl ?? '').trim().isNotEmpty) c.credentialUrl!.trim(),
            ].join('  ·  '),
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }
}
