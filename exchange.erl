-module(exchange).
-export([start_master/0]).

%%% Start the master
start_master() ->
    {ok, Calls} = file:consult("calls.txt"),
    io:format("~n** Calls to be made **~n"),
    lists:foreach(fun start_calls/1, Calls),
    master([]).
    % TEST
    % register(john_PID, spawn(project, client, [self(), john, [jill,joe, bob]])),
    % register(jill_PID, spawn(project, client, [self(), jill, [bob, joe, bob]])),
    % register(sue_PID, spawn(project, client, [self(), sue, [jill,jill,jill,bob,jill]])),
    % register(bob_PID, spawn(project, client, [self(), bob, [john]])),
    % register(joe_PID, spawn(project, client, [self(), joe, [sue]])),
    % server([{john_PID, john}, {jill_PID, jill}, {sue_PID, sue}, {bob_PID, bob}, {joe_PID, joe}]).

 start_calls({Caller, Friends}) -> 
    spawn(calling, register_caller, [self(), Caller, Friends]),
    % register(Caller, spawn(project, client, [self(), Caller, Friends])),
    io:format("~p: ~p~n",[Caller, Friends]).

master(User_List) ->
    % io:format("User_List:~p~n",[User_List]),
    receive
        {PID, register, Name} ->
            case lists:keymember(Name, 2, User_List) of
                true ->
                    master(User_List);
                false ->
                    master([{PID, Name} | User_List] )
            end;
        {PID, timeout, Name} ->
            io:format("~nProcess ~p has received no calls for 1 second, ending...~n", [Name]),
            master(User_List);
        {PID, intro, From, To, Message} ->
            server_transfer(intro, PID, From, To, Message, User_List),
            {MegaSeconds, Seconds, MicroSeconds} = erlang:now(),
            io:format("~p received intro message from ~p [~p]~n", [To, From, MicroSeconds]),
            master(User_List);
        {PID, reply, From, To, Message} ->
            server_transfer(reply, PID, From, To, Message, User_List),
            {MegaSeconds, Seconds, MicroSeconds} = erlang:now(),
            io:format("~p received reply message from ~p [~p]~n", [To, From, MicroSeconds]),
            master(User_List)
    after 1500 ->
            io:format("~nMaster has received no replies for 1.5 seconds, ending...~n", [])
            % exit(timeout)
    end.

%%% Master transfers a message between user
server_transfer(Type, P, From, To, Message, User_List) ->
    case lists:keysearch(From, 2, User_List) of
        false ->
            P ! {messenger, stop, you_are_not_logged_on};
        {value, {PID, Name}} ->
            server_transfer(Type, PID, Name, To, Message, User_List, User_List)
    end.

%%% If the user exists, send the message
server_transfer(Type, From, Name, To, Message, User_List, User_List) ->
    %% Find the receiver and send the message
    case lists:keysearch(To, 2, User_List) of
        false ->
            From ! {messenger, receiver_not_found};
        {value, {ToPid, To}} ->
            % io:format("~p~n~p~n", [ToPid, Message]),
            ToPid ! {Type, Name, Message}
    end.