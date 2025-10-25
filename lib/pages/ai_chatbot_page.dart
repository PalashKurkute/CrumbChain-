import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class AIChatbotPage extends StatefulWidget {
  final User? user;

  const AIChatbotPage({super.key, this.user});

  @override
  State<AIChatbotPage> createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends State<AIChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  GenerativeModel? _model;
  String _currentModel = '';

  // Model priority list - tries in order until one works
  final List<String> _modelPriority = [
    'gemini-1.5-flash', // ⚡ Fastest, lowest cost
    'gemini-1.5-flash-latest', // Alternative naming
    'gemini-pro', // Stable fallback
    'gemini-1.5-flash-8b', // 🚀 Ultra-fast, very low cost
    'gemini-1.5-pro', // 🧠 Complex reasoning
    'gemini-1.5-pro-latest', // Alternative naming
    'gemini-1.0-pro', // 📊 Stable, general-purpose
    'models/gemini-1.5-flash', // With models/ prefix
    'models/gemini-pro', // With models/ prefix
  ];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _addWelcomeMessage();
  }

  void _initializeGemini() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      print(
        'API Key loaded: ${apiKey.isNotEmpty ? "Yes (${apiKey.substring(0, 10)}...)" : "No"}',
      );

      if (apiKey.isEmpty) {
        _showError('API key not found. Please add GEMINI_API_KEY to .env file');
        return;
      }

      if (!apiKey.startsWith('AIzaSy')) {
        _showError(
          'Invalid API key format. Gemini API keys should start with "AIzaSy"',
        );
        return;
      }

      // Try models in priority order
      _tryInitializeWithModels(apiKey);
    } catch (e) {
      print('Initialization error: $e');
      _showError('Failed to initialize Gemini: $e');
    }
  }

  void _tryInitializeWithModels(String apiKey) {
    // Try gemini-1.5-flash first (highest priority)
    try {
      _model = GenerativeModel(
        model: _modelPriority[0],
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
      );
      _currentModel = _modelPriority[0];
      print('Successfully initialized with model: $_currentModel');
    } catch (e) {
      print('Failed to initialize with ${_modelPriority[0]}: $e');
      // Will fallback during first message send if this model doesn't work
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              'Hello! I\'m your CrumbChain AI assistant powered by Gemini. I can help you with:\n\n'
              '• Information about food donation\n'
              '• Tips for reducing food waste\n'
              '• Questions about our platform\n'
              '• Government schemes and programs\n\n'
              'How can I assist you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_model == null) {
      _showError('AI model not initialized');
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    // Try to send message with fallback logic
    await _sendWithFallback(userMessage);
  }

  Future<void> _sendWithFallback(String userMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    for (int i = 0; i < _modelPriority.length; i++) {
      try {
        // If not the first attempt, reinitialize with next model
        if (i > 0 || _model == null) {
          _model = GenerativeModel(
            model: _modelPriority[i],
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              topK: 40,
              topP: 0.95,
              maxOutputTokens: i < 3 ? 8192 : 2048, // Adjust based on model
            ),
          );
          _currentModel = _modelPriority[i];
          print('Trying model: $_currentModel');
        }

        final content = [Content.text(userMessage)];
        final response = await _model!.generateContent(content);

        setState(() {
          _messages.add(
            ChatMessage(
              text: response.text ?? 'Sorry, I couldn\'t generate a response.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });

        _scrollToBottom();
        print('Success with model: $_currentModel');
        return; // Success, exit the loop
      } catch (e) {
        print('Failed with ${_modelPriority[i]}: $e');

        // If this is the last model, show error
        if (i == _modelPriority.length - 1) {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    'Sorry, unable to connect to Gemini AI.\n\n'
                    'Possible issues:\n'
                    '• API key may be invalid or expired\n'
                    '• API key might not have Gemini API enabled\n'
                    '• Network connectivity issues\n\n'
                    'Please:\n'
                    '1. Verify your API key at: https://aistudio.google.com/apikey\n'
                    '2. Ensure Generative Language API is enabled\n'
                    '3. Try generating a new API key',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
        }
        // Otherwise, continue to next model in the loop
      }
    }
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE07A3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFFE07A3E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by Gemini',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE07A3E),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: const Color(0xFFFCEEDD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE07A3E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CommonFooter(selectedIndex: 2, user: widget.user),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A3E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFFE07A3E),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFFE07A3E)
                    : const Color(0xFFFCEEDD),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A3E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFFE07A3E),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
