/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Created by box on 2020/4/21.
///
/// 图片预览控件
const double _kMaxDragDistance = 200;
const Duration _kDuration = Duration(milliseconds: 300);

class DragNotification extends Notification {}

class DragStartNotification extends DragNotification {
  final DragStartDetails details;

  DragStartNotification({
    @required this.details,
  }) : assert(details != null);

  @override
  bool operator ==(Object other) => identical(this, other) || other is DragStartNotification && runtimeType == other.runtimeType && details == other.details;

  @override
  int get hashCode => details.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
  }
}

class DragUpdateNotification extends DragNotification {
  final DragUpdateDetails details;
  final Offset startPosition;
  final Offset translationPosition;
  final double scale;
  final double opacity;
  final double dragDistance;
  final double navigationBarOffsetPixels;
  final double bottomBarOffsetPixels;

  DragUpdateNotification({
    @required this.details,
    @required this.startPosition,
    @required this.translationPosition,
    @required this.scale,
    @required this.opacity,
    @required this.dragDistance,
    @required this.navigationBarOffsetPixels,
    @required this.bottomBarOffsetPixels,
  })  : assert(details != null),
        assert(startPosition != null),
        assert(translationPosition != null),
        assert(scale != null),
        assert(opacity != null),
        assert(dragDistance != null),
        assert(navigationBarOffsetPixels != null),
        assert(bottomBarOffsetPixels != null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragUpdateNotification &&
          runtimeType == other.runtimeType &&
          details == other.details &&
          startPosition == other.startPosition &&
          translationPosition == other.translationPosition &&
          scale == other.scale &&
          opacity == other.opacity &&
          dragDistance == other.dragDistance &&
          navigationBarOffsetPixels == other.navigationBarOffsetPixels &&
          bottomBarOffsetPixels == other.bottomBarOffsetPixels;

  @override
  int get hashCode =>
      details.hashCode ^
      startPosition.hashCode ^
      translationPosition.hashCode ^
      scale.hashCode ^
      opacity.hashCode ^
      dragDistance.hashCode ^
      navigationBarOffsetPixels.hashCode ^
      bottomBarOffsetPixels.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
    description.add('startPosition: $startPosition');
    description.add('translationPosition: $translationPosition');
    description.add('scale: $scale');
    description.add('opacity: $opacity');
    description.add('dragDistance: $dragDistance');
    description.add('navigationBarOffsetPixels: $navigationBarOffsetPixels');
    description.add('bottomBarOffsetPixels: $bottomBarOffsetPixels');
  }
}

class DragEndNotification extends DragNotification {
  final DragEndDetails details;

  DragEndNotification({
    @required this.details,
  }) : assert(details != null);

  @override
  bool operator ==(Object other) => identical(this, other) || other is DragEndNotification && runtimeType == other.runtimeType && details == other.details;

  @override
  int get hashCode => details.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
  }
}

typedef NavigationBarBuilder = Widget Function(
  BuildContext context,
  int index,
  int count,
);

typedef ImageProviderBuilder = ImageProvider Function(
  BuildContext context,
  int index,
);

typedef DragEndCallback = bool Function(
  double dragDistance,
  double velocity,
);

class ImageOptions {
  final String url;
  final Size thumbnailSize;
  final String tag;

  ImageOptions({
    @required this.url,
    this.thumbnailSize,
    this.tag,
  });

  bool get isEmpty => url == null || url.isEmpty;

  bool get isNotEmpty => url != null && url.isNotEmpty;

  ImageOptions copyWith({String url, String tag}) {
    return ImageOptions(
      url: url ?? this.url,
      tag: tag ?? this.tag,
    );
  }
}

class _HeroTag {
  const _HeroTag(this.url);

  final String url;

  @override
  String toString() => url;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _HeroTag && other.url == url;
  }

  @override
  int get hashCode {
    return identityHashCode(url);
  }
}

class ImagePreviewHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final CreateRectTween createRectTween;
  final HeroFlightShuttleBuilder flightShuttleBuilder;
  final HeroPlaceholderBuilder placeholderBuilder;
  final bool transitionOnUserGestures;

  const ImagePreviewHero({
    Key key,
    @required this.tag,
    @required this.child,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder = _buildPlaceholder,
    this.transitionOnUserGestures = false,
  })  : assert(child != null),
        assert(transitionOnUserGestures != null),
        super(key: key);

  static Widget _buildPlaceholder(BuildContext context, Size heroSize, Widget child) {
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (tag == null || tag.isEmpty) {
      return child;
    }
    return Hero(
      tag: _buildHeroTag(tag),
      child: child,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      placeholderBuilder: placeholderBuilder,
      transitionOnUserGestures: transitionOnUserGestures,
    );
  }

  static Object _buildHeroTag(String tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }
    return _HeroTag('imagePreview:$tag');
  }
}

