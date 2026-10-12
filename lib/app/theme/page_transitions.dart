import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 页面转场只用 Flutter 自带的：Android 跟系统的预测性返回，iOS、macOS
// 用户习惯右滑返回，Windows、Linux 淡入前推。

const pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
  },
);
