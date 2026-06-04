import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WhatsAppIcon extends StatelessWidget {
  final double size;
  final double opacity;

  const WhatsAppIcon({
    super.key,
    required this.size,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SvgPicture.asset(
        'assets/whatsapp.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
