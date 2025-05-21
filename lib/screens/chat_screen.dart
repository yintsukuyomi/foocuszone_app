import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'dart:math';

class Conversation {
  String id;
  String title;
  List<Message> messages;
  final DateTime createdAt;
  DateTime lastModified;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.lastModified,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((message) => message.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
      };

  // Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((messageJson) => Message.fromJson(messageJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }

  // Generate a title based on first message
  void generateTitle() {
    if (messages.isNotEmpty && messages[0].isUserMessage) {
      // Use the first 30 characters of the first user message as the title
      title = messages[0].text.length > 30
          ? '${messages[0].text.substring(0, 30)}...'
          : messages[0].text;
    } else {
      // Fallback to generic title with timestamp
      title = 'Yeni sohbet ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }
}

class Message {
  String id; // Added for message editing/deleting
  String text;
  bool isUserMessage;
  DateTime time;
  bool isEdited;
  bool isDeleted;

  Message({
    String? id,
    required this.text,
    required this.isUserMessage,
    DateTime? time,
    this.isEdited = false,
    this.isDeleted = false,
  }) : 
      id = id ?? _generateId(),
      time = time ?? DateTime.now();

  // Generate a random ID for the message
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUserMessage': isUserMessage,
        'time': time.toIso8601String(),
        'isEdited': isEdited,
        'isDeleted': isDeleted,
      };

  // Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      isUserMessage: json['isUserMessage'],
      time: DateTime.parse(json['time']),
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class ChatViewModel extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  bool _isLoading = false;
  bool _isUsingFallback = false;
  
  // Constants for storage
  static const String _storageKey = 'chat_conversations';

  // Getters
  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  List<Message> get messages => _activeConversation?.messages ?? [];
  bool get isLoading => _isLoading;
  bool get isUsingFallback => _isUsingFallback;

  // Constructor
  ChatViewModel() {
    _loadConversations();
  }

  // Create a new conversation
  void createNewConversation() {
    final newConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Yeni sohbet',
      messages: [],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    _conversations.insert(0, newConversation);
    _activeConversation = newConversation;
    notifyListeners();
    _saveConversations();
  }

  // Set active conversation
  void setActiveConversation(String conversationId) {
    _activeConversation = _conversations.firstWhere((c) => c.id == conversationId);
    notifyListeners();
  }

  // Delete conversation
  void deleteConversation(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations.removeAt(index);
      
      // If active conversation was deleted, set active to first available or null
      if (_activeConversation?.id == conversationId) {
        _activeConversation = _conversations.isNotEmpty ? _conversations.first : null;
      }
      
      notifyListeners();
      _saveConversations();
    }
  }

  // Add user message
  void addUserMessage(String text) {
    if (text.trim().isEmpty) return;
    
    // Create conversation if none exists
    if (_activeConversation == null) {
      createNewConversation();
    }
    
    final message = Message(text: text, isUserMessage: true);
    _activeConversation!.messages.add(message);
    _activeConversation!.lastModified = DateTime.now();
    
    // Generate a title if this is the first message
    if (_activeConversation!.messages.length == 1) {
      _activeConversation!.generateTitle();
    }
    
    notifyListeners();
    _saveConversations();
    
    // Get AI response
    _getAIResponse(text);
  }

  // Add AI message
  void _addAIMessage(String text) {
    if (_activeConversation == null) return;
    
    final message = Message(text: text, isUserMessage: false);
    _activeConversation!.messages.add(message);
    _activeConversation!.lastModified = DateTime.now();
    notifyListeners();
    _saveConversations();
  }

