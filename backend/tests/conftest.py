"""Shared fixtures. Run inside the container with ENV=test:
    docker compose exec -e ENV=test api python -m pytest -q tests

Uses real Firebase test users, the gemeye_test database and the test/ S3 prefix;
all of it is removed at the end of the session."""
import pytest
from fastapi.testclient import TestClient

from app.config import get_settings
from tests.helpers.firebase_test_user import FirebaseTestUser


def pytest_configure(config):
    if get_settings().env != "test":
        raise pytest.UsageError("Run the tests with ENV=test (docker compose exec -e ENV=test ...)")


class AuthedClient:
    """TestClient wrapper that sends one user's bearer token."""

    def __init__(self, client, user):
        self.raw, self.user = client, user

    def _call(self, method, url, headers=None, **kw):
        return getattr(self.raw, method)(url, headers={**self.user.headers, **(headers or {})}, **kw)

    def get(self, url, **kw):
        return self._call("get", url, **kw)

    def post(self, url, **kw):
        return self._call("post", url, **kw)

    def put(self, url, **kw):
        return self._call("put", url, **kw)

    def delete(self, url, **kw):
        return self._call("delete", url, **kw)


@pytest.fixture(scope="session")
def raw_client():
    from app.main import app
    with TestClient(app) as c:
        yield c
        # Clean up everything this session created (test environment only).
        s = get_settings()
        db, storage = app.state.db, app.state.storage
        assert s.env == "test"
        if db is not None:
            assert db.db.name == "gemeye_test"
            db.client.drop_database("gemeye_test")
        if storage is not None:
            assert storage.prefix == "test/"
            storage.delete_prefix("")


@pytest.fixture(scope="session")
def app_state(raw_client):
    return raw_client.app.state


@pytest.fixture(scope="session")
def user_a(raw_client):
    with FirebaseTestUser() as u:
        yield u


@pytest.fixture(scope="session")
def user_b(raw_client):
    with FirebaseTestUser() as u:
        yield u


@pytest.fixture(scope="session")
def client(raw_client, user_a):
    return AuthedClient(raw_client, user_a)


@pytest.fixture(scope="session")
def client_b(raw_client, user_b):
    return AuthedClient(raw_client, user_b)
