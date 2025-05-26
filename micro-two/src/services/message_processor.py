"""
Message Processor Service for Micro-Two
Handles processing of incoming messages and state management using Dapr.
"""

import json
from typing import Dict, Any, Optional
from datetime import datetime

import structlog
from dapr.clients.grpc.client import DaprGrpcClient

logger = structlog.get_logger(__name__)


class MessageProcessor:
    """Service for processing incoming messages via Dapr"""

    def __init__(self, dapr_client: DaprGrpcClient):
        self.dapr_client = dapr_client
        self.state_store_name = "statestore"

    async def process_message(
        self, message: str, message_id: str, sender: str
    ) -> Dict[str, Any]:
        """
        Process an incoming message and optionally store state

        Args:
            message: The message content
            message_id: Unique identifier for the message
            sender: The service that sent the message

        Returns:
            Processing result
        """
        logger.info(
            "Processing incoming message",
            message_id=message_id,
            sender=sender,
            message_length=len(message),
        )

        try:
            # Simulate message processing
            processed_at = datetime.utcnow().isoformat()

            # Create response message
            response_message = f"Hello {sender}! I received your message: '{message}'. Processed at {processed_at}"

            # Store message state in Dapr state store (optional)
            await self._store_message_state(
                message_id=message_id,
                original_message=message,
                sender=sender,
                processed_at=processed_at,
                response=response_message,
            )

            # Simulate some processing logic
            word_count = len(message.split())
            char_count = len(message)

            result = {
                "status": "processed",
                "message_id": message_id,
                "sender": sender,
                "processed_at": processed_at,
                "response": response_message,
                "analytics": {
                    "word_count": word_count,
                    "character_count": char_count,
                    "processing_time_ms": 42,  # Simulated processing time
                },
            }

            logger.info(
                "Message processed successfully",
                message_id=message_id,
                sender=sender,
                word_count=word_count,
                char_count=char_count,
            )

            return result

        except Exception as e:
            logger.error(
                "Failed to process message",
                message_id=message_id,
                sender=sender,
                error=str(e),
                exc_info=True,
            )
            raise

    async def _store_message_state(
        self,
        message_id: str,
        original_message: str,
        sender: str,
        processed_at: str,
        response: str,
    ) -> None:
        """
        Store message processing state in Dapr state store

        Args:
            message_id: Unique identifier for the message
            original_message: The original message content
            sender: The service that sent the message
            processed_at: Timestamp when message was processed
            response: The response message
        """
        try:
            state_data = {
                "message_id": message_id,
                "original_message": original_message,
                "sender": sender,
                "processed_at": processed_at,
                "response": response,
                "processor": "micro-two",
            }

            # Store in Dapr state store
            self.dapr_client.save_state(
                store_name=self.state_store_name,
                key=f"message_{message_id}",
                value=json.dumps(state_data),
            )

            logger.info(
                "Message state stored successfully",
                message_id=message_id,
                state_store=self.state_store_name,
            )

        except Exception as e:
            # Don't fail message processing if state storage fails
            logger.warning(
                "Failed to store message state", message_id=message_id, error=str(e)
            )

    async def get_message_state(self, message_id: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve message state from Dapr state store

        Args:
            message_id: Unique identifier for the message

        Returns:
            Message state data or None if not found
        """
        try:
            response = self.dapr_client.get_state(
                store_name=self.state_store_name, key=f"message_{message_id}"
            )

            if response.data:
                state_data = json.loads(response.data)
                logger.info(
                    "Retrieved message state",
                    message_id=message_id,
                    state_store=self.state_store_name,
                )
                return state_data
            else:
                logger.info(
                    "No state found for message",
                    message_id=message_id,
                    state_store=self.state_store_name,
                )
                return None

        except Exception as e:
            logger.error(
                "Failed to retrieve message state",
                message_id=message_id,
                error=str(e),
                exc_info=True,
            )
            return None

    async def delete_message_state(self, message_id: str) -> bool:
        """
        Delete message state from Dapr state store

        Args:
            message_id: Unique identifier for the message

        Returns:
            True if deleted successfully, False otherwise
        """
        try:
            self.dapr_client.delete_state(
                store_name=self.state_store_name, key=f"message_{message_id}"
            )

            logger.info(
                "Message state deleted",
                message_id=message_id,
                state_store=self.state_store_name,
            )
            return True

        except Exception as e:
            logger.error(
                "Failed to delete message state",
                message_id=message_id,
                error=str(e),
                exc_info=True,
            )
            return False
