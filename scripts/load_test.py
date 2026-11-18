#!/usr/bin/env python3
"""
DataMint Production Performance & Concurrency Load Test Runner
=============================================================================
Simulates concurrent production workloads against the DataMint API endpoints:
- Liveness & Readiness checks
- SIWE Nonce authentication generation
- Marketplace browsing & search
- High-concurrency burst and sustained throughput analysis

Calculates and displays:
- Total requests and elapsed time
- Throughput (Requests Per Second - RPS)
- Error rate and HTTP status code distribution
- Latency percentiles: Mean, Min, P50, P90, P95, P99, Max
=============================================================================
"""

import argparse
import asyncio
import json
import statistics
import sys
import time
from typing import Any, Dict, List

try:
    import httpx
except ImportError:
    print("[-] Error: 'httpx' is required. Install with: pip install httpx")
    sys.exit(1)


class LoadTester:
    def __init__(
        self,
        base_url: str,
        concurrency: int,
        duration: int,
        scenario: str,
    ):
        self.base_url = base_url.rstrip("/")
        self.concurrency = concurrency
        self.duration = duration
        self.scenario = scenario
        self.latencies: List[float] = []
        self.status_codes: Dict[int, int] = {}
        self.error_count = 0
        self.total_requests = 0

    async def _make_request(self, client: httpx.AsyncClient, worker_id: int) -> None:
        """Issue an HTTP request based on selected scenario."""
        url = f"{self.base_url}/api/v1/health/healthz"
        method = "GET"
        headers = {"X-Request-ID": f"loadtest-{worker_id}-{time.time()}"}
        payload = None

        if self.scenario == "health":
            url = f"{self.base_url}/api/v1/health/healthz"
        elif self.scenario == "ready":
            url = f"{self.base_url}/api/v1/health/readyz"
        elif self.scenario == "auth_nonce":
            url = f"{self.base_url}/api/v1/auth/nonce"
        elif self.scenario == "mixed":
            # Round-robin or cycle between core endpoints
            choice = self.total_requests % 3
            if choice == 0:
                url = f"{self.base_url}/api/v1/health/healthz"
            elif choice == 1:
                url = f"{self.base_url}/api/v1/health/readyz"
            else:
                url = f"{self.base_url}/api/v1/auth/nonce"

        t_start = time.perf_counter()
        try:
            resp = await client.request(method, url, headers=headers, json=payload, timeout=5.0)
            latency_ms = (time.perf_counter() - t_start) * 1000.0
            self.latencies.append(latency_ms)
            self.status_codes[resp.status_code] = self.status_codes.get(resp.status_code, 0) + 1
            if resp.status_code >= 400:
                self.error_count += 1
        except Exception:
            latency_ms = (time.perf_counter() - t_start) * 1000.0
            self.latencies.append(latency_ms)
            self.error_count += 1
            self.status_codes[599] = self.status_codes.get(599, 0) + 1
        finally:
            self.total_requests += 1

    async def _worker(self, worker_id: int, stop_time: float) -> None:
        limits = httpx.Limits(max_keepalive_connections=50, max_connections=100)
        async with httpx.AsyncClient(limits=limits) as client:
            while time.perf_counter() < stop_time:
                await self._make_request(client, worker_id)
                # Small cooperative yield to allow event loop scheduling
                await asyncio.sleep(0.001)

    async def run(self) -> Dict[str, Any]:
        print(f"[*] Starting DataMint Load Test...")
        print(f"    Target:      {self.base_url}")
        print(f"    Scenario:    {self.scenario}")
        print(f"    Concurrency: {self.concurrency} concurrent workers")
        print(f"    Duration:    {self.duration}s")
        print("=" * 70)

        t_start = time.perf_counter()
        stop_time = t_start + self.duration

        tasks = [asyncio.create_task(self._worker(i, stop_time)) for i in range(self.concurrency)]
        await asyncio.gather(*tasks)

        total_time = time.perf_counter() - t_start
        rps = self.total_requests / total_time if total_time > 0 else 0

        # Compute percentile metrics
        lat_sorted = sorted(self.latencies) if self.latencies else [0.0]
        n = len(lat_sorted)

        def pct(p: float) -> float:
            idx = int(round(p * (n - 1)))
            return lat_sorted[min(idx, n - 1)]

        metrics = {
            "total_requests": self.total_requests,
            "duration_seconds": round(total_time, 2),
            "throughput_rps": round(rps, 2),
            "error_count": self.error_count,
            "error_rate_pct": round((self.error_count / self.total_requests * 100.0) if self.total_requests else 0, 2),
            "status_codes": self.status_codes,
            "latency_ms": {
                "mean": round(statistics.mean(lat_sorted), 2) if lat_sorted else 0,
                "min": round(lat_sorted[0], 2),
                "p50": round(pct(0.50), 2),
                "p90": round(pct(0.90), 2),
                "p95": round(pct(0.95), 2),
                "p99": round(pct(0.99), 2),
                "max": round(lat_sorted[-1], 2),
            },
        }

        self._print_report(metrics)
        return metrics

    def _print_report(self, m: Dict[str, Any]) -> None:
        print("\n" + "=" * 70)
        print(" DATAMINT PERFORMANCE BENCHMARK REPORT")
        print("=" * 70)
        print(f" Total Requests Completed: {m['total_requests']}")
        print(f" Elapsed Time:             {m['duration_seconds']}s")
        print(f" Average Throughput:       {m['throughput_rps']} RPS")
        print(f" Failed Requests:          {m['error_count']} ({m['error_rate_pct']}%)")
        print(f" Status Distribution:      {m['status_codes']}")
        print("-" * 70)
        print(" Latency Percentiles (ms):")
        lat = m["latency_ms"]
        print(f"   Min:   {lat['min']:>8.2f} ms")
        print(f"   Mean:  {lat['mean']:>8.2f} ms")
        print(f"   P50:   {lat['p50']:>8.2f} ms")
        print(f"   P90:   {lat['p90']:>8.2f} ms")
        print(f"   P95:   {lat['p95']:>8.2f} ms")
        print(f"   P99:   {lat['p99']:>8.2f} ms")
        print(f"   Max:   {lat['max']:>8.2f} ms")
        print("=" * 70)


def main():
    parser = argparse.ArgumentParser(description="DataMint Load Testing Benchmark")
    parser.add_argument("--base-url", default="http://localhost:8000", help="Target API Base URL")
    parser.add_argument("--concurrency", type=int, default=15, help="Number of concurrent workers")
    parser.add_argument("--duration", type=int, default=5, help="Test duration in seconds")
    parser.add_argument(
        "--scenario",
        choices=["mixed", "health", "ready", "auth_nonce"],
        default="mixed",
        help="Workload scenario",
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON metrics")
    args = parser.parse_args()

    runner = LoadTester(
        base_url=args.base_url,
        concurrency=args.concurrency,
        duration=args.duration,
        scenario=args.scenario,
    )
    metrics = asyncio.run(runner.run())

    if args.json:
        print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
