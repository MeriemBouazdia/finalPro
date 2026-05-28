// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import './widget/theme_provider.dart';
import 'package:app/l10n/translations.dart';
import '../theme/app_colors.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String key;
  final String text;
  final String sender;
  final DateTime? timestamp;
  final bool read;

  const ChatMessage({
    required this.key,
    required this.text,
    required this.sender,
    this.timestamp,
    required this.read,
  });

  bool get isAdmin => sender == 'admin';

  factory ChatMessage.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);
    DateTime? ts;
    final raw = data['timestamp'];
    if (raw is int) ts = DateTime.fromMillisecondsSinceEpoch(raw);
    return ChatMessage(
      key: snap.key ?? '',
      text: data['text'] as String? ?? '',
      sender: data['sender'] as String? ?? 'user',
      timestamp: ts,
      read: data['read'] as bool? ?? false,
    );
  }
}

// ── List item wrapper ────────────────────────────────────────────────────────

class _ListItem {
  final bool isDivider;
  final String? label;
  final ChatMessage? message;

  const _ListItem.divider(String l)
      : isDivider = true,
        label = l,
        message = null;

  const _ListItem.message(ChatMessage m)
      : isDivider = false,
        label = null,
        message = m;
}

// ── ChatScreen ───────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _loading = true;
  DatabaseReference? _msgsRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottom > 0) _scrollToBottom();
  }

  void _initChat() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _msgsRef = _db.ref('users/$uid/messages');
    _msgsRef!.orderByChild('timestamp').onValue.listen((event) {
      if (!mounted) return;
      final snap = event.snapshot;
      final msgs = <ChatMessage>[];

      if (snap.exists && snap.value != null) {
        final raw = Map<String, dynamic>.from(snap.value as Map);
        for (final entry in raw.entries) {
          msgs.add(ChatMessage.fromSnapshot(snap.child(entry.key)));
        }
        msgs.sort((a, b) {
          if (a.timestamp == null && b.timestamp == null) return 0;
          if (a.timestamp == null) return -1;
          if (b.timestamp == null) return 1;
          return a.timestamp!.compareTo(b.timestamp!);
        });
        for (final m in msgs) {
          if (m.isAdmin && !m.read) {
            _msgsRef!.child(m.key).update({'read': true});
          }
        }
      }

      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      await _db.ref('users/$uid/messages').push().set({
        'text': text,
        'sender': 'user',
        'timestamp': ServerValue.timestamp,
        'read': false,
      });
    } catch (e) {
      if (mounted) {
        final tr = Translations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr.get('failedToSend')}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _focusNode.requestFocus();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  String _formatDateDivider(DateTime dt, Translations tr) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return tr.get('today');
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return tr.get('yesterday');
    }
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  List<_ListItem> _buildListItems(Translations tr) {
    final items = <_ListItem>[];
    String? lastDate;
    for (final msg in _messages) {
      final dateKey = msg.timestamp != null
          ? DateFormat('yyyy-MM-dd').format(msg.timestamp!)
          : null;
      if (dateKey != null && dateKey != lastDate) {
        lastDate = dateKey;
        items.add(_ListItem.divider(_formatDateDivider(msg.timestamp!, tr)));
      }
      items.add(_ListItem.message(msg));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: ThemeColors.background(isDark),
      appBar: ChatAppBar(isDark: isDark, tr: tr),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? _LoadingView(isDark: isDark)
                : _messages.isEmpty
                    ? EmptyChatView(isDark: isDark, tr: tr)
                    : MessageList(
                        items: _buildListItems(tr),
                        scrollCtrl: _scrollCtrl,
                        formatTime: _formatTime,
                        isDark: isDark,
                      ),
          ),
          ChatInputBar(
            controller: _controller,
            focusNode: _focusNode,
            sending: _sending,
            isDark: isDark,
            tr: tr,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final Translations tr;

  const ChatAppBar({super.key, required this.isDark, required this.tr});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : Colors.white;
    return AppBar(
      backgroundColor: ThemeColors.appBar(isDark),
      foregroundColor: foreground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ThemeColors.border(isDark)),
      ),
      leadingWidth: 56,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: foreground,
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const _AdminAvatar(size: 38),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.get('greenIQ'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr.get('online'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final double size;
  const _AdminAvatar({this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          'AD',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final bool isDark;
  const _LoadingView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class EmptyChatView extends StatelessWidget {
  final bool isDark;
  final Translations tr;

  const EmptyChatView({super.key, required this.isDark, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.15)
                  : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr.get('noMessagesYet'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ThemeColors.text(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr.get('sendAMessageToGetStarted'),
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.secondaryText(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── MessageList ──────────────────────────────────────────────────────────────

class MessageList extends StatelessWidget {
  final List<_ListItem> items;
  final ScrollController scrollCtrl;
  final String Function(DateTime?) formatTime;
  final bool isDark;

  const MessageList({
    super.key,
    required this.items,
    required this.scrollCtrl,
    required this.formatTime,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.isDivider) {
          return DateDivider(label: item.label!, isDark: isDark);
        }
        return MessageBubble(
          message: item.message!,
          formatTime: formatTime,
          isDark: isDark,
        );
      },
    );
  }
}

// ── DateDivider ──────────────────────────────────────────────────────────────

class DateDivider extends StatelessWidget {
  final String label;
  final bool isDark;

  const DateDivider({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = ThemeColors.border(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ThemeColors.secondaryText(isDark),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: borderColor)),
        ],
      ),
    );
  }
}

// ── MessageBubble ────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String Function(DateTime?) formatTime;
  final bool isDark;

  const MessageBubble({
    super.key,
    required this.message,
    required this.formatTime,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = !message.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const _AdminAvatar(size: 30),
            const SizedBox(width: 8),
          ],
          _BubbleContent(
            message: message,
            isMe: isMe,
            isDark: isDark,
            formattedTime: formatTime(message.timestamp),
          ),
          if (!isMe) const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ── Bubble Content ────────────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;
  final String formattedTime;

  const _BubbleContent({
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.primary : ThemeColors.card(isDark);
    final textColor = isMe ? Colors.white : ThemeColors.text(isDark);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.68,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border:
                  isMe ? null : Border.all(color: ThemeColors.border(isDark)),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.shadow(isDark),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14.5,
                color: textColor,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10.5,
                  color: ThemeColors.secondaryText(isDark),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.read ? Icons.done_all_rounded : Icons.done_rounded,
                  size: 13,
                  color: message.read
                      ? AppColors.success
                      : ThemeColors.secondaryText(isDark),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── ChatInputBar ─────────────────────────────────────────────────────────────

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool isDark;
  final Translations tr;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.isDark,
    required this.tr,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: ThemeColors.surface(isDark),
        border: Border(top: BorderSide(color: ThemeColors.border(isDark))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _InputField(
              controller: controller,
              focusNode: focusNode,
              isDark: isDark,
              hintText: tr.get('messageAdmin'),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            controller: controller,
            sending: sending,
            isDark: isDark,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final String hintText;
  final void Function(String) onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hintText,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: ThemeColors.inputFill(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ThemeColors.border(isDark)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 14.5,
          color: ThemeColors.text(isDark),
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: ThemeColors.secondaryText(isDark),
            fontSize: 14.5,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

// ── Send Button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final VoidCallback onSend;

  const _SendButton({
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: hasText && !sending ? onSend : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasText ? AppColors.primary : ThemeColors.border(isDark),
              borderRadius: BorderRadius.circular(22),
            ),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 19,
                    color: hasText
                        ? Colors.white
                        : ThemeColors.secondaryText(isDark),
                  ),
          ),
        );
      },
    );
  }
}
