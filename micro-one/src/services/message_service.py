"""
Message Service for Micro-One
Handles sending messages to other microservices using Dapr service invocation.
"""

import json
from typing import Dict, Any, Optional

import structlog
from dapr.clients import DaprClient

logger = structlog.get_logger(__name__)


class MessageService:
    """Service for handling message operations via Dapr"""

    def __init__(self, dapr_client: DaprClient):
        self.dapr_client = dapr_client

    async def send_message(
        self,
        recipient_service: str,
        message: str,
        message_id: str,
        method: str = "receive-message",
    ) -> Dict[str, Any]:
        """
        Send a message to another service using Dapr service invocation

        Args:
            recipient_service: The app-id of the target service
            message: The message content to send
            message_id: Unique identifier for the message
            method: The HTTP method/endpoint on the target service

        Returns:
            Response from the target service
        """
        payload = {
            "message": message,
            "message_id": message_id,
            "sender": "micro-one",
            "timestamp": "2024-01-01T00:00:00Z",  # In real app, use datetime.utcnow().isoformat()
        }

        logger.info(
            "Sending message via Dapr service invocation",
            recipient_service=recipient_service,
            message_id=message_id,
            method=method,
        )

        try:
            # Use Dapr service invocation to call the target service
            response = self.dapr_client.invoke_method(
                app_id=recipient_service,
                method_name=method,
                data=json.dumps(payload),
                http_verb="POST",
            )

            # Parse response
            if response.data:
                response_data = json.loads(response.data)
            else:
                response_data = {"status": "success", "message": "No response data"}

            logger.info(
                "Message sent successfully via Dapr",
                recipient_service=recipient_service,
                message_id=message_id,
                response_status=response_data.get("status", "unknown"),
            )

            return response_data

        except Exception as e:
            logger.error(
                "Failed to send message via Dapr",
                recipient_service=recipient_service,
                message_id=message_id,
                error=str(e),
                exc_info=True,
            )
            raise

    async def send_message_with_retry(
        self,
        recipient_service: str,
        message: str,
        message_id: str,
        max_retries: int = 3,
        method: str = "receive-message",
    ) -> Dict[str, Any]:
        """
        Send a message with retry logic

        Args:
            recipient_service: The app-id of the target service
            message: The message content to send
            message_id: Unique identifier for the message
            max_retries: Maximum number of retry attempts
            method: The HTTP method/endpoint on the target service

        Returns:
            Response from the target service
        """
        last_exception = None

        for attempt in range(max_retries + 1):
            try:
                return await self.send_message(
                    recipient_service=recipient_service,
                    message=message,
                    message_id=message_id,
                    method=method,
                )
            except Exception as e:
                last_exception = e
                if attempt < max_retries:
                    logger.warning(
                        "Message send attempt failed, retrying",
                        attempt=attempt + 1,
                        max_retries=max_retries,
                        message_id=message_id,
                        error=str(e),
                    )
                else:
                    logger.error(
                        "All message send attempts failed",
                        attempts=max_retries + 1,
                        message_id=message_id,
                        error=str(e),
                    )

        raise last_exception
