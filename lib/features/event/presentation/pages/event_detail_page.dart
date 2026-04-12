import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/event.dart';
import '../bloc/event_detail_cubit.dart';

@RoutePage()
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, @PathParam('id') required this.eventId});

  final String eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final EventDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EventDetailCubit>();
    _cubit.loadEvent(widget.eventId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showParticipantsList(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text('${event.currentParticipants} Joined', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: event.participantAvatars.length,
                  itemBuilder: (context, index) {
                     return ListTile(
                       contentPadding: const EdgeInsets.symmetric(vertical: 8),
                       leading: CircleAvatar(
                         radius: 24,
                         backgroundImage: NetworkImage(event.participantAvatars[index]),
                         onBackgroundImageError: (_, __) {},
                         backgroundColor: AppColors.bgSecondary,
                       ),
                       title: Text('Member ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.secondary)),
                       subtitle: const Text('Vibe Level: Elite', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                       trailing: ElevatedButton(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(
                           elevation: 0,
                           backgroundColor: AppColors.primarySurface,
                           foregroundColor: AppColors.primary,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                         ),
                         child: const Text('View'),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<EventDetailCubit, EventDetailState>(
          builder: (context, state) {
            if (state is EventDetailLoading || state is EventDetailInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is EventDetailError) {
              return Center(child: Text('Failed to load vibe: ${state.message}', style: const TextStyle(color: AppColors.textSecondary)));
            } else if (state is EventDetailLoaded) {
              final event = state.event;
              return Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      _buildSliverAppBar(event),
                      SliverToBoxAdapter(
                         child: _buildContent(event),
                      ),
                    ],
                  ),
                  _buildBottomBar(event, state.isJoining),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    final imageUrl = event.photoUrls.isNotEmpty ? event.photoUrls.first : 'https://picsum.photos/800/400';
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary, size: 20),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.secondary, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
             Image.network(
               imageUrl,
               fit: BoxFit.cover,
               errorBuilder: (context, error, stackTrace) => Container(color: AppColors.bgSecondary, child: const Icon(Icons.image_not_supported, color: AppColors.textHint)),
             ),
            Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Colors.black54, Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                   stops: const [0.0, 0.5, 1.0],
                 )
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Event event) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      transform: Matrix4.translationValues(0, -32, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 140), // extra padding for bottom bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                   child: Text('${event.categoryEmoji} ${event.categoryName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                if (event.isEliteOnly) 
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(10)),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.verified_rounded, size: 14, color: AppColors.warning),
                         SizedBox(width: 4),
                         Text('Elite Only', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 12)),
                       ],
                     ),
                   ),
                if (event.vibeTags != null && event.vibeTags!.isNotEmpty)
                   ...event.vibeTags!.split(',').take(2).map((t) => Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
                     child: Text(t.trim(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                   )),
              ],
            ),
            const SizedBox(height: 20),
            Text(event.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.secondary, height: 1.15, letterSpacing: -0.5)),
            const SizedBox(height: 32),
            
            // Host Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 26,
                     backgroundImage: NetworkImage(event.hostAvatar.isNotEmpty ? event.hostAvatar : 'https://i.pravatar.cc/100'),
                     onBackgroundImageError: (_, __) {},
                   ),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Hosted by', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w700)),
                         Text(event.hostName.isNotEmpty ? event.hostName : 'Unknown Vibe Caster', style: const TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.w900)),
                       ],
                     ),
                   ),
                   ElevatedButton(
                     onPressed: () {},
                     style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySurface,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.w800)),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // AI Match Bar
            if (event.matchScore > 0) ...[
               Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(blue: 200)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 const Text('AI Vibe Match', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
                                 Text('${event.matchScore.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                               ],
                             ),
                             const SizedBox(height: 10),
                             ClipRRect(
                               borderRadius: BorderRadius.circular(6),
                               child: LinearProgressIndicator(
                                 value: (event.matchScore / 100).clamp(0.0, 1.0),
                                 backgroundColor: Colors.white.withValues(alpha: 0.3),
                                 valueColor: const AlwaysStoppedAnimation(Colors.white),
                                 minHeight: 8,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
               ),
               const SizedBox(height: 32),
            ],

            // DateTime & Location
            _infoRow(Icons.calendar_month_rounded, 'Date & Time', '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year} • ${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 20),
            _infoRow(Icons.location_on_rounded, event.location.name, event.location.address, hasAction: true),
            
            const SizedBox(height: 32),

            // Circle Size
            GestureDetector(
              onTap: () => _showParticipantsList(event), // Open bottom sheet on tap
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('The Circle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                        Row(
                          children: [
                            Text('${event.currentParticipants}/${event.maxParticipants} Joined', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: event.maxParticipants > 0 ? (event.currentParticipants / event.maxParticipants).clamp(0.0, 1.0) : 0,
                        backgroundColor: AppColors.borderLight,
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (event.participantAvatars.isNotEmpty)
                      Row(
                        children: [
                           ...event.participantAvatars.take(5).map((avatar) => Padding(
                             padding: const EdgeInsets.only(right: -10.0), // Overlapping active effect
                             child: Container(
                               decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                               child: CircleAvatar(
                                 radius: 18, 
                                 backgroundImage: NetworkImage(avatar),
                                 onBackgroundImageError: (_, __) {},
                               ),
                             ),
                           )),
                           if (event.currentParticipants > 5)
                             Padding(
                               padding: const EdgeInsets.only(left: 14.0),
                               child: Text('+${event.currentParticipants - 5} more', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 13)),
                             )
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // About
            const Text('About this vibe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondary)),
            const SizedBox(height: 16),
            Text(
              event.description.isNotEmpty ? event.description : 'Come join us and have a great time! Looking forward to meeting new people who match this vibe.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle, {bool hasAction = false}) {
     return Row(
       children: [
         Container(
           padding: const EdgeInsets.all(14),
           decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(16)),
           child: Icon(icon, color: AppColors.primary, size: 24),
         ),
         const SizedBox(width: 16),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondary)),
               const SizedBox(height: 4),
               Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
             ],
           ),
         ),
         if (hasAction)
           Container(
             decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight), shape: BoxShape.circle),
             child: IconButton(
               icon: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
               onPressed: () {},
             ),
           )
       ],
     );
  }

  Widget _buildBottomBar(Event event, bool isJoining) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36), // SafeArea inclusive
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95), // Slight transparency for modern feel
          border: const Border(top: BorderSide(color: AppColors.bgSecondary, width: 2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                  const Text('Price per pax', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(event.price == null || event.price == 0 ? 'Free' : '\$${event.price}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.secondary)),
               ],
             ),
             const SizedBox(width: 24),
             Expanded(
               child: ElevatedButton(
                 onPressed: isJoining ? null : () => _cubit.toggleJoinLeave(),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: event.isJoined ? AppColors.bgSecondary : AppColors.primary,
                   foregroundColor: event.isJoined ? AppColors.textSecondary : Colors.white,
                   elevation: event.isJoined ? 0 : 8,
                   padding: const EdgeInsets.symmetric(vertical: 18),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                   shadowColor: AppColors.primary.withValues(alpha: 0.4),
                 ),
                 child: isJoining
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                     : Text(
                         event.isJoined ? 'LEAVE VIBE' : 'JOIN VIBE 🚀',
                         style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 16, 
                            letterSpacing: 0.5,
                            color: event.isJoined ? AppColors.error : Colors.white
                         ),
                       ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
