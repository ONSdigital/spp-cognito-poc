resource "aws_cognito_user_pool" "cognito_poc" {
  name = "spp-cognito-poc"

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }
}

resource "aws_cognito_user_pool_domain" "cognito_poc" {
  domain       = "spp-poc"
  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}

resource "aws_cognito_user_pool_client" "poc_client" {
  name = "poc_client"

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]

  supported_identity_providers = ["COGNITO"]

  callback_urls = ["https://spp-cognito-poc.crosscutting.aws.onsdigital.uk/auth/callback"]

  prevent_user_existence_errors = "ENABLED"

  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}

resource "aws_cognito_user_group" "main_survey_read" {
  name = "main_survey.read"

  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}

resource "aws_cognito_user_group" "main_survey_write" {
  name = "main_survey.write"

  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}


resource "aws_cognito_user_group" "secondary_survey_read" {
  name = "secondary_survey.read"

  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}

resource "aws_cognito_user_group" "secondary_survey_write" {
  name = "secondary_survey.write"

  user_pool_id = aws_cognito_user_pool.cognito_poc.id
}

resource "null_resource" "poc_users" {
  provisioner "local-exec" {
    command = "aws --region ${var.region} cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.cognito_poc.id} --username test-user --user-attributes Name=email,Value=test-user@ons.gov.uk --temporary-password foobar"
  }
  provisioner "local-exec" {
    command = "aws --region ${var.region} cognito-idp admin-add-user-to-group --user-pool-id ${aws_cognito_user_pool.cognito_poc.id} --username test-user --group-name main_survey.read"
  }
  provisioner "local-exec" {
    command = "aws --region ${var.region} cognito-idp admin-add-user-to-group --user-pool-id ${aws_cognito_user_pool.cognito_poc.id} --username test-user --group-name main_survey.write"
  }


  provisioner "local-exec" {
    command = "aws --region ${var.region} cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.cognito_poc.id} --username test-user2 --user-attributes Name=email,Value=test-user2@ons.gov.uk --temporary-password foobar"
  }
  provisioner "local-exec" {
    command = "aws --region ${var.region} cognito-idp admin-add-user-to-group --user-pool-id ${aws_cognito_user_pool.cognito_poc.id} --username test-user2 --group-name secondary_survey.read"
  }
}

output client_id {
  value = aws_cognito_user_pool_client.poc_client.id
}

output client_secret {
  value = aws_cognito_user_pool_client.poc_client.client_secret
}

output cognito_domain {
  value = "https://${aws_cognito_user_pool_domain.cognito_poc.domain}.auth.${var.region}.amazoncognito.com"
}

output cognito_public_key_url {
  value = "https://${aws_cognito_user_pool.cognito_poc.endpoint}/.well-known/jwks.json"
}

output poc_client_url {
  value = "https://spp-cognito-poc.crosscutting.aws.onsdigital.uk"
}

output fake_baw_url {
  value = "https://spp-cognito-poc-baw.crosscutting.aws.onsdigital.uk"
}
