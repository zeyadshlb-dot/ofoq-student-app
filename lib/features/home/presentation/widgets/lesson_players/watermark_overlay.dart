import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WatermarkOverlay extends StatefulWidget {
  final String studentName;
  final String? studentPhone;
  final bool animate;

  const WatermarkOverlay({
    super.key,
    required this.studentName,
    this.studentPhone,
    this.animate = true,
  });

  @override
  State<WatermarkOverlay> createState() => _WatermarkOverlayState();
}

class _WatermarkOverlayState extends State<WatermarkOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double x = 50;
  double y = 50;
  double dx = 1.25;
  double dy = 0.85;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 32),
      )..addListener(_move);
      _controller.repeat();
    }
  }

  void _move() {
    final size = MediaQuery.of(context).size;
    setState(() {
      x += dx;
      y += dy;

      if (x < 0 || x > size.width - 150) dx = -dx;
      if (y < 0 || y > 200) dy = -dy; // Keeping it within video bounds
    });
  }

  @override
  void dispose() {
    if (widget.animate) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return IgnorePointer(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => Center(
            child: Transform.rotate(
              angle: -0.4,
              child: Opacity(
                opacity: 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.studentPhone != null)
                      Text(
                        widget.studentPhone!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.25,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.studentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (widget.studentPhone != null)
                Text(
                  widget.studentPhone!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
