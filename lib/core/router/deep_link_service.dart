import 'package:app_links/app_links.dart';
import 'package:mytube/domain/marmot/invite_transport_models.dart';

enum AppDeepLinkDestination { parentZone }

class AppDeepLink {
  const AppDeepLink({required this.uri, required this.destination});

  final Uri uri;
  final AppDeepLinkDestination destination;
}

AppDeepLink? parseAppDeepLink(Uri uri) {
  if (!GroupInvitePacket.isSupportedScheme(uri.scheme)) {
    return null;
  }
  return AppDeepLink(uri: uri, destination: AppDeepLinkDestination.parentZone);
}

abstract class DeepLinkService {
  Future<Uri?> getInitialUri();
  Stream<Uri> get uriStream;
}

class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialUri() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;
}
