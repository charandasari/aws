#!/bin/bash
# AfterInstall hook
# Runs AFTER the new application files are copied

echo "AfterInstall: Setting file permissions..."
chmod -R 755 /var/www/html/
chown -R apache:apache /var/www/html/

echo "AfterInstall: Done."
