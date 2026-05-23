import 'package:flutter/material.dart';

class SanathanColors {
  static const Color background = Color(0xFFFFF8EA);
  static const Color surface = Color(0xFFFFFDF7);
  static const Color surfaceStrong = Color(0xFFFFF1DA);
  static const Color maroon = Color(0xFF8F101D);
  static const Color saffron = Color(0xFFE86D13);
  static const Color gold = Color(0xFFF4B64A);
  static const Color green = Color(0xFF176445);
  static const Color ink = Color(0xFF2C1711);
  static const Color muted = Color(0xFF806252);
  static const Color border = Color(0xFFEAD1B5);
}

class SanathanSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class SanathanScaffold extends StatelessWidget {
  const SanathanScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanathanColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(title),
        actions: actions,
        backgroundColor: SanathanColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class SanathanCard extends StatelessWidget {
  const SanathanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SanathanSpacing.md),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: SanathanColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SanathanColors.border),
        boxShadow: [
          BoxShadow(
            color: SanathanColors.ink.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: card,
    );
  }
}

class SanathanPrimaryButton extends StatelessWidget {
  const SanathanPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SanathanColors.maroon,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class SanathanChip extends StatelessWidget {
  const SanathanChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : SanathanColors.saffron,
            ),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: selected ? SanathanColors.maroon : SanathanColors.surfaceStrong,
      labelStyle: TextStyle(
        color: selected ? Colors.white : SanathanColors.ink,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? SanathanColors.maroon : SanathanColors.border,
        ),
      ),
    );
  }
}

class SanathanFeatureTile extends StatelessWidget {
  const SanathanFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SanathanCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SanathanColors.surfaceStrong,
            child: Icon(icon, color: SanathanColors.saffron),
          ),
          const SizedBox(width: SanathanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SanathanColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SanathanColors.muted),
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class GurujiPromptCard extends StatelessWidget {
  const GurujiPromptCard({
    super.key,
    required this.title,
    required this.prompt,
    this.onTap,
  });

  final String title;
  final String prompt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SanathanCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: SanathanColors.maroon,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: SanathanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SanathanColors.maroon,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(prompt, style: const TextStyle(color: SanathanColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SanathanChatBubble extends StatelessWidget {
  const SanathanChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(SanathanSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? SanathanColors.maroon : SanathanColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser ? SanathanColors.maroon : SanathanColors.border,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : SanathanColors.ink,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class SanathanTextField extends StatelessWidget {
  const SanathanTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      cursorColor: SanathanColors.maroon,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: SanathanColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SanathanColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SanathanColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SanathanColors.maroon),
        ),
      ),
    );
  }
}
