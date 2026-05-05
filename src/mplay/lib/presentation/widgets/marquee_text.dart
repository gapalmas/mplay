import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.gap = 48,
    this.velocity = 36,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final TextStyle? style;
  final double gap;
  final double velocity;
  final TextAlign textAlign;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        final textWidth = textPainter.width;
        final textHeight = textPainter.height;
        final availableWidth = constraints.maxWidth;

        if (textWidth <= availableWidth) {
          _controller.stop();
          return SizedBox(
            width: availableWidth,
            height: textHeight,
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: effectiveStyle,
              textAlign: widget.textAlign,
            ),
          );
        }

        final loopWidth = textWidth + widget.gap;
        final duration = Duration(
          milliseconds: ((loopWidth / widget.velocity) * 1000).round(),
        );

        if (_controller.duration != duration || !_controller.isAnimating) {
          _controller
            ..duration = duration
            ..repeat();
        }

        final textChild = Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: effectiveStyle,
        );

        return ClipRect(
          child: SizedBox(
            height: textHeight,
            width: availableWidth,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final offset = -_controller.value * loopWidth;
                return OverflowBox(
                  minWidth: 0,
                  maxWidth: loopWidth * 2,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        textChild,
                        SizedBox(width: widget.gap),
                        textChild,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
