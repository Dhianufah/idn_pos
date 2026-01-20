import 'package:flutter/material.dart';

class QrResultModal extends StatefulWidget {
  final String qrData;
  final int total;
  final bool isPrinting;
  final VoidCallback onPrint;

  const QrResultModal({super.key, required this.qrData, required this.total, required this.isPrinting, required this.onPrint});

  @override
  State<QrResultModal> createState() => _QrResultModalState();
}

class _QrResultModalState extends State<QrResultModal> {
  // variable unutuk menyimpan status pencetakan
  late bool _printFinished;

  @override
  void initState() {
    super.initState();
    // awalnya, anggap proses print belum selesai
    _printFinished = false;

    // jika mode mecetak(printer nyala), kita buat simulasi loading
    if (widget.isPrinting) {
      Future.delayed(Duration(seconds: 2), () {
        // mengecek jika proses delay sesuai dengan waktu yang dibutuhkan printer ketika mencetak
        if (mounted) {
          // mounted adalah kondisi ketika widget nya aktif
          setState(() {
            _printFinished = true; //ubah status jadi selesai

          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // menentukan warna dan text berdasarkan status
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;

    if (!widget.isPrinting) {
      // kondisi 1: printer mati/mode tanpa printer
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
      statusIcon = Icons.print_disabled;
      statusText = "Mode Tanpa Printer";

    } else if (!_printFinished) {
        // kondisi 2: ketika sedang proses mencetak struk
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
      statusIcon = Icons.print;
      statusText = "Mencetak Struk Fisik...";

    } else {
        // kondisi 3: ketika sudah selesai mencetak struk
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle;
      statusText = "Cetak Selesai";
    };

    return const Placeholder();
  }
}