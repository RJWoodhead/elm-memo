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


type alias Model =
    { boys : Boys.Model
    , girls : Girls.Model
    , parents : Parents.Model
    , main : MainModel
    , msgs : List Msg
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



-- If the memos result in too many Msgs, it's a memo blizzard and we should give up.
-- In a production application this might be set to 50 or 100.


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
    in
        updateWithMemos msg newModel



-- The actual update function


updateWithMemos : Msg -> Model -> ( Model, Cmd Msg )
updateWithMemos msg model =
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

            -- Deliver the messages.
            finalModel =
                List.foldl deliverMsgs ( newModel, cmds ) msgs
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



-- Two ways to route Memos, which can be combined. In the first, a
-- Memo triggers a Msg if the filter is True.


type alias MemoSender =
    ( Memo, Msg, MemoFilter )



-- Note that the final entry in this list will generate an infinite recursion,
-- and so will trigger our "blizzard" checking.


memoSenders : List MemoSender
memoSenders =
    [ ( FromBoys Boys.NewBoy, GirlsMsg Girls.AddBrother, alwaysForward )
    , ( FromGirls Girls.NewGirl, BoysMsg Boys.AddSister, alwaysForward )
    , ( FromParents Parents.MakeBlizzard, ParentsMsg Parents.TestBlizzard, alwaysForward )
    ]



-- In the second, a Msg can subscribe to a Memo. Note how we can use a function
-- to query the model and determine if the Msg is created; in this case, the
-- parents are refusing to acknowledge any children after the first two. :)


type alias MemoSubscriber =
    ( Msg, Memo, MemoFilter )


memoSubscribers : List MemoSubscriber
memoSubscribers =
    [ ( ParentsMsg Parents.AddDaughter, FromGirls Girls.NewGirl, (\m -> (m.parents.sons + m.parents.daughters) < 2) )
    , ( ParentsMsg Parents.AddSon, FromBoys Boys.NewBoy, (\m -> (m.parents.sons + m.parents.daughters) < 2) )
    ]



-- The router is boilerplate; the order in which Msgs will be generated from Memos is
-- senders first, then subscribers, and in order they appear in the lists.


routeMemos : Model -> Memo -> List Msg
routeMemos model memo =
    let
        senders =
            List.concatMap (validSender model memo) memoSenders

        subscribers =
            List.concatMap (validSubscriber model memo) memoSubscribers

        msgs =
            List.concat [ senders, subscribers ]
    in
        msgs



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


deliverMsgs : Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
deliverMsgs msg ( model, cmd ) =
    if List.length model.msgs > memoBlizzardLimit then
        ( model, cmd )
    else
        let
            modelWithMsg =
                { model | msgs = List.append model.msgs [ msg ] }

            -- Update the model
            ( newModel, newCmd ) =
                updateWithMemos msg modelWithMsg

            -- Assemble any generated commands
            allCmds =
                Cmd.batch [ cmd, newCmd ]
        in
            ( newModel, allCmds )



-- view


mainView : Model -> Html Msg
mainView model =
    div [ class "main" ]
        [ text
            (let
                l =
                    List.length model.msgs
             in
                if l > memoBlizzardLimit then
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
