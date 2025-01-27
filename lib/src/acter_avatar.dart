import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('ActerAvatar');

/// ActerAvatar allows you to display the different types of Avatars in the
/// acter.global app.
///
/// If no avatar is found, the widget renders the fallback according to the
/// configured `DisplayMode`. If an avatar is found, that is being shown. Any
/// image resizing (for memory purposes) has to be done beforehand, the image
/// is shown as given.
class ActerAvatar extends StatefulWidget {
  /// Set the display mode for this Avatar
  final DisplayMode mode;

  /// The size this Avatar has
  final double? size;

  /// the uniqueId of this object (e.g. full username or roomId)
  /// used to calculate the Multiavatar in `DisplayMode.User`.
  final String uniqueId;

  /// the display name they've chosen
  final String? displayName;

  /// a canonical uniqueName to use instead of the uniqueId in the tooltip, if given.
  /// most commonly this is the canonical alias for a space/room rather than the roomID
  final String? uniqueName;

  /// If and how to display the tooltip
  final TooltipStyle tooltip;

  /// The actual avatar (takes precedence)
  final ImageProvider<Object>? avatar;

  /// Or alternatively a future that loads the avatar (show fallback until loaded)
  final Future<ImageProvider<Object>>? imageProviderFuture;

  ActerAvatar(
      {Key? key,
      this.displayName,
      this.uniqueName,
      required this.uniqueId,
      required this.mode,
      this.tooltip = TooltipStyle.Combined,
      this.avatar,
      this.imageProviderFuture,
      this.size})
      : super(key: key ?? Key('avatar-$uniqueId-$size'));

  @override
  _ActerAvatar createState() => _ActerAvatar();
}

class _ActerAvatar extends State<ActerAvatar> {
  bool _imgSuccess = false;
  ImageProvider<Object>? _avatar;
  @override
  void initState() {
    super.initState();
    ImageStreamListener listener =
        ImageStreamListener(_setImage, onError: _setError);
    if (widget.avatar != null) {
      widget.avatar!.resolve(ImageConfiguration()).addListener(listener);
    } else if (widget.imageProviderFuture != null) {
      _fetchImageProvider(listener);
    }
  }

  void _fetchImageProvider(ImageStreamListener listener) async {
    var res = await widget.imageProviderFuture!;
    res.resolve(ImageConfiguration()).addListener(listener);
    setState(() {
      _avatar = res;
    });
  }

  void _setImage(ImageInfo image, bool sync) {
    setState(() => _imgSuccess = true);
  }

  void _setError(Object obj, StackTrace? st) {
    setState(() => _imgSuccess = false);
    dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = inner(context);
    switch (widget.tooltip) {
      case TooltipStyle.DisplayName:
        return Tooltip(
            message: widget.displayName ?? widget.uniqueId, child: child);
      case TooltipStyle.UniqueId:
        return Tooltip(message: widget.uniqueId, child: child);
      case TooltipStyle.Combined:
        var message = widget.uniqueName ?? widget.uniqueId;
        if (widget.displayName != null) {
          message = '${widget.displayName} (${widget.uniqueId})';
        }
        return Tooltip(message: message, child: child);
      case TooltipStyle.None:
        return child;
    }
  }

  Widget inner(BuildContext context) {
    if (widget.avatar != null && _imgSuccess == true) {
      return renderWithAvatar(context, widget.avatar!);
    } else if (_avatar != null && _imgSuccess == true) {
      return renderWithAvatar(context, _avatar!);
    } else {
      return renderFallback(context);
    }
  }

  void avatarError(Object error, StackTrace? stackTrace) {
    log.warning(
      'Error loading avatar for ${widget.uniqueId}. Returning to fallback.',
      error,
      stackTrace,
    );
    setState(() {
      _avatar = null;
      _imgSuccess = false;
    });
  }

  Widget renderWithAvatar(BuildContext context, ImageProvider avatar) {
    /// Fallback
    switch (widget.mode) {
      case DisplayMode.User:
      case DisplayMode.DM:
        // User fallback mode
        return CircleAvatar(
          foregroundImage: avatar,
          onForegroundImageError: avatarError,
          radius: widget.size ?? 24,
        );
      case DisplayMode.Space:
      case DisplayMode.GroupChat:
        return Container(
          height: widget.size ?? 24,
          width: widget.size ?? 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: avatar,
              onError: avatarError,
            ),
          ),
        );
    }
  }

  Widget renderFallback(BuildContext context) {
    /// Fallback
    switch (widget.mode) {
      case DisplayMode.User:
        // User fallback mode
        return MultiAvatar(
          uniqueId: widget.uniqueId,
          size: widget.size ?? 24,
        );
      case DisplayMode.Space:
        return TextAvatar(
          text: widget.displayName ?? widget.uniqueId,
          sourceText: widget.uniqueId,
          size: widget.size ?? 24,
          shape: Shape.Rectangle,
        );

      case DisplayMode.GroupChat:
        // FIXME: add support for groupchat style
        return SizedBox(
          height: widget.size ?? 24,
          width: widget.size ?? 24,
        );

      case DisplayMode.DM:
        // FIXME: add support for dm style
        return SizedBox(
          height: widget.size ?? 24,
          width: widget.size ?? 24,
        );
    }
  }
}
