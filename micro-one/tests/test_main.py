"""
Tests for micro-one service
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
    assert data["service"] == "micro-one"
    assert data["version"] == "1.0.0"


def test_root_endpoint():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "micro-one"
    assert "endpoints" in data


@patch("app.main.message_service")
def test_send_message(mock_message_service):
    """Test send message endpoint"""
    # Mock the message service
    mock_message_service.send_message.return_value = {
        "status": "success",
        "message": "Message sent successfully",
    }

    # Test data
    test_message = {"message": "Hello, World!", "recipient_id": "micro-two"}

    response = client.post("/send-message", json=test_message)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "sent"
    assert data["sent_to"] == "micro-two"
    assert "message_id" in data


def test_get_message_status():
    """Test get message status endpoint"""
    message_id = "test-message-123"
    response = client.get(f"/messages/status/{message_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["message_id"] == message_id
    assert "status" in data
