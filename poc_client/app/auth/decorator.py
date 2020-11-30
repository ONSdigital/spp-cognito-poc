from functools import wraps

from flask import abort, current_app, redirect, request


def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if current_app.auth.logged_in():
            return f(*args, **kwargs)

        current_app.auth.set_redirect(request.url)
        return redirect(current_app.auth.login_url())

    return decorated


def requires_role(required_roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):

            if not any([current_app.auth.has_role(role) for role in required_roles]):
                abort(403)

            return f(*args, **kwargs)

        return decorated

    return decorator
