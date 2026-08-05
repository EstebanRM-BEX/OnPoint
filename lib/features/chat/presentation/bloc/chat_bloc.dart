import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';
import 'package:wms_app/features/chat/domain/usecases/ensure_conversation.dart';
import 'package:wms_app/features/chat/domain/usecases/get_contacts.dart';
import 'package:wms_app/features/chat/domain/usecases/get_conversations.dart';
import 'package:wms_app/features/chat/domain/usecases/get_current_user.dart';
import 'package:wms_app/features/chat/domain/usecases/get_messages.dart';
import 'package:wms_app/features/chat/domain/usecases/send_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC del feature de chat. Inyecta use cases (no repositorios) y expone un
/// único estado inmutable. Es un singleton global: la burbuja lee el badge y
/// el diálogo comparte la misma instancia.
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetCurrentUser getCurrentUser;
  final GetConversations getConversations;
  final GetContacts getContacts;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final EnsureConversation ensureConversation;

  ChatBloc({
    required this.getCurrentUser,
    required this.getConversations,
    required this.getContacts,
    required this.getMessages,
    required this.sendMessage,
    required this.ensureConversation,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatRetried>(_onStarted);
    on<ChatConversationOpened>(_onConversationOpened);
    on<ChatContactSelected>(_onContactSelected);
    on<ChatBackToList>(_onBackToList);
    on<ChatSearchChanged>(_onSearchChanged);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMediaSent>(_onMediaSent);
  }

  Future<void> _onStarted(ChatEvent event, Emitter<ChatState> emit) async {
    // Ya cargado: no recargamos (la burbuja puede reabrirse sin coste).
    if (state.status == ChatStatus.ready) return;
    emit(state.copyWith(status: ChatStatus.loading, errorMessage: null));

    final userRes = await getCurrentUser(NoParams());
    final convosRes = await getConversations(NoParams());
    final contactsRes = await getContacts(NoParams());

    final failure = userRes.getLeft().toNullable() ??
        convosRes.getLeft().toNullable() ??
        contactsRes.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(
          status: ChatStatus.error, errorMessage: failure.message));
      return;
    }

    emit(state.copyWith(
      status: ChatStatus.ready,
      currentUser: userRes.getRight().toNullable(),
      conversations: convosRes.getRight().toNullable(),
      contacts: contactsRes.getRight().toNullable(),
    ));
  }

  Future<void> _onConversationOpened(
    ChatConversationOpened event,
    Emitter<ChatState> emit,
  ) async {
    await _openThread(event.conversation, emit);
  }

  Future<void> _onContactSelected(
    ChatContactSelected event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(view: ChatView.thread, loadingThread: true));
    final res = await ensureConversation(event.contact);
    await res.fold(
      (f) async => emit(state.copyWith(
          view: ChatView.list, loadingThread: false, errorMessage: f.message)),
      (convo) async => _openThread(convo, emit, alreadyInThread: true),
    );
  }

  /// Abre un hilo: cambia de panel, marca la conversación como leída en el
  /// listado y carga sus mensajes.
  Future<void> _openThread(
    ChatConversation convo,
    Emitter<ChatState> emit, {
    bool alreadyInThread = false,
  }) async {
    emit(state.copyWith(
      view: ChatView.thread,
      activeConversation: convo,
      activeMessages: const [],
      loadingThread: true,
      conversations: _markRead(convo.id),
    ));

    final res = await getMessages(convo.id);
    res.fold(
      (f) => emit(state.copyWith(
          loadingThread: false, errorMessage: f.message)),
      (messages) => emit(state.copyWith(
          loadingThread: false, activeMessages: messages)),
    );
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(state.copyWith(view: ChatView.list));
  }

  void _onSearchChanged(ChatSearchChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    await _send(emit, (convo, me) => SendMessageParams(
          conversationId: convo.id,
          authorId: me.id,
          text: text,
        ));
  }

  Future<void> _onMediaSent(
    ChatMediaSent event,
    Emitter<ChatState> emit,
  ) async {
    await _send(emit, (convo, me) => SendMessageParams(
          conversationId: convo.id,
          authorId: me.id,
          type: event.type,
          mediaSource: event.source,
          audioDuration: event.audioDuration,
        ));
  }

  /// Persiste un mensaje y actualiza listado + hilo. El hilo se refresca
  /// también vía el controller del widget (inserción optimista).
  Future<void> _send(
    Emitter<ChatState> emit,
    SendMessageParams Function(ChatConversation convo, ChatContact me) build,
  ) async {
    final convo = state.activeConversation;
    final me = state.currentUser;
    if (convo == null || me == null) return;

    final res = await sendMessage(build(convo, me));
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (msg) {
        final updated = state.conversations
            .map((c) => c.id == convo.id
                ? c.copyWith(
                    lastMessage: msg.preview, lastMessageAt: msg.createdAt)
                : c)
            .toList()
          ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        emit(state.copyWith(
          conversations: updated,
          activeMessages: [...state.activeMessages, msg],
        ));
      },
    );
  }

  /// Devuelve el listado con la conversación [id] marcada como leída.
  List<ChatConversation> _markRead(String id) => state.conversations
      .map((c) => c.id == id ? c.copyWith(unreadCount: 0) : c)
      .toList();
}
