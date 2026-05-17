import 'dart:math' as math;
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_loading.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';
import '../bloc/create_event_cubit.dart';
import '../bloc/event_bloc.dart' as import_event_bloc;

@RoutePage()
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage>
    with SingleTickerProviderStateMixin {
  late final CreateEventCubit _cubit;
  late final EventApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _locationNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  EventCategory _selectedCategory = EventCategory.sports;
  int _maxParticipants = 12;
  bool _isEliteOnly = false;
  bool _isPublic = true;

  final List<String> _vibeTags = [];
  final List<String> _photoUrls = [];

  final MapController _mapController = MapController();
  LatLng _coords = const LatLng(10.7769, 106.7009);
  final TextEditingController _locationSearchCtrl = TextEditingController();
  final FocusNode _locationSearchNode = FocusNode();

  List<Map<String, dynamic>> _placeSuggestions = const [];
  bool _isSearchingPlaces = false;
  int _searchSequence = 0;
  Timer? _searchDebounce;
  int _selectedCoverPreset = 0;
  late final AnimationController _heroPulse;

  static const List<String> _locationQuickQueries = [
    'Đại học',
    'Trường THPT',
    'Sân bay',
    'Trung tâm thương mại',
    'Bến xe',
    'Ga tàu',
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreateEventCubit>();
    _apiService = sl<EventApiService>();
    _heroPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..repeat(reverse: true);

    final now = DateTime.now();
    _startDate = now.add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 19, minute: 0);
    _endDate = _startDate;
    _endTime = const TimeOfDay(hour: 21, minute: 0);

    _locationNameCtrl.text = '';
    _addressCtrl.text = '';
    _locationSearchCtrl.text = '';

    _locationSearchNode.addListener(() {
      if (_locationSearchNode.hasFocus && _placeSuggestions.isEmpty) {
        _runPlaceSearch(_locationSearchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollController.dispose();

    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationNameCtrl.dispose();
    _addressCtrl.dispose();
    _tagCtrl.dispose();
    _locationSearchCtrl.dispose();
    _locationSearchNode.dispose();
    _searchDebounce?.cancel();
    _heroPulse.dispose();

    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String _tr(String key) => AppLocalizations.tr(key);

  Future<void> _pickDate({required bool isEnd}) async {
    final initialDate = isEnd ? (_endDate ?? _startDate) : _startDate;
    final firstDate = isEnd ? _startDate : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      }
    });
  }

  Future<void> _pickTime({required bool isEnd}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isEnd ? (_endTime ?? _startTime) : _startTime,
    );
    if (picked == null) return;

    setState(() {
      if (isEnd) {
        _endTime = picked;
      } else {
        _startTime = picked;
      }
    });
  }

  DateTime _mergeDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

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

  Future<void> _searchPlaces(String query) async {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () async {
      await _runPlaceSearch(query);
    });
  }

  Future<void> _runPlaceSearch(String query) async {
    // We allow empty query to show top/recommended places

    final requestId = ++_searchSequence;
    setState(() => _isSearchingPlaces = true);

    final result = await _apiService.searchPlaces(query.trim());

    if (!mounted || requestId != _searchSequence) {
      return;
    }

    setState(() {
      _placeSuggestions = result;
      _isSearchingPlaces = false;
    });
  }

  void _applyPlaceSelection(Map<String, dynamic> place) {
    final lat = (place['lat'] as num?)?.toDouble() ?? _coords.latitude;
    final lng = (place['lng'] as num?)?.toDouble() ?? _coords.longitude;
    final point = LatLng(lat, lng);

    setState(() {
      final name = place['name'] as String? ?? '';
      final address = place['address'] as String? ?? '';

      // Show full details in search box for better clarity as requested
      _locationSearchCtrl.text = address.isNotEmpty ? '$name, $address' : name;

      _locationNameCtrl.text = name;
      _addressCtrl.text = address;
      _coords = point;
      _placeSuggestions = const [];
    });

    _mapController.move(point, 16.2);
    _apiService.recordPlaceSelection(place);
    FocusScope.of(context).unfocus();
  }

  Future<void> _submitEvent() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _descriptionCtrl.text.trim().isEmpty) {
      VibeSnackBar.warning(context, _tr('event_validation_title_description'));
      return;
    }

    if (_locationNameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      VibeSnackBar.warning(context, _tr('event_validation_location'));
      return;
    }

    final startDateTime = _mergeDateTime(_startDate, _startTime);
    DateTime? endDateTime;
    if (_endDate != null && _endTime != null) {
      endDateTime = _mergeDateTime(_endDate!, _endTime!);
      if (!endDateTime.isAfter(startDateTime)) {
        VibeSnackBar.warning(context, _tr('event_validation_end_time'));
        return;
      }
    }

    // Default Cover Selection if no cover uploaded
    final finalPhotoUrls = List<String>.from(_photoUrls);
    if (finalPhotoUrls.isEmpty) {
      final titleHash = _titleCtrl.text.trim().hashCode.abs();
      final coverIndex = (titleHash % 20) + 1;
      finalPhotoUrls.add(
        'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-$coverIndex.webp',
      );
    }

    _cubit.updateVibe(_titleCtrl.text.trim(), _selectedCategory.name, [
      ..._vibeTags,
      'preset:$_selectedCoverPreset',
    ]);
    _cubit.updateSchedule(
      _startDate,
      _startTime,
      _maxParticipants,
      _isEliteOnly,
      _isPublic,
    );
    _cubit.updateLocation(
      _locationNameCtrl.text.trim(),
      _addressCtrl.text.trim(),
      _coords,
    );

    await _cubit.submitEvent(
      extraData: {
        'description': _descriptionCtrl.text.trim(),
        'category': _selectedCategory.name,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime?.toIso8601String(),
        'maxParticipants': _maxParticipants,
        'latitude': _coords.latitude,
        'longitude': _coords.longitude,
        'photoUrls': finalPhotoUrls,
        'locationName': _locationNameCtrl.text.trim(),
        'location': _addressCtrl.text.trim(),
        'isPublic': _isPublic,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF0E121A) : const Color(0xFFF4F6FB);
    final card = _isDark ? const Color(0xFF161D2A) : Colors.white;
    final border = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final sectionHint = _isDark
        ? AppColors.darkTextHint
        : const Color(0xFF8B97B6);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: bg,
        extendBodyBehindAppBar: true,
        appBar: VibeHeader(
          title: _tr('create_event_title_new'),
          actions: [
            VibeHeaderButton(
              icon: Icons.auto_awesome_rounded,
              onTap: () {},
              isDark: _isDark,
              color: AppColors.primary,
            ),
          ],
        ),
        body: BlocConsumer<CreateEventCubit, CreateEventState>(
          listener: (context, state) {
            if (state.isSuccess) {
              // Professional state refresh
              sl<import_event_bloc.EventBloc>().add(
                import_event_bloc.LoadEvents(),
              );

              context.router.replaceAll([const HomeRoute()]);
              VibeSnackBar.success(context, _tr('event_create_success'));
            } else if (state.error != null) {
              VibeSnackBar.error(
                context,
                '${_tr('event_create_error')}: ${state.error}',
              );
            }
          },
          builder: (context, state) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      VibeHeader.headerHeight + 20,
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
                      _cardShell(card, border, _coreSection()),
                      const SizedBox(height: 18),
                      _sectionHeader(
                        _tr('event_section_schedule').toUpperCase(),
                        sectionHint,
                      ),
                      const SizedBox(height: 10),
                      _cardShell(card, border, _scheduleSection()),
                      const SizedBox(height: 18),
                      _sectionHeader(
                        _tr('event_section_location').toUpperCase(),
                        sectionHint,
                      ),
                      const SizedBox(height: 10),
                      _cardShell(card, border, _locationSection()),
                    ],
                  ),
                  _bottomButton(state),
                  if (state.isSubmitting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VibeLoading(
                              size: 18,
                              strokeWidth: 2.2,
                              segments: 10,
                            ),
                            const SizedBox(width: 10),
                            Text(_tr('event_create_loading')),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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

  Widget _coreSection() {
    final border = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
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
                    'Add at least 1 photo to unlock premium cover quality.',
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

  Widget _scheduleSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _pickerButton(
                Icons.calendar_month_rounded,
                _formatDate(_startDate),
                () => _pickDate(isEnd: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pickerButton(
                Icons.schedule_rounded,
                _startTime.format(context),
                () => _pickTime(isEnd: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _pickerButton(
                Icons.event_available_rounded,
                _endDate == null ? '-' : _formatDate(_endDate!),
                () => _pickDate(isEnd: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pickerButton(
                Icons.timelapse_rounded,
                _endTime == null ? '-' : _endTime!.format(context),
                () => _pickTime(isEnd: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _stepperRow(
          title: _tr('event_field_max_participants'),
          value: _maxParticipants,
          min: 2,
          max: 50,
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

  Widget _locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VibeTextField(
          controller: _locationSearchCtrl,
          label: _tr('event_field_search_place'),
          hint: _tr('event_field_search_place_hint'),
          onChanged: _searchPlaces,
          prefixIcon: Icons.search_rounded,
          suffix: _isSearchingPlaces
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: VibeLoading(size: 16, strokeWidth: 2, segments: 8),
                )
              : null,
          focusNode: _locationSearchNode,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _locationQuickQueries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final query = _locationQuickQueries[index];
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  _locationSearchCtrl.text = query;
                  _searchPlaces(query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    query,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_placeSuggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF151B2A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.36,
              ),
              child: Scrollbar(
                thumbVisibility: _placeSuggestions.length > 5,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _placeSuggestions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AppColors.borderLight.withValues(alpha: 0.65),
                  ),
                  itemBuilder: (context, index) {
                    final option = _placeSuggestions[index];
                    return InkWell(
                      onTap: () => _applyPlaceSelection(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['name'] as String? ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option['address'] as String? ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        if (_placeSuggestions.isEmpty && _locationNameCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 12),
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
                        _locationNameCtrl.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.secondary,
                        ),
                      ),
                      if (_addressCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _addressCtrl.text,
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
      ],
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

  Widget _pickerButton(IconData icon, String text, VoidCallback onTap) {
    final bgColor = _isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor = _isDark
        ? AppColors.darkBorderLight
        : AppColors.borderLight;
    final textColor = _isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
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
              max: max.toDouble(),
              divisions: max - min,
              value: value.toDouble(),
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
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: value == quick
                              ? AppColors.primary
                              : (_isDark
                                    ? AppColors.darkBorderLight
                                    : AppColors.borderLight),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (value == quick)
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          if (value == quick) const SizedBox(width: 4),
                          Text(
                            '$quick',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: value == quick
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
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
    final cardBg = _isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF7F9FF);
    final activeBorder = AppColors.primary.withValues(alpha: 0.24);
    final normalBorder = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.borderLight;
    final titleColor = _isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? activeBorder : normalBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : (_isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value
                  ? AppColors.primary
                  : (_isDark ? AppColors.darkTextHint : AppColors.textHint),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: value ? AppColors.primary : titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _bottomButton(CreateEventState state) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 14,
      child: VibeButton(
        label: state.isSubmitting
            ? _tr('event_create_loading')
            : _tr('event_create_button'),
        isLoading: state.isSubmitting,
        onPressed: state.isSubmitting ? null : _submitEvent,
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
