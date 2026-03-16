#!/bin/bash
# ApplicationStop hook
# Runs to gracefully stop the application before deployment

echo "ApplicationStop: Stopping Apache web server..."
systemctl stop httpd || true

echo "ApplicationStop: Server stopped."
