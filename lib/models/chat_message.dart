import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String senderId;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [senderId, text, timestamp];
}
