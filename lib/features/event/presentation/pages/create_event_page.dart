import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../data/services/event_api_service.dart';
import '../bloc/create_event_cubit.dart';

@RoutePage()
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  late final CreateEventCubit _cubit;
  late final EventApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  // Step 1 State
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  String _selectedCat = 'Sports';
  final List<String> _vibeTags = [];
  final List<String> _photos = []; // mock photo paths

  // Step 2 State
  late DateTime _date;
  late TimeOfDay _time;
  double _participants = 12;
  bool _isElite = false;
  bool _isPublic = true;

  // Step 3 State
  final MapController _mapController = MapController();
  LatLng _coords = const LatLng(10.7769, 106.7009); // Default HCMC D1
  String _address = 'District 1, Ho Chi Minh City';
  String _locName = 'District 1 Center';

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreateEventCubit>();
    _apiService = sl<EventApiService>();
    _date = DateTime.now().add(const Duration(days: 1));
    _time = const TimeOfDay(hour: 19, minute: 0);
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollController.dispose();
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _submitVibe() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a vibe title!')));
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    
    _cubit.updateVibe(_titleCtrl.text.trim(), _selectedCat, _vibeTags);
    _cubit.updateSchedule(_date, _time, _participants.toInt(), _isElite, _isPublic);
    _cubit.updateLocation(_locName, _address, _coords);
    _cubit.submitEvent();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<CreateEventCubit, CreateEventState>(
            listener: (context, state) {
              if (state.isSuccess) {
                 context.router.replaceAll([const HomeRoute()]);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vibe created successfully! 🎉'), backgroundColor: AppColors.success));
              } else if (state.error != null) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}'), backgroundColor: AppColors.error));
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
                          children: [
                             const SizedBox(height: 24),
                             _buildSectionTitle("What's the Vibe?", "Give your event a persona"),
                             const SizedBox(height: 24),
                             _buildVibeSection(),
                             
                             const SizedBox(height: 40),
                             _buildSectionTitle("Schedule & Size", "When and how many?"),
                             const SizedBox(height: 24),
                             _buildScheduleSection(),

                             const SizedBox(height: 40),
                             _buildSectionTitle("The Destination", "Where is it happening?"),
                             const SizedBox(height: 24),
                             _buildDestinationSection(),

                             const SizedBox(height: 48),
                             _buildCreateSection(state),
                             const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (state.isSubmitting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppColors.primary),
                                SizedBox(height: 16),
                                Text('Casting your vibe...', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.bgSecondary, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.router.maybePop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.secondary, size: 24),
          ),
          const Text('Create Vibe', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHint)),
      ],
    );
  }

  // ──────────────────────────────────────────
  // SECTION: VIBE
  // ──────────────────────────────────────────
  Widget _buildVibeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'e.g., Midnight Padel & Smoothie',
            hintStyle: const TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: AppColors.bgSecondary,
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _suggestChip('Weekend Coffee Run'),
              _suggestChip('Casual Bowling'),
              _suggestChip('Photography Walk'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text("Event Category", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
             _catBox('🏃', 'Sports', AppColors.categorySports),
             _catBox('🍜', 'Dining', AppColors.categoryDining),
             _catBox('💬', 'Social', AppColors.categorySocial),
             _catBox('🎨', 'Arts', AppColors.categoryArts),
             _catBox('⛺', 'Outdoors', AppColors.categoryOutdoors),
             _catBox('🎮', 'Gaming', AppColors.categoryGaming),
          ],
        ),
        const SizedBox(height: 32),
        const Text("Vibe Tags", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._vibeTags.map((tag) => Container(
               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
               decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(tag, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                   const SizedBox(width: 6),
                   GestureDetector(
                     onTap: () => setState(() => _vibeTags.remove(tag)),
                     child: const Icon(Icons.close, color: AppColors.primary, size: 14),
                   ),
                 ],
               ),
            )),
            SizedBox(
              width: 140,
              height: 40,
              child: TextField(
                controller: _tagCtrl,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty && !_vibeTags.contains(val.trim())) {
                    setState(() { _vibeTags.add(val.trim()); _tagCtrl.clear(); });
                  }
                },
                decoration: InputDecoration(
                  hintText: '+ Add tag',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text("Photos (Max 5)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: () {
                if (_photos.length < 5) {
                  setState(() => _photos.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200'));
                }
              },
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 2, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: AppColors.textHint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _photos.map((url) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.remove(url)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 10, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  )).toList(),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _suggestChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.primarySurface, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => setState(() => _titleCtrl.text = text),
      ),
    );
  }

  Widget _catBox(String emoji, String text, Color catColor) {
    final isSelected = _selectedCat == text;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCat = text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [catColor.withValues(alpha: 0.15), catColor.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? catColor.withValues(alpha: 0.5) : AppColors.borderLight,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: catColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected ? catColor.withValues(alpha: 0.15) : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? catColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // SECTION: SCHEDULE
  // ──────────────────────────────────────────
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Date & Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        const SizedBox(height: 12),
        Row(
           children: [
             Expanded(
               child: _pickerButton(Icons.calendar_month_rounded, '${_date.day}/${_date.month}/${_date.year}', () async {
                 final dt = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 100)));
                 if (dt != null) setState(() => _date = dt);
               }),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: _pickerButton(Icons.access_time_rounded, _time.format(context), () async {
                 final t = await showTimePicker(context: context, initialTime: _time);
                 if (t != null) setState(() => _time = t);
               }),
             ),
           ],
        ),
        const SizedBox(height: 32),
        const Text("Circle Size", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        const SizedBox(height: 16),
        Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(20)),
           child: Column(
             children: [
               Text('${_participants.toInt()} Participants', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
               const SizedBox(height: 12),
               Slider(
                 value: _participants,
                 min: 2, max: 50, divisions: 48,
                 activeColor: AppColors.primary,
                 inactiveColor: AppColors.borderLight,
                 onChanged: (v) => setState(() => _participants = v),
               ),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: const [
                   Text('Intimate (2)', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w700, fontSize: 12)),
                   Text('Party (50)', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w700, fontSize: 12)),
                 ],
               ),
             ],
           ),
        ),
        const SizedBox(height: 24),
        _buildToggleRow(
          icon: Icons.public_rounded,
          title: 'Publicly Visible',
          subtitle: 'Appear on discovery map',
          val: _isPublic,
          onChanged: (v) => setState(() => _isPublic = v),
        ),
        const SizedBox(height: 16),
        _buildToggleRow(
          icon: Icons.verified_rounded,
          title: 'Elite Match Priority',
          subtitle: 'Boost vibe exclusively to top profiles.',
          val: _isElite,
          onChanged: (v) => setState(() => _isElite = v),
        ),
      ],
    );
  }

  Widget _pickerButton(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(icon, color: AppColors.primary, size: 18),
             const SizedBox(width: 8),
             Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({required IconData icon, required String title, required String subtitle, required bool val, required ValueChanged<bool> onChanged}) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         border: Border.all(color: val ? AppColors.primarySurface : AppColors.bgSecondary, width: 2),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Row(
         children: [
           Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: val ? AppColors.primarySurface : AppColors.bgSecondary, shape: BoxShape.circle), child: Icon(icon, color: val ? AppColors.primary : AppColors.textHint, size: 20)),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: val ? AppColors.primary : AppColors.secondary)),
                 const SizedBox(height: 2),
                 Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
               ],
             ),
           ),
           Switch(value: val, activeTrackColor: AppColors.primary, onChanged: onChanged),
         ],
       ),
     );
  }

  // ──────────────────────────────────────────
  // SECTION: DESTINATION
  // ──────────────────────────────────────────
  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
            return await _apiService.searchPlaces(textEditingValue.text);
          },
          displayStringForOption: (option) => option['name'],
          onSelected: (option) {
            final lat = option['lat'] as double;
            final lng = option['lng'] as double;
            final pos = LatLng(lat, lng);
            setState(() {
              _locName = option['name'];
              _address = option['address'];
              _coords = pos;
            });
            _mapController.move(pos, 16.0);
            FocusScope.of(context).unfocus(); // dismiss kb
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search for places...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.bgSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: options.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.bgSecondary),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(option['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(option['address'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => onSelected(option),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bgSecondary, width: 2),
          ),
          child: ClipRRect(
             borderRadius: BorderRadius.circular(18),
             child: Stack(
               children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                       initialCenter: _coords,
                       initialZoom: 15.0,
                       onTap: (tapPosition, point) {
                          setState(() { _coords = point; _address = 'Custom Location'; _locName = 'Pinned Location'; });
                          _mapController.move(point, 15.0);
                       },
                    ),
                    children: [
                       TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.vibepulse.app'),
                       MarkerLayer(
                         markers: [
                           Marker(point: _coords, width: 40, height: 40, child: const Icon(Icons.location_on, color: AppColors.primary, size: 40)),
                         ],
                       ),
                    ],
                  ),
                  Positioned(
                    bottom: 12, left: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_locName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(_address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
               ],
             ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // SECTION: CREATE BUTTON
  // ──────────────────────────────────────────
  Widget _buildCreateSection(CreateEventState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: state.isSubmitting ? null : _submitVibe,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            child: const Text('CREATE VIBE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}