  // Edit message
  void editMessage(String messageId, String newText) {
    if (_activeConversation == null) return;
    
    final index = _activeConversation!.messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final message = _activeConversation!.messages[index];
      // Only allow editing user messages
      if (message.isUserMessage) {
        message.text = newText;
        message.isEdited = true;
        _activeConversation!.lastModified = DateTime.now();
        notifyListeners();
        _saveConversations();
      }
    }
  }

  // Delete message
  void deleteMessage(String messageId) {
    if (_activeConversation == null) return;
    
    final index = _activeConversation!.messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      // Mark as deleted instead of removing
      _activeConversation!.messages[index].isDeleted = true;
      _activeConversation!.lastModified = DateTime.now();
      notifyListeners();
      _saveConversations();
    }
  }

  // Clear all messages in the active conversation
  void clearConversation() {
    if (_activeConversation != null) {
      _activeConversation!.messages.clear();
      _activeConversation!.lastModified = DateTime.now();
      notifyListeners();
      _saveConversations();
    }
  }

  // Fetch response from OpenAI API
  Future<void> _getAIResponse(String userMessage) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get API key from environment variables
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // Prepare the API request
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': '''Sen FocusZone uygulamasında bulunan kapsamlı bir AI asistansın. 
              Kullanıcılara her konuda yardımcı olabilirsin.
              Özellikle şu konuları iyi bilirsin:
              
              1. Odaklanma, üretkenlik ve görev yönetimi
              2. Pomodoro tekniği ve zaman yönetimi stratejileri
              3. Eğitim ve öğrenme ile ilgili konular
              4. İş dünyası ve kariyer gelişimi
              5. Teknoloji, bilim ve güncel konular
              6. Sağlık, fitness ve iyi yaşam
              7. Kişisel gelişim ve motivasyon
              8. Sanat, kültür ve yaratıcılık
              
              Yanıtların Türkçe olmalı, kullanıcıya hitap şekli saygılı ve samimi olmalı.
              Bilmediğin konularda dürüst ol, yanlış bilgi vermekten kaçın.
              Kullanıcılara karmaşık konularda bile net, doğru ve yararlı yanıtlar ver.
              İhtiyaç duyulduğunda detaylı açıklamalar yapabilirsin.'''
            },
            // Include previous conversation context (limited to last few messages)
            ..._getPreviousMessages(),
            {
              'role': 'user',
              'content': userMessage
            },
          ],
          'max_tokens': 2000, // Increased token limit for more comprehensive responses
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        _isUsingFallback = false;
        _isLoading = false;
        _addAIMessage(aiResponse);
      } else {
        // If API call fails, fall back to local responses
        _useFallbackResponses(userMessage);
      }
    } catch (e) {
      // If any error occurs, use fallback responses
      _useFallbackResponses(userMessage);
    }
  }

  // Use fallback local responses when API is unavailable
  void _useFallbackResponses(String userMessage) {
    _isUsingFallback = true;
    
    // Simple response templates based on user query
    final lowerCaseMessage = userMessage.toLowerCase();
    String response = '';
    
    if (lowerCaseMessage.contains('merhaba') || 
        lowerCaseMessage.contains('selam') || 
        lowerCaseMessage.contains('hey')) {
      response = "Merhaba! Ben FocusZone'un gelişmiş AI asistanıyım. Size her konuda yardımcı olabilirim. Odaklanma, üretkenlik, eğitim, iş hayatı, sağlık veya güncel konular hakkında sorularınızı yanıtlayabilirim. Nasıl yardımcı olabilirim?";
    } else if (lowerCaseMessage.contains('yapabildiğin')) {
      response = "Size birçok konuda yardımcı olabilirim:\n\n• Üretkenlik ve odaklanma teknikleri\n• Eğitim ve öğrenme stratejileri\n• İş ve kariyer tavsiyeleri\n• Teknoloji, bilim ve güncel konular\n• Sağlık ve fitness önerileri\n• Kişisel gelişim ve motivasyon\n• Genel bilgi ve ansiklopedik sorular\n\nSorularınızı mümkün olduğunca detaylı yanıtlamaya çalışacağım!";
    } else if (lowerCaseMessage.contains('pomodoro') || lowerCaseMessage.contains('odaklanma')) {
      response = "Pomodoro Tekniği, 25 dakikalık odaklanma ve 5 dakikalık molalardan oluşan etkili bir zaman yönetimi metodudur. Beynin kısa aralıklarla dinlenmesi üretkenliği artırır. Her 4 pomodoro sonrasında 15-30 dakikalık uzun bir mola verilmesi önerilir. FocusZone uygulaması tam da bu tekniği uygulamanızı kolaylaştırmak için tasarlanmıştır.";
    } else {
      response = "Şu anda çevrimdışı modda çalışıyorum ve yanıtım sınırlı. İnternet bağlantısı sağlandığında, sorunuza daha kapsamlı bir yanıt verebileceğim. FocusZone uygulamasının sunduğu özellikleri kullanmaya devam edebilir, tekrar çevrimiçi olduğumda bana soru sorabilirsiniz.";
    }

    _isLoading = false;
    _addAIMessage(response);
  }

  // Get the last few messages for conversation context
  List<Map<String, String>> _getPreviousMessages() {
    if (_activeConversation == null || _activeConversation!.messages.isEmpty) {
      return [];
    }
    
    // Get visible messages (not deleted)
    final visibleMessages = _activeConversation!.messages
        .where((m) => !m.isDeleted)
        .toList();
        
    // Get the last 10 messages (5 turns of conversation) or fewer
    final int messagesCount = visibleMessages.length;
    final int startIdx = messagesCount > 10 ? messagesCount - 10 : 0;
    
    final contextMessages = <Map<String, String>>[];
    
    for (int i = startIdx; i < messagesCount; i++) {
      final message = visibleMessages[i];
      contextMessages.add({
        'role': message.isUserMessage ? 'user' : 'assistant',
        'content': message.text,
      });
    }
    
    return contextMessages;
  }
  
  // Save conversations to SharedPreferences
  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = _conversations.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonData));
  }

  // Load conversations from SharedPreferences
  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    
    if (data != null) {
      try {
        final jsonData = jsonDecode(data) as List;
        _conversations = jsonData
            .map((json) => Conversation.fromJson(json))
            .toList();
        
        if (_conversations.isNotEmpty) {
          _activeConversation = _conversations.first;
        }
      } catch (e) {
        // Create default conversation on error
        createNewConversation();
      }
    } else {
      // No saved data, create default conversation
      createNewConversation();
    }
    
    notifyListeners();
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatViewModel _chatViewModel;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _chatViewModel = ChatViewModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _controller.clear();
    _chatViewModel.addUserMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEditDialog(Message message) {
    final TextEditingController editController = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              _chatViewModel.editMessage(message.id, editController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteMessageDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              _chatViewModel.deleteMessage(message.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
  
  void _showClearConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Temizle'),
        content: const Text('Bu sohbetteki tüm mesajları silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              _chatViewModel.clearConversation();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tümünü Temizle'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConversationDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: const Text('Bu sohbeti tamamen silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              // Ensure we're using the provider properly
              final viewModel = Provider.of<ChatViewModel>(context, listen: false);
              viewModel.deleteConversation(conversation.id);
              Navigator.of(context).pop();
              // Close drawer if it was open
              if (_isDrawerOpen) {
                setState(() {
                  _isDrawerOpen = false;
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final focusModel = Provider.of<FocusModel>(context);
    
    return ChangeNotifierProvider.value(
      value: _chatViewModel,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              _isDrawerOpen ? Icons.menu_open : Icons.menu,
              color: colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isDrawerOpen = !_isDrawerOpen;
              });
            },
          ),
          actions: [
            Consumer<ChatViewModel>(
              builder: (context, viewModel, _) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.primary),
                  onSelected: (value) {
                    switch (value) {
                      case 'new':
                        viewModel.createNewConversation();
                        break;
                      case 'clear':
                        _showClearConversationDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'new',
                      child: Row(
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('Yeni Sohbet'),
                        ],
                      ),
                    ),
                    if (viewModel.activeConversation != null && 
                        viewModel.activeConversation!.messages.isNotEmpty)
                      const PopupMenuItem<String>(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.cleaning_services),
                            SizedBox(width: 8),
                            Text('Sohbeti Temizle'),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Consumer<ChatViewModel>(
            builder: (context, viewModel, _) {
              return Text(
                viewModel.activeConversation?.title ?? 'AI Asistan',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        body: Stack(
          children: [
            // Main Chat View (always full width)
            Column(
              children: [
                // Premium banner for free users
                if (!focusModel.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: colorScheme.primary.withAlpha(51),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Premium ile her konuda sınırsız AI yanıtları',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to premium screen
                            Navigator.pushNamed(context, '/premium');
                          },
                          child: const Text('Yükselt'),
                        )
                      ],
                    ),
                  ),

                // Fallback mode banner (when API is not working)
                Consumer<ChatViewModel>(
                  builder: (context, viewModel, child) {
                    return viewModel.isUsingFallback 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.amber.withAlpha(51),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, size: 18, color: Colors.amber),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Çevrimdışı mod - Sınırlı yanıtlar',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink();
                  },
                ),
                  
                // Chat messages
                Expanded(
                  child: Consumer<ChatViewModel>(
                    builder: (context, viewModel, child) {
                      // Show placeholder when no conversation is active or conversation has no messages
                      if (viewModel.activeConversation == null || 
                          viewModel.activeConversation!.messages.isEmpty) {
                        return _buildWelcomePlaceholder(colorScheme, isDarkMode);
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.messages.length,
                        itemBuilder: (context, index) {
                          final message = viewModel.messages[index];
                          if (message.isDeleted) {
                            // Show a placeholder for deleted messages
                            return _buildDeletedMessage(colorScheme, isDarkMode, message);
                          }
                          return _buildMessage(message, colorScheme, isDarkMode);
                        },
                      );
                    },
                  ),
                ),
                
                // Typing indicator
                Consumer<ChatViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(51),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Yanıt Yazıyor...',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                // Divider
                Divider(height: 1, color: colorScheme.outlineVariant),
                
                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  color: isDarkMode ? colorScheme.surfaceContainerHighest : colorScheme.surface,
                  child: Row(
                    children: [
                      // Message input field
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            onSubmitted: _handleSubmitted,
                            decoration: InputDecoration(
                              hintText: 'Bir mesaj yazın...',
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      Consumer<ChatViewModel>(
                        builder: (context, viewModel, child) {
                          return IconButton(
                            icon: const Icon(Icons.send),
                            color: colorScheme.primary,
                            onPressed: viewModel.isLoading
                              ? null
                              : () => _handleSubmitted(_controller.text),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Overlay Drawer (when open)
            if (_isDrawerOpen)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 280,
                child: Material(
                  elevation: 16,
                  child: Consumer<ChatViewModel>(
                    builder: (context, viewModel, _) {
                      return _buildConversationDrawer(viewModel, colorScheme, isDarkMode);
                    },
                  ),
                ),
              ),
            
            // Semi-transparent overlay behind drawer (to dismiss on tap)
            if (_isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDrawerOpen = false;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withAlpha(64), // semi-transparent background
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _isDrawerOpen 
            ? null
            : FloatingActionButton(
                onPressed: () => _chatViewModel.createNewConversation(),
                mini: true,
                tooltip: 'Yeni Sohbet',
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
  
  Widget _buildConversationDrawer(ChatViewModel viewModel, ColorScheme colorScheme, bool isDarkMode) {
    return Container(
      color: isDarkMode ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer.withAlpha(76), // Changed from withOpacity(0.3)
            child: Row(
              children: [
                Text(
                  'Sohbetler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Yeni Sohbet',
                  onPressed: viewModel.createNewConversation,
                ),
              ],
            ),
          ),
          
          // Conversations List
          Expanded(
            child: viewModel.conversations.isEmpty
                ? Center(
                    child: Text(
                      'Henüz sohbet yok',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: viewModel.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = viewModel.conversations[index];
                      final isActive = conversation.id == viewModel.activeConversation?.id;
                      
                      return ListTile(
                        tileColor: isActive
                            ? colorScheme.primaryContainer.withAlpha(51)
                            : Colors.transparent,
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? colorScheme.primary
                                : isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          _formatConversationDate(conversation.lastModified),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isActive ? colorScheme.primary : Colors.grey,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            // Make sure we're closing dialog before showing another one
                            _showDeleteConversationDialog(conversation);
                          },
                        ),
                        onTap: () {
                          viewModel.setActiveConversation(conversation.id);
                          // Close drawer on mobile
                          setState(() {
                            _isDrawerOpen = false;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  String _formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  Widget _buildWelcomePlaceholder(ColorScheme colorScheme, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FocusZone AI Asistan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: Text(
              'Odaklanma, üretkenlik, eğitim, iş hayatı ve daha birçok konuda size yardımcı olmak için buradayım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              _controller.text = 'Merhaba, bana yardımcı olabilir misin?';
              _handleSubmitted(_controller.text);
            },
            icon: const Icon(Icons.send),
            label: const Text('Sohbete Başla'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage(ColorScheme colorScheme, bool isDarkMode, Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.withAlpha(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Mesaj silindi',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message, ColorScheme colorScheme, bool isDarkMode) {
    final isUserMessage = message.isUserMessage;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar (only for AI messages)
          if (!isUserMessage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: isUserMessage ? () {
                // Only allow editing user messages
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Düzenle'),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditDialog(message);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Sil', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteMessageDialog(message);
                        },
                      ),
                    ],
                  ),
                );
              } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isUserMessage
                      ? colorScheme.primary
                      : isDarkMode
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUserMessage
                            ? colorScheme.onPrimary
                            : isDarkMode
                                ? Colors.white
                                : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    if (message.isEdited) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(düzenlendi)',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isUserMessage
                              ? colorScheme.onPrimary.withAlpha(179) // Changed from withOpacity(0.7)
                              : isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // User avatar (only for user messages)
          if (isUserMessage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
