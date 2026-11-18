"""Rate limiting middleware and dependency for sensitive API routes."""

import time
from collections import defaultdict
from typing import Dict, List
from fastapi import HTTPException, Request, status


class InMemoryRateLimiter:
    """Sliding-window rate limiter for brute-force and spam protection."""

    def __init__(self, requests_per_minute: int = 30):
        self.requests_per_minute = requests_per_minute
        self.window_seconds = 60
        self._history: Dict[str, List[float]] = defaultdict(list)

    async def check(self, request: Request, key_prefix: str = "") -> None:
        client_ip = request.client.host if request.client else "unknown"
        key = f"{key_prefix}:{client_ip}"
        now = time.time()
        cutoff = now - self.window_seconds

        # Clean old timestamps
        timestamps = [t for t in self._history[key] if t > cutoff]
        self._history[key] = timestamps

        if len(timestamps) >= self.requests_per_minute:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Please wait before retrying.",
            )

        self._history[key].append(now)


# Standard rate limiters for sensitive endpoints
auth_rate_limiter = InMemoryRateLimiter(requests_per_minute=20)
media_rate_limiter = InMemoryRateLimiter(requests_per_minute=60)
submission_rate_limiter = InMemoryRateLimiter(requests_per_minute=30)
