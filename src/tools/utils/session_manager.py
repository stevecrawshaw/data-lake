"""Session management for interactive schema comment editing.

This module handles persistence of review progress across sessions, allowing
users to save, resume, and track their schema comment review work.
"""

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


class FieldReviewStatus(BaseModel):
    """Review status for a single field (table column or view column).

    Attributes:
        status: Current review state (pending, reviewed, skipped, confirmed)
        original_description: Original description from inference/pattern matching
        user_description: User-provided description (None if not yet reviewed)
        data_type: SQL data type of the field
        confidence: Confidence score from inference (0.0-1.0)
        source: Source of metadata (xml, inferred, fallback, computed, etc.)
        reviewed_at: Timestamp when field was last reviewed
    """

    status: Literal["pending", "reviewed", "skipped", "confirmed"]
    original_description: str
    user_description: str | None = None
    data_type: str
    confidence: float
    source: str
    reviewed_at: datetime | None = None


class CurrentPosition(BaseModel):
    """Current position in review workflow.

    Attributes:
        entity_name: Table or view name
        entity_type: 'table' or 'view'
        column_index: Index of column being reviewed
    """

    entity_name: str
    entity_type: Literal["table", "view"]
    column_index: int


class SessionState(BaseModel):
    """Complete session state for schema review.

    Attributes:
        version: Session file format version
        database_path: Path to database being reviewed
        created_at: Session creation timestamp
        last_updated: Last update timestamp
        current_position: Current position in review workflow (None if not started)
        fields: Nested dict mapping entity_name -> column_name -> review status
        statistics: Progress statistics (total, reviewed, skipped, pending)
    """

    version: str = "1.0"
    database_path: str
    created_at: datetime
    last_updated: datetime
    current_position: CurrentPosition | None = None
    fields: dict[str, dict[str, FieldReviewStatus]] = Field(default_factory=dict)
    statistics: dict[str, int] = Field(default_factory=dict)


