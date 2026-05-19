// lib/features/event/presentation/pages/edit_event_page.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_loading.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';
import '../bloc/event_bloc.dart' as import_event_bloc;

@RoutePage()
class EditEventPage extends StatefulWidget {
  final String eventId;
  final Event? event;

  const EditEventPage({
    super.key,
    required this.eventId,
    this.event,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage>
    with SingleTickerProviderStateMixin {
  late final EventApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();

  Event? _event;
  bool _isLoadingEvent = false;
  bool _isSubmitting = false;

  EventCategory _selectedCategory = EventCategory.social;
  int _maxParticipants = 12;
  bool _isEliteOnly = false;
  bool _isPublic = true;

  final List<String> _vibeTags = [];
  final List<String> _photoUrls = [];
  int _selectedCoverPreset = 0;
  late final AnimationController _heroPulse;

  @override
  void initState() {
    super.initState();
    _apiService = sl<EventApiService>();
    _heroPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..repeat(reverse: true);

    if (widget.event != null) {
      _event = widget.event;
      _initializeFields();
    } else {
      _loadEventDetails();
    }
  }

  void _initializeFields() {
    final e = _event;
    if (e == null) return;

    _titleCtrl.text = e.title;
    _descriptionCtrl.text = e.description;
    _selectedCategory = e.category;
    _maxParticipants = e.maxParticipants;
    _isPublic = e.isPublic;
    _isEliteOnly = e.isEliteOnly;

    _vibeTags.clear();
    if (e.vibeTags != null && e.vibeTags!.isNotEmpty) {
      final tags = e.vibeTags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
      for (final t in tags) {
        if (t.startsWith('preset:')) {
          _selectedCoverPreset = int.tryParse(t.replaceFirst('preset:', '')) ?? 0;
        } else {
          _vibeTags.add(t);
        }
      }
    }

    _photoUrls.clear();
    _photoUrls.addAll(e.photoUrls);
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoadingEvent = true;
    });

    try {
      final fetched = await _apiService.getEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = fetched;
        _isLoadingEvent = false;
      });
      _initializeFields();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvent = false;
      });
      VibeSnackBar.error(context, 'Failed to load event details: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagCtrl.dispose();
    _heroPulse.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String _tr(String key) => AppLocalizations.tr(key);

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _categoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.sports:
        return _tr('event_category_sports');
      case EventCategory.dining:
        return _tr('event_category_dining');
      case EventCategory.social:
        return _tr('event_category_social');
      case EventCategory.arts:
        return _tr('event_category_arts');
      case EventCategory.outdoor:
        return _tr('event_category_outdoors');
      case EventCategory.gaming:
        return _tr('event_category_gaming');
    }
  }

  String _categoryEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.sports:
        return '🏃';
      case EventCategory.dining:
        return '🍜';
      case EventCategory.social:
        return '💬';
      case EventCategory.arts:
        return '🎨';
      case EventCategory.outdoor:
        return '⛺';
      case EventCategory.gaming:
        return '🎮';
    }
  }

  Color _categoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.sports:
        return AppColors.categorySports;
      case EventCategory.dining:
        return AppColors.categoryDining;
      case EventCategory.social:
        return AppColors.categorySocial;
      case EventCategory.arts:
        return AppColors.categoryArts;
      case EventCategory.outdoor:
        return AppColors.categoryOutdoors;
      case EventCategory.gaming:
        return AppColors.categoryGaming;
    }
  }

  void _addTag() {
    final value = _tagCtrl.text.trim();
    if (value.isEmpty || _vibeTags.contains(value)) return;
    setState(() {
      _vibeTags.add(value);
      _tagCtrl.clear();
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;
      if (!mounted) return;

      if (_photoUrls.length >= 5) {
        VibeSnackBar.warning(context, 'Maximum 5 photos allowed.');
        return;
      }

      VibeSnackBar.info(context, 'Uploading image...');

      final url = kIsWeb
          ? await _apiService.uploadImageBytes(
              await image.readAsBytes(),
              image.name.isNotEmpty ? image.name : 'event-cover.jpg',
            )
          : await _apiService.uploadImage(image.path);

      if (!mounted) return;

      if (url != null) {
        setState(() {
          _photoUrls.add(url);
        });
        VibeSnackBar.success(context, 'Image uploaded successfully!');
      } else {
        VibeSnackBar.error(
          context,
          'Failed to upload image. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Pick and Upload Error: $e');
      if (!mounted) return;
      VibeSnackBar.error(context, 'An error occurred during upload.');
    }
  }

  Future<void> _submitChanges() async {
    final e = _event;
    if (e == null) return;

    if (_titleCtrl.text.trim().isEmpty || _descriptionCtrl.text.trim().isEmpty) {
      VibeSnackBar.error(context, _tr('event_validation_title_description'));
      return;
    }

    // Front-end capacity validation check
    if (_maxParticipants < e.currentParticipants) {
      final message = _tr('edit_event_validation_capacity')
          .replaceAll('{current}', e.currentParticipants.toString());
      VibeSnackBar.error(context, message);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedPhotoUrls = List<String>.from(_photoUrls);
      final tagsToSave = [..._vibeTags, 'preset:$_selectedCoverPreset'];
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'category': _selectedCategory.name,
        'maxParticipants': _maxParticipants,
        'photoUrls': updatedPhotoUrls,
        'isPublic': _isPublic,
        'vibeTags': tagsToSave.join(', '),
      };

      final updatedEvent = await _apiService.updateEvent(e.id, data);

      if (!mounted) return;
      // Refresh list views
      sl<import_event_bloc.EventBloc>().add(
        import_event_bloc.LoadEvents(),
      );

      VibeSnackBar.success(context, _tr('edit_event_success'));
      context.router.maybePop(updatedEvent);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      VibeSnackBar.error(
        context,
        '${_tr('edit_event_error')}: $err',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);
    final card = _isDark ? const Color(0xFF161D2A) : Colors.white;
    final border = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final sectionHint = _isDark
        ? AppColors.darkTextHint
        : const Color(0xFF8B97B6);

    if (_isLoadingEvent) {
      return Scaffold(
        backgroundColor: bg,
        appBar: VibeHeader(title: _tr('edit_event_title')),
        body: const Center(
          child: VibeLoading(size: 40, strokeWidth: 3, segments: 10),
        ),
      );
    }

    final e = _event;
    if (e == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: VibeHeader(title: _tr('edit_event_title')),
        body: const Center(child: Text('Event not found.')),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: _tr('edit_event_title'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.viewPaddingOf(context).top +
                    VibeHeader.headerHeight +
                    20,
                20,
                84,
              ),
              children: [
                _coverComposer(card, border),
                const SizedBox(height: 20),
                _sectionHeader(
                  _tr('event_section_core').toUpperCase(),
                  sectionHint,
                ),
                const SizedBox(height: 10),
                _cardShell(card, border, _coreSection(border)),
                const SizedBox(height: 18),
                _sectionHeader(
                  '${_tr('event_section_schedule').toUpperCase()} (LOCKED)',
                  sectionHint,
                ),
                const SizedBox(height: 10),
                _cardShell(card, border, _scheduleSectionLocked()),
                const SizedBox(height: 18),
                _sectionHeader(
                  '${_tr('event_section_location').toUpperCase()} (LOCKED)',
                  sectionHint,
                ),
                const SizedBox(height: 10),
                _cardShell(card, border, _locationSectionLocked()),
                const SizedBox(height: 30),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFooterAction(bg, border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, Color sectionHint) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: sectionHint,
      ),
    );
  }

  Widget _cardShell(Color card, Color border, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _buildFooterAction(Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: VibeButton(
          label: _tr('save').toUpperCase(),
          onPressed: _isSubmitting ? () {} : _submitChanges,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }

  Widget _coverComposer(Color card, Color border) {
    const presets = <List<Color>>[
      [Color(0xFF161B3A), Color(0xFF28418D), Color(0xFF1EB9D8)],
      [Color(0xFF0B1220), Color(0xFF123E68), Color(0xFF2A6EF3)],
      [Color(0xFF1B1333), Color(0xFF503EA3), Color(0xFF2D95EA)],
    ];
    final colors = presets[_selectedCoverPreset % presets.length];
    final previewUrl = _photoUrls.isNotEmpty ? _photoUrls.first : null;

    return AnimatedBuilder(
      animation: _heroPulse,
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_heroPulse.value);

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'EVENT COVER PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 144,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 380),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: previewUrl == null
                                  ? Container()
                                  : Transform.scale(
                                      key: ValueKey(previewUrl),
                                      scale: 1 + (pulse * 0.015),
                                      child: Image.network(
                                        previewUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            Container(color: Colors.black12),
                                      ),
                                    ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(
                                      alpha: previewUrl == null ? 0.18 : 0.04,
                                    ),
                                    Colors.black.withValues(
                                      alpha: previewUrl == null ? 0.5 : 0.38,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (previewUrl == null)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _GalaxyPainter(progress: pulse),
                                ),
                              ),
                            Positioned(
                              left: 14,
                              top: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.26),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Text(
                                  'Live Preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              top: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      previewUrl == null
                                          ? Icons.add_photo_alternate_rounded
                                          : Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      previewUrl == null
                                          ? 'Upload Cover'
                                          : 'Change Cover',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 14,
                              right: 14,
                              bottom: 12,
                              child: Text(
                                'Your event cover appears exactly like this in feed.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  height: 1.2,
                  letterSpacing: 0.05,
                ),
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: _tr('event_field_title_hint'),
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.74),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedCoverPreset;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCoverPreset = index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.26)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.66)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          switch (index) {
                            0 => 'Deep Space',
                            1 => 'Ocean Neon',
                            _ => 'Electric Mist',
                          },
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: selected ? 1 : 0.86,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coreSection(Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VibeTextField(
          controller: _descriptionCtrl,
          label: _tr('event_field_description'),
          hint: _tr('event_field_description_hint'),
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _fieldLabel(_tr('event_field_category')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventCategory.values.map((category) {
            final selected = _selectedCategory == category;
            final color = _categoryColor(category);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : (_isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.bgSecondary),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color.withValues(alpha: 0.6) : border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_categoryEmoji(category)),
                    const SizedBox(width: 6),
                    Text(
                      _categoryLabel(category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr('event_field_vibe_tags'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: VibeTextField(
                    maxLines: 1,
                    controller: _tagCtrl,
                    hint: _tr('event_field_add_tag_hint'),
                    onSubmitted: (value) => _addTag(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vibeTags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _vibeTags.remove(tag)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        _fieldLabel(_tr('event_field_photo_urls')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pick up to 5 photos',
                style: TextStyle(
                  fontSize: 12,
                  color: _isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Add photo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photoUrls.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add photos to enrich your event profile visual aesthetics.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = _photoUrls[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoUrls.remove(url)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _scheduleSectionLocked() {
    final e = _event!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLockedNoticeBadge(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _lockedField(
                icon: Icons.calendar_month_rounded,
                text: _formatDate(e.startDateTime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _lockedField(
                icon: Icons.schedule_rounded,
                text: TimeOfDay.fromDateTime(e.startDateTime).format(context),
              ),
            ),
          ],
        ),
        if (e.endDateTime != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _lockedField(
                  icon: Icons.event_available_rounded,
                  text: _formatDate(e.endDateTime!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _lockedField(
                  icon: Icons.timelapse_rounded,
                  text: TimeOfDay.fromDateTime(e.endDateTime!).format(context),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        _stepperRow(
          title: _tr('event_field_max_participants'),
          value: _maxParticipants,
          min: e.currentParticipants, // The absolute limit set by business logic
          max: 100,
          onChanged: (value) => setState(() => _maxParticipants = value),
        ),
        const SizedBox(height: 12),
        _toggleRow(
          icon: Icons.public_rounded,
          title: _tr('event_field_is_public'),
          subtitle: 'Appear on discovery map',
          value: _isPublic,
          onChanged: (value) => setState(() => _isPublic = value),
        ),
        const SizedBox(height: 10),
        _toggleRow(
          icon: Icons.workspace_premium_rounded,
          title: _tr('event_field_is_elite_only'),
          subtitle: 'Prioritize premium matching audience',
          value: _isEliteOnly,
          onChanged: (value) => setState(() => _isEliteOnly = value),
        ),
      ],
    );
  }

  Widget _locationSectionLocked() {
    final e = _event!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLockedNoticeBadge(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.location.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (e.location.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.location.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedNoticeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.categorySports.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.categorySports.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: AppColors.categorySports,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tr('edit_event_read_only_fields'),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.categorySports,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedField({required IconData icon, required String text}) {
    final bgColor = _isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor = _isDark
        ? AppColors.darkBorderLight
        : AppColors.borderLight;
    final textColor = (_isDark ? AppColors.darkTextPrimary : AppColors.secondary)
        .withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: _isDark ? AppColors.darkTextPrimary : AppColors.secondary,
      ),
    );
  }

  Widget _stepperRow({
    required String title,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final bgColor = _isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor = _isDark
        ? AppColors.darkBorderLight
        : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$value people',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: _isDark
                  ? AppColors.darkBorderLight
                  : AppColors.borderLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.18),
            ),
            child: Slider(
              min: min.toDouble(),
              max: max < min ? min.toDouble() : max.toDouble(),
              divisions: (max - min) <= 0 ? 1 : max - min,
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              label: '$value',
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              for (final quick in const [8, 12, 20, 30])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(quick.clamp(min, max));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: value == quick
                            ? AppColors.primary
                            : (_isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: value == quick
                              ? AppColors.primary
                              : (_isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        '$quick',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: value == quick
                              ? Colors.white
                              : (_isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.secondary),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bgColor = _isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor = _isDark
        ? AppColors.darkBorderLight
        : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({required this.progress});

  final double progress;

  static const List<Offset> _stars = [
    Offset(0.05, 0.12),
    Offset(0.12, 0.22),
    Offset(0.18, 0.15),
    Offset(0.23, 0.33),
    Offset(0.31, 0.18),
    Offset(0.38, 0.09),
    Offset(0.45, 0.24),
    Offset(0.54, 0.16),
    Offset(0.6, 0.31),
    Offset(0.68, 0.13),
    Offset(0.75, 0.23),
    Offset(0.84, 0.14),
    Offset(0.91, 0.31),
    Offset(0.2, 0.43),
    Offset(0.33, 0.39),
    Offset(0.47, 0.45),
    Offset(0.62, 0.42),
    Offset(0.79, 0.41),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final spin = progress * math.pi * 2;

    final topNebula = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF8BD5FF).withValues(alpha: 0.23),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.18),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.18),
      size.width * 0.42,
      topNebula,
    );

    final leftNebula = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF9B7BFF).withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.14, size.height * 0.38),
              radius: size.width * 0.36,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.38),
      size.width * 0.36,
      leftNebula,
    );

    final core = Offset(
      size.width * 0.56,
      size.height * (0.28 + (math.sin(progress * 2 * math.pi) * 0.02)),
    );
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0xFF8FD1FF).withValues(alpha: 0.62),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: core, radius: size.width * 0.18));
    canvas.drawCircle(core, size.width * 0.18, corePaint);

    final armPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final alpha = 0.12 + (i * 0.06);
      final direction = i.isEven ? 1.0 : -1.0;
      armPaint
        ..strokeWidth = 1.2 + (i * 0.6)
        ..color = Colors.white.withValues(alpha: alpha);
      final radius = size.width * (0.16 + (i * 0.05));
      final rect = Rect.fromCircle(center: core, radius: radius);
      canvas.drawArc(
        rect,
        (-0.55 + (i * 0.18)) + (spin * direction * 0.35),
        2.75,
        false,
        armPaint,
      );
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
    for (var i = 0; i < 2; i++) {
      final radius = size.width * (0.24 + (i * 0.06));
      final rect = Rect.fromCircle(center: core, radius: radius);
      final direction = i == 0 ? 1.0 : -1.0;
      canvas.drawArc(
        rect,
        (0.25 + (i * 0.5)) + (spin * direction * 0.42),
        1.6,
        false,
        orbitPaint,
      );
    }

    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final twinkle = 0.4 + (0.6 * math.sin((progress * 2 * math.pi) + i));
      final radius = i.isEven ? 1.0 : 1.7;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22 + (twinkle * 0.68));
      final center = Offset(star.dx * size.width, star.dy * size.height);
      canvas.drawCircle(center, radius, paint);

      if (i % 4 == 0) {
        final crossPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3 + (twinkle * 0.4))
          ..strokeWidth = 0.8;
        canvas.drawLine(
          Offset(center.dx - 2.4, center.dy),
          Offset(center.dx + 2.4, center.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - 2.4),
          Offset(center.dx, center.dy + 2.4),
          crossPaint,
        );
      }
    }

    final planetCenter = Offset(
      size.width * 0.83,
      size.height * (0.68 + (math.sin(progress * 2 * math.pi) * 0.01)),
    );
    final planetRadius = size.height * 0.16;

    final planetShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      Offset(planetCenter.dx + 8, planetCenter.dy + 10),
      planetRadius,
      planetShadow,
    );

    final planet = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFA6D4FF).withValues(alpha: 0.96),
              const Color(0xFF4C7BEA).withValues(alpha: 0.9),
              const Color(0xFF262F6F).withValues(alpha: 0.94),
            ],
          ).createShader(
            Rect.fromCircle(center: planetCenter, radius: planetRadius),
          );
    canvas.drawCircle(planetCenter, planetRadius, planet);

    final highlight = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.52), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                planetCenter.dx - (planetRadius * 0.3),
                planetCenter.dy - (planetRadius * 0.28),
              ),
              radius: planetRadius * 0.78,
            ),
          );
    canvas.drawCircle(planetCenter, planetRadius, highlight);

    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-0.35);
    final ringRect = Rect.fromCenter(
      center: Offset.zero,
      width: planetRadius * 2.7,
      height: planetRadius * 0.88,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(ringRect);
    canvas.drawOval(ringRect, ring);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
