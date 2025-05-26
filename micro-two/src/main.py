"""
Micro-Two: Receiver Service
A FastAPI microservice that receives messages from micro-one using Dapr.
"""

import logging
from contextlib import asynccontextmanager
from typing import Dict, Any, List
from datetime import datetime

import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dapr.clients.grpc.client import DaprGrpcClient

from .services.message_processor import MessageProcessor

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
class IncomingMessage(BaseModel):
    message: str
    message_id: str
    sender: str
    timestamp: str


class MessageResponse(BaseModel):
    status: str
    message_id: str
    processed_at: str
    response_message: str


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    messages_received: int


class MessageListResponse(BaseModel):
    messages: List[Dict[str, Any]]
    total_count: int


# Global variables
message_processor: MessageProcessor = None
received_messages: List[Dict[str, Any]] = []


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    global message_processor

    logger.info("Starting micro-two service")

    # Initialize Dapr client and message processor
    dapr_client = DaprGrpcClient()
    message_processor = MessageProcessor(dapr_client)

    yield

    # Cleanup
    logger.info("Shutting down micro-two service")
    if dapr_client:
        await dapr_client.close()


# Create FastAPI app
app = FastAPI(
    title="Micro-Two",
    description="Receiver microservice for Dapr demo",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/healthz", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        service="micro-two",
        version="1.0.0",
        messages_received=len(received_messages),
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "micro-two",
        "message": "Hello from Micro-Two! I'm ready to receive messages.",
        "endpoints": {
            "health": "/healthz",
            "receive_message": "/receive-message",
            "messages": "/messages",
            "docs": "/docs",
        },
        "stats": {"messages_received": len(received_messages)},
    }


@app.post("/receive-message", response_model=MessageResponse)
async def receive_message(message: IncomingMessage):
    """Receive and process a message from another microservice"""
    logger.info(
        "Received message",
        message_id=message.message_id,
        sender=message.sender,
        message_length=len(message.message),
    )

    try:
        # Process the message
        processed_message = await message_processor.process_message(
            message=message.message,
            message_id=message.message_id,
            sender=message.sender,
        )

        # Store the message for later retrieval
        message_record = {
            "message_id": message.message_id,
            "sender": message.sender,
            "message": message.message,
            "received_at": datetime.utcnow().isoformat(),
            "processed": True,
            "response": processed_message["response"],
        }
        received_messages.append(message_record)

        logger.info(
            "Message processed successfully",
            message_id=message.message_id,
            sender=message.sender,
            total_messages=len(received_messages),
        )

        return MessageResponse(
            status="received",
            message_id=message.message_id,
            processed_at=datetime.utcnow().isoformat(),
            response_message=processed_message["response"],
        )

    except Exception as e:
        logger.error(
            "Failed to process message",
            message_id=message.message_id,
            sender=message.sender,
            error=str(e),
            exc_info=True,
        )
        raise HTTPException(
            status_code=500, detail=f"Failed to process message: {str(e)}"
        )


@app.get("/messages", response_model=MessageListResponse)
async def get_messages(limit: int = 10, offset: int = 0):
    """Get list of received messages"""
    total_count = len(received_messages)
    messages_slice = received_messages[offset : offset + limit]

    return MessageListResponse(messages=messages_slice, total_count=total_count)


@app.get("/messages/{message_id}")
async def get_message(message_id: str):
    """Get a specific message by ID"""
    for message in received_messages:
        if message["message_id"] == message_id:
            return message

    raise HTTPException(
        status_code=404, detail=f"Message with ID {message_id} not found"
    )


@app.delete("/messages")
async def clear_messages():
    """Clear all received messages (for testing)"""
    global received_messages
    count = len(received_messages)
    received_messages.clear()

    logger.info("Cleared all messages", count=count)

    return {"status": "cleared", "messages_removed": count}


@app.post("/echo")
async def echo_message(data: Dict[str, Any]):
    """Simple echo endpoint for testing"""
    logger.info("Echo request received", data=data)
    return {
        "echo": data,
        "service": "micro-two",
        "timestamp": datetime.utcnow().isoformat(),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app", host="0.0.0.0", port=8002, reload=True, log_level="info"
    )
