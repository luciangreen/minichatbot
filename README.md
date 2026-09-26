# minichatbot

A minimal SWI-Prolog web chatbot that starts with a small symbolic kernel built from AND composition, dimensions, memory, learning, prediction, correction, explanation, and persistence.

## Run tests

```sh
swipl -q -f tests/run_tests.pl
```

## Start the web chatbot

```sh
swipl -q -g "use_module('src/chatbot.pl'), start_server(8080), thread_get_message(stop)"
```

## HTTP endpoints

- `GET /`
- `POST /chat`
- `GET /memory`
- `GET /concepts`
- `GET /predictions`
- `POST /forget`
- `POST /reset`

## API

### `POST /chat`

Request body:

```json
{"input":"create something"}
```

Success response contains `response` and `debug`. If `input` is missing or the JSON body is malformed, the endpoint returns HTTP `400` with an `error` field.

### `POST /forget`

Request body must contain either:

```json
{"observation_id":"observation_1"}
```

or

```json
{"concept":"concept_1"}
```

If the payload is malformed or missing both fields, the endpoint returns HTTP `400`. If the requested observation or concept does not exist, it returns HTTP `404`.

### `POST /reset`

Resets learned memory and short-term dialogue state and returns:

```json
{"status":"reset"}
```
