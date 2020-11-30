import requests
from flask import Blueprint, current_app, redirect, request, url_for

auth_blueprint = Blueprint(name="auth", import_name=__name__, url_prefix="/auth")


@auth_blueprint.route("/callback", methods=["GET"])
def callback():
    auth_code = request.args.get("code")
    current_app.auth.process_callback(auth_code)
    redirect_url = current_app.auth.get_redirect()
    if redirect_url:
        return redirect(redirect_url)
    return redirect(url_for("root.home"))


@auth_blueprint.route("/logout", methods=["GET"])
def logout():
    current_app.auth.logout()
    return redirect(current_app.auth.login_url())
