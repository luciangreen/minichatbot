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

# Example Conversation

```
Here’s the same interaction rewritten as a natural web-chat transcript, while preserving what MiniChatbot is learning internally.

MiniChatbot

System: Memory has been reset. I’m starting with no learned domain knowledge.

⸻

You: Alice creates songs.

MiniChatbot: Okay. I’ve learned that Alice creates songs.

You: Alice creates songs.

MiniChatbot: I’ve seen that again. I’m strengthening the connection between Alice + creates + songs.

You: Alice creates songs.

MiniChatbot: Learned. This pattern is now strong enough for me to form a reusable concept about Alice creating songs.

⸻

You: Alice creates something.

MiniChatbot: I predict that she creates songs.

You: Why?

MiniChatbot: Because I’ve repeatedly learned the pattern Alice + creates + song.
The missing part of your sentence is the object, and song is currently my strongest match.

⸻

You: No, Alice creates melodies.

MiniChatbot: Thanks. I’ve learned the correction.

I now have evidence that my prediction song was wrong in this context and that melody is the corrected answer.

⸻

You: Alice creates something.

MiniChatbot: I predict melody.

You: Why did you change your answer?

MiniChatbot: You corrected my previous prediction. I used that correction to update what I’ve learned about Alice + creates + ?.

⸻

You: Alice creates a robot.

MiniChatbot: Learned.

You: What did Alice create?

MiniChatbot: A robot.

You: How do you know?

MiniChatbot: It’s in our recent conversation. You just told me that Alice created a robot.

⸻

You: Bob protects Alice.

MiniChatbot: Learned.

You: He protects her.

MiniChatbot: Understood. I’ve learned another observation about Bob protecting Alice.

You: Who does “he” mean?

MiniChatbot: Bob, based on the recent conversation.

You: And “her”?

MiniChatbot: Alice.

⸻

Inspect what you’ve learned

You: Show me your memory.

MiniChatbot:

I currently remember observations involving:

* Alice creating songs
* Alice creating melodies
* Alice creating a robot
* Bob protecting Alice

I also remember your correction from song to melody, along with concepts and predictions formed from these experiences.

⸻

You: Show me your concepts.

MiniChatbot: Here are the reusable concepts I’ve formed from repeated patterns and learned relationships.

⸻

You: Show me your predictions.

MiniChatbot: Here are the predictions I’ve made, together with the evidence that led to them and any subsequent corrections.

⸻

You: Forget the observation that Alice created the robot.

MiniChatbot: Forgotten.

You: What did Alice create?

MiniChatbot: I no longer have that particular observation available as recent learned evidence.

⸻

You: Forget the concept about Alice creating songs.

MiniChatbot: Forgotten.

⸻

What is happening underneath?

The conversation can be thought of as:

Experience

Alice + creates + song

↓

Repetition

Alice + creates + song
Alice + creates + song
Alice + creates + song

↓

Learned pattern

Alice AND creates AND song

↓

Incomplete thought

Alice AND creates AND ?

↓

Prediction

song

↓

Human correction

not song → melody

↓

Learning

Alice AND creates AND melody

↓

New prediction

melody

The chatbot therefore does not need to begin with a rule saying:

“When Alice creates something, the answer is song.”

It learns relationships from interaction, predicts missing dimensions, accepts corrections, remembers conversational context, and can use what it has learned in later interactions.

This version could also serve almost directly as the demo conversation displayed on MiniChatbot’s home page, with the underlying AND/dimension reasoning hidden behind an expandable “Why?” or “Show reasoning” control.
```
