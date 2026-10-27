# minichatbot

minichatbot is a small symbolic chatbot written in SWI-Prolog. It learns facts and associations from a conversation, predicts missing dimensions from prior examples, accepts corrections, and exposes its live state through a browser UI and JSON API.

## Requirements

- SWI-Prolog with its HTTP libraries (`http/thread_httpd`, `http/http_json`, and `http/http_open`).
- No third-party Prolog packages are required.

## Run the tests

From the repository root, run the complete PlUnit suite:

```sh
swipl -q -f tests/run_tests.pl
```

The runner loads these suites:

| Test file | Coverage |
| --- | --- |
| `tests/test_and.pl` | AND composition and normalization |
| `tests/test_dimensions.pl` | Text-to-dimension parsing and dimension differences |
| `tests/test_learning.pl` | Observation and association learning |
| `tests/test_prediction.pl` | Missing-dimension predictions |
| `tests/test_generalisation.pl` | Generalisation and repeated-observation concept compression |
| `tests/test_memory.pl` | Save/load round-trip and ID counters |
| `tests/test_corrections.pl` | Corrected predictions and contextual answers |
| `tests/test_bootstrap.pl` | Empty startup state, dialogue, explanations, UI, and existing HTTP behavior |
| `tests/test_web_api.pl` | Successful chat, concept listing, forgetting observations/concepts, and reset |

To run only the HTTP API tests:

```sh
swipl -q -g "load_files('tests/test_web_api.pl'), run_tests(web_api), halt"
```

## Start the chatbot

```sh
swipl -q -g "use_module('src/chatbot.pl'), start_server(8080), thread_get_message(stop)"
```

Open [http://localhost:8080](http://localhost:8080) for the browser chat. The page shows the conversation, live counts for observations/associations/predictions/concepts/corrections, known concepts, recent predictions, and the latest `/chat` debug output. Use **Reset memory** to clear learned and short-term dialogue state. Stop the foreground server with Ctrl+C.

Each server process starts with in-memory state. Persistence is available through the Prolog API, but the web server does not save or load memory automatically.

## Features

- **Symbolic dimensions:** Simple English statements are mapped to dimensions such as `actor`, `action`, `object`, `target`, and qualifiers. Common action forms (for example, `creates`/`created` and `teaches`/`taught`) are normalized.
- **Learning and associations:** `learn/4` stores an interaction and output associations. Chat statements are stored as observations.
- **Prediction and explanation:** Missing or placeholder values such as “something” are predicted from matching observations and weighted associations. Explanations include supporting observations, associations, and relevant corrections.
- **Corrections:** After a prediction, a message beginning with `no` and containing the corrected value teaches the chatbot to prefer the correction.
- **Dialogue context:** Short-term context supports simple questions and pronoun resolution, for example `robot has father`, `he taught it geometry`, and `what did he taught?`.
- **Generalisation and concepts:** Repeated identical observations can be compressed into concepts after three observations. Concepts can also be registered and recursively expanded through the Prolog API.
- **Memory management:** Memory snapshots expose observations, associations, concepts, predictions, corrections, context, and counts. Observations and concepts can be forgotten through the API.
- **Persistence:** `save_memory/1` writes memory terms to a file and `load_memory/1` validates and restores them. Dialogue transient state is not persisted.
- **Web UI and JSON API:** The built-in HTTP server exposes chat, memory, concepts, predictions, forgetting, and reset operations.

The parser intentionally handles a small set of sentence patterns; this is a symbolic prototype, not a general-purpose natural-language processor.

## Conversation example

```text
You: alice create song
Bot: learned

You: alice create something
Bot: I predict object-song (3.75)

You: no alice create melody
Bot: correction learned

You: alice create something
Bot: I predict object-melody (5.33)
```

The exact score varies with learned examples. Start a fresh conversation or call `/reset` to clear state.

## JSON API

All routes use the same in-process memory as the browser UI.

### `POST /chat`

Request:

```sh
curl -i -H 'Content-Type: application/json' \
  -d '{"input":"alice create song"}' \
  http://localhost:8080/chat
```

The success response contains `response` and `debug`. Debug includes dimensions, prediction, explanation, rejected value, and corrected value; optional fields are returned as `"none"` and missing dimensions as an empty list. Malformed JSON or a missing `input` returns HTTP `400` with an `error` field.

### `GET /memory`

Returns a human-readable `memory` string and a structured `snapshot`. Snapshot term entries are serialized as strings; it also contains concept/prediction labels and counts for observations, associations, concepts, predictions, and corrections.

```sh
curl http://localhost:8080/memory
```

### `GET /concepts` and `GET /predictions`

Return lists of serialized concept and prediction terms:

```sh
curl http://localhost:8080/concepts
curl http://localhost:8080/predictions
```

### `POST /forget`

Forget one observation or concept by ID/name:

```sh
curl -i -H 'Content-Type: application/json' \
  -d '{"observation_id":"observation_1"}' \
  http://localhost:8080/forget

curl -i -H 'Content-Type: application/json' \
  -d '{"concept":"concept_1"}' \
  http://localhost:8080/forget
```

Success returns `{"forgotten":"<id-or-name>"}`. Invalid JSON, a missing identifier, or a value of the wrong type returns HTTP `400`; an unknown observation or concept returns HTTP `404`.

### `POST /reset`

Clears learned memory and short-term dialogue state:

```sh
curl -i -X POST http://localhost:8080/reset
```

Returns `{"status":"reset"}`.

## Prolog API

Load the chatbot from the repository root:

```prolog
?- use_module('src/chatbot.pl').
?- bootstrap.
?- chat("robot finds father", Response, Debug).
?- learn([action-create, domain-music], [], [object-song], Learned).
?- predict_known_dimensions([action-create, domain-music], Candidates).
?- explain_prediction([action-create, domain-music], object-song, Explanation).
?- save_memory('memory.pl').
?- load_memory('memory.pl').
?- use_module('src/concepts.pl').
?- register_concept(my_concept, and([actor-robot, action-finds]), [], manual).
?- expand_concept(concept(my_concept), Expanded).
```

`bootstrap/0` resets both memory and dialogue state. Other exported predicates include `learn_observation/2`, `learn_correction/4`, `start_server/1`, `stop_server/0`, `reset_memory/0`, `reset_dialogue/0`, and `kernel_measurement/1`.

## Implementation status

The repository currently has no open issues, unmerged feature PRs, or explicit TODO/FIXME backlog. The features listed above are implemented; there is no separately tracked set of remaining features. Current limitations and possible future work—not committed roadmap items—include broader language parsing, automatic persistence, multiple isolated users/sessions, and browser controls for forgetting individual items (the forget operation is currently available through the JSON API).
