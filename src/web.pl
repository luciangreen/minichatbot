:- module(web,
    [ start_server/1,
      stop_server/0
    ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(dialogue).
:- use_module(memory).
:- use_module(concepts).

:- dynamic server_port/1.

:- http_handler(root(.), home_handler, []).
:- http_handler(root(chat), chat_handler, [method(post)]).
:- http_handler(root(memory), memory_handler, [method(get)]).
:- http_handler(root(concepts), concepts_handler, [method(get)]).
:- http_handler(root(predictions), predictions_handler, [method(get)]).
:- http_handler(root(forget), forget_handler, [method(post)]).
:- http_handler(root(reset), reset_handler, [method(post)]).

start_server(Port) :-
    with_mutex(web_server_lifecycle,
        ( stop_server,
          http_server(http_dispatch, [port(Port)]),
          retractall(server_port(_)),
          assertz(server_port(Port))
        )).

stop_server :-
    with_mutex(web_server_lifecycle,
        (   retract(server_port(Port))
        ->  http_stop_server(Port, [])
        ;   true
        )).

home_handler(_Request) :-
    format('Content-type: text/html; charset=UTF-8~n~n'),
    home_page_html(Html),
    format('~s', [Html]).

chat_handler(Request) :-
    (   read_json_dict_safe(Request, Dict)
    ->  (   _{input:Input} :< Dict
    ->  chat(Input, Response, Debug),
        debug_json(Debug, DebugJson),
        reply_json_dict(_{response:Response, debug:DebugJson})
    ;   reply_json_dict(_{error:"input is required"}, [status(400)])
    )
    ;   reply_json_dict(_{error:"invalid JSON body"}, [status(400)])
    ).

memory_handler(_Request) :-
    memory_snapshot(Snapshot),
    json_term(Snapshot, SnapshotJson),
    reply_json_dict(_{memory:SnapshotJson, counts:Snapshot.counts}).

concepts_handler(_Request) :-
    list_concepts(Concepts),
    json_terms(Concepts, ConceptStrings),
    reply_json_dict(_{concepts:ConceptStrings}).

predictions_handler(_Request) :-
    list_predictions(Predictions),
    json_terms(Predictions, PredictionStrings),
    reply_json_dict(_{predictions:PredictionStrings}).

forget_handler(Request) :-
    (   read_json_dict_safe(Request, Dict)
    ->  (   _{observation_id:RawId} :< Dict
    ->  (   normalize_request_value(RawId, IdInput)
        ->  (   resolve_observation_id(IdInput, Id)
            ->  (   forget_observation(Id)
                ->  reply_json_dict(_{forgotten:Id})
                ;   reply_json_dict(_{error:"observation not found", observation_id:IdInput}, [status(404)])
                )
            ;   reply_json_dict(_{error:"observation not found", observation_id:IdInput}, [status(404)])
            )
        ;   reply_json_dict(_{error:"observation_id must be a string or atom"}, [status(400)])
        )
    ;   _{concept:RawConcept} :< Dict
    ->  (   normalize_request_value(RawConcept, ConceptInput)
        ->  (   resolve_concept_name(ConceptInput, Concept)
            ->  (   forget_concept(Concept)
                ->  reply_json_dict(_{forgotten:Concept})
                ;   reply_json_dict(_{error:"concept not found", concept:ConceptInput}, [status(404)])
                )
            ;   reply_json_dict(_{error:"concept not found", concept:ConceptInput}, [status(404)])
            )
        ;   reply_json_dict(_{error:"concept must be a string or atom"}, [status(400)])
        )
    ;   reply_json_dict(_{error:"expected observation_id or concept"}, [status(400)])
    )
    ;   reply_json_dict(_{error:"invalid JSON body"}, [status(400)])
    ).

reset_handler(_Request) :-
    reset_dialogue,
    reset_memory,
    reply_json_dict(_{status:"reset"}).

debug_json(Debug, Json) :-
    json_terms(Debug.dimensions, DimensionStrings),
    json_term(Debug.prediction, PredictionString),
    json_term(Debug.explanation, ExplanationString),
    Json = _{
        dimensions:DimensionStrings,
        prediction:PredictionString,
        explanation:ExplanationString
    }.

json_terms(Terms, Strings) :-
    maplist(json_term, Terms, Strings).

json_term(Term, String) :-
    term_string(Term, String).

normalize_request_value(Value, Value) :-
    string(Value),
    !.
normalize_request_value(Value, Value) :-
    atom(Value).

resolve_observation_id(Value, Id) :-
    list_observations(Observations),
    member(observation(Id, _, _), Observations),
    identifier_matches(Value, Id).

resolve_concept_name(Value, Name) :-
    list_concepts(Concepts),
    member(concept(Name, _, _, _), Concepts),
    identifier_matches(Value, Name).

identifier_matches(Value, Id) :-
    atom(Value),
    Value == Id.
identifier_matches(Value, Id) :-
    string(Value),
    atom_string(Id, Value).

read_json_dict_safe(Request, Dict) :-
    catch(http_read_json_dict(Request, Dict), Error, (json_read_error(Error), fail)).

json_read_error(error(syntax_error(_), _)).
json_read_error(error(type_error(json_term, _), _)).
json_read_error(error(domain_error(json, _), _)).

home_page_html("<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>minichatbot</title>
  <style>
    :root {
      color-scheme: light;
      font-family: Arial, sans-serif;
      --bg: #f4f7fb;
      --panel: #ffffff;
      --accent: #2563eb;
      --accent-dark: #1d4ed8;
      --text: #0f172a;
      --muted: #475569;
      --border: #dbe3f0;
      --assistant: #e8f0ff;
      --user: #dcfce7;
      --error: #fee2e2;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      background: linear-gradient(180deg, #eaf1ff 0%, var(--bg) 100%);
      color: var(--text);
    }
    main {
      max-width: 1080px;
      margin: 0 auto;
      padding: 32px 20px;
    }
    .hero {
      margin-bottom: 20px;
    }
    .hero h1 {
      margin: 0 0 8px;
      font-size: 2.2rem;
    }
    .hero p {
      margin: 0;
      color: var(--muted);
      max-width: 720px;
      line-height: 1.5;
    }
    .layout {
      display: grid;
      grid-template-columns: minmax(0, 2fr) minmax(280px, 1fr);
      gap: 20px;
      align-items: start;
    }
    .card {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 18px;
      box-shadow: 0 16px 40px rgba(15, 23, 42, 0.08);
    }
    .chat-shell {
      padding: 18px;
    }
    .toolbar {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: center;
      margin-bottom: 14px;
    }
    .toolbar h2,
    .sidebar h2 {
      margin: 0;
      font-size: 1.05rem;
    }
    .toolbar p,
    .sidebar p {
      margin: 4px 0 0;
      color: var(--muted);
      font-size: 0.92rem;
    }
    #transcript {
      min-height: 420px;
      max-height: 68vh;
      overflow-y: auto;
      padding: 8px 2px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .message {
      max-width: 85%;
      padding: 12px 14px;
      border-radius: 16px;
      line-height: 1.5;
      white-space: pre-wrap;
      word-break: break-word;
    }
    .message.user {
      align-self: flex-end;
      background: var(--user);
    }
    .message.assistant {
      align-self: flex-start;
      background: var(--assistant);
    }
    .message.system {
      align-self: center;
      background: #eef2ff;
      color: var(--muted);
      font-size: 0.95rem;
    }
    .message.error {
      align-self: flex-start;
      background: var(--error);
    }
    .message strong {
      display: block;
      margin-bottom: 4px;
      font-size: 0.84rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    form {
      display: grid;
      gap: 12px;
      margin-top: 14px;
    }
    textarea {
      width: 100%;
      min-height: 108px;
      resize: vertical;
      border-radius: 14px;
      border: 1px solid var(--border);
      padding: 14px;
      font: inherit;
      color: inherit;
      background: #fff;
    }
    textarea:focus,
    button:focus {
      outline: 2px solid rgba(37, 99, 235, 0.22);
      outline-offset: 2px;
    }
    .actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }
    button {
      border: none;
      border-radius: 999px;
      padding: 10px 16px;
      font: inherit;
      cursor: pointer;
    }
    #send-button {
      background: var(--accent);
      color: #fff;
    }
    #send-button:hover {
      background: var(--accent-dark);
    }
    #reset-button {
      background: #e2e8f0;
      color: var(--text);
    }
    button:disabled {
      opacity: 0.6;
      cursor: wait;
    }
    #status {
      color: var(--muted);
      font-size: 0.92rem;
      min-height: 1.2em;
    }
    .sidebar {
      padding: 18px;
      display: grid;
      gap: 16px;
    }
    .metric-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
    }
    .metric {
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px;
      background: #f8fbff;
    }
    .metric strong {
      display: block;
      font-size: 1.3rem;
      margin-bottom: 4px;
    }
    .panel {
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px;
      background: #f8fbff;
    }
    .panel h3 {
      margin: 0 0 8px;
      font-size: 0.96rem;
    }
    ul {
      margin: 0;
      padding-left: 18px;
    }
    pre {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      font: 0.88rem/1.45 monospace;
    }
    @media (max-width: 900px) {
      .layout {
        grid-template-columns: 1fr;
      }
      #transcript {
        max-height: none;
      }
      .message {
        max-width: 100%;
      }
    }
  </style>
