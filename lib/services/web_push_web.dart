import 'dart:js' as js;

void promptWebPush() => js.context.callMethod('promptOneSignal', []);

void loginWebPush(String userId) =>
    js.context.callMethod('loginOneSignal', [userId]);
