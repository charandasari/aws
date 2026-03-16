#!/bin/bash
# ApplicationStart hook
# Runs to start the application after deployment

echo "ApplicationStart: Starting Apache web server..."
systemctl start httpd
systemctl enable httpd

echo "ApplicationStart: Server started."
