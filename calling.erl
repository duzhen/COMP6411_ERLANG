-module(calling).
-export([register_caller/3]).

register_caller(Server_Node, From, To) ->
    Server_Node ! {self(), register, From},
    call_friends(Server_Node, From, To).

%%% The client process which runs on each user node
call_friends(Server_Node, From, To) ->
    % io:format("~p client start: ~n", [To]),
    [First | Rest ] = To,
    % timer:sleep(timer:seconds(rand:uniform(10))),
    timer:sleep(rand:uniform(100)),
    Server_Node ! {self(), intro, From, First, "intro"},
    await_result(Server_Node, From),
    case Rest of
        [] ->
            always_await_result(Server_Node, From);
        _ ->
        call_friends(Server_Node, From, Rest)
    end.

%%% wait for a response from the server
await_result(Server_Node,From) ->
    receive
        % {messenger, stop, Why} -> % Stop the client 
        %     io:format("~p~n", [Why]),
        %     exit(normal);
        {intro, Name, Message} ->  % Normal response
            % io:format("~p receive message from: ~p say: ~p~n", [From, Name, Message]),
            Server_Node ! {self(), reply, From, Name, "reply"};
            % await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            % io:format("Message reply: ~p say: ~p~n", [Name, Message])
            % await_result(Server_Node,From)
            pass
    after 1000 ->
            Server_Node ! {self(), timeout, From},
            exit(timeout)
    end.

always_await_result(Server_Node,From) ->
    receive
        {intro, Name, Message} ->  % Normal response
            Server_Node ! {self(), reply, From, Name, "reply"},
            always_await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            always_await_result(Server_Node,From)
    after 1000 ->
            Server_Node ! {self(), timeout, From},
            exit(timeout)
    end.