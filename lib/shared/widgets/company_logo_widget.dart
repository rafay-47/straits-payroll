import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;

class CompanyLogoWidget extends StatefulWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final double size;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final IconData fallbackIcon;
  final BoxFit fit;

  const CompanyLogoWidget({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.imageName,
    required this.size,
    required this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.fallbackIcon = Icons.business,
    this.fit = BoxFit.cover,
  });

  @override
  State<CompanyLogoWidget> createState() => _CompanyLogoWidgetState();
}

class _CompanyLogoWidgetState extends State<CompanyLogoWidget> {
  bool _isSvgUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return path.extension(uri.path).toLowerCase() == '.svg';
    } catch (_) {
      return imageUrl.toLowerCase().contains('.svg');
    }
  }

  Widget _buildSvgMemory(Uint8List bytes) {
    return SvgPicture.memory(bytes, fit: widget.fit);
  }

  Widget _buildNetworkImage(String imageUrl) {
    if (_isSvgUrl(imageUrl)) {
      return SvgPicture.network(
        imageUrl,
        fit: widget.fit,
        placeholderBuilder: (context) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: widget.fit,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.imageBytes != null) {
      child = _isSvgUrl(widget.imageName ?? '')
          ? _buildSvgMemory(widget.imageBytes!)
          : Image.memory(
              widget.imageBytes!,
              fit: widget.fit,
              gaplessPlayback: true,
            );
    } else if (widget.imageUrl == null) {
      child = _buildFallback();
    } else {
      child = _buildNetworkImage(widget.imageUrl!);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        widget.fallbackIcon,
        size: widget.size * 0.5,
        color: widget.iconColor,
      ),
    );
  }
}
