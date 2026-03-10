import json
import os
import boto3
import pytest
import requests
import time


def api_url(region):
    ssm = boto3.client("ssm", region_name=region)

    response = ssm.get_parameter(
        Name="/greet-url",
        WithDecryption=False
    )
    greet_url = response["Parameter"]["Value"]

    response = ssm.get_parameter(
        Name="/dispatch-url",
        WithDecryption=False
    )
    dispatch_url = response["Parameter"]["Value"]

    return {
        "greet_url": greet_url,
        "dispatch_url": dispatch_url
    }

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
    ssm = boto3.client("ssm", region_name="us-east-1")

    response = ssm.get_parameter(
        Name="/user-pool-client-id",
        WithDecryption=False
    )
    client_id = response["Parameter"]["Value"]

    response = ssm.get_parameter(
        Name="/user-pool-id",
        WithDecryption=False
    )
    pool_id = response["Parameter"]["Value"]

    client = boto3.client("secretsmanager")

    response = client.get_secret_value(SecretId="cognito-user")

    secret_string = response.get("SecretString")

    secret_json = json.loads(secret_string)


    username = secret_json.get("username")
    password = secret_json.get("password")

    if not all([pool_id, client_id, password]):
        pytest.skip("Cognito credentials not set in environment")

    return {
        "pool_id": pool_id,
        "client_id": client_id,
        "username": username,
        "password": password,
    }

@pytest.mark.parametrize("region", ["us-east-1", "eu-west-1"])
def test_greet(region, cognito_config):
    result = authenticate(
        cognito_config["username"],
        cognito_config["password"],
        cognito_config["pool_id"],
        cognito_config["client_id"],
    )

    # make a request to /greet using the access token
    headers = {"Authorization": f"{result['IdToken']}"}

    url = api_url(region)["greet_url"]

    # Time the request
    start = time.perf_counter()
    resp = requests.get(f"{url}/greet", headers=headers)
    latency = time.perf_counter() - start
    print(f"{region} latency: {latency:.3f}s")

    assert resp.status_code == 200
    data = resp.json()
    assert "region" in data, "response json must include region"

    # if a test region is provided, validate against it
    assert data["region"] == region

@pytest.mark.parametrize("region", ["us-east-1", "eu-west-1"])
def test_dispatch(region, cognito_config):
    result = authenticate(
        cognito_config["username"],
        cognito_config["password"],
        cognito_config["pool_id"],
        cognito_config["client_id"],
    )

    # make a request to /greet using the access token
    headers = {"Authorization": f"{result['IdToken']}"}

    url = api_url(region)["dispatch_url"]

    resp = requests.get(f"{url}/dispatch", headers=headers)

    assert resp.status_code == 200