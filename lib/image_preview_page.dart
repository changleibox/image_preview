/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:imagepreview/dimens.dart';
import 'package:imagepreview/primitive_navigation_bar.dart';
import 'package:imagepreview/support_activity_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageOptions {
  final String url;
  final String tag;

  const ImageOptions({
    @required this.url,
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

class ImagePreview {
  static Future<T> preview<T>(
    BuildContext context, {
    int initialIndex = 0,
    @required List<ImageOptions> images,
    ValueChanged<int> onIndexChanged,
    IndexedWidgetBuilder bottomBarBuilder,
    ValueChanged<ImageOptions> onLongPressed,
  }) {
    final _images = images?.where((image) => image.isNotEmpty)?.toList();
    if (_images == null || _images.isEmpty) {
      return Future.value();
    }
    return _push(
      context,
      ImagePreviewPage(
        initialIndex: initialIndex,
        images: images?.where((image) => image.isNotEmpty)?.toList(),
        onIndexChanged: onIndexChanged,
        bottomBarBuilder: bottomBarBuilder,
        onLongPressed: onLongPressed,
      ),
    );
  }

  static Future<T> previewSingle<T>(
    BuildContext context,
    ImageOptions image, {
    WidgetBuilder bottomBarBuilder,
    ValueChanged<ImageOptions> onLongPressed,
  }) {
    if (image == null || image.isEmpty) {
      return Future.value();
    }
    return _push(
      context,
      ImagePreviewPage.single(
        image,
        bottomBarBuilder: bottomBarBuilder,
        onLongPressed: onLongPressed,
      ),
    );
  }

  static Future<T> _push<T>(BuildContext context, Widget widget) {
    return Navigator.push(
      context,
      ImagePreviewRoute(
        opaque: false,
        fullscreenDialog: false,
        builder: (context) => widget,
      ),
    );
  }
}

class ImagePreviewRoute<T> extends PageRoute<T> {
  ImagePreviewRoute({
    @required this.builder,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    RouteSettings settings,
    bool fullscreenDialog = false,
  })  : assert(builder != null),
        assert(opaque != null),
        assert(barrierDismissible != null),
        assert(maintainState != null),
        assert(fullscreenDialog != null),
        super(
          settings: settings,
          fullscreenDialog: fullscreenDialog,
        );

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  final bool maintainState;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget child = builder(context);
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
    assert(() {
      if (child == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The builder for route "${settings.name}" returned null.'),
          ErrorDescription('Route builders must never return null.'),
        ]);
      }
      return true;
    }());
    return result;
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
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

  const ImagePreviewHero({
    Key key,
    @required this.tag,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tag == null || tag.isEmpty) {
      return child;
    }
    return Hero(
      tag: _buildHeroTag(tag),
      child: child,
    );
  }

  static Object _buildHeroTag(String url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    return _HeroTag('imagePreview:$url');
  }
}

class ImagePreviewPage extends StatefulWidget {
  final int initialIndex;
  final List<ImageOptions> images;
  final ValueChanged<int> onIndexChanged;
  final IndexedWidgetBuilder bottomBarBuilder;
  final ValueChanged<ImageOptions> onLongPressed;

  ImagePreviewPage({
    Key key,
    this.initialIndex = 0,
    this.images,
    this.onIndexChanged,
    this.bottomBarBuilder,
    this.onLongPressed,
  })  : assert(images != null && images.length > 0),
        assert(initialIndex != null && initialIndex >= 0 && initialIndex < images.length),
        super(key: key);

  factory ImagePreviewPage.single(
    ImageOptions image, {
    WidgetBuilder bottomBarBuilder,
    ValueChanged<ImageOptions> onLongPressed,
  }) {
    return ImagePreviewPage(
      images: [image],
      onLongPressed: onLongPressed,
      bottomBarBuilder: bottomBarBuilder == null
          ? null
          : (context, index) {
              return bottomBarBuilder(context);
            },
    );
  }

  @override
  _ImagePreviewPageState createState() => _ImagePreviewPageState();
}

