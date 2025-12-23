#!/usr/bin/env python3
"""
Simple DockSTARTer - A simplified Docker container management tool
Author: Claude AI
License: MIT

A modern, simplified alternative to the original DockSTARTer with:
- Single Python script instead of 199+ bash scripts
- Interactive CLI with beautiful interface
- Simple YAML-based app definitions
- Focus on core functionality
"""

import os
import sys
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

# Check if required packages are available, if not provide helpful message
try:
    from InquirerPy import inquirer
    from InquirerPy.base.control import Choice
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
    from rich import print as rprint
except ImportError:
    print("Required packages not installed. Please run:")
    print("  pip3 install InquirerPy rich PyYAML")
    sys.exit(1)

console = Console()

class SimpleDockSTARTer:
    """Main class for Simple DockSTARTer"""

    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.apps_dir = self.base_dir / "apps"
        self.config_file = self.base_dir / "config.yml"
        self.docker_compose_file = self.base_dir / "docker-compose.yml"
        self.env_file = self.base_dir / ".env"
        self.config = self.load_config()

    def load_config(self) -> Dict:
        """Load or create configuration"""
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                return yaml.safe_load(f) or {}
        return {
            'selected_apps': [],
            'user_id': os.getuid(),
            'group_id': os.getgid(),
            'timezone': 'Europe/Berlin',
            'data_dir': str(self.base_dir / 'data')
        }

    def save_config(self):
        """Save configuration"""
        with open(self.config_file, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False)

    def load_available_apps(self) -> Dict:
        """Load all available app definitions"""
        apps = {}
        if not self.apps_dir.exists():
            return apps

        for app_file in self.apps_dir.glob("*.yml"):
            try:
                with open(app_file, 'r') as f:
                    app_data = yaml.safe_load(f)
                    app_name = app_file.stem
                    apps[app_name] = app_data
            except Exception as e:
                console.print(f"[red]Error loading {app_file}: {e}[/red]")
        return apps

    def select_apps(self):
        """Interactive app selection"""
        apps = self.load_available_apps()

        if not apps:
            console.print("[red]No apps found in apps/ directory![/red]")
            console.print("Please add app definitions first.")
            return

        # Create choices with app descriptions
        choices = [
            Choice(
                value=name,
                name=f"{name} - {data.get('description', 'No description')}"
            )
            for name, data in sorted(apps.items())
        ]

        selected = inquirer.checkbox(
            message="Select apps to install (Space to select, Enter to confirm):",
            choices=choices,
            default=self.config.get('selected_apps', []),
            validate=lambda result: len(result) > 0,
            invalid_message="Please select at least one app"
        ).execute()

        self.config['selected_apps'] = selected
        self.save_config()

        console.print(f"\n[green]✓[/green] Selected {len(selected)} app(s)")

    def configure_settings(self):
        """Configure basic settings"""
        console.print("\n[bold cyan]Configure Settings[/bold cyan]")

        self.config['timezone'] = inquirer.text(
            message="Timezone:",
            default=self.config.get('timezone', 'Europe/Berlin')
        ).execute()

        self.config['data_dir'] = inquirer.text(
            message="Data directory:",
            default=self.config.get('data_dir', str(self.base_dir / 'data'))
        ).execute()

        self.save_config()
        console.print("[green]✓[/green] Settings saved")

    def generate_docker_compose(self):
        """Generate docker-compose.yml from selected apps"""
        if not self.config.get('selected_apps'):
            console.print("[red]No apps selected! Please select apps first.[/red]")
            return

        apps = self.load_available_apps()
        compose = {
            'version': '3.8',
            'services': {}
        }

        # Generate .env file
        env_vars = [
            f"PUID={self.config['user_id']}",
            f"PGID={self.config['group_id']}",
            f"TZ={self.config['timezone']}",
            f"DATA_DIR={self.config['data_dir']}"
        ]

        for app_name in self.config['selected_apps']:
            if app_name not in apps:
                console.print(f"[yellow]Warning: {app_name} definition not found[/yellow]")
                continue

            app = apps[app_name]
            service = {
                'container_name': app_name,
                'image': app['image'],
                'restart': app.get('restart', 'unless-stopped')
            }

            # Add environment variables
            if 'environment' in app:
                service['environment'] = app['environment']

            # Add volumes
            if 'volumes' in app:
                service['volumes'] = [
                    vol.replace('${DATA_DIR}', self.config['data_dir'])
                    for vol in app['volumes']
                ]

            # Add ports
            if 'ports' in app:
                service['ports'] = app['ports']

            # Add networks
            if 'networks' in app:
                service['networks'] = app['networks']

            # Add depends_on
            if 'depends_on' in app:
                service['depends_on'] = app['depends_on']

            # Add custom options
            for key in ['devices', 'privileged', 'labels', 'cap_add']:
                if key in app:
                    service[key] = app[key]

            compose['services'][app_name] = service

            # Add app-specific env vars
            if 'env_vars' in app:
                env_vars.extend(app['env_vars'])

        # Write docker-compose.yml
        with open(self.docker_compose_file, 'w') as f:
            yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

        # Write .env file
        with open(self.env_file, 'w') as f:
            f.write('\n'.join(env_vars) + '\n')

        console.print(f"[green]✓[/green] Generated docker-compose.yml with {len(compose['services'])} service(s)")
        console.print(f"[green]✓[/green] Generated .env file")

    def docker_command(self, command: str):
        """Execute docker compose command"""
        if not self.docker_compose_file.exists():
            console.print("[red]No docker-compose.yml found! Generate it first.[/red]")
            return

        console.print(f"\n[cyan]Running: docker compose {command}[/cyan]\n")

        try:
            result = subprocess.run(
                ['docker', 'compose', *command.split()],
                cwd=self.base_dir,
                check=True
            )
            console.print(f"\n[green]✓[/green] Command completed successfully")
        except subprocess.CalledProcessError as e:
            console.print(f"[red]✗[/red] Command failed with exit code {e.returncode}")
        except FileNotFoundError:
            console.print("[red]Docker not found! Please install Docker first.[/red]")

    def show_status(self):
        """Show current status"""
        table = Table(title="Simple DockSTARTer Status")
        table.add_column("Setting", style="cyan")
        table.add_column("Value", style="green")

        table.add_row("Data Directory", self.config.get('data_dir', 'Not set'))
        table.add_row("Timezone", self.config.get('timezone', 'Not set'))
        table.add_row("Selected Apps", str(len(self.config.get('selected_apps', []))))
        table.add_row("Config File", str(self.config_file))
        table.add_row("Compose File", "✓ Exists" if self.docker_compose_file.exists() else "✗ Not generated")

        console.print(table)

        if self.config.get('selected_apps'):
            console.print("\n[bold]Selected Apps:[/bold]")
            for app in self.config['selected_apps']:
                console.print(f"  • {app}")

    def main_menu(self):
        """Main interactive menu"""
        while True:
            console.print("\n")
            console.print(Panel.fit(
                "[bold cyan]Simple DockSTARTer[/bold cyan]\n"
                "A simplified Docker container management tool",
                border_style="cyan"
            ))

            choices = [
                Choice(value="select", name="📦 Select Apps"),
                Choice(value="configure", name="⚙️  Configure Settings"),
                Choice(value="generate", name="🔨 Generate docker-compose.yml"),
                Choice(value="status", name="📊 Show Status"),
                Choice(value="up", name="🚀 Start Containers (docker compose up -d)"),
                Choice(value="down", name="🛑 Stop Containers (docker compose down)"),
                Choice(value="restart", name="🔄 Restart Containers"),
                Choice(value="pull", name="⬇️  Pull Latest Images"),
                Choice(value="logs", name="📝 View Logs"),
                Choice(value="quit", name="❌ Quit")
            ]

            action = inquirer.select(
                message="What would you like to do?",
                choices=choices
            ).execute()

            if action == "quit":
                console.print("\n[cyan]Thanks for using Simple DockSTARTer![/cyan]")
                break
            elif action == "select":
                self.select_apps()
            elif action == "configure":
                self.configure_settings()
            elif action == "generate":
                self.generate_docker_compose()
            elif action == "status":
                self.show_status()
            elif action == "up":
                self.docker_command("up -d")
            elif action == "down":
                self.docker_command("down")
            elif action == "restart":
                self.docker_command("restart")
            elif action == "pull":
                self.docker_command("pull")
            elif action == "logs":
                self.docker_command("logs -f")

def main():
    """Main entry point"""
    console.print("[bold cyan]Simple DockSTARTer[/bold cyan] - Starting...\n")

    # Check if Docker is available
    try:
        subprocess.run(['docker', '--version'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        console.print("[red]Docker not found! Please install Docker first.[/red]")
        console.print("Visit: https://docs.docker.com/get-docker/")
        sys.exit(1)

    app = SimpleDockSTARTer()

    # If no config exists, show welcome message
    if not app.config_file.exists():
        console.print(Panel.fit(
            "[bold green]Welcome to Simple DockSTARTer![/bold green]\n\n"
            "This is a simplified Docker container management tool.\n"
            "Let's get started by selecting some apps!",
            border_style="green"
        ))

    app.main_menu()

if __name__ == "__main__":
    main()
