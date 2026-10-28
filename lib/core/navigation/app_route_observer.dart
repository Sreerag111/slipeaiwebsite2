import 'package:flutter/material.dart';

/// Global route observer that notifies [RouteAware] widgets when routes are pushed or popped.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
