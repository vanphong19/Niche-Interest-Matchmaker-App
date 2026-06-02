// lib/features/chat/presentation/cubit/chat_state.dart
import 'package:equatable/equatable.dart';

import '../../data/models/chat_room_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoomModel> rooms;

  const ChatRoomsLoaded(this.rooms);

  @override
  List<Object?> get props => [rooms];
}

class ChatMessagesLoaded extends ChatState {
  final ChatRoomModel room;
  final List<ChatMessageModel> messages;
  final bool isSending;
  final List<String> typingUserNames; // danh sách tên đang typing

  const ChatMessagesLoaded({
    required this.room,
    required this.messages,
    this.isSending = false,
    this.typingUserNames = const [],
  });

  ChatMessagesLoaded copyWith({
    List<ChatMessageModel>? messages,
    bool? isSending,
    List<String>? typingUserNames,
  }) {
    return ChatMessagesLoaded(
      room: room,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      typingUserNames: typingUserNames ?? this.typingUserNames,
    );
  }

  @override
  List<Object?> get props => [room, messages, isSending, typingUserNames];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomOpening extends ChatState {}
