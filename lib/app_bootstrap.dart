import "app_bootstrap_io.dart"
    if (dart.library.js_interop) "app_bootstrap_web.dart"
    as bootstrap;

Future<void> initializeAppDependencies() async {
  await bootstrap.initializeAppDependencies();
}
