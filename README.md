## Penalty Box - A redis backed rate limiter service
[![Github License](https://img.shields.io/github/license/gamechanger/penalty-box.svg)](https://github.com/gamechanger/penalty-box/blob/master/LICENSE)

Penalty Box is an independent service which can be used to keep track of requests and inform clients when a request should be rate limited.

### Installation
Penalty Box is a Node.js service. After cloning the repository, you can run it with:
```
npm install
node penalty-box.js
```

### Getting Started
Penalty Box relies on a redis instance and can send metrics to a datadog server.
Penalty Box knows about the following configuration variables (defaults in parentheses):
```
debug: if True, enables additional debug information in logs (false)
log_requests: if True, logs info on each HTTP request to stdout
port: port on which to run the Penalty Box HTTP API (80)
redis_host: host of the underlying Redis instance (localhost)
redis_port: port of the underlying Redis instance (6379)
port: port on which to run the Penalty Box HTTP API (80)
datadog_host: host of the datadog server (localhost)
datadog_port: port to connect to on the datadog host (8135)
```

### Endpoints
#### POST /rate-limit
#### GET /rate-limited

### Example Usage
#### POST /rate-limit
Lets say you are working on a web application and you want to rate limit by user_id. You can post a request like the following to Penalty Box:
```
POST /rate-limit
{
    app_name: "web"
    key: "<user_id>"
    cost: 1
    rate_limit: 60
    period_seconds: 120 (OPTIONAL)
}
```
The first four arguments are the are required by rate-limit. The first two describe a unique name space (using app_name and key), the third provides the cost for the request (cost), and the fourth provides how many requests are allowed per minute (rate_limit).
The final argument (period_seconds) is optional. It gives the amount of time, in seconds, it takes the rate limiter to reset. If this agument is not provided initially, the reset period will default to 60 seconds

Penalty Box will respond with a response as follows:
```
200 Success
{
    limit: 60
    remaining: 59
    is_rate_limted: false
    reset: <epoch_time_in_ms_till_rate_limit_is_reset>
}
```

Some important information on the response body:
```
limit - once set cannot be changed
remaining - tells clients how many requests left they have for the current minute
is_rate_limited - will return false as long as the cost does not exceed the amount of requests remaining
reset - epoch time in milliseconds when your current rate limiting window resets
```

#### GET /rate-limited
Lets say you are working on a web application and you want to rate to check if user_id is rate limited:
```
POST /rate-limited
{
    app_name: "web"
    key: "<user_id>"
}
```
The arguments describe a unique name space (using app_name and key)

Penalty Box will respond with a response as follows:
```
200 Success
{
    is_rate_limted: false
}
```

Some important information on the response body:
```
is_rate_limited - will return true or false depending on if the key is currently rate limited
```


### Edge Cases
#### Cost > Remaining and Remaining != 0
Lets say you are making a request and your previous response from Penalty Box was:
```
200 Success
{
    limit: 60
    remaining: 10
    is_rate_limted: false
    reset: <epoch_time_in_ms_till_rate_limit_is_reset>
}
```

If you make a new requests to Penalty Box:
```
POST /rate-limit
{
    app_name: "web"
    key: "<user_id>"
    cost: 20
    rate_limit: 60
}
```

Your response will be:
```
    limit: 60
    remaining: 10
    is_rate_limted: true
    reset: <epoch_time_in_ms_till_rate_limit_is_reset>
```

It is important to note that `remaining` is still at ten. If your cost was greater than remaining we do not remove any requests from remaining, we simply tell you your request has been rate limited.
