"""Orchestration logic for SQL transformations."""

import logging
from collections import defaultdict
from pathlib import Path

import duckdb
import yaml
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress, SpinnerColumn, TextColumn

from .models import SQLModule, TransformationConfig

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(rich_tracebacks=True, show_time=False)],
)
logger = logging.getLogger(__name__)
console = Console()


class TransformationOrchestrator:
    """Orchestrates SQL transformations across Bronze, Silver, and Gold layers.

    Responsibilities:
        - Discover SQL modules from filesystem and YAML metadata
        - Resolve dependencies via topological sort
        - Execute SQL files in dependency order
        - Handle errors with informative messages
        - Support dry-run mode for preview
        - Validate source files before execution
    """

    def __init__(self, config: TransformationConfig | None = None) -> None:
        """Initialize orchestrator with configuration.

        Args:
            config: Transformation configuration (uses defaults if None)
        """
        self.config = config or TransformationConfig()
        self.modules: dict[str, SQLModule] = {}
        self._discovery_complete = False

    def discover_modules(self) -> dict[str, SQLModule]:
        """Discover SQL modules from filesystem and YAML metadata.

        Scans each layer directory for .sql files and reads module metadata
        from _schema.yaml. Creates SQLModule instances for each discovered file.

        Returns:
            Dictionary mapping qualified module names to SQLModule instances

        Raises:
            FileNotFoundError: If SQL root directory doesn't exist
        """
        if not self.config.sql_root.exists():
            msg = f"SQL root directory not found: {self.config.sql_root}"
            raise FileNotFoundError(msg)

        modules: dict[str, SQLModule] = {}

        for layer in self.config.layers:
            layer_path = self.config.get_layer_path(layer)

            # Skip if layer directory doesn't exist yet
            if not layer_path.exists():
                logger.debug(f"Layer directory not found (skipping): {layer_path}")
                continue

            # Load schema metadata if available
            schema_metadata = self._load_schema_metadata(layer)

            # Discover SQL files in layer directory
            for sql_file in layer_path.glob("*.sql"):
                module_name = sql_file.stem
                qualified_name = f"{layer}/{module_name}"

                # Get metadata from schema.yaml or use defaults
                metadata = schema_metadata.get(module_name, {})

                module = SQLModule(
                    name=module_name,
                    layer=layer,
                    file_path=sql_file,
                    depends_on=metadata.get("depends_on", []),
                    description=metadata.get("description"),
                    enabled=metadata.get("enabled", True),
                    requires_vpn=metadata.get("requires_vpn", False),
                    source_files=metadata.get("source_files", []),
                )

                modules[qualified_name] = module
                logger.debug(f"Discovered module: {qualified_name}")

        self.modules = modules
        self._discovery_complete = True
        logger.info(f"Discovered {len(modules)} SQL modules across {len(self.config.layers)} layers")
        return modules

    def _load_schema_metadata(self, layer: str) -> dict:
        """Load module metadata from _schema.yaml for a layer.

        Args:
            layer: Layer name (bronze, silver, or gold)

        Returns:
            Dictionary mapping module names to their metadata
        """
        schema_path = self.config.get_schema_path(layer)

        if not schema_path.exists():
            logger.debug(f"No schema metadata found: {schema_path}")
            return {}

        try:
            with schema_path.open() as f:
                metadata = yaml.safe_load(f) or {}
            logger.debug(f"Loaded schema metadata for {layer} layer: {len(metadata)} modules")
            return metadata
        except yaml.YAMLError as e:
            logger.warning(f"Failed to parse {schema_path}: {e}")
            return {}

    def execute_layer(
        self,
        layer: str,
        *,
        dry_run: bool = False,
        validate: bool = False,
    ) -> None:
        """Execute all modules in a specific layer.

        Args:
            layer: Layer name (bronze, silver, or gold)
            dry_run: If True, preview modules without executing
            validate: If True, validate source files before execution

        Raises:
            ValueError: If layer is invalid or modules not discovered
            RuntimeError: If validation fails or execution errors occur
        """
        if not self._discovery_complete:
            self.discover_modules()

        if layer not in self.config.layers:
            msg = f"Invalid layer: {layer}. Must be one of {self.config.layers}"
            raise ValueError(msg)

        # Filter modules for this layer
        layer_modules = {
            name: module
            for name, module in self.modules.items()
            if module.layer == layer and module.enabled
        }

        if not layer_modules:
            logger.warning(f"No enabled modules found for {layer} layer")
            return

        # Sort by dependencies
        sorted_modules = self._sort_by_dependencies(layer_modules)

        # Validate sources if requested
        if validate and layer == "bronze":
            self.validate_sources(sorted_modules)

        # Execute or preview modules
        if dry_run:
            self._preview_execution(sorted_modules)
        else:
            self._execute_modules(sorted_modules)

    def execute_all(self, *, dry_run: bool = False, validate: bool = False) -> None:
        """Execute all layers in order (Bronze → Silver → Gold).

        Args:
            dry_run: If True, preview modules without executing
            validate: If True, validate source files before execution
        """
        if not self._discovery_complete:
            self.discover_modules()

        for layer in self.config.layers:
            console.rule(f"[bold blue]{layer.upper()} Layer")
            self.execute_layer(layer, dry_run=dry_run, validate=validate)

    def _sort_by_dependencies(self, modules: dict[str, SQLModule]) -> list[SQLModule]:
        """Sort modules by dependencies using topological sort.

        Args:
            modules: Dictionary of modules to sort

        Returns:
            List of modules in execution order

        Raises:
            RuntimeError: If circular dependencies detected
        """
        # Build dependency graph
        # Only track dependencies between modules in the current set (same layer)
        # Cross-layer dependencies are assumed to be already satisfied
        graph: dict[str, list[str]] = defaultdict(list)
        in_degree: dict[str, int] = defaultdict(int)

        for qualified_name, module in modules.items():
            if qualified_name not in in_degree:
                in_degree[qualified_name] = 0

            for dep in module.get_dependencies():
                # Only add dependency if it's within the same module set
                if dep in modules:
                    graph[dep].append(qualified_name)
                    in_degree[qualified_name] += 1

        # Kahn's algorithm for topological sort
        queue = [name for name, degree in in_degree.items() if degree == 0]
        sorted_names = []

        while queue:
            current = queue.pop(0)
            sorted_names.append(current)

            for neighbor in graph[current]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)

        # Check for circular dependencies
        if len(sorted_names) != len(modules):
            msg = "Circular dependency detected in modules"
            raise RuntimeError(msg)

        # Return modules in sorted order
        return [modules[name] for name in sorted_names if name in modules]

    def validate_sources(self, modules: list[SQLModule]) -> None:
        """Validate that source files exist for Bronze layer modules.

        Args:
            modules: List of modules to validate

        Raises:
            RuntimeError: If required source files are missing
        """
        missing_files = []

        for module in modules:
            for source_file in module.source_files:
                file_path = Path(source_file)
                if not file_path.exists():
                    missing_files.append((module.name, source_file))

        if missing_files:
            console.print("[red]Validation failed: Missing source files[/red]")
            for module_name, file_path in missing_files:
                console.print(f"  - {module_name}: {file_path}")
            msg = f"{len(missing_files)} source file(s) missing"
            raise RuntimeError(msg)

        logger.info(f"Validation passed: All source files present for {len(modules)} modules")

    def _preview_execution(self, modules: list[SQLModule]) -> None:
        """Preview module execution order without executing.

        Args:
            modules: List of modules in execution order
        """
        console.print(f"\n[bold]Execution Plan ({len(modules)} modules):[/bold]\n")

        for i, module in enumerate(modules, 1):
            console.print(f"  {i}. [cyan]{module.get_qualified_name()}[/cyan]")
            if module.description:
                console.print(f"     {module.description}")
            if module.depends_on:
                deps = ", ".join(module.depends_on)
                console.print(f"     [dim]Depends on: {deps}[/dim]")
            if module.requires_vpn:
                console.print("     [yellow]WARNING: Requires VPN connection[/yellow]")

        console.print()

    def _execute_modules(self, modules: list[SQLModule]) -> None:
        """Execute SQL modules in order.

        Args:
            modules: List of modules in execution order

        Raises:
            RuntimeError: If any module execution fails
        """
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            for module in modules:
                task_id = progress.add_task(
                    f"Executing {module.get_qualified_name()}...",
                    total=None,
                )

                try:
                    self._execute_sql_file(module.file_path)
                    progress.update(task_id, completed=True)
                    logger.info(f"OK: {module.get_qualified_name()}")
                except Exception as e:
                    progress.stop()
                    console.print(f"[red]FAILED: {module.get_qualified_name()}[/red]")
                    console.print(f"[red]Error: {e}[/red]")
                    msg = f"Module execution failed: {module.get_qualified_name()}"
                    raise RuntimeError(msg) from e

        console.print(f"\n[green]SUCCESS: Executed {len(modules)} modules[/green]\n")

    def _execute_sql_file(self, sql_file: Path) -> None:
        """Execute a SQL file against the DuckDB database.

        Args:
            sql_file: Path to SQL file to execute

        Raises:
            FileNotFoundError: If SQL file doesn't exist
            duckdb.Error: If SQL execution fails
        """
        if not sql_file.exists():
            msg = f"SQL file not found: {sql_file}"
            raise FileNotFoundError(msg)

        if not self.config.db_path.exists():
            msg = f"Database not found: {self.config.db_path}"
            raise FileNotFoundError(msg)

        sql_content = sql_file.read_text(encoding="utf-8")

        with duckdb.connect(str(self.config.db_path)) as conn:
            # Load required extensions (INSTALL is persistent, LOAD needed per session)
            # Spatial extension does NOT autoload, must be explicitly loaded
            conn.execute("LOAD spatial;")
            # Postgres extension will autoload but load explicitly for consistency
            conn.execute("LOAD postgres;")
            conn.execute(sql_content)
