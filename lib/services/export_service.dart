import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import '../providers/credit_provider.dart';
import '../models/person.dart';

class ExportService {
  static Future<void> exportToPdf(FinanceProvider provider) async {
    final pdf = pw.Document();

    final imageByteData = await rootBundle.load('assets/images/logo.jpeg');
    final imageBytes = imageByteData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Masroufi',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Rapport Financier',
                        style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Date: ${DateTime.now().toString().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Image(logoImage, width: 80, height: 80),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Revenus',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${provider.totalIncome.toStringAsFixed(2)} MAD',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Dépenses',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${provider.totalExpense.toStringAsFixed(2)} MAD',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Solde',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${provider.totalBalance.toStringAsFixed(2)} MAD',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Transactions Récentes:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Date', 'Catégorie', 'Type', 'Montant'],
                data: provider.transactions.map((t) {
                  final cat = provider.categories.firstWhere(
                    (c) => c.id == t.categoryId,
                    orElse: () => throw Exception('Cat introuvable'),
                  );
                  return [
                    t.date.toString().substring(0, 10),
                    cat.name,
                    t.isExpense ? 'Dépense' : 'Revenu',
                    '${t.amount.toStringAsFixed(2)} MAD',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Save and share
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rapport_masroufi.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Voici mon rapport financier Masroufi.');
  }

  static Future<void> exportToExcel(FinanceProvider provider) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    excel.setDefaultSheet('Transactions');

    // Title
    sheet.merge(
      CellIndex.indexByString("A1"),
      CellIndex.indexByString("E1"),
      customValue: TextCellValue('Masroufi - Rapport Financier'),
    );
    var cell = sheet.cell(CellIndex.indexByString("A1"));
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Add space
    sheet.appendRow([TextCellValue('')]);

    // Headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Catégorie'),
      TextCellValue('Type'),
      TextCellValue('Note'),
      TextCellValue('Montant (MAD)'),
    ]);

    // Data
    for (var t in provider.transactions) {
      final cat = provider.categories.firstWhere((c) => c.id == t.categoryId);
      sheet.appendRow([
        TextCellValue(t.date.toString().substring(0, 10)),
        TextCellValue(cat.name),
        TextCellValue(t.isExpense ? 'Dépense' : 'Revenu'),
        TextCellValue(t.note),
        DoubleCellValue(t.amount),
      ]);
    }

    final bytes = excel.encode()!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rapport_masroufi.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Voici mon rapport financier Excel Masroufi.');
  }

  static Future<void> exportCarnetToPdf(
    BuildContext context, 
    CreditProvider provider, 
    bool isClientView
  ) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final imageByteData = await rootBundle.load('assets/images/logo.jpeg');
    final imageBytes = imageByteData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(imageBytes);

    final String title = isClientView ? 'clients'.tr() : 'suppliers'.tr();
    final String dateStr = 'date_of_statement'.tr(args: [DateFormat('dd/MM/yyyy').format(DateTime.now())]);
    
    // Filter persons
    final persons = provider.persons.where((p) => p.isClient == isClientView).toList();
    
    // Calculate total balance
    double totalBalance = 0;
    for (var p in persons) {
      totalBalance += provider.getPersonBalance(p.id);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Masroufi - ${'carnet'.tr()}',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        dateStr,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Image(logoImage, width: 60, height: 60),
                ],
              ),
              pw.SizedBox(height: 20),
              // Total box
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'total_balance'.tr(),
                      style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      '${totalBalance.toStringAsFixed(2)} DH',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: totalBalance >= 0 ? PdfColors.green600 : PdfColors.red600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'name'.tr(), 
                  'phone'.tr(), 
                  'balance'.tr()
                ],
                data: persons.map((p) {
                  final balance = provider.getPersonBalance(p.id);
                  return [
                    p.name,
                    p.phone,
                    '${balance.toStringAsFixed(2)} DH',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = isClientView ? 'Carnet_Clients.pdf' : 'Carnet_Fournisseurs.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Voici le rapport du carnet ($title).');
  }
}
