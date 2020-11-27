import os

import requests
from authlib.integrations.requests_client import OAuth2Session
from authlib.jose import jwt


class AuthConfig:
    CLIENT_ID = os.getenv("CLIENT_ID")
    CLIENT_SECRET = os.getenv("CLIENT_SECRET")
    APP_HOST = os.getenv("APP_HOST")
    COGNITO_DOMAIN = os.getenv("COGNITO_DOMAIN")
    COGNITO_PUBLIC_KEY_URL = os.getenv("COGNITO_PUBLIC_KEY_URL")


def new_oauth_client(config):
    return OAuth2Session(
        config.CLIENT_ID,
        config.CLIENT_SECRET,
        redirect_uri=f"{config.APP_HOST}/auth/callback",
    )


class Auth:
    def __init__(self, config, oauth, session):
        self._config = config
        self._session = session
        self._oauth = oauth

    def login_url(self):
        return (
            f"{self._config.COGNITO_DOMAIN}/login?"
            + f"client_id={self._config.CLIENT_ID}&"
            + "response_type=code&"
            + "scope=aws.cognito.signin.user.admin+email+openid+phone+profile&"
            + f"redirect_uri={self._config.APP_HOST}/auth/callback"
        )

    def process_callback(self, auth_code):
        auth_info = self._get_auth_info(auth_code)
        self._session["access_token"] = auth_info["access_token"]
        self._session["id_token"] = auth_info["id_token"]
        self._session["refresh_token"] = auth_info["refresh_token"]
        self._session["expires_at"] = auth_info["expires_at"]

        token = self._decode_token()
        self._session["roles"] = token["cognito:groups"]
        self._session["username"] = token["username"]

    def logged_in(self):
        if "access_token" in self._session:
            try:
                jwt_claims = self._decode_token()
                jwt_claims.validate()
                return True

            except ExpiredTokenError:
                pass

        return False

    def logout(self):
        self._session.clear()

    def get_roles(self):
        return self._session.get("roles", [])

    def get_username(self):
        return self._session.get("username", None)

    def has_role(self, role):
        return role in self.get_roles()

    def _get_auth_info(self, auth_code):
        return self._oauth.fetch_token(
            f"{self._config.COGNITO_DOMAIN}/oauth2/token",
            grant_type="authorization_code",
            code=auth_code,
            authorization_response=f"{self._config.APP_HOST}/auth/callback",
        )

    def _decode_token(self):
        keys = requests.get(self._config.COGNITO_PUBLIC_KEY_URL)
        decoded_token = jwt.decode(self._session["access_token"], keys.json())
        return decoded_token
