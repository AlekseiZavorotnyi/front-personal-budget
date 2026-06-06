import 'dart:html' as html;

bool get isOnline => html.window.navigator.onLine ?? false;

Stream<bool> connectivityChanges() {
  return Stream.multi((controller) {
    html.window.addEventListener('online', (html.Event event) {
      controller.add(true);
    });

    html.window.addEventListener('offline', (html.Event event) {
      controller.add(false);
    });
  });
}
