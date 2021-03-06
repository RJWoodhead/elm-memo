-- The Memo Metaphor - trebor@animeigo.com


port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Boys
import Girls
import Parents


-- Model does not have any "global" state, it just wraps the
-- state of the modules. It also contains a list of the Msgs
-- triggered from the last update triggered by a Cmd Msg, so
-- you can debug the message passing.


type alias MemoTrace =
    { msg : Msg
    , level : Int
    }


type alias Model =
    { boys : Boys.Model
    , girls : Girls.Model
    , parents : Parents.Model
    , main : MainModel
    , msgs : List MemoTrace
    }



-- The MainModel would contain state for the Main module.
-- In this case, we don't have any.


type alias MainModel =
    {}


mainModelInit : ( MainModel, Cmd Msg )
mainModelInit =
    ( {}, Cmd.none )



-- Initialization boilerplate.


init : ( Model, Cmd Msg )
init =
    let
        ( boysInit, boysCmd ) =
            Boys.init

        ( girlsInit, girlsCmd ) =
            Girls.init

        ( parentsInit, parentsCmd ) =
            Parents.init

        ( mainInit, mainCmd ) =
            mainModelInit

        initModel =
            { boys = boysInit
            , girls = girlsInit
            , parents = parentsInit
            , main = mainInit
            , msgs = []
            }

        cmds =
            Cmd.batch
                [ mainCmd
                , Cmd.map BoysMsg boysCmd
                , Cmd.map GirlsMsg girlsCmd
                , Cmd.map ParentsMsg parentsCmd
                ]
    in
        ( initModel, cmds )



-- Msg and Memo just wrap the module Msgs and Memos.


type Msg
    = BoysMsg Boys.Msg
    | GirlsMsg Girls.Msg
    | ParentsMsg Parents.Msg


type Memo
    = FromBoys Boys.Memo
    | FromGirls Girls.Memo
    | FromParents Parents.Memo



-- If the memos result in too great a nesting depth, then we probably have
-- an inifinite recursion going on. So we set a limit on how deep we'll
-- go before giving up


memoBlizzardLimit : Int
memoBlizzardLimit =
    10



-- Update the state. We use a wrapper to reset the msgs trace once per
-- Cmd Msg, which lets us check for memo blizzards.


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        newModel =
            { model | msgs = [] }

        ( outputModel, outputMsg, level ) =
            updateWithMemos msg newModel 0
    in
        ( outputModel, outputMsg )



-- The actual update function


updateWithMemos : Msg -> Model -> Int -> ( Model, Cmd Msg, Int )
updateWithMemos msg model level =
    let
        -- Actual update is done in the let block; result is a tuple of the new model,
        -- Cmd Msgs, and any Memos that need to be routed. Main.elm doesn't actually
        -- do any state computation, it lets the modules handle that. So a module's
        -- contribution to the state is only changed in that module!
        ( newModel, cmds, memos ) =
            case msg of
                -- The update handlers for each module are almost-identical
                -- boilerplate, since all the logic is implemented in the
                -- modules.
                BoysMsg msg ->
                    let
                        ( newModel, newCmds, newMemos ) =
                            Boys.update msg model.boys
                    in
                        ( { model | boys = newModel }
                        , Cmd.map BoysMsg newCmds
                        , List.map FromBoys newMemos
                        )

                GirlsMsg msg ->
                    let
                        ( newModel, newCmds, newMemos ) =
                            Girls.update msg model.girls
                    in
                        ( { model | girls = newModel }
                        , Cmd.map GirlsMsg newCmds
                        , List.map FromGirls newMemos
                        )

                ParentsMsg msg ->
                    let
                        ( newModel, newCmds, newMemos ) =
                            Parents.update msg model.parents
                    in
                        ( { model | parents = newModel }
                        , Cmd.map ParentsMsg newCmds
                        , List.map FromParents newMemos
                        )
    in
        let
            -- Route the memos, generating Msgs.
            msgs =
                List.concatMap (routeMemos model) memos

            -- Deliver the messages (will call updateWithMemos recursively)
            finalModel =
                List.foldl deliverMsgs ( newModel, cmds, level ) msgs
        in
            finalModel



-- Memo filters can examine the current model and decide whether or not
-- the memo will be forwarded.


type alias MemoFilter =
    Model -> Bool



-- Handy "always true" MemoFilter.


alwaysForward : MemoFilter
alwaysForward model =
    True



-- Several ways to route Memos, which can be combined. In the first, a
-- Memo triggers a Msg if the filter is True.


type alias MemoSender =
    ( Memo, Msg, MemoFilter )



-- The Memo and Msg can have constant parameters (if defined in their union
-- types), but you can't pass an arbitrary parameter from the Memo to the
-- Msg using this method. To do that, you define a custom router.
--
-- In this example, the simple NewGirl memo triggers an AddSister 1 message.
-- We could define MemoSenders that match Memos like NewBoy 1, NewBoy 2, etc.,
-- instead of using a custom router, with the caveat that you have to take care
-- to handle all the cases. And you can have multiple entries for the same
-- Memo, so a memo can generate multiple Msgs.
--
-- Note that the final entry in this list will generate an infinite recursion,
-- and so will trigger our "blizzard" checking.


memoSenders : List MemoSender
memoSenders =
    [ ( FromGirls Girls.NewGirl, BoysMsg (Boys.AddSister 1), alwaysForward )
    , ( FromGirls Girls.NewGirlTwins, BoysMsg (Boys.AddSister 1), alwaysForward )
    , ( FromGirls Girls.NewGirlTwins, BoysMsg (Boys.AddSister 1), alwaysForward )
    , ( FromParents Parents.MakeBlizzard, ParentsMsg Parents.TestBlizzard, alwaysForward )
    ]



