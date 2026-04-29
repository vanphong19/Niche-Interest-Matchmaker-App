import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';

@RoutePage()
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  late final EventBloc _eventBloc;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadMyEvents());
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _eventBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('My Activity', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Hosting'),
              Tab(text: 'Joined'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            if (state is EventLoading || state is EventInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is MyEventsLoaded) {
               return TabBarView(
                 controller: _tabController,
                 children: [
                   _buildEventList(state.hosting, isHost: true),
                   _buildEventList(state.joined, isHost: false),
                   _buildEventList(state.past, isHost: false, isPast: true),
                 ],
               );
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }

  Widget _buildEventList(List<Event> events, {required bool isHost, bool isPast = false}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_rounded, size: 64, color: AppColors.borderMedium),
            const SizedBox(height: 16),
            Text('No events here yet', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   Container(
                     width: 60,
                     height: 60,
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
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                          const SizedBox(height: 4),
                          Text('${event.startDateTime.day}/${event.startDateTime.month} • ${event.location.name}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                       ],
                     ),
                   )
                 ],
               ),
               const SizedBox(height: 16),
               const Divider(color: AppColors.borderLight, height: 1),
               const SizedBox(height: 12),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     isPast ? 'Ended' : 'Starts in 2 days', 
                     style: TextStyle(fontWeight: FontWeight.w800, color: isPast ? AppColors.textHint : AppColors.info, fontSize: 13),
                   ),
                   Row(
                     children: [
                       if (isHost && !isPast) ...[
                         TextButton(
                           onPressed: () {},
                           child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                         ),
                       ],
                       ElevatedButton(
                         onPressed: () => context.router.push(EventDetailRoute(eventId: event.id)),
                         style: ElevatedButton.styleFrom(
                            backgroundColor: isPast ? AppColors.bgSecondary : AppColors.primary,
                            foregroundColor: isPast ? AppColors.secondary : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: Text(isPast ? 'Rate Experience' : (isHost ? 'Manage' : 'Check In'), style: const TextStyle(fontWeight: FontWeight.w800)),
                       ),
                     ],
                   )
                 ],
               )
            ],
          ),
        );
      },
    );
  }
}
