"""
Micro-One: Sender Service
A FastAPI microservice that sends messages to micro-two using Dapr.
"""

import logging
import uuid
from contextlib import asynccontextmanager
from typing import Dict, Any

import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dapr.clients.grpc.client import DaprGrpcClient

from .services.message_service import MessageService

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer(),
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)


# Pydantic models
class MessageRequest(BaseModel):
    message: str
    recipient_id: str = "micro-two"


class MessageResponse(BaseModel):
    status: str
    message_id: str
    sent_to: str


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str


# Global variables
message_service: MessageService = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    global message_service

    logger.info("Starting micro-one service")

    # Initialize Dapr client and message service
    dapr_client = DaprGrpcClient()
    message_service = MessageService(dapr_client)

    yield

    # Cleanup
    logger.info("Shutting down micro-one service")
    if dapr_client:
        await dapr_client.close()


# Create FastAPI app
app = FastAPI(
    title="Micro-One",
    description="Sender microservice for Dapr demo",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/healthz", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(status="healthy", service="micro-one", version="1.0.0")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "micro-one",
        "message": "Hello from Micro-One! I'm ready to send messages.",
        "endpoints": {
            "health": "/healthz",
            "send_message": "/send-message",
            "docs": "/docs",
        },
    }


@app.post("/send-message", response_model=MessageResponse)
async def send_message(request: MessageRequest):
    """Send a message to another microservice via Dapr"""
    message_id = str(uuid.uuid4())

    logger.info(
        "Received message send request",
        message_id=message_id,
        recipient=request.recipient_id,
        message_length=len(request.message),
    )

    try:
        # Send message using Dapr service invocation
        response = await message_service.send_message(
            recipient_service=request.recipient_id,
            message=request.message,
            message_id=message_id,
        )

        logger.info(
            "Message sent successfully",
            message_id=message_id,
            recipient=request.recipient_id,
            response_status=response.get("status", "unknown"),
        )

        return MessageResponse(
            status="sent", message_id=message_id, sent_to=request.recipient_id
        )

    except Exception as e:
        logger.error(
            "Failed to send message",
            message_id=message_id,
            recipient=request.recipient_id,
            error=str(e),
            exc_info=True,
        )
        raise HTTPException(status_code=500, detail=f"Failed to send message: {str(e)}")


@app.get("/messages/status/{message_id}")
async def get_message_status(message_id: str):
    """Get the status of a sent message"""
    # In a real application, you might store message status in a database
    # For this demo, we'll return a simple response
    return {
        "message_id": message_id,
        "status": "delivered",
        "timestamp": "2024-01-01T00:00:00Z",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app", host="0.0.0.0", port=8001, reload=True, log_level="info"
    )
