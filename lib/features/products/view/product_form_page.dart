import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_category.dart';
import '../bloc/product_form_bloc.dart';

/// Add (POST /products/add) or edit (PUT /products/{id}) a product.
/// Pops with the saved [Product] on success.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.categories, this.product});

  final Product? product;
  final List<ProductCategory> categories;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final Product? _original = widget.product;
  late final _titleController = TextEditingController(text: _original?.title);
  late final _brandController = TextEditingController(text: _original?.brand);
  late final _priceController = TextEditingController(
    text: _original?.price.toStringAsFixed(2),
  );
  late final _discountController = TextEditingController(
    text: _original == null || _original.discountPercentage == 0
        ? ''
        : _original.discountPercentage.toString(),
  );
  late final _stockController = TextEditingController(
    text: _original?.stock.toString(),
  );
  late final _thumbnailController = TextEditingController(
    text: _original?.thumbnail,
  );
  late final _descriptionController = TextEditingController(
    text: _original?.description,
  );
  late final _categoryController = TextEditingController(
    text: _original?.category,
  );
  late String? _category = _original?.category;

  bool get _isEdit => _original != null;

  /// Known categories, plus the product's own if the API list lacks it.
  late final List<ProductCategory> _categoryOptions = [
    ...widget.categories,
    if (_original != null &&
        _original.category.isNotEmpty &&
        !widget.categories.any((c) => c.slug == _original.category))
      ProductCategory(
        slug: _original.category,
        name: Formatters.humanize(_original.category),
      ),
  ];

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _brandController,
      _priceController,
      _discountController,
      _stockController,
      _thumbnailController,
      _descriptionController,
      _categoryController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final original = _original;
    final thumbnail = _thumbnailController.text.trim();
    final brand = _brandController.text.trim();
    final category = _categoryOptions.isEmpty
        ? _categoryController.text.trim().toLowerCase()
        : _category!;

    // A new thumbnail becomes the gallery image, otherwise keep the gallery.
    final images = original == null || thumbnail != original.thumbnail
        ? (thumbnail.isEmpty ? const <String>[] : [thumbnail])
        : original.images;

    final draft = Product(
      id: original?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      discountPercentage: double.tryParse(_discountController.text.trim()) ?? 0,
      rating: original?.rating ?? 0,
      stock: int.parse(_stockController.text.trim()),
      brand: brand.isEmpty ? null : brand,
      category: category,
      thumbnail: thumbnail,
      images: images,
      isLocal: original?.isLocal ?? false,
    );

    context.read<ProductFormBloc>().add(
      ProductFormSubmitted(draft, isNew: !_isEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = horizontalPaddingFor(
      MediaQuery.sizeOf(context).width,
      maxContentWidth: 640,
    );
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return BlocListener<ProductFormBloc, ProductFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ProductFormStatus.success:
            context.pop(state.saved);
          case ProductFormStatus.failure:
            showAppSnackBar(
              context,
              UiMessage(state.error ?? 'Could not save', isError: true),
            );
          default:
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding, 8.h, padding, 24.h),
            children: [
              _ThumbnailPreview(controller: _thumbnailController),
              const _SectionLabel('Basic info'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, field: 'Title'),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _brandController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
              ),
              SizedBox(height: 14.h),
              if (_categoryOptions.isEmpty)
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'Category'),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    helperText: 'e.g. smartphones',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  menuMaxHeight: 360,
                  validator: (v) => v == null ? 'Category is required' : null,
                  onChanged: (value) => setState(() => _category = value),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  items: [
                    for (final category in _categoryOptions)
                      DropdownMenuItem(
                        value: category.slug,
                        child: Text(category.name),
                      ),
                  ],
                ),
              const _SectionLabel('Pricing & inventory'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimal,
                      textInputAction: TextInputAction.next,
                      validator: Validators.price,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimal,
                      textInputAction: TextInputAction.next,
                      validator: Validators.discount,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        suffixText: '%',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: Validators.stock,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  suffixText: 'units',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const _SectionLabel('Media & description'),
              TextFormField(
                controller: _thumbnailController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: Validators.optionalUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://…',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 8.h, padding, 12.h),
            child: BlocBuilder<ProductFormBloc, ProductFormState>(
              builder: (context, state) => LoadingButton(
                label: _isEdit ? 'Save changes' : 'Create product',
                icon: _isEdit ? Icons.save_outlined : Icons.add_rounded,
                loading: state.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 24.h, 4.w, 12.h),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Live preview of the image URL field.
class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final url = value.text.trim();
        final valid = Validators.optionalUrl(url) == null;
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: ProductImage(
                url: valid ? url : '',
                width: 140.w,
                height: 140.h,
              ),
            ),
          ),
        );
      },
    );
  }
}
