import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart'; // Add this import
import '../models/chat_message.dart';
import '../Theme.dart'; // Import your theme

class ChatScreen extends StatefulWidget {
  final String uid; // <-- store uid

  const ChatScreen({super.key, required this.uid}); 

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Get API key from environment variables
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addMessage(ChatMessage(
      text:
          'Hello! I am your Gut Health AI Assistant. I provide professional information on gut health, the digestive system, nutrition, and related topics. Please note that my advice is for reference only. For serious health concerns, consult a doctor.\n\nWhat gut health concern can I help you with today?',
      isUser: false,
    ));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  if (apiKey.isEmpty) {
    _addMessage(ChatMessage(
      text: '⚠️ API key not found. Please check your .env configuration.',
      isUser: false,
    ));
    return;
  }

  // Add user message
  _addMessage(ChatMessage(text: text, isUser: true));
  _textController.clear();

  setState(() => _isLoading = true);

  try {
    bool isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    String language = isChinese ? "Chinese" : "English";

    String healthPrompt = """
You are a professional Gut Health AI Assistant.  
Answer ONLY about gut health, digestive system, nutrition, and related health issues.  
If unrelated, politely guide the user back.  

User language: **$language**  
Reply in **$language** with a warm, professional tone.  

User Question: $text
""";

    const int maxRetries = 3;
    int attempt = 0;
    Duration delay = Duration(seconds: 2);
    http.Response response;

    while (true) {
      attempt++;
      response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': healthPrompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 429 && attempt < maxRetries) {
        // Too many requests → wait and retry
        _addMessage(ChatMessage(
          text: '⏳ Rate limit reached. Retrying in ${delay.inSeconds}s...',
          isUser: false,
        ));
        await Future.delayed(delay);
        delay *= 2; // exponential backoff
        continue;
      }
      break;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      String? aiResponse =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (aiResponse != null && aiResponse.isNotEmpty) {
        _addMessage(ChatMessage(text: aiResponse, isUser: false));
      } else {
        _addMessage(ChatMessage(
          text: '⚠️ No response received from AI. Please try again.',
          isUser: false,
        ));
      }
    } else if (response.statusCode == 429) {
      _addMessage(ChatMessage(
        text:
            '❌ Rate limit exceeded. Please wait a few minutes and try again later.',
        isUser: false,
      ));
    } else {
      _addMessage(ChatMessage(
        text:
            '❌ Error: ${response.statusCode}. Please check your network or API configuration.',
        isUser: false,
      ));
    }
  } catch (e) {
    _addMessage(ChatMessage(
      text: '❌ Connection error. Please check network/API settings.\n$e',
      isUser: false,
    ));
  } finally {
    setState(() => _isLoading = false);
  }
}



  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.orangeAccent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brownPrimary, width: 2),
                boxShadow: AppTheme.cartoonShadow,
              ),
              child: Icon(
                Icons.medical_services, 
                color: Colors.white, 
                size: 22
              ),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.brownPrimary
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 6),
                  bottomRight: Radius.circular(message.isUser ? 6 : 20),
                ),
                border: Border.all(
                  color: message.isUser 
                    ? AppTheme.brownPrimary 
                    : AppTheme.borderColor,
                  width: 2,
                ),
                boxShadow: AppTheme.cartoonShadow,
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: GoogleFonts.bubblegumSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                          .copyWith(
                        p: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.2,
                        ),
                        h1: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        h2: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        strong: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        em: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      builders: {
                        'p': JustifyParagraphBuilder(),
                      },
                    ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brownPrimary, width: 2),
                boxShadow: AppTheme.cartoonShadow,
              ),
              child: Icon(
                Icons.person, 
                color: Colors.white, 
                size: 22
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppTheme.borderColor, width: 2),
                  boxShadow: AppTheme.cartoonShadow,
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask about gut health...',
                    hintStyle: GoogleFonts.bubblegumSans(
                      color: AppTheme.borderColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: GoogleFonts.bubblegumSans(
                    color: AppTheme.brownPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.orangeAccent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brownPrimary, width: 2),
                boxShadow: AppTheme.cartoonShadow,
              ),
              child: IconButton(
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send, color: Colors.white, size: 24),
                onPressed: _isLoading
                    ? null
                    : () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.orangeAccent.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                Icons.medical_services, 
                color: AppTheme.orangeAccent,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Health AI Assistant',
              style: GoogleFonts.bubblegumSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.brownPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: AppTheme.creamBackground,
        elevation: 0,
        actions: [
          AppTheme.cartoonIconButton(
            icon: Icons.refresh,
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              _addMessage(ChatMessage(
                text:
                    'Hello! I am your Gut Health AI Assistant. I provide professional information on gut health, the digestive system, nutrition, and related topics. Please note that my advice is for reference only. For serious health concerns, consult a doctor.\n\nWhat gut health concern can I help you with today?',
                isUser: false,
              ));
            },
            backgroundColor: AppTheme.cardBackground,
            iconColor: AppTheme.brownPrimary,
            size: 45,
          ),
          SizedBox(width: 16),
        ],
      ),
      backgroundColor: AppTheme.creamBackground,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: EdgeInsets.symmetric(vertical: 12),
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class JustifyParagraphBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    return Text(
      text.text,
      style: preferredStyle,
      textAlign: TextAlign.justify,
    );
  }
}