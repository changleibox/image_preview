/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:imagepreview/image_preview_route.dart';
import 'package:imagepreview/image_preview_view.dart';
import 'package:imagepreview/primitive_navigation_bar.dart';
import 'package:imagepreview/support_activity_indicator.dart';

const double _kMaxDragVelocity = 100;
const double _kMaxDragDistance = 200;
const Duration _kDuration = Duration(milliseconds: 300);

typedef ImagePreviewNavigationBarBuilder = Widget Function(
  BuildContext context,
  int index,
  int count,
  VoidCallback onBackPressed,
);

class ImagePreview {
  static Future<T> preview<T>(
    BuildContext context, {
    int initialIndex = 0,
    @required List<ImageOptions> images,
    ValueChanged<int> onIndexChanged,
    ImagePreviewNavigationBarBuilder navigationBarBuilder = _buildNavigationBar,
    IndexedWidgetBuilder bottomBarBuilder,
    ValueChanged<ImageOptions> onLongPressed,
  }) {
    final _images = images?.where((image) => image != null && image.isNotEmpty)?.toList();
    if (_images == null || _images.isEmpty) {
      return Future.value();
    }
    return _push(
      context,
      ImagePreviewPage(
        initialIndex: initialIndex,
        images: _images,
        onIndexChanged: onIndexChanged,
        navigationBarBuilder: navigationBarBuilder,
        bottomBarBuilder: bottomBarBuilder,
        onLongPressed: onLongPressed,
      ),
    );
  }

  static Future<T> previewSingle<T>(
    BuildContext context,
    ImageOptions image, {
    ImagePreviewNavigationBarBuilder navigationBarBuilder = _buildNavigationBar,
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
        navigationBarBuilder: navigationBarBuilder,
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

  static Widget _buildNavigationBar(
    BuildContext context,
    int index,
    int count,
    VoidCallback onBackPressed,
  ) {
    return _DefaultNavigationBar(
      currentIndex: index,
      count: count,
      onBackPressed: onBackPressed,
    );
  }
}

class ImagePreviewPage extends StatefulWidget {
  final int initialIndex;
  final List<ImageOptions> images;
  final ValueChanged<int> onIndexChanged;
  final ImagePreviewNavigationBarBuilder navigationBarBuilder;
  final IndexedWidgetBuilder bottomBarBuilder;
  final ValueChanged<ImageOptions> onLongPressed;

  ImagePreviewPage({
    Key key,
    this.initialIndex = 0,
    this.images,
    this.onIndexChanged,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onLongPressed,
  })  : assert(images != null && images.length > 0),
        assert(initialIndex != null && initialIndex >= 0 && initialIndex < images.length),
        super(key: key);

  factory ImagePreviewPage.single(
    ImageOptions image, {
    WidgetBuilder bottomBarBuilder,
    ImagePreviewNavigationBarBuilder navigationBarBuilder,
    ValueChanged<ImageOptions> onLongPressed,
  }) {
    return ImagePreviewPage(
      images: [image],
      onLongPressed: onLongPressed,
      navigationBarBuilder: navigationBarBuilder,
      bottomBarBuilder: bottomBarBuilder == null ? null : (context, index) => bottomBarBuilder(context),
    );
  }

  @override
  _ImagePreviewPageState createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  _onPageChanged(int index) {
    _currentIndex = index;
  }

  _onBackPressed() {
    if (widget.onIndexChanged != null) {
      widget.onIndexChanged(_currentIndex);
    }
    Navigator.maybePop(context, _currentIndex);
  }

  _onPressed(ImageOptions options) {
    _onBackPressed();
  }

  _onLongPressed(ImageOptions options) {
    if (widget.onLongPressed != null) {
      widget.onLongPressed(options);
    }
  }

  bool _onDragEndCallback(double dragDistance, double velocity) {
    if (dragDistance > _kMaxDragDistance / 2 || velocity >= _kMaxDragVelocity) {
      _onBackPressed();
      return true;
    }
    return false;
  }

  bool _onDragNotification(DragNotification notification) {
    if (notification is DragUpdateNotification) {
      _opacity = notification.opacity;
    } else {
      _opacity = 1.0;
    }
    setState(() {});
    return false;
  }

  ImageProvider _buildImageProvider(BuildContext context, int index) {
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
    return Center(
      child: SupportCupertinoActivityIndicator(
        radius: 14,
        animating: offset == null,
        position: offset,
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, int index, int count) {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return widget.navigationBarBuilder(
      context,
      index,
      count,
      _onBackPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    var duration = _opacity == 1.0 ? _kDuration : Duration.zero;
    var queryData = MediaQuery.of(context);
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: CupertinoColors.white,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black.withOpacity(0),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CupertinoPageScaffold(
          child: MediaQuery(
            data: queryData.copyWith(
              textScaleFactor: 1.0,
            ),
            child: AnimatedContainer(
              duration: duration,
              color: CupertinoColors.black.withOpacity(_opacity),
              child: NotificationListener<DragNotification>(
                onNotification: _onDragNotification,
                child: ImagePreviewView(
                  initialIndex: widget.initialIndex,
                  images: widget.images,
                  imageProviderBuilder: _buildImageProvider,
                  navigationBarBuilder: _buildNavigationBar,
                  bottomBarBuilder: widget.bottomBarBuilder,
                  loadingBuilder: _buildLoading,
                  duration: _kDuration,
                  dragReferenceDistance: _kMaxDragDistance,
                  onPressed: _onPressed,
                  onLongPressed: _onLongPressed,
                  onPageChanged: _onPageChanged,
                  onDragEndCallback: _onDragEndCallback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultNavigationBar extends StatelessWidget {
  final int currentIndex;
  final int count;
  final VoidCallback onBackPressed;

  const _DefaultNavigationBar({
    Key key,
    @required this.currentIndex,
    @required this.count,
    @required this.onBackPressed,
  })  : assert(currentIndex != null && count != null && currentIndex < count),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return PrimitiveNavigationBar(
      middle: Text('${currentIndex + 1}/$count'),
      padding: EdgeInsetsDirectional.only(
        start: 10,
        end: 10,
      ),
      brightness: Brightness.dark,
      leading: CupertinoButton(
        child: Text('关闭'),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: onBackPressed,
      ),
    );
  }
}
