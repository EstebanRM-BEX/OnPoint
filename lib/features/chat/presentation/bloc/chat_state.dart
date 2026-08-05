part of 'chat_bloc.dart';

/// Estado de la carga general del chat.
enum ChatStatus { initial, loading, ready, error }

/// Panel visible dentro del diálogo.
enum ChatView { list, thread }

/// Estado único e inmutable del chat.
///
/// Un solo estado (en lugar de múltiples clases) evita perder el listado al
/// abrir un hilo y hace triviales las transiciones lista <-> hilo.
class ChatState {
  final ChatStatus status;
  final ChatView view;
  final List<ChatConversation> conversations;
  final List<ChatContact> contacts;
  final ChatContact? currentUser;

  /// Conversación abierta (cuando [view] == thread).
  final ChatConversation? activeConversation;

  /// Mensajes de la conversación activa (semilla del hilo).
  final List<ChatMessage> activeMessages;

  /// Cargando los mensajes del hilo recién abierto.
  final bool loadingThread;
  final String searchQuery;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.view = ChatView.list,
    this.conversations = const [],
    this.contacts = const [],
    this.currentUser,
    this.activeConversation,
    this.activeMessages = const [],
    this.loadingThread = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Total de mensajes sin leer (para el badge de la burbuja global).
  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Conversaciones filtradas por el texto de búsqueda.
  List<ChatConversation> get filteredConversations {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where((c) =>
            c.contact.name.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  /// Contactos filtrados por el texto de búsqueda.
  List<ChatContact> get filteredContacts {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.role.toLowerCase().contains(q))
        .toList();
  }

  ChatState copyWith({
    ChatStatus? status,
    ChatView? view,
    List<ChatConversation>? conversations,
    List<ChatContact>? contacts,
    ChatContact? currentUser,
    ChatConversation? activeConversation,
    List<ChatMessage>? activeMessages,
    bool? loadingThread,
    String? searchQuery,
    String? errorMessage,
  }) =>
      ChatState(
        status: status ?? this.status,
        view: view ?? this.view,
        conversations: conversations ?? this.conversations,
        contacts: contacts ?? this.contacts,
        currentUser: currentUser ?? this.currentUser,
        activeConversation: activeConversation ?? this.activeConversation,
        activeMessages: activeMessages ?? this.activeMessages,
        loadingThread: loadingThread ?? this.loadingThread,
        searchQuery: searchQuery ?? this.searchQuery,
        errorMessage: errorMessage,
      );
}
