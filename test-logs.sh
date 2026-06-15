#!/bin/bash

logger -t app-auth '{"timestamp": "2026-06-15T11:40:00Z", "level": "INFO", "service": "auth-service", "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736", "message": "User login successful", "user_id": "usr_9823", "duration_ms": 45}'

logger -t app-payment '{"timestamp": "2026-06-15T11:41:02Z", "level": "INFO", "service": "payment-service", "trace_id": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6", "message": "Payment captured successfully", "amount": 55000, "duration_ms": 120}'

logger -t app-db '{"timestamp": "2026-06-15T11:42:15Z", "level": "WARN", "service": "order-service", "trace_id": "7ff92f3577b34da6a3ce929d0e0e4799", "message": "Slow query detected on order_shippings table", "duration_ms": 1540}'

logger -t app-auth '{"timestamp": "2026-06-15T11:43:00Z", "level": "WARN", "service": "auth-service", "trace_id": "3cf92f3577b34da6a3ce929d0e0e4111", "message": "Database connection pool usage high: 88%", "active_connections": 44}'

logger -t app-db '{"timestamp": "2026-06-15T11:45:22Z", "level": "ERROR", "service": "order-service", "trace_id": "99f92f3577b34da6a3ce929d0e0e4999", "message": "Failed to connect to MySQL database master node. Connection timed out.", "exception": "java.net.ConnectException"}'

logger -t app-payment '{"timestamp": "2026-06-15T11:46:10Z", "level": "ERROR", "service": "payment-service", "trace_id": "88f92f3577b34da6a3ce929d0e0e4888", "message": "Payment gateway returned 500 Internal Server Error", "gateway_code": "PG_ERR_500"}'

logger -t app-auth '{"timestamp": "2026-06-15T11:50:01Z", "level": "INFO", "service": "auth-service", "trace_id": "lgtmtrace1234567890abcdef123456", "message": "API Token validated for user_777"}'

logger -t app-order '{"timestamp": "2026-06-15T11:50:02Z", "level": "INFO", "service": "order-service", "trace_id": "lgtmtrace1234567890abcdef123456", "message": "Creating pending order #4401"}'

logger -t app-payment '{"timestamp": "2026-06-15T11:50:03Z", "level": "ERROR", "service": "payment-service", "trace_id": "lgtmtrace1234567890abcdef123456", "message": "Card processing failed due to timeout"}'

