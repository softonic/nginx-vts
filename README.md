# Description

This nginx image exports metrics from VTS module to port 8080 with url /status.
It will output the logs in a JSON format to stdout.

# Usage

You need to define the next environment variables:

* APPLICATION: application name to be used in the logs
