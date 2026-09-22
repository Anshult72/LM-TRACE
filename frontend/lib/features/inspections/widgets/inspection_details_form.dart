import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../inspections_controller.dart';

class InspectionFormData {
  final String location;
  final String? sellerName;
  final String businessName;
  final String productCategory;
  final String inspectionType;
  final String packageType;
  final String packageConstructionType;
  final Map<String, dynamic> applicabilityContext;
  final String? notes;
  final String? listingUrl;
  final String? canonicalUrl;
  final String? marketplace;
  final Map<String, dynamic>? listingMetadata;

  const InspectionFormData({
    required this.location,
    this.sellerName,
    required this.businessName,
    required this.productCategory,
    required this.inspectionType,
    required this.packageType,
    required this.packageConstructionType,
    required this.applicabilityContext,
    this.notes,
    this.listingUrl,
    this.canonicalUrl,
    this.marketplace,
    this.listingMetadata,
  });

  Map<String, dynamic> toMap() => {
    'location': location,
    'seller_name': sellerName,
    'business_name': businessName,
    'product_category': productCategory,
    'inspection_type': inspectionType,
    'package_type': packageType,
    'package_construction_type': packageConstructionType,
    'applicability_context': applicabilityContext,
    'notes': notes,
    if (listingUrl != null) 'listing_url': listingUrl,
    if (canonicalUrl != null) 'canonical_url': canonicalUrl,
    if (marketplace != null) 'marketplace': marketplace,
    if (listingMetadata != null) 'listing_metadata': listingMetadata,
  };
}

class InspectionDetailsForm extends ConsumerStatefulWidget {
  final InspectionModel? initialInspection;
  final bool isFinalizing;
  final Future<void> Function(InspectionFormData data) onSubmit;
  final bool isLoading;
  final String? submitButtonLabel;

  const InspectionDetailsForm({
    super.key,
    this.initialInspection,
    this.isFinalizing = false,
    required this.onSubmit,
    this.isLoading = false,
    this.submitButtonLabel,
  });

  @override
  ConsumerState<InspectionDetailsForm> createState() => _InspectionDetailsFormState();
}

