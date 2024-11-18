import os
import json
import time
from datetime import datetime
from pathlib import Path
import subprocess


class FactorioPlayerMonitor:
    def __init__(self, log_file, state_file):
        self.log_file = log_file
        self.state_file = state_file
        self.current_players = set()
        self.load_state()

    def load_state(self):
        """Load the previously saved state if it exists."""
        if os.path.exists(self.state_file):
            try:
                with open(self.state_file, "r") as f:
                    data = json.load(f)
                    self.current_players = set(data["players"])
            except Exception as e:
                print(f"Error loading state: {e}")
                self.current_players = set()

    def save_state(self):
        """Save the current state to a file."""
        try:
            with open(self.state_file, "w") as f:
                json.dump(
                    {
                        "players": list(self.current_players),
                        "last_updated": datetime.now().isoformat(),
                    },
                    f,
                    indent=2,
                )
        except Exception as e:
            print(f"Error saving state: {e}")

    def update_players(self, line):
        """Update the player list based on log entries."""
        if "[JOIN]" in line:
            player = line.split("[JOIN]")[1].split("joined the game")[0].strip()
            self.current_players.add(player)
            self.save_state()
            print(f"Player joined: {player}")
            print(f"Current players: {', '.join(sorted(self.current_players))}")

        elif "[LEAVE]" in line:
            player = line.split("[LEAVE]")[1].split("left the game")[0].strip()
            self.current_players.discard(player)
            self.save_state()
            print(f"Player left: {player}")
            print(f"Current players: {', '.join(sorted(self.current_players))}")

    def monitor_log(self):
        """Monitor the log file for player joins and leaves."""
        # Get initial file position
        if os.path.exists(self.log_file):
            with open(self.log_file, "r") as f:
                f.seek(0, 2)  # Seek to end
                pos = f.tell()
        else:
            pos = 0

        while True:
            try:
                if os.path.exists(self.log_file):
                    with open(self.log_file, "r") as f:
                        f.seek(pos)
                        for line in f:
                            self.update_players(line)
                        pos = f.tell()
                else:
                    pos = 0

                time.sleep(1)  # Check every second
            except Exception as e:
                print(f"Error monitoring log: {e}")
                time.sleep(5)  # Wait longer on error

    def get_current_players(self):
        """Return the list of current players."""
        return sorted(list(self.current_players))


if __name__ == "__main__":
    LOG_FILE = "/var/log/factorio/factorio.log"
    STATE_FILE = "/var/log/factorio/player_state.json"

    monitor = FactorioPlayerMonitor(LOG_FILE, STATE_FILE)
    monitor.monitor_log()
