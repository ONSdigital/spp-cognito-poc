# SPP Cognito PoC

A simple PoC to test the approach of using Cognito as an authentication front end for SPP flask apps.

## Contents

- **terraform**
  - The main bulk of interesting config is all in `cognito.tf` - **Note**: This is deliberately not using security
    best practices for simplicity, make sure to review the security aspects of this before deploying a
    `production` cognito anywhere.
  - You probably want to ignore `fargate.tf` its what deploys the two test apps `fake_baw` and `poc_client`
    but isn't really how you would likely deploy them for real, it was a quick and dirty way of getting them running.

  - **Note**: If when running a terraform plan you encounter an error such as: 
    "Error: Invalid for_each argument  on fargate.tf line 170, in resource "aws_route53_record" "poc_client_validation":"

    The fix is to run 
    terraform apply -target aws_acm_certificate.poc_client
    Then a subsequent plan and apply will run successfully.

- **fake_baw** - An extremely simple flask app with no auth that serves some static html links to the `poc_client`.
  Each link opens a new tab/ window in a simple way of replicating what happens in BAW.
- **poc_client** - The juicy bit!
  - This is where all the auth happens, it integrates with cognito by receiving a `callback` as part of the auth flow,
    this callback receives an `authorization_code` that is used to request a JWT token from the cognito service. This
    token is then stored in the session, along with the users roles and username.
  - User roles are loaded out of the JWT access token from `cognito:groups` and can be used to map permissions.
  - If users access any endpoint that needs auth they are redirected to the cognito hosted login page.
  - Endpoints
    - `/` - This endpoint is a simple hello world and requires a user to be authenticated but includes
      no authorisation.
    - `/main_survey` - An endpoint that requires authentication and additionally requires a user to have one of the
      `["main_survey.read", "main_survey.write"]` roles.
    - `/secondary_survey` - An endpoint that requires authentication and additionally requires a user to have one of the
      `["secondary_survey.read", "secondary_survey.write"]` roles.

## The PoC deployment

Two apps have been spun up on AWS ECS Fargate, the apps are `fake_baw` and `poc_client` as described above.

**Note**: All users are initially setup with the password `foobar` but cognito requires that they are reset on the first
login, the passwords that should have been set after that are described below.

**Note**: We have noticed a bug in our code that causes internal server errors when an auth token expires. If you see
this then try using the `force logout` option and then test the user behaviour again.

Two users have also been created:

- `test-user`, with a password of `foobar` and roles of `["main_survey.read", "main_survey.write"]`
- `test-user2`, with a password of `foobar` and roles of `["secondary_survey.read"]`

The expected behaviour is that a user would go to `fake_baw` using the url
<https://spp-cognito-poc-baw.crosscutting.aws.onsdigital.uk>.

If you use this url, clicking any of the `Home`, `Main Survey` or `Secondary Survey` options should prompt you to login.
Once you have logged in once you can close your tab, and attempt to re-use any of the links and they should let you in
without any need to login.

You should notice that when accessing the `Main Survey` page that `test-user` gets a nice response and `test-user2`
gets a `Forbidden` authorisation error. Likewise if you access the `Secondary Survey` page then `test-user2` should get
a nice response while `test-user` gets a `Forbidden` authorisation error. You will also notice that these pages print
out your current logged in user and roles so you can verify that the auth is working as expected.
