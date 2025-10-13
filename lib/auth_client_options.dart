enum AuthFlowType { implicit, pkce }

class AuthClientOptions {
  final AuthFlowType authFlowType;
  final String? redirectUrl;

  const AuthClientOptions({
    this.authFlowType = AuthFlowType.implicit,
    this.redirectUrl,
  });
}