class SessionManager:
    """Manages session persistence and state tracking."""

    def __init__(self, session_file: Path = Path(".schema_review_session.json")):
        """Initialize session manager.

        Args:
            session_file: Path to session file (default: .schema_review_session.json)
        """
        self.session_file = session_file
        self.state: SessionState | None = None

    def load_or_create(self, database_path: Path) -> SessionState:
        """Load existing session or create new one.

        Args:
            database_path: Path to database being reviewed

        Returns:
            SessionState object
        """
        if self.session_file.exists():
            try:
                logger.info(f"Loading session from {self.session_file}")
                data = json.loads(self.session_file.read_text(encoding="utf-8"))

                # Check database path matches
                if data.get("database_path") != str(database_path):
                    logger.warning(
                        f"Database path mismatch. Expected {database_path}, "
                        f"found {data.get('database_path')}. Creating new session."
                    )
                    return self._create_new_session(database_path)

                self.state = SessionState(**data)
                logger.info(f"Loaded session: {self.get_progress_stats()}")
                return self.state

            except Exception as e:
                logger.error(f"Error loading session: {e}")
                # Backup corrupted file
                backup_path = self.session_file.with_suffix(".json.backup")
                self.session_file.rename(backup_path)
                logger.info(f"Backed up corrupted session to {backup_path}")
                return self._create_new_session(database_path)
        else:
            return self._create_new_session(database_path)

    def _create_new_session(self, database_path: Path) -> SessionState:
        """Create new session state.

        Args:
            database_path: Path to database being reviewed

        Returns:
            New SessionState object
        """
        logger.info("Creating new session")
        now = datetime.now()
        self.state = SessionState(
            database_path=str(database_path),
            created_at=now,
            last_updated=now,
            statistics={"total": 0, "reviewed": 0, "skipped": 0, "pending": 0},
        )
        return self.state

    def save(self) -> None:
        """Persist session state to JSON file (atomic write)."""
        if not self.state:
            logger.warning("No session state to save")
            return

        # Update timestamp and statistics
        self.state.last_updated = datetime.now()
        self._update_statistics()

        # Atomic write: write to temp file then rename
        temp_file = self.session_file.with_suffix(".tmp")
        try:
            temp_file.write_text(
                self.state.model_dump_json(indent=2),
                encoding="utf-8",
            )
            temp_file.replace(self.session_file)
            logger.debug(f"Session saved to {self.session_file}")
        except Exception as e:
            logger.error(f"Error saving session: {e}")
            if temp_file.exists():
                temp_file.unlink()
            raise

    def initialize_field(
        self,
        entity_name: str,
        column_name: str,
        original_description: str,
        data_type: str,
        confidence: float,
        source: str,
    ) -> None:
        """Initialize a field for review (if not already in session).

        Args:
            entity_name: Table or view name
            column_name: Column name
            original_description: Original inferred/pattern-based description
            data_type: SQL data type
            confidence: Confidence score
            source: Metadata source (inferred, fallback, computed, etc.)
        """
        if not self.state:
            raise ValueError("Session not initialized. Call load_or_create() first.")

        if entity_name not in self.state.fields:
            self.state.fields[entity_name] = {}

        if column_name not in self.state.fields[entity_name]:
            self.state.fields[entity_name][column_name] = FieldReviewStatus(
                status="pending",
                original_description=original_description,
                data_type=data_type,
                confidence=confidence,
                source=source,
            )
            logger.debug(f"Initialized field: {entity_name}.{column_name}")

    def mark_reviewed(
        self,
        entity_name: str,
        column_name: str,
        user_description: str,
    ) -> None:
        """Mark field as reviewed with user-provided description.

        Args:
            entity_name: Table or view name
            column_name: Column name
            user_description: User-provided description
        """
        if not self.state:
            raise ValueError("Session not initialized")

        if (
            entity_name not in self.state.fields
            or column_name not in self.state.fields[entity_name]
        ):
            raise ValueError(f"Field not initialized: {entity_name}.{column_name}")

        self.state.fields[entity_name][column_name].status = "reviewed"
        self.state.fields[entity_name][column_name].user_description = user_description
        self.state.fields[entity_name][column_name].reviewed_at = datetime.now()

        logger.debug(f"Marked reviewed: {entity_name}.{column_name}")
        self.save()  # Auto-save after each review

    def mark_confirmed(
        self,
        entity_name: str,
        column_name: str,
    ) -> None:
        """Mark field as confirmed (keep existing description).

        Args:
            entity_name: Table or view name
            column_name: Column name
        """
        if not self.state:
            raise ValueError("Session not initialized")

        if (
            entity_name not in self.state.fields
            or column_name not in self.state.fields[entity_name]
        ):
            raise ValueError(f"Field not initialized: {entity_name}.{column_name}")

        field = self.state.fields[entity_name][column_name]
        field.status = "confirmed"
        field.user_description = field.original_description  # Use original as final
        field.reviewed_at = datetime.now()

        logger.debug(f"Marked confirmed: {entity_name}.{column_name}")
        self.save()

    def mark_skipped(
        self,
        entity_name: str,
        column_name: str,
    ) -> None:
        """Mark field as skipped for later review.

        Args:
            entity_name: Table or view name
            column_name: Column name
        """
        if not self.state:
            raise ValueError("Session not initialized")

        if (
            entity_name not in self.state.fields
            or column_name not in self.state.fields[entity_name]
        ):
            raise ValueError(f"Field not initialized: {entity_name}.{column_name}")

        self.state.fields[entity_name][column_name].status = "skipped"
        logger.debug(f"Marked skipped: {entity_name}.{column_name}")
        self.save()

    def update_position(
        self,
        entity_name: str,
        entity_type: Literal["table", "view"],
        column_index: int,
    ) -> None:
        """Update current position in review workflow.

        Args:
            entity_name: Table or view name
            entity_type: 'table' or 'view'
            column_index: Index of column being reviewed
        """
        if not self.state:
            raise ValueError("Session not initialized")

        self.state.current_position = CurrentPosition(
            entity_name=entity_name,
            entity_type=entity_type,
            column_index=column_index,
        )
        logger.debug(
            f"Updated position: {entity_type} {entity_name}, column {column_index}"
        )

    def get_next_pending_field(self) -> tuple[str, str] | None:
        """Get next field that needs review.

        Returns:
            Tuple of (entity_name, column_name) or None if all reviewed
        """
        if not self.state:
            return None

        for entity_name, columns in self.state.fields.items():
            for column_name, field in columns.items():
                if field.status == "pending":
                    return (entity_name, column_name)

        return None

    def get_progress_stats(self) -> dict[str, int]:
        """Calculate progress statistics.

        Returns:
            Dict with total, reviewed, skipped, pending counts
        """
        if not self.state:
            return {"total": 0, "reviewed": 0, "skipped": 0, "pending": 0}

        stats = {"total": 0, "reviewed": 0, "skipped": 0, "pending": 0, "confirmed": 0}

        for entity_name, columns in self.state.fields.items():
            for column_name, field in columns.items():
                stats["total"] += 1
                stats[field.status] += 1

        return stats

    def _update_statistics(self) -> None:
        """Update statistics in session state."""
        if not self.state:
            return

        self.state.statistics = self.get_progress_stats()

    def get_field_status(
        self, entity_name: str, column_name: str
    ) -> FieldReviewStatus | None:
        """Get review status for a specific field.

        Args:
            entity_name: Table or view name
            column_name: Column name

        Returns:
            FieldReviewStatus or None if not found
        """
        if not self.state:
            return None

        return self.state.fields.get(entity_name, {}).get(column_name)

    def get_reviewed_fields(self) -> dict[str, dict[str, FieldReviewStatus]]:
        """Get all fields that have been reviewed or confirmed.

        Returns:
            Dict mapping entity_name -> column_name -> review status
            Only includes fields with status='reviewed' or status='confirmed'
        """
        if not self.state:
            return {}

        reviewed = {}
        for entity_name, columns in self.state.fields.items():
            for column_name, field in columns.items():
                if field.status in ("reviewed", "confirmed"):
                    if entity_name not in reviewed:
                        reviewed[entity_name] = {}
                    reviewed[entity_name][column_name] = field

        return reviewed

    def clear_session(self) -> None:
        """Clear session file and state."""
        if self.session_file.exists():
            self.session_file.unlink()
            logger.info(f"Cleared session file: {self.session_file}")
        self.state = None