class ImagePreviewView extends StatefulWidget {
  final int initialIndex;
  final List<ImageOptions> images;
  final ValueChanged<int> onPageChanged;
  final NavigationBarBuilder navigationBarBuilder;
  final IndexedWidgetBuilder bottomBarBuilder;
  final ValueChanged<ImageOptions> onPressed;
  final ValueChanged<ImageOptions> onLongPressed;
  final ValueChanged<PhotoViewScaleState> onScaleStateChanged;
  final LoadingBuilder loadingBuilder;
  final ImageProviderBuilder imageProviderBuilder;
  final double dragReferenceDistance;
  final Duration duration;
  final DragEndCallback onDragEndCallback;

  const ImagePreviewView({
    Key key,
    this.initialIndex = 0,
    @required this.images,
    @required this.imageProviderBuilder,
    this.onPageChanged,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onLongPressed,
    this.onScaleStateChanged,
    this.loadingBuilder,
    this.dragReferenceDistance = _kMaxDragDistance,
    this.duration = _kDuration,
    this.onDragEndCallback,
  })  : assert(images != null && images.length > 0),
        assert(initialIndex != null && initialIndex >= 0 && initialIndex < images.length),
        assert(imageProviderBuilder != null),
        assert(dragReferenceDistance != null && dragReferenceDistance >= 0 && dragReferenceDistance != double.infinity),
        assert(duration != null),
        super(key: key);

  @override
  _ImagePreviewViewState createState() => _ImagePreviewViewState();
}

class _ImagePreviewViewState extends State<ImagePreviewView> with SingleTickerProviderStateMixin {
  final _navigationBarKey = GlobalKey();
  final _bottomBarKey = GlobalKey();

