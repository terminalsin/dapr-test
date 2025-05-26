"""
Tests for micro-two service
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch

from app.main import app

client = TestClient(app)


def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "micro-two"
    assert data["version"] == "1.0.0"


def test_root_endpoint():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "micro-two"
    assert "endpoints" in data
    assert "stats" in data


@patch("app.main.message_processor")
def test_receive_message(mock_message_processor):
    """Test receive message endpoint"""
    # Mock the message processor
    mock_message_processor.process_message.return_value = {
        "status": "processed",
        "response": "Message processed successfully",
    }

    # Test data
    test_message = {
        "message": "Hello from micro-one!",
        "message_id": "test-123",
        "sender": "micro-one",
        "timestamp": "2024-01-01T00:00:00Z",
    }

    response = client.post("/receive-message", json=test_message)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "received"
    assert data["message_id"] == "test-123"
    assert "processed_at" in data


def test_get_messages():
    """Test get messages endpoint"""
    response = client.get("/messages")
    assert response.status_code == 200
    data = response.json()
    assert "messages" in data
    assert "total_count" in data


def test_echo_endpoint():
    """Test echo endpoint"""
    test_data = {"test": "data", "number": 42}
    response = client.post("/echo", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert data["echo"] == test_data
    assert data["service"] == "micro-two"


def test_clear_messages():
    """Test clear messages endpoint"""
    response = client.delete("/messages")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "cleared"
    assert "messages_removed" in data