-- In the second, a Msg can subscribe to a Memo. Note how we can use a function
-- to query the model and determine if the Msg is created; in this case, the
-- parents are refusing to acknowledge any children after the first two. :)


type alias MemoSubscriber =
    ( Msg, Memo, MemoFilter )



-- One gotcha to be aware of; the MemoFilter is evaluated based on the state of the model when the memos are
-- routed, not the state when they are actually delivered. Consider what happens if the Parents have one
-- child and they naively subscribe to the NewGirlTwins message twice (as below). If they used the same
-- MemoFilter, they'd end up with 3 children, which is more than they'll accept!


memoSubscribers : List MemoSubscriber
memoSubscribers =
    [ ( ParentsMsg Parents.AddDaughter, FromGirls Girls.NewGirl, (\m -> (m.parents.sons + m.parents.daughters) < 2) )
    , ( ParentsMsg Parents.AddDaughter, FromGirls Girls.NewGirlTwins, (\m -> (m.parents.sons + m.parents.daughters) < 2) )
    , ( ParentsMsg Parents.AddDaughter, FromGirls Girls.NewGirlTwins, (\m -> (m.parents.sons + m.parents.daughters) < 1) )
    ]



-- The router generates Msgs from Memos in a deterministic manner; senders first, then
-- subscribers, and then any Memos with parameters, which are special-cased in the function.
-- Note that Memos can end up generating no Msgs at all.


routeMemos : Model -> Memo -> List Msg
routeMemos model memo =
    let
        senders =
            List.concatMap (validSender model memo) memoSenders

        subscribers =
            List.concatMap (validSubscriber model memo) memoSubscribers

        -- Custom routers handle special cases, such as Memos that
        -- have parameters. You could stuff all the special cases
        -- into a single custom router but it may be cleaner to
        -- have several smaller ones.
        customRouters =
            List.concat
                [ boysRouter model memo
                ]

        msgs =
            List.concat [ senders, subscribers, customRouters ]
    in
        msgs



-- Handle the NewBoy Memo keeping the limitation that the Parents, for some strange
-- reason, don't want to admit to having lots of children! I admit this is a really
-- dumb example.


boysRouter : Model -> Memo -> List Msg
boysRouter model memo =
    case memo of
        FromBoys (Boys.NewBoy n) ->
            addBoys (model.parents.sons + model.parents.daughters) n

        _ ->
            []


addBoys : Int -> Int -> List Msg
addBoys kids n =
    if n == 0 then
        []
    else
        GirlsMsg Girls.AddBrother
            :: if kids < 2 then
                ParentsMsg Parents.AddSon :: addBoys (kids + 1) (n - 1)
               else
                addBoys kids (n - 1)



-- Check a MemoSender and return a Msg wrapped in a list if we get a match.


validSender : Model -> Memo -> MemoSender -> List Msg
validSender model memo memosender =
    let
        ( sender, msg, condition ) =
            memosender
    in
        if memo == sender && (condition model) then
            [ msg ]
        else
            []



-- Check a MemoSubscriber and return a Msg wrapped in a list if we get a match.


validSubscriber : Model -> Memo -> MemoSubscriber -> List Msg
validSubscriber model memo memosubscriber =
    let
        ( msg, subscriber, condition ) =
            memosubscriber
    in
        if memo == subscriber && (condition model) then
            [ msg ]
        else
            []



-- Call update to apply a Msg to a Model and accumulate any Cmd Msgs that get generated along the way
-- Thanks to @jessta on Elm-slack for a key insight.


deliverMsgs : Msg -> ( Model, Cmd Msg, Int ) -> ( Model, Cmd Msg, Int )
deliverMsgs msg ( model, cmd, level ) =
    if level > memoBlizzardLimit then
        ( model, cmd, level )
    else
        let
            modelWithMsg =
                { model | msgs = List.append model.msgs [ MemoTrace msg level ] }

            -- Update the model
            ( newModel, newCmd, newLvl ) =
                updateWithMemos msg modelWithMsg (level + 1)

            -- Assemble any generated commands
            allCmds =
                Cmd.batch [ cmd, newCmd ]
        in
            ( newModel, allCmds, level )



-- view


mainView : Model -> Html Msg
mainView model =
    div [ class "main" ]
        [ text
            (let
                l =
                    List.foldl (\trace _ -> trace.level) 0 model.msgs
             in
                if l >= memoBlizzardLimit then
                    "Memo blizzard detected - check History!"
                else if l > 0 then
                    toString l ++ " memos handled"
                else
                    ""
            )
        ]


view : Model -> Html Msg
view model =
    div []
        [ Html.map BoysMsg
            (Boys.view model.boys)
        , Html.map GirlsMsg
            (Girls.view model.girls)
        , Html.map ParentsMsg
            (Parents.view model.parents)
        , mainView model
        ]



-- subscriptions


mainModelSubscriptions : MainModel -> Sub Msg
mainModelSubscriptions model =
    Sub.none


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        boysSub =
            Boys.subscriptions model.boys

        girlsSub =
            Girls.subscriptions model.girls

        parentsSub =
            Parents.subscriptions model.parents

        mainSub =
            mainModelSubscriptions model.main
    in
        Sub.batch
            [ mainSub
            , Sub.map BoysMsg boysSub
            , Sub.map GirlsMsg girlsSub
            , Sub.map ParentsMsg parentsSub
            ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
