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
  Map<String, dynamic>? _fetchResult;
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

  void _autoDetectMarketplace(String url) {
    final lower = url.toLowerCase();
    String detected = _selectedMarketplace;
    if (lower.contains('amazon.')) {
      detected = 'Amazon India';
    } else if (lower.contains('flipkart.')) {
      detected = 'Flipkart';
    } else if (lower.contains('blinkit.')) {
      detected = 'Blinkit';
    } else if (lower.contains('zepto')) {
      detected = 'Zepto';
    } else if (lower.contains('swiggy')) {
      detected = 'Swiggy Instamart';
    } else if (lower.contains('bigbasket')) {
      detected = 'BigBasket';
    } else if (lower.contains('jiomart')) {
      detected = 'JioMart';
    }
    if (detected != _selectedMarketplace) {
      setState(() => _selectedMarketplace = detected);
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
                        ? (isFinalizing
                            ? 'E-Commerce Listing Mode: Review digital declarations and finalize the audit record.'
                            : 'E-Commerce Listing Mode: Governed by Rule 6(10). Enter product listing URL to audit digital declarations.')
                        : (isFinalizing
                            ? 'Confirm establishment particulars and field notes to finalize and seal this statutory inspection record.'
                            : 'Create the inspection case and provide the minimum information needed to begin.'),
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
                              ? (isFinalizing ? 'Confirm & Finalize Inspection' : 'Create & Fetch Listing')
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
    return _buildMinimalEcommerceListingForm();
  }

  Widget _buildMinimalEcommerceListingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Online Listing Information'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _urlController,
          onChanged: _autoDetectMarketplace,
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
                  final txt = data!.text!.trim();
                  _urlController.text = txt;
                  _autoDetectMarketplace(txt);
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
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                key: ValueKey('market_$_selectedMarketplace'),
                initialValue: _selectedMarketplace,
                decoration: const InputDecoration(
                  labelText: 'Marketplace / Platform',
                  prefixIcon: Icon(Icons.store_mall_directory_outlined),
                  helperText: 'Auto-detected from URL if recognized',
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
              flex: 5,
              child: DropdownButtonFormField<String>(
                key: ValueKey('category_$_category'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Commodity Category (Optional)',
                  prefixIcon: Icon(Icons.category_outlined),
                  helperText: 'Statutory classification',
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
          controller: _businessController,
          decoration: const InputDecoration(
            labelText: 'Establishment / Seller Name (Optional)',
            hintText: 'Leave empty to auto-derive from marketplace',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('Optional Field Notes'),
        const SizedBox(height: 10),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Inspection Field Notes (Optional)',
            hintText: 'Add relevant observations, compliance notes, or case reference...',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PHYSICAL COMMODITY WORKFLOW
  // ---------------------------------------------------------------------------
  Widget _buildPhysicalCommodityForm() {
    return _buildMinimalPhysicalCommodityForm();
  }

  Widget _buildMinimalPhysicalCommodityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Inspection Information'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _businessController,
          decoration: const InputDecoration(
            labelText: 'Establishment / Trader Name *',
            hintText: 'e.g. M/s Greenfield Retail Hub',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Establishment name is required' : null,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Commodity Category *',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _categories
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _sellerController,
          decoration: const InputDecoration(
            labelText: 'Dealer / Seller Licensee (Optional)',
            hintText: 'e.g. Registered Distributor or Packer license',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('Optional Field Notes'),
        const SizedBox(height: 10),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Inspection Field Notes (Optional)',
            hintText: 'Add relevant observations, batch information, or sample tags...',
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

}
