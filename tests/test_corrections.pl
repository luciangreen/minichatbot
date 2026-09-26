:- begin_tests(corrections).

:- use_module('../src/chatbot.pl').


test(revises_prediction_after_correction, [setup(bootstrap)]) :-
    learn([action-create, domain-music], [], [object-melody], _),
    learn([action-create, domain-music, lyrics-yes], [], [object-song], _),
    learn_correction([action-create, domain-music, lyrics-yes], object-melody, object-song, _),
    predict_known_dimensions([action-create, domain-music, lyrics-yes], candidates(Candidates)),
    Candidates = [candidate(object-song, _, _)|_].

test(correction_sentence_updates_prediction, [setup(bootstrap)]) :-
    chat('alice create song', _, _),
    chat('alice create song', _, _),
    chat('alice create song', _, _),
    chat('alice create something', PredictionResponse, _),
    sub_string(PredictionResponse, 0, _, _, "I predict"),
    chat('no alice create melody', 'correction learned', _),
    chat('alice create something', UpdatedResponse, _),
    sub_string(UpdatedResponse, 0, _, _, "I predict object-melody").

test(answer_who_is_from_context, [setup(bootstrap)]) :-
    chat('I am Lucian.', _, _),
    chat('Who is Lucian?', Response, _),
    Response = "i".

:- end_tests(corrections).
