// lib/screens/view_pdf_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ViewPdfScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const ViewPdfScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<ViewPdfScreen> createState() => _ViewPdfScreenState();
}

class _ViewPdfScreenState extends State<ViewPdfScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    try {
      // 1. Download the file bytes
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filename = 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$filename');

        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            _localFilePath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not load PDF. \n$e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, textAlign: TextAlign.center))
          : SfPdfViewer.file(File(_localFilePath!)),
    );
  }
}