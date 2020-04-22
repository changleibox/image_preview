import 'package:flutter/cupertino.dart';

/// Created by box on 2020/4/22.
///
/// 自定义图片预览路由
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
