/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:imagepreview/dimens.dart';

/// Created by box on 2020/3/14.
///
/// 一个简陋的navigationBar，可以自定义背景
class PrimitiveNavigationBar extends StatefulWidget implements ObstructingPreferredSizeWidget {
  final Widget middle;
  final Widget leading;
  final BoxDecoration decoration;
  final EdgeInsetsDirectional padding;
  final Brightness brightness;
  final Widget trailing;

  const PrimitiveNavigationBar({
    Key key,
    this.middle,
    this.leading,
    this.decoration,
    this.padding = const EdgeInsetsDirectional.only(
      start: 10,
      end: 10,
    ),
    this.brightness,
    this.trailing,
  }) : super(key: key);

  @override
  _PrimitiveNavigationBarState createState() => _PrimitiveNavigationBarState();

  @override
  Size get preferredSize => Size.fromHeight(navBarPersistentHeight);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }
}

class _PrimitiveNavigationBarState extends State<PrimitiveNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final Brightness newBrightness = widget.brightness ?? Brightness.light;
    SystemUiOverlayStyle overlayStyle;
    switch (newBrightness) {
      case Brightness.dark:
        overlayStyle = SystemUiOverlayStyle.light;
        break;
      case Brightness.light:
      default:
        overlayStyle = SystemUiOverlayStyle.dark;
        break;
    }
    Widget middle = widget.middle;
    if (middle != null) {
      middle = DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
        child: Semantics(header: true, child: middle),
      );
    }

    Widget toolbar = NavigationToolbar(
      middle: middle,
      leading: widget.leading,
      trailing: widget.trailing,
      centerMiddle: true,
      middleSpacing: 6.0,
    );

    if (widget.padding != null) {
      toolbar = Padding(
        padding: widget.padding,
        child: toolbar,
      );
    }

    toolbar = AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      sized: true,
      child: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: SizedBox(
          height: widget.preferredSize.height + MediaQuery.of(context).padding.top,
          child: SafeArea(
            bottom: false,
            child: toolbar,
          ),
        ),
      ),
    );

    if (widget.decoration != null) {
      toolbar = DecoratedBox(
        decoration: widget.decoration,
        child: toolbar,
      );
    }

    return toolbar;
  }
}
