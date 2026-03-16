#!/bin/bash
# BeforeInstall hook
# Runs BEFORE the new application files are copied to the destination

echo "BeforeInstall: Stopping existing server if running..."
systemctl stop httpd || true

echo "BeforeInstall: Cleaning up old files..."
rm -rf /var/www/html/*
