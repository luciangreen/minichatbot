:- module(dimensions,
    [ observation_from_pairs/2,
      observation_pairs/2,
      infer_dimensions/2,
      merge_dimensions/3,
      discover_dimension/3,
      resolve_pronouns/3
    ]).

:- use_module(library(lists)).

observation_from_pairs(Pairs0, observation(Pairs)) :-
    normalize_pairs(Pairs0, Pairs).

observation_pairs(observation(Pairs), Pairs) :-
    !.
observation_pairs(Pairs0, Pairs) :-
    normalize_pairs(Pairs0, Pairs).

infer_dimensions(Text, observation(Pairs)) :-
    text_tokens(Text, Tokens),
    infer_pairs_from_tokens(Text, Tokens, Pairs0),
    normalize_pairs(Pairs0, Pairs).

merge_dimensions(Left0, Right0, observation(Merged)) :-
    observation_pairs(Left0, Left),
    observation_pairs(Right0, Right),
    append(Left, Right, Combined),
    normalize_pairs(Combined, Merged).

resolve_pronouns(Observation0, Entities, observation(Resolved)) :-
    observation_pairs(Observation0, Pairs),
    resolve_pairs(Pairs, Entities, Resolved).

resolve_pairs([], _Entities, []).
resolve_pairs([Key-Value|Rest], Entities, [Key-Resolved|ResolvedRest]) :-
    resolve_value(Value, Key, Entities, Resolved),
    resolve_pairs(Rest, Entities, ResolvedRest).

resolve_value(Value, _Key, Entities, Resolved) :-
    pronoun_slot(Value, Index),
    nth1(Index, Entities, Resolved),
    !.
resolve_value(Value, _Key, _Entities, Value).

pronoun_slot(it, 2).
pronoun_slot(he, 1).
pronoun_slot(him, 1).
pronoun_slot(she, 1).
pronoun_slot(her, 1).
pronoun_slot(they, 1).
pronoun_slot(them, 1).

text_tokens(Text, Tokens) :-
    text_to_string(Text, String),
    string_lower(String, Lower),
    split_string(Lower, " \n\t,.;:!?'\"()[]{}", " \n\t,.;:!?'\"()[]{}", Parts),
    exclude(==(""), Parts, NonEmpty),
    maplist(atom_string, Tokens, NonEmpty).

infer_pairs_from_tokens(Text, Tokens, Pairs) :-
    text_to_string(Text, String),
    (   sub_string(String, _, _, _, "?")
    ->  SpeechAct = question
    ;   SpeechAct = statement
    ),
    findall(token(Index)-Token,
        nth1(Index, Tokens, Token),
        TokenPairs),
    length(Tokens, TokenCount),
    (   parse_question(Tokens, QuestionPairs)
    ->  CorePairs = QuestionPairs
    ;   parse_statement(Tokens, StatementPairs),
        CorePairs = StatementPairs
    ),
    append([speech_act-SpeechAct, token_count-TokenCount|TokenPairs], CorePairs, Pairs).

parse_question([what, did, Subject, Action|_],
    [query-object, actor-Subject, action-Action]).
parse_question([what, is, Subject|_],
    [query-predicate, actor-Subject]).
parse_question([who, Action, Object|_],
    [query-actor, action-Action, object-Object]).
parse_question(_Tokens, _) :-
    fail.

parse_statement([], []).
parse_statement([Action, Object|Rest], [mode-imperative, action-Action, object-Object|Tail]) :-
    common_imperative(Action),
    !,
    qualifier_pairs(Rest, Tail).
parse_statement([Actor, Action, Target, Object|Rest], [actor-Actor, action-Action, target-Target, object-Object|Tail]) :-
    pronoun_or_placeholder(Target),
    !,
    qualifier_pairs(Rest, Tail).
parse_statement([Actor, Action, Object|Rest], [actor-Actor, action-Action, object-Object|Tail]) :-
    !,
    qualifier_pairs(Rest, Tail).
parse_statement([Single], [value-Single]).

common_imperative(create).
common_imperative(make).
common_imperative(find).
common_imperative(build).
common_imperative(remember).
common_imperative(protect).
common_imperative(teach).
common_imperative(request).

pronoun_or_placeholder(Value) :-
    pronoun_slot(Value, _),
    !.
pronoun_or_placeholder(something).
pronoun_or_placeholder(someone).
pronoun_or_placeholder(x).
pronoun_or_placeholder(unknown).

qualifier_pairs([], []).
qualifier_pairs([with, Qualifier|Rest], [with-Qualifier|Tail]) :-
    !,
    qualifier_pairs(Rest, Tail).
qualifier_pairs([and, Qualifier|Rest], [and-Qualifier|Tail]) :-
    !,
    qualifier_pairs(Rest, Tail).
qualifier_pairs([Token|Rest], [detail-Token|Tail]) :-
    qualifier_pairs(Rest, Tail).

normalize_pairs(Pairs0, Pairs) :-
    include(valid_pair, Pairs0, Pairs1),
    sort(Pairs1, Pairs).

valid_pair(Key-Value) :-
    nonvar(Key),
    nonvar(Value).

text_to_string(Text, String) :-
    string(Text),
    !,
    String = Text.
text_to_string(Text, String) :-
    atom(Text),
    !,
    atom_string(Text, String).
text_to_string(Text, String) :-
    with_output_to(string(String), write(Text)).

discover_dimension(Left0, Right0, discovery(DimensionName, LeftValue, RightValue)) :-
    observation_pairs(Left0, Left),
    observation_pairs(Right0, Right),
    member(DimensionName-LeftValue, Left),
    member(DimensionName-RightValue, Right),
    LeftValue \= RightValue,
    !.
discover_dimension(Left0, Right0, discovery(NewDimension, LeftOnly, RightOnly)) :-
    observation_pairs(Left0, Left),
    observation_pairs(Right0, Right),
    subtract(Left, Right, [LeftDimension-LeftOnly|_]),
    subtract(Right, Left, [_RightDimension-RightOnly|_]),
    atomic_list_concat([distinguishes, LeftDimension], '_', NewDimension).
