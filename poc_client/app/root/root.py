from flask import Blueprint, current_app

from spp_cognito_auth import requires_auth, requires_role

root_blueprint = Blueprint(name="root", import_name=__name__, url_prefix="/")


@root_blueprint.route("/")
@requires_auth
def home():
    return (
        f"Hello, <strong>{current_app.auth.get_username()}</strong>!</br>"
        + "Welcome to the SPP Cognito PoC!"
    )


@root_blueprint.route("/main_survey")
@requires_auth
@requires_role(["main_survey.read", "main_survey.write"])
def main_survey():
    return (
        f"Welcome {current_app.auth.get_username()}!</br></br>"
        + f"User had roles: {current_app.auth.get_roles()}</br>"
        + "Required roles were: ['main_survey.read', 'main_survey.write']</br></br>"
        + "Congratulations you can see the main surveys"
    )


@root_blueprint.route("/secondary_survey")
@requires_auth
@requires_role(["secondary_survey.read", "secondary_survey.write"])
def secondary_survey():
    return (
        f"Welcome {current_app.auth.get_username()}!</br></br>"
        + f"User had roles: {current_app.auth.get_roles()}</br>"
        + "Required roles were: ['secondary_survey.read', 'secondary_survey.write']</br></br>"
        + "Congratulations you can see the secondary surveys"
    )
