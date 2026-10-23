import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/course.dart';
import '../../providers/manage_courses_provider.dart';
import '../../widgets/course_thumb.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';

class CourseFormScreen extends StatefulWidget {
  /// null = create a new course, otherwise edit this one.
  final Course? course;

  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  static const _levelOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'All Levels',
  ];

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _durationCtrl;

  late String _category;
  late String _level;
  late bool _active;
  XFile? _picked;
  Uint8List? _bytes;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _feeCtrl = TextEditingController(
      text: c == null
          ? ''
          : (c.fee % 1 == 0
                ? c.fee.toStringAsFixed(0)
                : c.fee.toStringAsFixed(2)),
    );
    _durationCtrl = TextEditingController(
      text: c == null ? '' : c.durationMonths.toString(),
    );
    _category = c?.category.isNotEmpty == true ? c!.category : 'computer';
    _level = c?.level.isNotEmpty == true ? c!.level : 'Beginner';
    _active = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _feeCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = 'That photo is too large (max 5 MB).');
        return;
      }

      setState(() {
        _picked = file;
        _bytes = bytes;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the photo picker.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await context.read<ManageCoursesProvider>().save(
      id: widget.course?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      level: _level,
      fee: _feeCtrl.text.trim(),
      durationMonths: _durationCtrl.text.trim(),
      isActive: _active,
      image: _picked,
    );

    if (!mounted) return;

    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Course updated.' : 'Course created.'),
        ),
      );
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = {..._levelOptions, _level}.toList();
    final hasImage = _bytes != null || widget.course?.thumbnailUrl != null;

    return GradientScaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit course' : 'New course')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        if (_bytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.memory(
                              _bytes!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          CourseThumb(
                            category: _category,
                            url: widget.course?.thumbnailUrl,
                            width: double.infinity,
                            height: 160,
                            accent: widget.course == null
                                ? AppColors.sky
                                : AppColors.accentFor(widget.course!.id),
                          ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FilledButton.tonalIcon(
                            onPressed: _saving ? null : _pickPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(
                              hasImage ? 'Change photo' : 'Add photo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Course title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'computer',
                          child: Text('Computer'),
                        ),
                        DropdownMenuItem(
                          value: 'english',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _level,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        prefixIcon: Icon(Icons.stairs_outlined),
                      ),
                      items: [
                        for (final l in levels)
                          DropdownMenuItem(value: l, child: Text(l)),
                      ],
                      onChanged: (v) => setState(() => _level = v ?? _level),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _feeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Fee (USD)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').trim());
                              if (n == null) return 'Enter a number';
                              if (n < 0 || n > 99999) return '0 to 99999';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Months',
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Enter a number';
                              if (n < 1 || n > 60) return '1 to 60';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 5000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: const Text('Visible to students'),
                        subtitle: const Text(
                          'Hidden courses cannot be enrolled in',
                        ),
                        value: _active,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _active = v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Save changes' : 'Create course'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
