"""EPC API client with pagination and authentication support."""

import base64
import io
import logging
import sys
from datetime import date

import duckdb
import httpx

from .epc_models import CertificateType, EPCConfig

logger = logging.getLogger(__name__)

# Detect if we're in a Rich-incompatible environment (Git Bash with cp1252)
USE_RICH_PROGRESS = True
try:
    from rich.progress import (
        BarColumn,
        Progress,
        SpinnerColumn,
        TextColumn,
        TimeRemainingColumn,
    )

    # Check if stdout can handle unicode
    if hasattr(sys.stdout, "encoding") and sys.stdout.encoding.lower() == "cp1252":
        USE_RICH_PROGRESS = False
        logger.debug("Disabling Rich progress bar (cp1252 encoding detected)")
except ImportError:
    USE_RICH_PROGRESS = False


class EPCAPIClient:
    """Client for EPC API with automatic pagination and authentication.

    Attributes:
        config: EPCConfig instance with API credentials and endpoints
        client: httpx.Client for making requests
    """

    def __init__(self, config: EPCConfig) -> None:
        """Initialize API client with configuration.

        Args:
            config: EPCConfig instance with credentials and settings
        """
        self.config = config

        # Create Basic Auth token
        auth_string = f"{config.username}:{config.password}"
        auth_bytes = auth_string.encode("utf-8")
        auth_token = base64.b64encode(auth_bytes).decode("utf-8")

        # Setup httpx client with retry and timeout
        self.client = httpx.Client(
            base_url=config.base_url,
            headers={
                "Authorization": f"Basic {auth_token}",
                "Accept": "text/csv",
            },
            timeout=httpx.Timeout(30.0, read=60.0),
            follow_redirects=True,
        )

    def fetch_certificates(
        self,
        certificate_type: str,
        from_date: date,
        to_date: date | None = None,
    ) -> list[dict[str, str]]:
        """Fetch EPC certificates from API with pagination.

        Args:
            certificate_type: Type of certificate ("domestic" or "non-domestic")
            from_date: Start date for lodgement date filter
            to_date: End date for lodgement date filter (default: today)

        Returns:
            List of certificate records as dictionaries

        Raises:
            ValueError: If invalid certificate type
            httpx.HTTPStatusError: If API returns error status
        """
        if to_date is None:
            to_date = date.today()

        # Determine endpoint
        if certificate_type == CertificateType.DOMESTIC:
            endpoint = self.config.domestic_endpoint
        elif certificate_type == CertificateType.NON_DOMESTIC:
            endpoint = self.config.non_domestic_endpoint
        else:
            msg = f"Invalid certificate type: {certificate_type}"
            raise ValueError(msg)

        logger.info(
            f"Fetching {certificate_type} certificates from {from_date} to {to_date}"
        )

        # Build initial parameters
        params = self._build_params(from_date, to_date)

        # Fetch all pages with pagination
        return self._paginate_requests(endpoint, params)

    def _build_params(
        self,
        from_date: date,
        to_date: date,
        search_after: str | None = None,
    ) -> dict[str, str | int]:
        """Build API request parameters.

        Args:
            from_date: Start date for filter
            to_date: End date for filter
            search_after: Pagination cursor (optional)

        Returns:
            Dictionary of query parameters
        """
        params: dict[str, str | int] = {
            "from-month": from_date.month,
            "from-year": from_date.year,
            "to-month": to_date.month,
            "to-year": to_date.year,
            "size": self.config.page_size,
        }

        if search_after:
            params["search-after"] = search_after

        return params

    def _paginate_requests(
        self, endpoint: str, initial_params: dict[str, str | int]
    ) -> list[dict[str, str]]:
        """Fetch all pages using search-after cursor pagination.

        Args:
            endpoint: API endpoint path
            initial_params: Initial query parameters

        Returns:
            List of all records from all pages

        Raises:
            httpx.HTTPStatusError: If API returns error status
        """
        all_records: list[dict[str, str]] = []
        search_after: str | None = None
        page_num = 0

        # Use Rich progress bar if available, otherwise simple logging
        if USE_RICH_PROGRESS:
            # Setup progress bar
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                TextColumn("[progress.percentage]{task.completed} records"),
                TimeRemainingColumn(),
            ) as progress:
                task = progress.add_task("Fetching certificates...", total=None)
                return self._fetch_pages(
                    endpoint,
                    initial_params,
                    all_records,
                    search_after,
                    page_num,
                    progress,
                    task,
                )
        else:
            # Simple logging without Rich progress
            return self._fetch_pages(
                endpoint, initial_params, all_records, search_after, page_num
            )

    def _fetch_pages(
        self,
        endpoint: str,
        initial_params: dict[str, str | int],
        all_records: list[dict[str, str]],
        search_after: str | None,
        page_num: int,
        progress=None,  # type: ignore[no-untyped-def]
        task=None,  # type: ignore[no-untyped-def]
    ) -> list[dict[str, str]]:
        """Fetch pages with optional progress tracking.

        Uses DuckDB read_csv + UNION ALL BY NAME for efficient CSV processing.
        """
        csv_pages: list[str] = []
        total_rows = 0

        while True:
            page_num += 1

            # Build params for this page
            params = initial_params.copy()
            if search_after:
                params["search-after"] = search_after

            try:
                # Make request
                logger.debug(f"Fetching page {page_num} with params: {params}")
                response = self.client.get(endpoint, params=params)

                # Handle specific error codes
                if response.status_code == 401:
                    msg = "Invalid EPC API credentials (401 Unauthorized)"
                    raise ValueError(msg)
                elif response.status_code == 429:
                    logger.warning("Rate limit hit (429), waiting 60 seconds...")
                    import time

                    time.sleep(60)
                    response = self.client.get(endpoint, params=params)

                response.raise_for_status()

            except httpx.HTTPStatusError as e:
                logger.error(f"HTTP error on page {page_num}: {e}")
                raise
            except httpx.TimeoutException:
                logger.error(f"Request timeout on page {page_num}")
                raise

            # Store CSV response text
            csv_text = response.content.decode("utf-8")
            csv_pages.append(csv_text)

            # Count rows for progress (quick estimate from newlines)
            page_rows = csv_text.count("\n") - 1  # Subtract header
            total_rows += page_rows

            # Update progress
            if progress and task:
                progress.update(task, completed=total_rows)

            logger.info(
                f"Page {page_num}: Fetched ~{page_rows} records (total: ~{total_rows})"
            )

            # Check for next page cursor
            search_after = response.headers.get("X-Next-Search-After")
            if not search_after:
                logger.info(f"No more pages. Total records: ~{total_rows}")
                break

            # Safety check for max records
            if total_rows >= self.config.max_records_per_batch:
                logger.warning(
                    f"Reached max records limit ({self.config.max_records_per_batch})"
                )
                break

        # Combine all CSV pages using DuckDB UNION ALL BY NAME
        if not csv_pages:
            return []

        logger.debug("Combining CSV pages with DuckDB UNION ALL BY NAME...")
        con = duckdb.connect()

        try:
            # Read each CSV page into a relation and register it
            for idx, csv_text in enumerate(csv_pages):
                rel = con.read_csv(io.StringIO(csv_text))
                con.register(f"page_{idx}", rel)

            # Build dynamic UNION ALL BY NAME query (integer indices are safe)
            union_query = " UNION ALL BY NAME ".join(
                f"SELECT * FROM page_{i}"
                for i in range(len(csv_pages))  # noqa: S608
            )
            combined = con.sql(union_query)

            # Convert to list of dicts
            records = combined.fetchall()
            columns = [desc[0] for desc in combined.description]
            all_records = [dict(zip(columns, row, strict=True)) for row in records]

            logger.info(
                f"Combined {len(all_records)} records from {len(csv_pages)} pages"
            )

            return all_records

        finally:
            con.close()

    def close(self) -> None:
        """Close the HTTP client connection."""
        self.client.close()

    def __enter__(self) -> "EPCAPIClient":
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:  # type: ignore[no-untyped-def]
        """Context manager exit."""
        self.close()
