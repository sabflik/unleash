import os
import boto3
import pytest
import requests
import logging
logger = logging.getLogger(__name__)


def api_url():
    # url = os.environ.get("API_URL")
    # TODO:
    url = "https://pd51p133x2.execute-api.us-east-1.amazonaws.com/greet_prod"
    if not url:
        pytest.skip("API_URL not set")
    return url


def authenticate(username: str, password: str, pool_id: str, client_id: str) -> dict:
    """Initiate USER_PASSWORD_AUTH against Cognito and return auth result."""
    client = boto3.client("cognito-idp")
    resp = client.initiate_auth(
        ClientId=client_id,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={
            "USERNAME": username,
            "PASSWORD": password,
        },
    )
    return resp.get("AuthenticationResult", {})


@pytest.fixture(scope="module")
def cognito_config():
    pool_id = os.environ.get("USER_POOL_ID", "us-east-1_AjrIEPaaD")
    client_id = os.environ.get("CLIENT_ID", "43uj0jvrtdev9ro6ob0shdjqas")
    username = os.environ.get("USERNAME", "testuser")
    password = os.environ.get("PASSWORD", "Testuser123!")

    if not all([pool_id, client_id, password]):
        pytest.skip("Cognito credentials not set in environment")

    return {
        "pool_id": pool_id,
        "client_id": client_id,
        "username": username,
        "password": password,
    }


def test_can_retrieve_jwt(cognito_config):
    result = authenticate(
        cognito_config["username"],
        cognito_config["password"],
        cognito_config["pool_id"],
        cognito_config["client_id"],
    )
    assert "IdToken" in result
    assert "AccessToken" in result
    # optionally check format
    assert result["IdToken"].count(".") == 2
    assert result["AccessToken"].count(".") == 2

    # make a request to /greet using the access token
    headers = {"Authorization": f"{result['IdToken']}"}
    resp = requests.get(f"{api_url()}/greet", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "region" in data, "response json must include region"

    # if a test region is provided, validate against it
    expected_region = "us-east-1"  # or get from env/config
    if expected_region:
        assert data["region"] == expected_region
    else:
        # fallback: just ensure the field is not empty
        assert data["region"]
