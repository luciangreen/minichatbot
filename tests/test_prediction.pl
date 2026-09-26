:- begin_tests(prediction).

:- use_module('../src/chatbot.pl').


test(predicts_missing_dimension, [setup(bootstrap)]) :-
    learn_observation([action-create, domain-music, object-song, lyrics-yes], _),
    learn_observation([action-make, domain-music, object-song, lyrics-yes], _),
    learn_observation([action-create, domain-music, object-song, instrument-piano], _),
    predict_known_dimensions([action-create, domain-music], candidates(Candidates)),
    Candidates = [candidate(object-song, Score, _)|_],
    Score > 0.

test(predicts_from_placeholder_sentence, [setup(bootstrap)]) :-
    chat('Alice creates songs.', _, _),
    chat('Alice creates songs.', _, _),
    chat('Alice creates songs.', _, _),
    chat('alice create something', Response, _),
    sub_string(Response, 0, _, _, "I predict").

:- end_tests(prediction).
