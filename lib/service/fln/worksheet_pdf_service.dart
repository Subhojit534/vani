import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:speech_translator/models/fln_models.dart';

class WorksheetPdfService {
  /// Generates a high-quality PDF document of the given BilingualWorksheet
  static Future<pw.Document> generatePdf(
    BilingualWorksheet worksheet, {
    bool includeAnswerKey = false,
  }) async {
    final pdf = pw.Document();

    // Load fonts for Devanagari and Ol Chiki scripts
    pw.Font fontDevaRegular;
    pw.Font fontDevaBold;
    pw.Font fontOlRegular;
    pw.Font fontOlBold;

    try {
      final devaRegBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final devaBoldBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      final olRegBytes = await rootBundle.load('assets/fonts/NotoSansOlChiki-Regular.ttf');
      final olBoldBytes = await rootBundle.load('assets/fonts/NotoSansOlChiki-Bold.ttf');

      fontDevaRegular = pw.Font.ttf(devaRegBytes);
      fontDevaBold = pw.Font.ttf(devaBoldBytes);
      fontOlRegular = pw.Font.ttf(olRegBytes);
      fontOlBold = pw.Font.ttf(olBoldBytes);
    } catch (_) {
      // Fallback to standard PDF fonts if asset loading is unavailable in test runner
      fontDevaRegular = pw.Font.helvetica();
      fontDevaBold = pw.Font.helveticaBold();
      fontOlRegular = pw.Font.helvetica();
      fontOlBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: fontDevaRegular,
      bold: fontDevaBold,
      fontFallback: [
        fontOlRegular,
        fontOlBold,
        fontDevaRegular,
        fontDevaBold,
        pw.Font.helvetica(),
        pw.Font.helveticaBold(),
      ],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        header: (context) => _buildHeader(worksheet, fontDevaBold, fontOlBold),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInstructions(worksheet, fontDevaRegular, fontOlRegular),
          pw.SizedBox(height: 12),
          ...worksheet.items.map((item) => _buildWorksheetItem(item, fontDevaBold, fontDevaRegular, fontOlRegular)),
          if (includeAnswerKey) ...[
            pw.SizedBox(height: 16),
            _buildAnswerKeySection(worksheet, fontDevaBold, fontDevaRegular),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Downloads or opens the system Print / PDF Save sheet directly.
  /// If running in an active session where native plugin channel isn't hot-reloaded yet,
  /// it gracefully falls back to direct device file storage.
  static Future<String> downloadOrPrintPdf(
    BilingualWorksheet worksheet, {
    bool includeAnswerKey = false,
  }) async {
    final pdf = await generatePdf(worksheet, includeAnswerKey: includeAnswerKey);
    final bytes = await pdf.save();
    final fileName = 'Worksheet_${worksheet.competencyCode}_${worksheet.grade.shortLabel}.pdf';

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      return "PDF तैयार और शेयर/प्रिंट किया गया!";
    } on MissingPluginException {
      // Fallback: Save directly to application documents or downloads storage
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {
        dir = null;
      }
      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return "PDF फाइल सुरक्षित सहेजी गई: ${file.path}";
    }
  }

  static pw.Widget _buildHeader(BilingualWorksheet ws, pw.Font boldDeva, pw.Font boldOl) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            "JHARKHAND PALASH MTB-MLE & NIPUN BHARAT",
            style: pw.TextStyle(font: boldDeva, fontSize: 11, color: PdfColors.indigo900, letterSpacing: 1.0),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            ws.titleHindi,
            style: pw.TextStyle(font: boldDeva, fontSize: 14, color: PdfColors.black),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            ws.titleSantali,
            style: pw.TextStyle(font: boldOl, fontSize: 13, color: PdfColors.indigo800),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("कक्षा (Grade): ${ws.grade.label}", style: const pw.TextStyle(fontSize: 10)),
              pw.Text("दक्षता कोड: ${ws.competencyCode}", style: const pw.TextStyle(fontSize: 10)),
              pw.Text("दिनांक: ______________", style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("विद्यार्थी का नाम: _________________________________", style: const pw.TextStyle(fontSize: 10)),
              pw.Text("रोल नं: ______________", style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInstructions(BilingualWorksheet ws, pw.Font regDeva, pw.Font regOl) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.amber200, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "निर्देश (Hindi): ${ws.instructionsHindi}",
            style: pw.TextStyle(font: regDeva, fontSize: 9.5, color: PdfColors.brown900),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            "ᱫᱤᱥᱟᱹ (Santali): ${ws.instructionsSantali}",
            style: pw.TextStyle(font: regOl, fontSize: 9.5, color: PdfColors.indigo900),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorksheetItem(
    BilingualWorksheetItem item,
    pw.Font boldDeva,
    pw.Font regDeva,
    pw.Font regOl,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "प्र. ${item.itemNumber}. ${item.promptHindi}",
            style: pw.TextStyle(font: boldDeva, fontSize: 11),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            item.promptSantali,
            style: pw.TextStyle(font: regOl, fontSize: 10.5, color: PdfColors.indigo900),
          ),
          if (item.stimulusText.isNotEmpty || item.countQuantity != null) ...[
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                if (item.countQuantity != null)
                  pw.Text(
                    "वस्तुएं: ${' ★ ' * item.countQuantity!}",
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.amber900),
                  ),
                if (item.stimulusText.isNotEmpty)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(left: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      "[ ${item.stimulusText} ]",
                      style: pw.TextStyle(font: boldDeva, fontSize: 11, color: PdfColors.indigo900),
                    ),
                  ),
              ],
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            children: item.options.map((opt) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
                ),
                child: pw.Text(
                  opt,
                  style: pw.TextStyle(font: regOl, fontSize: 10.5),
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "उत्तर: [                 ]",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAnswerKeySection(BilingualWorksheet ws, pw.Font boldDeva, pw.Font regDeva) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.green300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "शिक्षक उत्तर कुंजी (Teacher Answer Key):",
            style: pw.TextStyle(font: boldDeva, fontSize: 11, color: PdfColors.green900),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 16,
            runSpacing: 4,
            children: ws.items.map((item) {
              return pw.Text(
                "प्र. ${item.itemNumber}: ${item.correctAnswer}",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.green900),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "झारखंड प्राथमिक संथाली शिक्षण साथी - निपुण भारत कार्यपत्रक",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            "Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
