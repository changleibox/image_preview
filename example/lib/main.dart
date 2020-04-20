import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:imagepreview/imagepreview.dart';

const String testAvatarUrl = 'http://b-ssl.duitang.com/uploads/item/201410/09/20141009224754_AswrQ.jpeg';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: _PluginExamplePage(),
    );
  }
}

class _PluginExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Plugin example app'),
      ),
      child: Center(
        child: SizedBox.fromSize(
          size: Size.square(200),
          child: CupertinoButton(
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.zero,
            onPressed: () {
              ImagePreview.preview(
                context,
                images: List.generate(10, (index) {
                  return ImageOptions(
                    url: testAvatarUrl,
                    tag: testAvatarUrl,
                  );
                }),
                bottomBarBuilder: (context, int index) {
                  if (index % 4 == 1) {
                    return SizedBox.shrink();
                  }
                  return Container(
                    height: index.isEven ? null : MediaQuery.of(context).size.height / 2,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '测试标题',
                            style: TextStyle(
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.label,
                                context,
                              ),
                            ),
                          ),
                          Text(
                            '测试内容',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: ImagePreviewHero(
              tag: testAvatarUrl,
              child: CachedNetworkImage(
                imageUrl: testAvatarUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
