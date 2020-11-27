import os

from flask import Flask, Blueprint

root_blueprint = Blueprint(name="root", import_name=__name__, url_prefix="/")

def create_app():
    # Define the WSGI application object
    application = Flask(__name__)

    add_blueprints(application)
    return application


def add_blueprints(application):
    application.register_blueprint(root_blueprint)

@root_blueprint.route("/")
def home():
    return """<h1>Fake BAW</h1>
<ul>
    <li><a href="https://spp-cognito-poc.crosscutting.aws.onsdigital.uk/" target="_blank">Cognito PoC Home</a></li>
    <li><a href="https://spp-cognito-poc.crosscutting.aws.onsdigital.uk/main_survey" target="_blank">Main Survey Page</a></li>
    <li><a href="https://spp-cognito-poc.crosscutting.aws.onsdigital.uk/secondary_survey" target="_blank">Secondary Survey Page</a></li>
    <li><a href="https://spp-cognito-poc.crosscutting.aws.onsdigital.uk/auth/logout" target="_blank">Force Logout</a></li>
<ul>
"""
