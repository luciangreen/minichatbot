:- begin_tests(prediction).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/chatbot.pl').


test(predicts_missing_dimension, [setup(bootstrap)]) :-
    learn_observation([action-create, domain-music, object-song, lyrics-yes], _),
    learn_observation([action-make, domain-music, object-song, lyrics-yes], _),
    learn_observation([action-create, domain-music, object-song, instrument-piano], _),
    predict_known_dimensions([action-create, domain-music], candidates(Candidates)),
    Candidates = [candidate(object-song, Score, _)|_],
    Score > 0.

:- end_tests(prediction).
