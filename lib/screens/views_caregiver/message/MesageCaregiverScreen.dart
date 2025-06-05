import 'package:flutter/material.dart';

import 'package:happyp/config/themes/colors/AppColors.dart';

class ChatMessage {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String avatarUrl;
  final bool isOnline;

  ChatMessage({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
    required this.isOnline,
  });
}

class MessageCaregiverScreen extends StatefulWidget {
  const MessageCaregiverScreen({super.key});

  @override
  State<MessageCaregiverScreen> createState() => _MessageCaregiverScreenState();
}

class _MessageCaregiverScreenState extends State<MessageCaregiverScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<ChatMessage> _chats = [
    ChatMessage(
      name: 'Juan Pérez',
      message: 'Hola, ¿cómo estás hoy?',
      time: '10:30',
      unreadCount: 2,
      avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      isOnline: true,
    ),
    ChatMessage(
      name: 'María López',
      message: 'Te envié la información que pediste',
      time: '09:15am',
      unreadCount: 1,
      avatarUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
      isOnline: false,
    ),
    ChatMessage(
      name: 'Carlos Rodríguez',
      message: '¿Nos vemos mañana para la revisión?',
      time: 'Ayer',
      unreadCount: 0,
      avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
      isOnline: true,
    ),
    ChatMessage(
      name: 'Ana Martínez',
      message: 'Gracias por tu ayuda',
      time: 'Ayer',
      unreadCount: 3,
      avatarUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
      isOnline: true,
    ),
    ChatMessage(
      name: 'Roberto Sánchez',
      message: 'Confirmado para el lunes',
      time: '23/05',
      unreadCount: 0,
      avatarUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
      isOnline: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Mostrar menú de opciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.separated(
              itemCount: _chats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(chat.avatarUrl),
                        ),
                        if (chat.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          chat.time,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.message,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Navegar a la conversación individual
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: GestureDetector(
        onTap: () {
          /*Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SearchRealTimeScreen()),
          );*/
        },
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.3),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar mascota...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}