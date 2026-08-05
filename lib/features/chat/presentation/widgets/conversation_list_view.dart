import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:wms_app/features/chat/presentation/widgets/contacts_strip.dart';
import 'package:wms_app/features/chat/presentation/widgets/conversation_tile.dart';

/// Panel izquierdo del diálogo: búsqueda, contactos y conversaciones.
class ConversationListView extends StatelessWidget {
  const ConversationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.conversations != b.conversations ||
          a.contacts != b.contacts ||
          a.searchQuery != b.searchQuery,
      builder: (context, state) {
        return Column(
          children: [
            _SearchField(
              onChanged: (q) => bloc.add(ChatSearchChanged(q)),
            ),
            Expanded(child: _body(context, state, bloc)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, ChatState state, ChatBloc bloc) {
    if (state.status == ChatStatus.loading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColorApp));
    }
    if (state.status == ChatStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'No se pudo cargar el chat.',
        onRetry: () => bloc.add(const ChatRetried()),
      );
    }

    final convos = state.filteredConversations;
    final contacts = state.filteredContacts;
    final searching = state.searchQuery.trim().isNotEmpty;

    if (convos.isEmpty && contacts.isEmpty) {
      return const _EmptyView(message: 'Sin resultados');
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (!searching) ...[
          const ChatSectionHeader('Contactos'),
          ContactsStrip(
            contacts: state.contacts,
            onContactTap: (c) => bloc.add(ChatContactSelected(c)),
          ),
        ],
        ChatSectionHeader(searching ? 'Conversaciones' : 'Recientes'),
        if (convos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: _EmptyView(message: 'Sin conversaciones'),
          )
        else
          ...convos.map((c) => ConversationTile(
                conversation: c,
                onTap: () => bloc.add(ChatConversationOpened(c)),
              )),
        if (searching && contacts.isNotEmpty) ...[
          const ChatSectionHeader('Contactos'),
          ...contacts.map((c) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: primaryColorAppLigth,
                  child: Text(c.initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
                title: Text(c.name, style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(c.role,
                    style: const TextStyle(fontSize: 11.5)),
                onTap: () => bloc.add(ChatContactSelected(c)),
              )),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar contacto o mensaje…',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
            prefixIcon: const Icon(Icons.search, size: 20, color: grey),
            filled: true,
            fillColor: primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 40, color: lightGrey),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: red),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(foregroundColor: primaryColorApp),
              ),
            ],
          ),
        ),
      );
}
