import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/managed_announcement.dart';
import '../../services/announcement_manage_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/gradient_scaffold.dart';

class AnnouncementFormScreen extends StatefulWidget {
  /// null = create a new announcement, otherwise edit this one.
  final ManagedAnnouncement? item;

  const AnnouncementFormScreen({super.key, this.item});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  static const _maxImageBytes = 5 * 1024 * 1024; // matches the server's 5 MB

  final _service = AnnouncementManageService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  late bool _isActive;
  XFile? _picked;
  Uint8List? _pickedBytes;

  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final a = widget.item;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _contentCtrl = TextEditingController(text: a?.content ?? '');
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    if (bytes.length > _maxImageBytes) {
      setState(
        () => _error = 'That image is larger than 5 MB. Pick a smaller one.',
      );
      return;
    }

    setState(() {
      _error = null;
      _picked = file;
      _pickedBytes = bytes;
    });
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

    try {
      await _service.save(
        id: widget.item?.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        isActive: _isActive,
        image: _picked,
      );

      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Announcement updated.' : 'Announcement created.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Widget _imageArea() {
    final existing = widget.item?.imageUrl;

    final placeholder = Container(
      color: AppColors.sky.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppColors.sky,
          ),
          SizedBox(height: 6),
          Text(
            'Add an image (optional)',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );

    final Widget content;
    if (_pickedBytes != null) {
      content = Image.memory(_pickedBytes!, fit: BoxFit.cover);
    } else if (existing != null) {
      content = Image.network(
        existing,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else {
      content = placeholder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _saving ? null : _pickImage,
            child: SizedBox(height: 180, child: content),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              (_pickedBytes != null || existing != null)
                  ? 'Change image'
                  : 'Choose image',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit announcement' : 'New announcement'),
      ),
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
                    if (_error != null) ...[
                      ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],
                    _imageArea(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentCtrl,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 10000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter the message'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: const Text('Visible to students'),
                      subtitle: const Text(
                        'Turn off to keep it as a hidden draft',
                      ),
                      value: _isActive,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 16),
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
                          : Text(_isEdit ? 'Save changes' : 'Publish'),
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
