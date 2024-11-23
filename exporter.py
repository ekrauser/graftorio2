import os
import time
import json
import logging
from pathlib import Path
import requests  # For sending data to Node-RED

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Configuration
JSON_DIRECTORY = Path("/factorio/script-output")
JSON_FILENAME = "graftorio_stats.json"
NODE_RED_ENDPOINT = os.getenv("NODE_RED_ENDPOINT", "http://localhost:1880/factorio-stats")  # Replace with your Node-RED endpoint
SEND_INTERVAL = int(os.getenv("SEND_INTERVAL", 15))  # Interval in seconds

def read_stats_file(filepath):
    """Read and parse the stats JSON file."""
    filepath = Path(filepath).expanduser().absolute()
    
    if not filepath.exists():
        logging.warning(f"Stats file not found: {filepath}")
        return None
    
    try:
        with open(filepath, 'r') as file:
            return json.load(file)
    except Exception as e:
        logging.error(f"Error reading stats file: {e}")
        return None

def send_to_node_red(data):
    """Send data to Node-RED."""
    try:
        response = requests.post(NODE_RED_ENDPOINT, json=data)
        if response.status_code == 200:
            logging.info("Successfully sent data to Node-RED")
        else:
            logging.error(f"Failed to send data to Node-RED: {response.status_code} - {response.text}")
    except Exception as e:
        logging.error(f"Error sending data to Node-RED: {e}")

def main():
    stats_filepath = JSON_DIRECTORY / JSON_FILENAME
    
    while True:
        # Read stats
        stats = read_stats_file(stats_filepath)
        
        if stats:
            # Send to Node-RED
            send_to_node_red(stats)
        
        # Wait for the next iteration
        time.sleep(SEND_INTERVAL)

if __name__ == "__main__":
    main()
