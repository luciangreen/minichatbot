:- begin_tests(corrections).

:- use_module('../src/chatbot.pl').


test(revises_prediction_after_correction, [setup(bootstrap)]) :-
    learn([action-create, domain-music], [], [object-melody], _),
    learn([action-create, domain-music, lyrics-yes], [], [object-song], _),
    learn_correction([action-create, domain-music, lyrics-yes], object-melody, object-song, _),
    predict_known_dimensions([action-create, domain-music, lyrics-yes], candidates(Candidates)),
    Candidates = [candidate(object-song, _, _)|_].

:- end_tests(corrections).
