import 'package:account_new/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Card whose surface catches a soft light that follows the pointer.
///
/// Only opacity and the highlight position change, so it stays cheap.
class LightFollowCard extends StatefulWidget {
  const LightFollowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius = 20,
    this.highlightColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double borderRadius;
  final Color? highlightColor;

  @override
  State<LightFollowCard> createState() => _LightFollowCardState();
}

class _LightFollowCardState extends State<LightFollowCard> {
  Offset? _position;
  bool _active = false;

  void _update(Offset local) {
    if (!_active) return;
    setState(() => _position = local);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
    );
    return Card(
      color: widget.color ?? scheme.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Listener(
        onPointerDown: (event) => setState(() {
          _active = true;
          _position = event.localPosition;
        }),
        onPointerMove: (event) => _update(event.localPosition),
        onPointerUp: (_) => setState(() => _active = false),
        onPointerCancel: (_) => setState(() => _active = false),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          splashColor: scheme.primary.withValues(alpha: 0.06),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Stack(
            children: [
              if (_position != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _active ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: CustomPaint(
                        painter: _LightPainter(
                          center: _position!,
                          color: widget.highlightColor ??
                              Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(padding: widget.padding, child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightPainter extends CustomPainter {
  _LightPainter({required this.center, required this.color});

  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.longestSide * 0.55;
    final shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      stops: const [0, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LightPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.color != color;
}

/// Bottom sheet with a light-outline entrance animation.
Future<T?> showImmersiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SheetLight(child: builder(sheetContext)),
  );
}

class _SheetLight extends StatefulWidget {
  const _SheetLight({required this.child});

  final Widget child;

  @override
  State<_SheetLight> createState() => _SheetLightState();
}

class _SheetLightState extends State<_SheetLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Transform.scale(
        scale: 0.98 + 0.02 * curved.value,
        alignment: Alignment.bottomCenter,
        child: Opacity(opacity: curved.value, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: scheme.primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Standard confirm dialog with the app's M3 styling.
Future<bool?> showImmersiveConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Shows a short-lived snack bar that is force-closed after one second.
///
/// Auto-dismiss can be disabled by the platform (e.g. accessibility mode), so
/// this guarantees the message never lingers.
void showBriefSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Color? backgroundColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(message),
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  Future<void>.delayed(const Duration(milliseconds: 1100), () {
    messenger.hideCurrentSnackBar();
  });
}

/// Full-bleed animated gradient background used behind every scaffold.
class ImmersiveBackground extends StatelessWidget {
  const ImmersiveBackground({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientFor(brightness),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