class _InspectionDetailsFormState extends ConsumerState<InspectionDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  // Physical Form Controllers
  late final TextEditingController _locationController;
  late final TextEditingController _businessController;
  late final TextEditingController _sellerController;
  late final TextEditingController _notesController;

  // E-Commerce Listing Controllers & State
  late final TextEditingController _urlController;
  bool _isFetchingListing = false;
  bool _isAnalyzingListing = false;
  Map<String, dynamic>? _fetchResult;
  Map<String, dynamic>? _analysisResult;
  String _selectedMarketplace = 'Auto-Detect';

  late String _inspectionType;
  late String _category;
  late String _constructionType;
  late String _packageType;
  late String _marketScope;
  late String _originType;
  late String _packerApplicability;
  late String _shelfLifeApplicability;
  late String _dimensionsApplicability;
  late String _unitSalePriceApplicability;
  late bool _isMultiPiecePackage;
  late bool _electronicDeclarationsViaQr;
  late bool _hasOuterWrapper;
  late bool _outerWrapperTransparent;
  late bool _declarationReadThroughLiquid;

  final List<String> _categories = [
    'Packaged Food',
    'Edible Oils & Fats',
    'Beverages & Juices',
    'Cosmetics & Toiletries',
    'Soaps & Detergents',
    'Baby Food & Milk Powder',
    'General Merchandise',
  ];

  final List<String> _marketplaces = [
    'Auto-Detect',
    'Amazon India',
    'Flipkart',
    'Blinkit',
    'Zepto',
    'Swiggy Instamart',
    'BigBasket',
    'JioMart',
    'Other / Independent Store'
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialInspection;

    String initialLoc = '';
    if (init != null) {
      if (init.location.isNotEmpty && !init.location.contains('Pending Finalisation')) {
        initialLoc = init.location;
      }
    }

    String initialBiz = '';
    if (init != null) {
      initialBiz = init.businessName ?? '';
    }

    String initialSeller = '';
    if (init != null) {
      initialSeller = init.sellerName ?? '';
    }

    String initialNotes = '';
    if (init != null && init.notes != null) {
      initialNotes = init.notes!.replaceAll(RegExp(r'\[DIRECT_SCAN\]\s*'), '');
    }

    _locationController = TextEditingController(text: initialLoc);
    _businessController = TextEditingController(text: initialBiz);
    _sellerController = TextEditingController(text: initialSeller);
    _notesController = TextEditingController(text: initialNotes);
    _urlController = TextEditingController(text: init?.listingUrl ?? '');

    _inspectionType = init?.inspectionType ?? 'PHYSICAL';
    final rawCat = init?.productCategory;
    _category = (rawCat != null && _categories.contains(rawCat)) ? rawCat : 'Packaged Food';
    _constructionType = init?.packageConstructionType ?? 'NORMAL';
    _packageType = init?.packageType ?? 'RECTANGULAR';
    _selectedMarketplace = init?.marketplace ?? 'Auto-Detect';
    _fetchResult = init?.listingMetadata;

    final applicability = init?.applicabilityContext ?? const <String, dynamic>{};
    _marketScope = (applicability['market_scope'] ?? 'RETAIL').toString();
    _originType = (applicability['origin_type'] ?? 'UNKNOWN').toString();
    String triState(dynamic value) => value is bool ? (value ? 'YES' : 'NO') : 'AUTO';
    _packerApplicability = triState(applicability['is_packer_distinct']);
    _shelfLifeApplicability = triState(applicability['shelf_life_declaration_required']);
    _dimensionsApplicability = triState(applicability['dimensions_declaration_required']);
    _unitSalePriceApplicability = triState(applicability['unit_sale_price_required']);
    _isMultiPiecePackage = applicability['is_multi_piece_package'] == true;
    _electronicDeclarationsViaQr = applicability['electronic_declarations_via_qr'] == true;
    _hasOuterWrapper = applicability['has_outer_wrapper'] == true;
    _outerWrapperTransparent = applicability['outer_wrapper_transparent'] == true;
    _declarationReadThroughLiquid = applicability['declaration_read_through_liquid'] == true;

    // Prefill from detected manufacturer if empty
    if (initialBiz.isEmpty && init != null && init.declarations.isNotEmpty) {
      for (final dec in init.declarations) {
        if (dec is Map) {
          final fn = (dec['field_name'] ?? '').toString().toLowerCase();
          final val = (dec['verified_value'] ?? dec['ai_value'] ?? '').toString();
          if ((fn.contains('manufacturer') || fn.contains('brand') || fn.contains('packer')) && val.isNotEmpty) {
            _businessController.text = val;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _businessController.dispose();
    _sellerController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool? _triStateValue(String raw) {
    if (raw == 'YES') return true;
    if (raw == 'NO') return false;
    return null;
  }

  Future<void> _handleFetchListing() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid product listing URL.'),
          backgroundColor: AppColors.violation,
        ),
      );
      return;
    }

    setState(() {
      _isFetchingListing = true;
      _analysisResult = null;
    });

    try {
      final controller = ref.read(inspectionsProvider.notifier);
      final result = await controller.fetchEcommerceListing(url, inspectionId: widget.initialInspection?.id);
      if (mounted) {
        setState(() {
          _isFetchingListing = false;
          if (result != null) {
            _fetchResult = result;
            if (result['marketplace'] != null) {
              _selectedMarketplace = result['marketplace'].toString();
            }
            if (result['seller'] != null && result['seller'].toString().isNotEmpty) {
              _sellerController.text = result['seller'].toString();
            }
            if (result['product_title'] != null && result['product_title'].toString().isNotEmpty) {
              _businessController.text = (result['seller'] ?? result['brand'] ?? result['product_title']).toString();
            }
          }
        });

        if (result != null) {
          final status = result['fetch_status'] ?? 'RETRIEVED';
          final isPartial = status == 'PARTIAL';
          final isBlocked = status == 'BLOCKED' || status == 'LOGIN_REQUIRED';
          final isFailed = status == 'FAILED' || status == 'TIMEOUT';

          Color snackColor = AppColors.compliant;
          String msg = 'Listing fetched successfully (${result['marketplace'] ?? 'Online Platform'}).';
          if (isPartial) {
            snackColor = AppColors.warning;
            msg = 'Listing fetched. Some mandatory digital declarations were not detected.';
          } else if (isBlocked) {
            snackColor = AppColors.warning;
            msg = result['error_message'] ?? 'Listing access requires interactive verification.';
          } else if (isFailed) {
            snackColor = AppColors.violation;
            msg = result['error_message'] ?? 'Unable to fetch listing URL.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: snackColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingListing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching listing: $e'), backgroundColor: AppColors.violation),
        );
      }
    }
  }

  Future<void> _handleRunAnalysis() async {
    final url = _urlController.text.trim();
    setState(() => _isAnalyzingListing = true);

    try {
      final controller = ref.read(inspectionsProvider.notifier);
      final result = await controller.analyzeEcommerceListing(
        url: url.isNotEmpty ? url : null,
        inspectionId: widget.initialInspection?.id,
        extractedData: _fetchResult?['declarations'] as Map<String, dynamic>?,
      );

      if (mounted) {
        setState(() {
          _isAnalyzingListing = false;
          _analysisResult = result;
        });

        if (result != null) {
          final assess = result['assessment'] as Map<String, dynamic>?;
          final overall = assess?['overall_status'] ?? 'REVIEW';
          final score = assess?['score'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statutory evaluation complete: $overall ($score%)'),
              backgroundColor: overall == 'PASS' ? AppColors.compliant : (overall == 'REVIEW' ? AppColors.warning : AppColors.violation),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingListing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation error: $e'), backgroundColor: AppColors.violation),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_inspectionType == 'PHYSICAL') {
      if (!_formKey.currentState!.validate()) return;
      final data = InspectionFormData(
        location: _locationController.text.trim(),
        sellerName: _sellerController.text.trim().isEmpty ? null : _sellerController.text.trim(),
        businessName: _businessController.text.trim(),
        productCategory: _category,
        inspectionType: _inspectionType,
        packageType: _packageType,
        packageConstructionType: _constructionType,
        applicabilityContext: {
          'market_scope': _marketScope,
          'origin_type': _originType,
          'is_packer_distinct': _triStateValue(_packerApplicability),
          'shelf_life_declaration_required': _triStateValue(_shelfLifeApplicability),
          'dimensions_declaration_required': _triStateValue(_dimensionsApplicability),
          'unit_sale_price_required': _triStateValue(_unitSalePriceApplicability),
          'is_multi_piece_package': _isMultiPiecePackage,
          'electronic_declarations_via_qr': _electronicDeclarationsViaQr,
          'has_outer_wrapper': _hasOuterWrapper,
          'outer_wrapper_transparent': _outerWrapperTransparent,
          'declaration_read_through_liquid': _declarationReadThroughLiquid,
        },
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await widget.onSubmit(data);
    } else {
      // ONLINE_LISTING validation
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the Product Listing URL to initiate an e-commerce inspection.'),
            backgroundColor: AppColors.violation,
          ),
        );
        return;
      }

      final market = _fetchResult?['marketplace']?.toString() ?? (_selectedMarketplace != 'Auto-Detect' ? _selectedMarketplace : 'Online Marketplace');
      final biz = _businessController.text.trim().isNotEmpty
          ? _businessController.text.trim()
          : (_fetchResult?['seller'] ?? _fetchResult?['brand'] ?? market).toString();
      final seller = _sellerController.text.trim().isNotEmpty
          ? _sellerController.text.trim()
          : _fetchResult?['seller']?.toString();

      final data = InspectionFormData(
        location: 'Online Listing ($market)',
        sellerName: seller,
        businessName: biz,
        productCategory: _category,
        inspectionType: 'ONLINE_LISTING',
        packageType: 'DIGITAL_LISTING',
        packageConstructionType: 'NOT_APPLICABLE',
        applicabilityContext: {
          'market_scope': 'RETAIL',
          'origin_type': _fetchResult?['country_of_origin'] != null ? 'DOMESTIC' : 'UNKNOWN',
          'is_ecommerce': true,
        },
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        listingUrl: url,
        canonicalUrl: _fetchResult?['final_url']?.toString() ?? url,
        marketplace: market,
        listingMetadata: _fetchResult,
      );
      await widget.onSubmit(data);
    }
  }

  void _viewSnapshotModal() {
    final preview = _fetchResult?['raw_text_preview']?.toString() ?? 'No text extracted.';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.description_outlined, color: AppColors.primaryNavy),
            SizedBox(width: 8),
            Text('Listing Content Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(
              preview,
              style: const TextStyle(fontSize: 12, height: 1.5, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinalizing = widget.isFinalizing;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contextual Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mintMist.withValues(alpha: 0.35),
              borderRadius: AppRadii.sm,
              border: Border.all(color: AppColors.inspectionGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isFinalizing ? Icons.verified_user_outlined : Icons.info_outline,
                  color: AppColors.inspectionGreen,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _inspectionType == 'ONLINE_LISTING'
                        ? 'E-Commerce Listing Mode: Governed by Rule 6(10) of PCR, 2011. Online disclosures are retrieved via safe server-side fetch without physical geometry or PDP scaling.'
                        : (isFinalizing
                            ? 'Complete establishment particulars to finalize and seal this inspection record.'
                            : 'Inspections are governed by Legal Metrology (Packaged Commodities) Rules, 2011. Sealed with cryptographic audit provenance.'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Inspection Channel Selector
          const Text(
            'Inspection Channel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeRadio(
                  title: 'Physical Commodity',
                  subtitle: 'Retail shelf / Warehouse',
                  icon: Icons.inventory_2_outlined,
                  value: 'PHYSICAL',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeRadio(
                  title: 'E-Commerce Listing',
                  subtitle: 'Online Marketplace (Rule 6(10))',
                  icon: Icons.language,
                  value: 'ONLINE_LISTING',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Conditional Workflow Rendering
          if (_inspectionType == 'PHYSICAL')
            _buildPhysicalCommodityForm()
          else
            _buildEcommerceListingForm(),

          const SizedBox(height: 32),

          // Submit / Proceed Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inspectionGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.submitButtonLabel ??
                          (_inspectionType == 'ONLINE_LISTING'
                              ? (isFinalizing ? 'Confirm & Finalize Inspection' : 'Create & Open E-Commerce Inspection')
                              : (isFinalizing ? 'Confirm & Finalize Inspection' : 'Create & Proceed to Capture')),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // E-COMMERCE LISTING WORKFLOW
  // ---------------------------------------------------------------------------
  Widget _buildEcommerceListingForm() {
    final status = _fetchResult?['fetch_status']?.toString();
    final isRetrieved = status == 'RETRIEVED' || status == 'PARTIAL';
    final isError = status == 'FAILED' || status == 'BLOCKED' || status == 'LOGIN_REQUIRED' || status == 'TIMEOUT';
    final rawImgs = (_fetchResult?['image_urls'] as List?)?.whereType<String>().toList() ?? [];
    final declMatrix = (_fetchResult?['declarations_matrix'] as List?)?.whereType<Map>().toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LISTING SOURCE
        _buildSectionTitle('Listing Source & URL'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMarketplace,
                      decoration: const InputDecoration(
                        labelText: 'Marketplace / Platform',
                        prefixIcon: Icon(Icons.store_mall_directory_outlined),
                        isDense: true,
                      ),
                      items: _marketplaces
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMarketplace = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Commodity Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        isDense: true,
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Product Listing URL *',
                  hintText: 'https://www.amazon.in/dp/... or https://www.flipkart.com/...',
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    tooltip: 'Paste from Clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _urlController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Product listing URL is required';
                  }
                  if (!val.startsWith('http://') && !val.startsWith('https://')) {
                    return 'URL must begin with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _isFetchingListing ? null : _handleFetchListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: _isFetchingListing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text(_isFetchingListing ? 'Fetching Listing...' : (_fetchResult != null ? 'Refresh Listing' : 'Fetch Listing')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. FETCH STATUS CARD
        if (_fetchResult != null || isError) ...[
          _buildSectionTitle('Fetch Status & Provenance'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isError ? AppColors.violationBg : (status == 'PARTIAL' ? AppColors.warningBg : AppColors.compliantBg),
              borderRadius: AppRadii.md,
              border: Border.all(
                color: isError ? AppColors.violation : (status == 'PARTIAL' ? AppColors.warning : AppColors.compliant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isError ? AppColors.violation : (status == 'PARTIAL' ? AppColors.warning : AppColors.compliant),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status ?? 'UNKNOWN',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Retrieved: ${_fetchResult?['retrieved_at'] ?? 'Timestamp unavailable'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (_fetchResult?['final_url'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Resolved Canonical: ${_fetchResult!['final_url']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_fetchResult?['page_title'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Page Title: ${_fetchResult!['page_title']}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                if (isError && _fetchResult?['error_message'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${_fetchResult!['error_message']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.violation, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. SELLER / LISTING IDENTITY (when extracted)
        if (isRetrieved) ...[
          _buildSectionTitle('Seller & Listing Identity'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _businessController,
                  decoration: const InputDecoration(
                    labelText: 'Product Title / Commodity Name *',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sellerController,
                        decoration: const InputDecoration(
                          labelText: 'Seller / Merchant',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _fetchResult?['brand']?.toString() ?? '',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Detected Brand',
                          prefixIcon: Icon(Icons.branding_watermark_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _fetchResult?['mrp']?.toString() ?? 'Not detected',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Declared MRP',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _fetchResult?['net_quantity']?.toString() ?? 'Not detected',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Declared Net Quantity',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. LISTING SNAPSHOT & PRODUCT IMAGES
          _buildSectionTitle('Listing Snapshot & Image Evidence'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Snapshot ID: ${_fetchResult?['snapshot_id'] ?? 'N/A'} (SHA-256: ${_fetchResult?['content_hash']?.toString().substring(0, 10) ?? ''}...)',
                      style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Text Snapshot', style: TextStyle(fontSize: 12)),
                      onPressed: _viewSnapshotModal,
                    ),
                  ],
                ),
                if (rawImgs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Extracted Listing Images:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: rawImgs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        return Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.neutral300),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            rawImgs[i],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. RULE 6(10) DECLARATIONS MATRIX
          _buildSectionTitle('Rule 6(10) Digital Declaration Matrix'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.neutral200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(3),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: AppColors.neutral200, width: 1),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppColors.neutral100),
                  children: const [
                    Padding(padding: EdgeInsets.all(10), child: Text('Mandatory Declaration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Rule Ref', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Extracted Value & Source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
                for (final item in declMatrix)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(item['label']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(item['statutory_rule']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: _buildMatrixStatusBadge(item['status']?.toString() ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['value']?.toString() ?? 'Not detected',
                              style: TextStyle(
                                fontSize: 12,
                                color: item['value'] != null ? AppColors.textPrimary : AppColors.neutral400,
                                fontStyle: item['value'] != null ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                            if (item['provenance'] != null && item['provenance'] != 'NOT_DETECTED')
                              Text(
                                'Source: ${item['provenance']}',
                                style: const TextStyle(fontSize: 10, color: AppColors.secondaryBlue),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. STATUTORY COMPLIANCE EVALUATION
          _buildSectionTitle('Statutory Compliance Evaluation'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isAnalyzingListing ? null : _handleRunAnalysis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isAnalyzingListing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('Run Rule Engine Analysis'),
                    ),
                    const SizedBox(width: 12),
                    if (_analysisResult != null) ...[
                      _buildAssessmentBadge(_analysisResult!['assessment']?['overall_status'] ?? 'REVIEW'),
                      const SizedBox(width: 10),
                      Text(
                        'Score: ${_analysisResult!['assessment']?['score'] ?? 0}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                if (_analysisResult != null) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 6),
                  const Text('Compliance Findings & Checks:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final check in (_analysisResult!['assessment']?['checks'] as List? ?? []))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            check['result'] == 'PASS' ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            size: 16,
                            color: check['result'] == 'PASS' ? AppColors.compliant : AppColors.violation,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${check['field_name']}: ${check['explanation'] ?? ''} (${check['rule_code'] ?? ''})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatrixStatusBadge(String status) {
    Color bg = AppColors.neutral200;
    Color fg = AppColors.neutral700;
    if (status == 'DETECTED') {
      bg = AppColors.compliantBg;
      fg = AppColors.compliant;
    } else if (status == 'NOT_DETECTED') {
      bg = AppColors.violationBg;
      fg = AppColors.violation;
    } else if (status == 'EXEMPT') {
      bg = AppColors.infoBg;
      fg = AppColors.secondaryBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildAssessmentBadge(String status) {
    Color bg = AppColors.warning;
    if (status == 'PASS') bg = AppColors.compliant;
    if (status == 'POTENTIAL_VIOLATION') bg = AppColors.violation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ---------------------------------------------------------------------------
  // PHYSICAL COMMODITY WORKFLOW (PRESERVED)
  // ---------------------------------------------------------------------------
  Widget _buildPhysicalCommodityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location & Trader Information
        _buildSectionTitle('Location & Trader Information'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessController,
          decoration: const InputDecoration(
            labelText: 'Establishment / Trader Name *',
            hintText: 'e.g. M/s Greenfield Retail Hub',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Establishment name is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Inspection Location / Address *',
            hintText: 'Shop No., Market, District, State',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Inspection location address is required';
            }
            if (val.trim() == 'Field Scan (Pending Finalisation)') {
              return 'Please provide the physical inspection address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sellerController,
          decoration: const InputDecoration(
            labelText: 'Dealer / Seller Licensee (Optional)',
            hintText: 'e.g. Registered Distributor or Packer',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 20),

        // Commodity Classification
        _buildSectionTitle('Commodity Classification (Rule 6 & 7 Context)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Commodity Category',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _categories
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _constructionType,
                decoration: const InputDecoration(
                  labelText: 'Package Construction',
                  helperText: 'Rule 7 Table-I font scaling',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'NORMAL',
                    child: Text('Normal (Cardboard / Poly / Label)'),
                  ),
                  DropdownMenuItem(
                    value: 'BLOWN_FORMED_MOLDED',
                    child: Text('Blown / Formed / Molded (Glass/Plastic)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _constructionType = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _packageType,
          decoration: const InputDecoration(
            labelText: 'Package Geometry / Shape',
            helperText: 'Calculates Principal Display Panel (PDP) area',
          ),
          items: const [
            DropdownMenuItem(value: 'RECTANGULAR', child: Text('Rectangular (H × W)')),
            DropdownMenuItem(value: 'CYLINDRICAL', child: Text('Cylindrical (40% of H × Circumference)')),
            DropdownMenuItem(value: 'IRREGULAR', child: Text('Irregular / Other (40% Total Surface)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _packageType = val);
          },
        ),
        const SizedBox(height: 16),

        // Declaration Applicability (Rule 6)
        _buildSectionTitle('Declaration Applicability (Rule 6)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _marketScope,
          decoration: const InputDecoration(
            labelText: 'Intended Consumer / Market Scope',
            helperText: 'Industrial and institutional packages may be outside retail declaration scope',
            prefixIcon: Icon(Icons.business_center_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'RETAIL', child: Text('Retail consumer package')),
            DropdownMenuItem(value: 'INDUSTRIAL', child: Text('Industrial consumer package')),
            DropdownMenuItem(value: 'INSTITUTIONAL', child: Text('Institutional consumer package')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _marketScope = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _originType,
          decoration: const InputDecoration(
            labelText: 'Commodity Origin',
            helperText: 'Importer and country-of-origin declarations activate for imported goods',
            prefixIcon: Icon(Icons.public_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'UNKNOWN', child: Text('Unknown — infer from package')),
            DropdownMenuItem(value: 'DOMESTIC', child: Text('Domestic')),
            DropdownMenuItem(value: 'IMPORTED', child: Text('Imported')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _originType = value);
          },
        ),
        const SizedBox(height: 8),
        _buildApplicabilityDropdown(
          label: 'Separate packer declaration',
          helper: 'Requires packer name and complete address when manufacturer and packer differ',
          value: _packerApplicability,
          onChanged: (value) => setState(() => _packerApplicability = value),
        ),
        _buildApplicabilityDropdown(
          label: 'Best Before / Use By declaration',
          helper: 'Applicable when the commodity may become unfit for human consumption',
          value: _shelfLifeApplicability,
          onChanged: (value) => setState(() => _shelfLifeApplicability = value),
        ),
        _buildApplicabilityDropdown(
          label: 'Commodity dimensions declaration',
          helper: 'Applicable to size-dependent commodities',
          value: _dimensionsApplicability,
          onChanged: (value) => setState(() => _dimensionsApplicability = value),
        ),
        _buildApplicabilityDropdown(
          label: 'Unit sale price declaration',
          helper: 'Rule 6(11) retail unit-price declaration',
          value: _unitSalePriceApplicability,
          onChanged: (value) => setState(() => _unitSalePriceApplicability = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Multi-piece / group / gift package', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Declarations must be checked on outer and constituent retail packages'),
          value: _isMultiPiecePackage,
          onChanged: (value) => setState(() => _isMultiPiecePackage = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Declarations provided through QR / electronic link', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Creates a mandatory review to open and capture the digital declarations'),
          value: _electronicDeclarationsViaQr,
          onChanged: (value) => setState(() => _electronicDeclarationsViaQr = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Package has an outside container / wrapper', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Capture the optional Outer Wrapper surface for Rule 9 placement checks'),
          value: _hasOuterWrapper,
          onChanged: (value) => setState(() {
            _hasOuterWrapper = value;
            if (!value) {
              _outerWrapperTransparent = false;
              _declarationReadThroughLiquid = false;
            }
          }),
        ),
        if (_hasOuterWrapper) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Outer wrapper is transparent', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Inner retail declarations remain readable without opening'),
              value: _outerWrapperTransparent,
              onChanged: (value) => setState(() => _outerWrapperTransparent = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Declarations read through liquid commodity', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Rule 9 wrapper exception applies to transparent wrappers/liquids'),
              value: _declarationReadThroughLiquid,
              onChanged: (value) => setState(() => _declarationReadThroughLiquid = value),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Notes
        _buildSectionTitle('Inspection Field Notes'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Record physical sample tags, batch numbers, or verification remarks',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
    );
  }

  Widget _buildTypeRadio({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _inspectionType == value;

    return InkWell(
      onTap: widget.isFinalizing ? null : () => setState(() => _inspectionType = value),
      borderRadius: AppRadii.sm,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintMist.withValues(alpha: 0.35) : AppColors.surfaceIvory,
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: isSelected ? AppColors.inspectionGreen : AppColors.skyGrey,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.inspectionGreen : AppColors.steelBlue,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.inspectionGreen : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.secondaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicabilityDropdown({
    required String label,
    required String helper,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
        ),
        items: const [
          DropdownMenuItem(value: 'AUTO', child: Text('Auto — infer from package evidence')),
          DropdownMenuItem(value: 'YES', child: Text('Yes — strictly required for this commodity')),
          DropdownMenuItem(value: 'NO', child: Text('No — exempt for this commodity')),
        ],
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }
}
