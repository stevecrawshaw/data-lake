"""Tests for EPC API client functionality."""

from datetime import date
from unittest.mock import Mock, patch

import httpx
import pytest

from src.extractors.epc_api_client import EPCAPIClient
from src.extractors.epc_models import CertificateType, EPCConfig


@pytest.fixture
def mock_config() -> EPCConfig:
    """Provide a mock EPCConfig for testing."""
    return EPCConfig(
        username="test_user",
        password="test_password",
        page_size=2,  # Small page size for testing
        max_records_per_batch=10,
    )


@pytest.fixture
def sample_csv_response() -> str:
    """Provide sample CSV response from API."""
    return """lmk-key,address1,postcode,uprn,lodgement-date
ABC123,123 Test St,TE1 1ST,100023336958,2025-11-15
DEF456,456 Sample Rd,SA2 2MP,100023336959,2025-11-20
"""


@pytest.fixture
def sample_csv_response_page2() -> str:
    """Provide sample CSV response for page 2."""
    return """lmk-key,address1,postcode,uprn,lodgement-date
GHI789,789 Next Ave,NE3 3XT,100023336960,2025-11-25
JKL012,012 Final Ln,FI4 4NL,100023336961,2025-11-30
"""


class TestEPCAPIClient:
    """Tests for EPCAPIClient class."""

    def test_init(self, mock_config: EPCConfig) -> None:
        """Test EPCAPIClient initialization."""
        client = EPCAPIClient(mock_config)

        assert client.config == mock_config
        assert isinstance(client.client, httpx.Client)
        # Check timeout configuration
        assert client.client.timeout.connect == 30.0
        assert client.client.timeout.read == 60.0

    def test_context_manager(self, mock_config: EPCConfig) -> None:
        """Test EPCAPIClient works as context manager."""
        with EPCAPIClient(mock_config) as client:
            assert isinstance(client, EPCAPIClient)
            assert client.client is not None

        # Client should be closed after exiting context
        assert client.client.is_closed

    def test_build_params_domestic(self, mock_config: EPCConfig) -> None:
        """Test _build_params builds parameters correctly."""
        client = EPCAPIClient(mock_config)
        params = client._build_params(
            from_date=date(2025, 11, 1),
            to_date=date(2025, 11, 30),
            search_after=None,
        )

        assert params["from-month"] == 11
        assert params["from-year"] == 2025
        assert params["to-month"] == 11
        assert params["to-year"] == 2025
        assert params["size"] == 2  # From config page_size
        assert "search-after" not in params

    def test_build_params_with_search_after(self, mock_config: EPCConfig) -> None:
        """Test _build_params includes search-after cursor."""
        client = EPCAPIClient(mock_config)
        params = client._build_params(
            from_date=date(2025, 11, 1),
            to_date=date(2025, 11, 30),
            search_after="cursor_abc123",
        )

        assert params["search-after"] == "cursor_abc123"

    def test_build_params_to_date(self, mock_config: EPCConfig) -> None:
        """Test _build_params with different year range."""
        client = EPCAPIClient(mock_config)
        params = client._build_params(
            from_date=date(2024, 12, 1),
            to_date=date(2025, 1, 31),
            search_after=None,
        )

        assert params["from-month"] == 12
        assert params["from-year"] == 2024
        assert params["to-month"] == 1
        assert params["to-year"] == 2025

    @patch("httpx.Client.get")
    def test_fetch_pages_single_page(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test _paginate_requests retrieves single page successfully."""
        # Mock HTTP response
        mock_response = Mock(spec=httpx.Response)
        mock_response.status_code = 200
        mock_response.content = sample_csv_response.encode("utf-8")
        mock_response.headers = {}
        mock_get.return_value = mock_response

        client = EPCAPIClient(mock_config)
        records = client._paginate_requests(
            endpoint="/api/v1/domestic/search",
            initial_params={"from-month": 11, "from-year": 2025, "size": 2},
        )

        assert len(records) == 2
        assert records[0]["lmk-key"] == "ABC123"
        assert mock_get.call_count == 1

    @patch("httpx.Client.get")
    def test_fetch_pages_multiple_pages(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
        sample_csv_response_page2: str,
    ) -> None:
        """Test _paginate_requests handles pagination correctly."""
        # Mock first response with search-after header
        mock_response1 = Mock(spec=httpx.Response)
        mock_response1.status_code = 200
        mock_response1.content = sample_csv_response.encode("utf-8")
        mock_response1.headers = {"X-Next-Search-After": "cursor_page2"}

        # Mock second response without search-after (last page)
        mock_response2 = Mock(spec=httpx.Response)
        mock_response2.status_code = 200
        mock_response2.content = sample_csv_response_page2.encode("utf-8")
        mock_response2.headers = {}

        mock_get.side_effect = [mock_response1, mock_response2]

        client = EPCAPIClient(mock_config)
        records = client._paginate_requests(
            endpoint="/api/v1/domestic/search",
            initial_params={"from-month": 11, "from-year": 2025, "size": 2},
        )

        assert len(records) == 4  # 2 from page 1 + 2 from page 2
        assert records[0]["lmk-key"] == "ABC123"
        assert records[2]["lmk-key"] == "GHI789"
        assert mock_get.call_count == 2

    @patch("httpx.Client.get")
    def test_fetch_pages_max_records_limit(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test _paginate_requests respects max_records_per_batch limit."""
        # Create response that would exceed limit
        mock_config.max_records_per_batch = 3  # Set low limit

        mock_response1 = Mock(spec=httpx.Response)
        mock_response1.status_code = 200
        mock_response1.content = sample_csv_response.encode("utf-8")  # 2 records
        mock_response1.headers = {"X-Next-Search-After": "cursor_page2"}

        mock_response2 = Mock(spec=httpx.Response)
        mock_response2.status_code = 200
        mock_response2.content = sample_csv_response.encode("utf-8")  # 2 more records
        mock_response2.headers = {"X-Next-Search-After": "cursor_page3"}

        mock_get.side_effect = [mock_response1, mock_response2]

        client = EPCAPIClient(mock_config)
        records = client._paginate_requests(
            endpoint="/api/v1/domestic/search",
            initial_params={"from-month": 11, "from-year": 2025, "size": 2},
        )

        # Should stop after hitting limit (3 records max, got 4 but should stop)
        assert len(records) == 4
        assert mock_get.call_count == 2

    @patch("httpx.Client.get")
    def test_fetch_pages_http_error(
        self, mock_get: Mock, mock_config: EPCConfig
    ) -> None:
        """Test _paginate_requests handles HTTP errors."""
        mock_get.side_effect = httpx.HTTPStatusError(
            "500 Server Error",
            request=Mock(),
            response=Mock(status_code=500),
        )

        client = EPCAPIClient(mock_config)

        with pytest.raises(httpx.HTTPStatusError):
            client._paginate_requests(
                endpoint="/api/v1/domestic/search",
                initial_params={"from-month": 11, "from-year": 2025, "size": 2},
            )

    @patch("httpx.Client.get")
    def test_fetch_certificates_domestic(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test fetch_certificates for domestic certificates."""
        mock_response = Mock(spec=httpx.Response)
        mock_response.status_code = 200
        mock_response.content = sample_csv_response.encode("utf-8")
        mock_response.headers = {}
        mock_get.return_value = mock_response

        client = EPCAPIClient(mock_config)
        records = client.fetch_certificates(
            certificate_type=CertificateType.DOMESTIC,
            from_date=date(2025, 11, 1),
        )

        assert len(records) == 2
        assert records[0]["lmk-key"] == "ABC123"

        # Verify correct endpoint was called
        call_args = mock_get.call_args
        assert call_args[0][0] == "/api/v1/domestic/search"

    @patch("httpx.Client.get")
    def test_fetch_certificates_non_domestic(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test fetch_certificates for non-domestic certificates."""
        mock_response = Mock(spec=httpx.Response)
        mock_response.status_code = 200
        mock_response.content = sample_csv_response.encode("utf-8")
        mock_response.headers = {}
        mock_get.return_value = mock_response

        client = EPCAPIClient(mock_config)
        records = client.fetch_certificates(
            certificate_type=CertificateType.NON_DOMESTIC,
            from_date=date(2025, 11, 1),
        )

        assert len(records) == 2

        # Verify correct endpoint was called
        call_args = mock_get.call_args
        assert call_args[0][0] == "/api/v1/non-domestic/search"

    def test_fetch_certificates_invalid_type(self, mock_config: EPCConfig) -> None:
        """Test fetch_certificates raises ValueError for invalid certificate type."""
        client = EPCAPIClient(mock_config)

        with pytest.raises(ValueError) as exc_info:
            client.fetch_certificates(
                certificate_type="invalid",  # type: ignore[arg-type]
                from_date=date(2025, 11, 1),
            )

        assert "Invalid certificate type" in str(exc_info.value)

    @patch("httpx.Client.get")
    def test_fetch_certificates_with_date_range(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test fetch_certificates with from_date and to_date."""
        mock_response = Mock(spec=httpx.Response)
        mock_response.status_code = 200
        mock_response.content = sample_csv_response.encode("utf-8")
        mock_response.headers = {}
        mock_get.return_value = mock_response

        client = EPCAPIClient(mock_config)
        records = client.fetch_certificates(
            certificate_type=CertificateType.DOMESTIC,
            from_date=date(2025, 11, 1),
            to_date=date(2025, 11, 30),
        )

        assert len(records) == 2

        # Verify params include to-month and to-year
        call_args = mock_get.call_args
        params = call_args.kwargs.get("params", {})
        assert params.get("to-month") == 11
        assert params.get("to-year") == 2025

    def test_close(self, mock_config: EPCConfig) -> None:
        """Test close method closes HTTP client."""
        client = EPCAPIClient(mock_config)
        assert not client.client.is_closed

        client.close()
        assert client.client.is_closed

    @patch("httpx.Client.get")
    def test_paginate_requests_integration(
        self,
        mock_get: Mock,
        mock_config: EPCConfig,
        sample_csv_response: str,
    ) -> None:
        """Test _paginate_requests integration."""
        mock_response = Mock(spec=httpx.Response)
        mock_response.status_code = 200
        mock_response.content = sample_csv_response.encode("utf-8")
        mock_response.headers = {}
        mock_get.return_value = mock_response

        client = EPCAPIClient(mock_config)

        # Test the method
        params = {"from-month": 11, "from-year": 2025, "size": 2}
        records = client._paginate_requests(
            endpoint="/api/v1/domestic/search",
            initial_params=params,
        )

        # Verify records were fetched
        assert len(records) == 2
        assert mock_get.call_count >= 1
