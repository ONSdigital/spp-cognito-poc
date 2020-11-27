import requests
from flask import Blueprint, current_app, redirect, request, url_for

auth_blueprint = Blueprint(name="auth", import_name=__name__, url_prefix="/auth")


@auth_blueprint.route("/callback", methods=["GET"])
def callback():
    auth_code = request.args.get("code")
    current_app.auth.process_callback(auth_code)
    return redirect(url_for("root.home", _external=True, _scheme="https"))


@auth_blueprint.route("/logout", methods=["GET"])
def logout():
    current_app.auth.logout()
    return redirect(current_app.auth.login_url())
