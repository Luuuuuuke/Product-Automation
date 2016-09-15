# Product-Automation
Automated installation & uninstallation is always a good practice to deliver the product to both technical or non-technical customers.

This is a product (called ETS) automated installation implemented in PowerShell scripts.

The installation scripts do the followings:

1. Check the input parameters, validate them.
2. Install DB product.
3. Install DB scripts.
4. Install Server product, Client product, etc.
5. Initialize the workspace.

The uninstallation scripts do the exact opposite way with the product detection on the top.
