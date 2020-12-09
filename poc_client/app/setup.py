import os

from flask import Flask, g, session
from werkzeug.middleware.proxy_fix import ProxyFix

from spp_cognito_auth import Auth, AuthConfig, AuthBlueprint, new_oauth_client


def create_app():
    # Define the WSGI application object
    application = Flask(__name__)

    add_blueprints(application)

    application.config["SESSION_COOKIE_SECURE"] = os.getenv(
        "SESSION_COOKIE_SECURE", False
    )
    application.secret_key = "my-secret-key"
    auth_config = AuthConfig.from_env()
    oauth_client = new_oauth_client(auth_config)
    application.auth = Auth(auth_config, oauth_client, session)
    # Run with proxyfix when behind ELB as SSL is done at the load balancer
    if application.config["SESSION_COOKIE_SECURE"]:
        return ProxyFix(application, x_for=1, x_host=1)
    return application


def add_blueprints(application):
    application.register_blueprint(AuthBlueprint().blueprint())

    from app.root import root_blueprint

    application.register_blueprint(root_blueprint)
