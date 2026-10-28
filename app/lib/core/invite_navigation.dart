import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

String? inviteReturnOf(BuildContext context) {
  try {
    return safeInviteReturn(GoRouterState.of(context).uri.queryParameters['next']);
  } on GoError {
    return null;
  }
}

String? safeInviteReturn(String? value) => value != null &&
    RegExp(r'^/consent/[A-Za-z0-9_-]{1,100}$').hasMatch(value) ? value : null;

String authRouteWithInvite(String route, String? next) => next == null
    ? route : Uri(path: route, queryParameters: {'next': next}).toString();
