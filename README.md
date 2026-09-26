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