  int _currentIndex = 0;
  PageController _pageController;
  Offset _startPosition;
  Offset _translationPosition;
  double _scaleOffset;
  double _opacity;
  double _dragDistance;
  double _navigationBarOffsetPixels;
  double _bottomBarOffsetPixels;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_reset);
    _reset();
  }

  @override
  void didUpdateWidget(ImagePreviewView oldWidget) {
    if (widget.initialIndex != oldWidget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  _onPageChanged(int index) {
    _currentIndex = index;
    setState(() {});
    if (widget.onPageChanged != null) {
      widget.onPageChanged(_currentIndex);
    }
  }

  _onTap() {
    var imageOptions = widget.images[_currentIndex];
    if (imageOptions != null && widget.onPressed != null) {
      widget.onPressed(imageOptions);
    }
  }

  _onLongPress() {
    var imageOptions = widget.images[_currentIndex];
    if (imageOptions != null && widget.onLongPressed != null) {
      widget.onLongPressed(imageOptions);
    }
  }

  double _computeBarHeight(GlobalKey key) {
    return key?.currentContext?.size?.height ?? 0.0;
  }

  _onScaleStateChanged(PhotoViewScaleState scaleState) {
    if (_translationPosition != Offset.zero) {
      return;
    }
    double navBarOffsetPixels;
    double bottomOffsetPixels;
    switch (scaleState) {
      case PhotoViewScaleState.covering:
      case PhotoViewScaleState.originalSize:
      case PhotoViewScaleState.zoomedIn:
        navBarOffsetPixels = -_computeBarHeight(_navigationBarKey);
        bottomOffsetPixels = -_computeBarHeight(_bottomBarKey);
        break;
      case PhotoViewScaleState.initial:
      case PhotoViewScaleState.zoomedOut:
      default:
        navBarOffsetPixels = 0;
        bottomOffsetPixels = 0;
        break;
    }
    if (navBarOffsetPixels != _navigationBarOffsetPixels || bottomOffsetPixels != _bottomBarOffsetPixels) {
      _navigationBarOffsetPixels = navBarOffsetPixels;
      _bottomBarOffsetPixels = bottomOffsetPixels;
      setState(() {});
    }
    if (widget.onScaleStateChanged != null) {
      widget.onScaleStateChanged(scaleState);
    }
  }

  _onVerticalDragStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    DragStartNotification(details: details).dispatch(context);
  }

  _onVerticalDragUpdate(DragUpdateDetails details) {
    var size = MediaQuery.of(context).size;
    var positionOffset = details.localPosition - _startPosition;
    _dragDistance = positionOffset.dy.abs();
    _scaleOffset = _dragDistance / (size.height * 2);
    _translationPosition = positionOffset + _startPosition * _scaleOffset;
    var dragOffset = _dragDistance / widget.dragReferenceDistance;
    _opacity = (1.0 - dragOffset).clamp(0.0, 1.0);
    var barOffset = -dragOffset.clamp(0.0, 1.0);
    _navigationBarOffsetPixels = _computeBarHeight(_navigationBarKey) * barOffset;
    _bottomBarOffsetPixels = _computeBarHeight(_bottomBarKey) * barOffset;
    setState(() {});
    DragUpdateNotification(
      details: details,
      startPosition: _startPosition,
      translationPosition: _translationPosition,
      scale: 1.0 - _scaleOffset,
      opacity: _opacity,
      dragDistance: _dragDistance,
      navigationBarOffsetPixels: _navigationBarOffsetPixels,
      bottomBarOffsetPixels: _bottomBarOffsetPixels,
    ).dispatch(context);
  }

  _onVerticalDragEnd(DragEndDetails details) {
    var dragDistance = _translationPosition.dy < 0 ? -_dragDistance : _dragDistance;
    var onDragEndCallback = widget.onDragEndCallback;
    if (onDragEndCallback == null || !onDragEndCallback(dragDistance, details.primaryVelocity)) {
      _reset();
      DragEndNotification(details: details).dispatch(context);
    }
  }

  _reset() {
    _startPosition = Offset.zero;
    _translationPosition = Offset.zero;
    _scaleOffset = 0.0;
    _opacity = 1.0;
    _dragDistance = 0.0;
    _navigationBarOffsetPixels = 0.0;
    _bottomBarOffsetPixels = 0.0;
    setState(() {});
  }

  PhotoViewGalleryPageOptions _buildPageOptions(BuildContext context, int index) {
    final image = widget.images[index];
    final heroTag = ImagePreviewHero._buildHeroTag(image.tag);
    return PhotoViewGalleryPageOptions(
      imageProvider: widget.imageProviderBuilder(context, index),
      initialScale: PhotoViewComputedScale.contained,
      basePosition: Alignment.center,
      tightMode: true,
      gestureDetectorBehavior: HitTestBehavior.translucent,
      heroAttributes: heroTag == null ? null : PhotoViewHeroAttributes(tag: heroTag),
    );
  }

  Widget _buildNavigationBar() {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return widget.navigationBarBuilder(
      context,
      _currentIndex,
      widget.images.length,
    );
  }

  Widget _buildBottomBar() {
    Widget bottomBar;
    if (widget.bottomBarBuilder != null) {
      bottomBar = widget.bottomBarBuilder(
        context,
        _currentIndex,
      );
    }
    if (bottomBar != null) {
      bottomBar = SingleChildScrollView(
        child: bottomBar,
      );
    }
    return bottomBar;
  }

  @override
  Widget build(BuildContext context) {
    var scale = 1.0 - _scaleOffset;
    var positionOffset = _translationPosition;
    var duration = positionOffset == Offset.zero ? widget.duration : Duration.zero;
    var queryData = MediaQuery.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onLongPress: _onLongPress,
      onTap: _onTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedContainer(
            transform: Matrix4.translationValues(
              positionOffset.dx,
              positionOffset.dy,
              0,
            )..scale(scale, scale),
            duration: duration,
            curve: Curves.ease,
            child: PhotoViewGallery.builder(
              itemCount: widget.images.length,
              scrollDirection: Axis.horizontal,
              enableRotation: true,
              gaplessPlayback: true,
              backgroundDecoration: BoxDecoration(
                color: CupertinoColors.black.withOpacity(0.0),
              ),
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              loadingBuilder: widget.loadingBuilder,
              scaleStateChangedCallback: _onScaleStateChanged,
              builder: _buildPageOptions,
            ),
          ),
          AnimatedPositioned(
            left: 0,
            right: 0,
            bottom: _bottomBarOffsetPixels,
            duration: duration,
            child: DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(
                shadows: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.6),
                    blurRadius: 0.8,
                    offset: Offset(0, 1.0),
                  ),
                ],
              ),
              child: Container(
                key: _bottomBarKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.black.withOpacity(0.0),
                      CupertinoColors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: queryData.size.height / 4,
                ),
                child: AnimatedSize(
                  duration: widget.duration,
                  vsync: this,
                  alignment: Alignment.topCenter,
                  child: ClipRect(
                    child: _buildBottomBar(),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            left: 0,
            top: _navigationBarOffsetPixels,
            right: 0,
            duration: duration,
            child: Container(
              key: _navigationBarKey,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.black.withOpacity(0.6),
                    CupertinoColors.black.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildNavigationBar(),
            ),
          ),
        ],
      ),
    );
  }
}
