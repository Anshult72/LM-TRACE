import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../inspections/inspections_controller.dart';

class OnlineListingScreen extends ConsumerStatefulWidget {
  final String? inspectionId;

  const OnlineListingScreen({super.key, this.inspectionId});

  @override
  ConsumerState<OnlineListingScreen> createState() => _OnlineListingScreenState();
}

class _OnlineListingScreenState extends ConsumerState<OnlineListingScreen> {
  final _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _screenshotBytes;
  String? _screenshotName;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _screenshotBytes = bytes;
        _screenshotName = picked.name;
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeListing() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty && _screenshotBytes == null) {
      setState(() {
        _errorMessage = 'Please enter a valid product listing URL or upload a screenshot.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      if (_screenshotBytes != null) {
        // Multi-part screenshot analysis
        final client = ref.read(apiClientProvider);
        final formData = FormData();
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            _screenshotBytes!,
            filename: _screenshotName ?? 'listing_screenshot.png',
            contentType: MediaType('image', 'png'),
          ),
        ));
        if (rawUrl.isNotEmpty) {
          formData.fields.add(MapEntry('url', rawUrl));
        }

        final response = await client.post(
          "${ApiConstants.onlineListings}/analyze",
          data: formData,
        );

        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _analysisResult = response.data as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          throw Exception('Backend returned status code ${response.statusCode}');
        }
      } else {
        // Direct URL fetch and analysis via inspections controller
        final result = await ref.read(inspectionsProvider.notifier).analyzeEcommerceListing(
          url: rawUrl,
          inspectionId: widget.inspectionId,
        );

        setState(() {
          _analysisResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Listing analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      appBar: AppBar(
        title: const Text('E-Commerce Listing Audit (Rule 2027)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statutory Context Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintMist.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inspectionGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_outlined, color: AppColors.inspectionGreen, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Legal Metrology E-Commerce Rules require marketplaces to display all mandatory Rule 6 declarations (MRP, Net Quantity, Expiry, Country of Origin, Manufacturer Address) before checkout.',
                      style: TextStyle(fontSize: 11, color: AppColors.textCharcoal),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Form
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Online Listing Source',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Marketplace Product URL',
                            hintText: 'https://www.amazon.in/dp/... or https://www.flipkart.com/...',
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.paste),
                        tooltip: 'Paste from Clipboard',
                        onPressed: _pasteFromClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      '— OR UPLOAD SCREENSHOT —',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral400),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(_screenshotBytes != null ? 'Screenshot Selected' : 'Upload Listing Screenshot'),
                          onPressed: _pickScreenshot,
                        ),
                      ),
                      if (_screenshotBytes != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.violation),
                          onPressed: () => setState(() => _screenshotBytes = null),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Analyzing Marketplace Listing...' : 'Scan E-Commerce Compliance',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _analyzeListing,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error Display
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.violationBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.violation.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.violation, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.violation, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Analysis Result View
            if (_analysisResult != null) _buildAnalysisView(_analysisResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisView(Map<String, dynamic> res) {
    final status = res['compliance_status'] ?? 'POTENTIAL_VIOLATION';
    final isViolation = status == 'POTENTIAL_VIOLATION' || status == 'VIOLATION';
    final detected = (res['declarations_detected'] as List?) ?? [];
    final missing = (res['declarations_missing'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isViolation ? AppColors.violation : AppColors.compliant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                res['marketplace'] ?? 'Marketplace Listing',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isViolation ? AppColors.violationBg : AppColors.compliantBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isViolation ? AppColors.violation : AppColors.compliant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Missing Declarations Alert
          if (missing.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.violationBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cancel_outlined, size: 16, color: AppColors.violation),
                      SizedBox(width: 6),
                      Text(
                        'Missing Mandatory E-Commerce Declarations:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.violation),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...missing.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 22),
                      child: Text(
                        '• ${m['field']} (${m['statutory_rule'] ?? 'LM Rules 2011'})',
                        style: const TextStyle(fontSize: 11, color: AppColors.neutral800, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Detected Declarations Table
          const Text(
            'Extracted Declarations from Digital Listing:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral700),
          ),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: AppColors.neutral200),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppColors.neutral100),
                children: [
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Declaration Field', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Extracted Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ...detected.map((d) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(d['field'] ?? '', style: const TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(d['value'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        d['status'] ?? 'OK',
                        style: const TextStyle(fontSize: 11, color: AppColors.compliant, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          if (res['advisory_notes'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Statutory Finding: ${res['advisory_notes']}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral700),
              ),
            ),
          ],
          if (res['snapshot_hash'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Snapshot SHA-256: ${res['snapshot_hash']}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.neutral700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
