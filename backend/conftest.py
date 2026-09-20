import pytest
from app.core.config import settings

@pytest.fixture(autouse=True)
def enable_mock_ai_in_tests():
    original = settings.MOCK_AI_MODE
    settings.MOCK_AI_MODE = True
    yield
    settings.MOCK_AI_MODE = original
