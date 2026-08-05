import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat;
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';
import 'package:wms_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:wms_app/features/chat/presentation/widgets/attachment_sheet.dart';
import 'package:wms_app/features/chat/presentation/widgets/audio_message_bubble.dart';
import 'package:wms_app/features/chat/presentation/widgets/audio_recorder_sheet.dart';
import 'package:wms_app/features/chat/presentation/widgets/image_message_bubble.dart';

/// Panel derecho: el hilo de mensajes usando `flutter_chat_ui`.
///
/// El [core.InMemoryChatController] es la fuente de verdad de la animación de
/// la lista; se siembra desde el estado del BLoC cada vez que cambia la
/// conversación activa, y en el envío se inserta de forma optimista.
class ChatThreadView extends StatefulWidget {
  const ChatThreadView({super.key});

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final core.InMemoryChatController _controller =
      core.InMemoryChatController();

  /// Id de la conversación ya sembrada en el controller (evita re-sembrar).
  String? _seededConversationId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mapea una entidad de dominio al mensaje del paquete de UI según su tipo.
  core.Message _toCoreMessage(ChatMessage m) => switch (m.type) {
        ChatMessageType.image => core.Message.image(
            id: m.id,
            authorId: m.authorId,
            createdAt: m.createdAt,
            source: m.mediaSource ?? '',
            text: m.text.isEmpty ? null : m.text,
          ),
        ChatMessageType.audio => core.Message.audio(
            id: m.id,
            authorId: m.authorId,
            createdAt: m.createdAt,
            source: m.mediaSource ?? '',
            duration: m.audioDuration ?? Duration.zero,
          ),
        ChatMessageType.text => core.Message.text(
            id: m.id,
            authorId: m.authorId,
            createdAt: m.createdAt,
            text: m.text,
          ),
      };

  void _seed(List<ChatMessage> messages) {
    _controller.setMessages(messages.map(_toCoreMessage).toList());
  }

  String get _localId => 'local_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _onSend(String text) async {
    final bloc = context.read<ChatBloc>();
    final me = bloc.state.currentUser;
    final convo = bloc.state.activeConversation;
    final clean = text.trim();
    if (me == null || convo == null || clean.isEmpty) return;

    // Inserción optimista para respuesta inmediata en UI.
    _controller.insertMessage(core.Message.text(
      id: _localId,
      authorId: me.id,
      createdAt: DateTime.now(),
      text: clean,
    ));
    bloc.add(ChatMessageSent(clean));
  }

  /// Botón de adjuntar (+): abre la hoja de opciones y ejecuta la elegida.
  Future<void> _onAttachment() async {
    final action = await showChatAttachmentSheet(context);
    if (!mounted || action == null) return;
    switch (action) {
      case ChatAttachmentAction.camera:
        await _pickImage(ImageSource.camera);
      case ChatAttachmentAction.gallery:
        await _pickImage(ImageSource.gallery);
      case ChatAttachmentAction.audio:
        await _recordAudio();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (!mounted || file == null) return;
    final me = context.read<ChatBloc>().state.currentUser;
    if (me == null) return;

    _controller.insertMessage(core.Message.image(
      id: _localId,
      authorId: me.id,
      createdAt: DateTime.now(),
      source: file.path,
    ));
    context.read<ChatBloc>().add(
          ChatMediaSent(type: ChatMessageType.image, source: file.path),
        );
  }

  Future<void> _recordAudio() async {
    final result = await showAudioRecorderSheet(context);
    if (!mounted || result == null) return;
    final me = context.read<ChatBloc>().state.currentUser;
    if (me == null) return;

    _controller.insertMessage(core.Message.audio(
      id: _localId,
      authorId: me.id,
      createdAt: DateTime.now(),
      source: result.path,
      duration: result.duration,
    ));
    context.read<ChatBloc>().add(ChatMediaSent(
          type: ChatMessageType.audio,
          source: result.path,
          audioDuration: result.duration,
        ));
  }

  core.ChatTheme _buildTheme() => core.ChatTheme.light().copyWith(
        colors: core.ChatColors.light().copyWith(
          primary: primaryColorApp,
          onPrimary: white,
          surface: white,
          surfaceContainer: secondary,
          surfaceContainerLow: primary,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (a, b) =>
          a.activeConversation?.id != b.activeConversation?.id ||
          a.loadingThread != b.loadingThread ||
          a.activeMessages != b.activeMessages,
      listener: (context, state) {
        final convoId = state.activeConversation?.id;
        // Sembramos solo cuando los mensajes ya cargaron y cambió la conversación.
        if (convoId != null &&
            !state.loadingThread &&
            convoId != _seededConversationId) {
          _seed(state.activeMessages);
          _seededConversationId = convoId;
        }
      },
      builder: (context, state) {
        final convo = state.activeConversation;
        if (convo == null) return const SizedBox.shrink();
        final me = state.currentUser;

        if (state.loadingThread) {
          return const Center(
              child: CircularProgressIndicator(color: primaryColorApp));
        }
        return Chat(
          currentUserId: me?.id ?? 'me',
          chatController: _controller,
          theme: _buildTheme(),
          onMessageSend: _onSend,
          onAttachmentTap: _onAttachment,
          resolveUser: (id) => _resolveUser(id, state),
          builders: core.Builders(
            imageMessageBuilder: (context, message, index,
                    {required isSentByMe, groupStatus}) =>
                ImageMessageBubble(
              source: message.source,
              caption: message.text,
              isSentByMe: isSentByMe,
            ),
            audioMessageBuilder: (context, message, index,
                    {required isSentByMe, groupStatus}) =>
                AudioMessageBubble(
              source: message.source,
              duration: message.duration,
              isSentByMe: isSentByMe,
            ),
          ),
        );
      },
    );
  }

  Future<core.User?> _resolveUser(String id, ChatState state) async {
    if (state.currentUser?.id == id) {
      return core.User(id: id, name: state.currentUser!.name);
    }
    final match = <ChatContact>[
      ...state.contacts,
      if (state.activeConversation != null) state.activeConversation!.contact,
    ].where((c) => c.id == id);
    if (match.isNotEmpty) {
      return core.User(id: id, name: match.first.name);
    }
    return core.User(id: id);
  }
}
