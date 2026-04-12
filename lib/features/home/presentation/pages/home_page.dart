import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final EventBloc _eventBloc;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadEvents());
  }

  @override
  void dispose() {
    _eventBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeroSection(),
                  const SizedBox(height: 32),
                  _buildCategoriesRow(),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Kèo Gần Đây',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildNearbyEventsList(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('CURRENT LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textHint, letterSpacing: 1)),
               Text('Ho Chi Minh City', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondary),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.secondary),
          onPressed: () {},
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.secondary),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              ),
            )
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Tonight's Vibes",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BlocBuilder<EventBloc, EventState>(
            builder: (context, state) {
              if (state is EventLoading || state is EventInitial) {
                 return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (state is EventLoaded) {
                 final highlighted = state.events.take(3).toList();
                 return PageView.builder(
                   controller: PageController(viewportFraction: 0.9),
                   itemCount: highlighted.length,
                   itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildHeroCard(highlighted[index]),
                      );
                   },
                 );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Event event) {
    return GestureDetector(
      onTap: () => context.router.push(EventDetailRoute(eventId: event.id)),
      child: Container(
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(32),
           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
           image: DecorationImage(
             image: NetworkImage(event.photoUrls.isNotEmpty ? event.photoUrls.first : 'https://picsum.photos/400/600'),
             fit: BoxFit.cover,
           )
        ),
        child: Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(32),
             gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
           ),
           padding: const EdgeInsets.all(24),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                if (event.matchScore > 80)
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(30)),
                   child: Text('⚡ ${event.matchScore.toInt()}% MATCH', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ) else const SizedBox(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                           child: Text('${event.categoryEmoji} ${event.categoryName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                         ),
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                           child: const Text('📍 1.2 km', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Text(
                       event.title,
                       style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                     ),
                     const SizedBox(height: 16),
                     Row(
                       children: [
                          CircleAvatar(radius: 16, backgroundImage: NetworkImage(event.hostAvatar)),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Hosted by ${event.hostName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                             decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                             child: const Text('JOIN VIBE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          )
                       ],
                     )
                  ],
                )
             ],
           ),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('Explore', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
               Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
         const SizedBox(height: 16),
         SizedBox(
           height: 48,
           child: ListView(
             scrollDirection: Axis.horizontal,
             padding: const EdgeInsets.symmetric(horizontal: 24),
             physics: const BouncingScrollPhysics(),
             children: [
                _buildCategoryChip('All', null, isSelected: _selectedCategory == 'All'),
                _buildCategoryChip('Sports', '🏃', isSelected: _selectedCategory == 'Sports'),
                _buildCategoryChip('Dining', '🍜', isSelected: _selectedCategory == 'Dining'),
                _buildCategoryChip('Social', '💬', isSelected: _selectedCategory == 'Social'),
                _buildCategoryChip('Arts', '🎨', isSelected: _selectedCategory == 'Arts'),
                _buildCategoryChip('Outdoors', '⛺', isSelected: _selectedCategory == 'Outdoors'),
                _buildCategoryChip('Gaming', '🎮', isSelected: _selectedCategory == 'Gaming'),
             ],
           ),
         ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? emoji, {required bool isSelected}) {
     final bool isDark = Theme.of(context).brightness == Brightness.dark;
     final Color catColor = label == 'All' ? AppColors.primary : AppColors.getCategoryColor(label);
     
     return GestureDetector(
       onTap: () {
         HapticFeedback.selectionClick();
         setState(() => _selectedCategory = label);
         _eventBloc.add(LoadEvents(category: label == 'All' ? null : label));
       },
       child: AnimatedContainer(
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeOutCubic,
         margin: const EdgeInsets.only(right: 14),
         padding: const EdgeInsets.symmetric(horizontal: 22),
         decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [catColor.withValues(alpha: 0.9), catColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      (isDark ? AppColors.darkCardBackground : Colors.white),
                      (isDark ? AppColors.darkCardBackground : Colors.white).withValues(alpha: 0.9)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
               color: isSelected ? catColor.withValues(alpha: 0.5) : (isDark ? AppColors.darkBorderLight : AppColors.borderLight),
               width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected 
                ? [
                    BoxShadow(color: catColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6)),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 0), spreadRadius: 1)
                  ] 
                : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                  ],
         ),
         alignment: Alignment.center,
         child: Row(
           children: [
             if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 16)), 
                const SizedBox(width: 8)
             ],
             Text(
               label,
               style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.secondaryMedium),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: isSelected ? 0.2 : 0,
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildNearbyEventsList() {
    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        if (state is EventLoaded) {
           final events = state.events.skip(3).toList();
           if (events.isEmpty) {
              return const SliverToBoxAdapter(
                 child: Padding(
                   padding: EdgeInsets.all(32.0),
                   child: Center(child: Text('No more events found in this category.', style: TextStyle(color: AppColors.textSecondary))),
                 )
              );
           }
           return SliverList(
             delegate: SliverChildBuilderDelegate(
               (context, index) {
                 final event = events[index];
                 return Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                   child: InkWell(
                     onTap: () => context.router.push(EventDetailRoute(eventId: event.id)),
                     borderRadius: BorderRadius.circular(16),
                     child: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: AppColors.borderLight),
                       ),
                       child: Row(
                         children: [
                           Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(image: NetworkImage(event.photoUrls.isNotEmpty ? event.photoUrls.first : 'https://picsum.photos/100'), fit: BoxFit.cover),
                              ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Row(
                                    children: [
                                      Text('${event.categoryEmoji} ${event.categoryName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                                      const Spacer(),
                                      const Text('📍 2.5km', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                       SizedBox(
                                         width: 60,
                                         height: 24,
                                         child: Stack(
                                           children: event.participantAvatars.take(3).toList().asMap().entries.map((e) => 
                                              Positioned(
                                                left: e.key * 14.0,
                                                child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(e.value)),
                                              )
                                           ).toList()
                                         ),
                                       ),
                                       Text('${event.currentParticipants}/${event.maxParticipants} Joined', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                    ],
                                  )
                               ],
                             ),
                           )
                         ],
                       ),
                     ),
                   ),
                 );
               },
               childCount: events.length,
             ),
           );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }
}