</head>
<body>
  <main>
    <section class=\"hero\">
      <h1>minichatbot</h1>
      <p>Have a conversation with the symbolic chatbot, see its responses immediately, and inspect what it remembers as you chat.</p>
    </section>
    <section class=\"layout\">
      <div class=\"card chat-shell\">
        <div class=\"toolbar\">
          <div>
            <h2>Conversation</h2>
            <p>Ask a question, teach the bot something new, or try a correction after a prediction.</p>
          </div>
        </div>
        <div id=\"transcript\" aria-live=\"polite\" aria-label=\"Conversation transcript\"></div>
        <form id=\"chat-form\">
          <label for=\"chat-input\">Message</label>
          <textarea id=\"chat-input\" name=\"input\" placeholder=\"Try: create something\" required></textarea>
          <div class=\"actions\">
            <button id=\"send-button\" type=\"submit\">Send message</button>
            <button id=\"reset-button\" type=\"button\">Reset memory</button>
            <span id=\"status\"></span>
          </div>
        </form>
      </div>
      <aside class=\"card sidebar\">
        <div>
          <h2>Live state</h2>
          <p>These panels update as the conversation changes.</p>
        </div>
        <div class=\"metric-grid\">
          <div class=\"metric\"><strong id=\"observation-count\">0</strong><span>Observations</span></div>
          <div class=\"metric\"><strong id=\"prediction-count\">0</strong><span>Predictions</span></div>
          <div class=\"metric\"><strong id=\"concept-count\">0</strong><span>Concepts</span></div>
          <div class=\"metric\"><strong id=\"correction-count\">0</strong><span>Corrections</span></div>
        </div>
        <div class=\"panel\">
          <h3>Latest debug output</h3>
          <pre id=\"debug-output\">Send a message to inspect model details.</pre>
        </div>
        <div class=\"panel\">
          <h3>Known concepts</h3>
          <ul id=\"concept-list\"><li>None yet.</li></ul>
        </div>
        <div class=\"panel\">
          <h3>Recent predictions</h3>
          <ul id=\"prediction-list\"><li>None yet.</li></ul>
        </div>
      </aside>
    </section>
  </main>
  <script>
    const transcript = document.getElementById('transcript');
    const form = document.getElementById('chat-form');
    const input = document.getElementById('chat-input');
    const sendButton = document.getElementById('send-button');
    const resetButton = document.getElementById('reset-button');
    const statusNode = document.getElementById('status');
    const debugOutput = document.getElementById('debug-output');
    const conceptList = document.getElementById('concept-list');
    const predictionList = document.getElementById('prediction-list');
    const observationCount = document.getElementById('observation-count');
    const predictionCount = document.getElementById('prediction-count');
    const conceptCount = document.getElementById('concept-count');
    const correctionCount = document.getElementById('correction-count');

    function setBusy(isBusy, label) {
      sendButton.disabled = isBusy;
      resetButton.disabled = isBusy;
      statusNode.textContent = label || '';
    }

    function addMessage(role, title, text) {
      const article = document.createElement('article');
      article.className = `message ${role}`;

      const heading = document.createElement('strong');
      heading.textContent = title;

      const body = document.createElement('div');
      body.textContent = text;

      article.appendChild(heading);
      article.appendChild(body);
      transcript.appendChild(article);
      transcript.scrollTop = transcript.scrollHeight;
    }

    function replaceList(node, items, fallback) {
      node.innerHTML = '';
      if (!items || items.length === 0) {
        const item = document.createElement('li');
        item.textContent = fallback;
        node.appendChild(item);
        return;
      }

      items.forEach((entry) => {
        const item = document.createElement('li');
        item.textContent = entry;
        node.appendChild(item);
      });
    }

    async function refreshSidebar() {
      try {
        const [memoryResponse, conceptsResponse, predictionsResponse] = await Promise.all([
          fetch('/memory'),
          fetch('/concepts'),
          fetch('/predictions')
        ]);

        const memoryData = await memoryResponse.json();
        const conceptsData = await conceptsResponse.json();
        const predictionsData = await predictionsResponse.json();

        const counts = memoryData.counts || {};
        observationCount.textContent = counts.observations || 0;
        predictionCount.textContent = counts.predictions || 0;
        conceptCount.textContent = counts.concepts || 0;
        correctionCount.textContent = counts.corrections || 0;

        replaceList(conceptList, conceptsData.concepts, 'None yet.');
        replaceList(predictionList, predictionsData.predictions, 'None yet.');
      } catch (_) {
        statusNode.textContent = 'Unable to refresh sidebar right now.';
      }
    }

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const message = input.value.trim();

      if (!message) {
        statusNode.textContent = 'Enter a message first.';
        return;
      }

      addMessage('user', 'You', message);
      input.value = '';
      setBusy(true, 'Waiting for minichatbot...');

      try {
        const response = await fetch('/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ input: message })
        });
        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || 'Request failed.');
        }

        addMessage('assistant', 'Bot', data.response);
        debugOutput.textContent = JSON.stringify(data.debug, null, 2);
        statusNode.textContent = 'Response received.';
        await refreshSidebar();
      } catch (error) {
        addMessage('error', 'Error', error.message);
        statusNode.textContent = 'The message could not be processed.';
      } finally {
        setBusy(false, statusNode.textContent);
        input.focus();
      }
    });

    resetButton.addEventListener('click', async () => {
      setBusy(true, 'Resetting memory...');

      try {
        const response = await fetch('/reset', { method: 'POST' });
        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || 'Reset failed.');
        }

        transcript.innerHTML = '';
        debugOutput.textContent = 'Send a message to inspect model details.';
        addMessage('system', 'System', 'Memory and dialogue state were reset.');
        statusNode.textContent = 'Memory reset.';
        await refreshSidebar();
      } catch (error) {
        addMessage('error', 'Error', error.message);
        statusNode.textContent = 'Unable to reset memory.';
      } finally {
        setBusy(false, statusNode.textContent);
        input.focus();
      }
    });

    addMessage('assistant', 'Bot', 'Hello! Start a conversation by teaching me something or asking a question.');
    refreshSidebar();
    input.focus();
  </script>
</body>
</html>
").
