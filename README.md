# Description

This nginx image exports metrics from VTS module to port 8080 with url /status.
It will output the logs in a JSON format to stdout.

# Usage

You need to define the next environment variables:

* APPLICATION: application name to be used in the logs

You need to set in your server configuration the request_start_time variable. For example:
```
server {
    listen  80;

    set $request_start_time '$time_iso8601';
    server_name _;
}
```