const double _kMaxDragDistance = 200;
const Duration _kDuration = Duration(milliseconds: 300);

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  final _bottomInfoKey = GlobalKey();

  int _currentIndex = 0;
  PhotoViewController _photoViewController;
  PageController _pageController;
  Offset _startPosition;
  Offset _currentPosition;
  double _startScale;
  double _scaleOffset;
  double _navBarOffset;
  double _opacity;
  double _dragDistance;
  double _bottomOffsetPixels;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _photoViewController = PhotoViewController();
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_reset);
    _reset();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  _onPageChanged(int index) {
    _currentIndex = index;
    setState(() {});
  }

  _onTap() {
    if (widget.onIndexChanged != null) {
      widget.onIndexChanged(_currentIndex);
    }
    Navigator.pop(context, _currentIndex);
  }

  _onLongPress() {
    var imageOptions = widget.images[_currentIndex];
    if (imageOptions != null && widget.onLongPressed != null) {
      widget.onLongPressed(imageOptions);
    }
  }

  _onScaleStateChanged(PhotoViewScaleState scaleState) {
    if (_currentPosition != Offset.zero) {
      return;
    }
    if (scaleState == PhotoViewScaleState.initial || scaleState == PhotoViewScaleState.zoomedOut) {
      _navBarOffset = 0;
      _bottomOffsetPixels = 0;
    } else {
      _navBarOffset = -1.0;
      _bottomOffsetPixels = -_bottomInfoKey.currentContext?.size?.height ?? 0;
    }
    _animating = true;
    setState(() {});
  }

  _onVerticalDragStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    _startScale = _photoViewController.scale ?? 0;
  }

  _onVerticalDragUpdate(DragUpdateDetails details) {
    _currentPosition = details.localPosition;
    _dragDistance = (_currentPosition - _startPosition).dy.abs();
    _scaleOffset = _dragDistance / (MediaQuery.of(context).size.height * 2);
    _navBarOffset = _dragDistance < 0 ? 0 : -_dragDistance / _kMaxDragDistance;
    _opacity = (1 - _dragDistance / _kMaxDragDistance).clamp(0.0, 1.0);
    _photoViewController.scale = _startScale * (1 - _scaleOffset);
    _bottomOffsetPixels = (_bottomInfoKey.currentContext?.size?.height ?? 0) * _navBarOffset;
    _animating = false;
    setState(() {});
  }

  _onVerticalDragEnd(DragEndDetails details) {
    if (_dragDistance > _kMaxDragDistance / 2) {
      _onTap();
    } else {
      _reset();
    }
  }

  _reset() {
    _startPosition = Offset.zero;
    _currentPosition = Offset.zero;
    _startScale = 1.0;
    _scaleOffset = 0.0;
    _navBarOffset = 0.0;
    _opacity = 1.0;
    _dragDistance = 0.0;
    _bottomOffsetPixels = 0.0;
    _photoViewController.reset();
    _animating = false;
    setState(() {});
  }

  ImageProvider _childProvider(int index) {
    final url = widget.images[index].url;
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    } else {
      return FileImage(File(url));
    }
  }

  Widget _buildLoading(BuildContext context, ImageChunkEvent event) {
    double offset;
    if (event != null) {
      offset = event.cumulativeBytesLoaded.toDouble() / event.expectedTotalBytes.toDouble();
    }
    Widget child = CupertinoActivityIndicator(
      radius: 14,
      animating: offset == null,
    );
    if (offset != null) {
      child = SupportCupertinoActivityIndicator(
        radius: 14,
        position: offset,
      );
    }
    return Center(
      child: child,
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final image = widget.images[index];
    final heroTag = ImagePreviewHero._buildHeroTag(image.tag);
    return PhotoViewGalleryPageOptions(
      controller: _photoViewController,
      imageProvider: _childProvider(index),
      initialScale: PhotoViewComputedScale.contained,
      basePosition: Alignment.center,
      tightMode: true,
      gestureDetectorBehavior: HitTestBehavior.translucent,
      heroAttributes: heroTag == null ? null : PhotoViewHeroAttributes(tag: heroTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomBar;
    if (widget.bottomBarBuilder != null) {
      bottomBar = widget.bottomBarBuilder(context, _currentIndex);
    }
    if (bottomBar != null) {
      bottomBar = SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: bottomBar,
        ),
      );
    }
    final offset = _currentPosition - _startPosition;
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: CupertinoColors.white,
        brightness: Brightness.dark,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black.withOpacity(_opacity),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: GestureDetector(
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
                    transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
                    duration: Duration(
                      milliseconds: offset == Offset.zero ? 200 : 0,
                    ),
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
                      loadingBuilder: _buildLoading,
                      scaleStateChangedCallback: _onScaleStateChanged,
                      builder: _buildItem,
                    ),
                  ),
                  AnimatedPositioned(
                    left: 0,
                    right: 0,
                    bottom: _bottomOffsetPixels,
                    duration: _animating ? _kDuration : Duration.zero,
                    onEnd: () => _animating = false,
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
                      child: AnimatedContainer(
                        key: _bottomInfoKey,
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
                          maxHeight: bottomBar == null ? 0 : MediaQuery.of(context).size.height / 4,
                        ),
                        duration: _kDuration,
                        child: ClipRect(
                          child: bottomBar,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    left: 0,
                    top: (navBarPersistentHeight + MediaQuery.of(context).padding.top) * _navBarOffset,
                    right: 0,
                    duration: _animating ? _kDuration : Duration.zero,
                    onEnd: () => _animating = false,
                    child: PrimitiveNavigationBar(
                      middle: Text('${_currentIndex + 1}/${widget.images.length}'),
                      padding: EdgeInsetsDirectional.only(
                        start: 10,
                        end: 10,
                      ),
                      brightness: Brightness.dark,
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
                      leading: CupertinoButton(
                        child: Text('关闭'),
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.zero,
                        onPressed: _onTap,
                      ),
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
}
