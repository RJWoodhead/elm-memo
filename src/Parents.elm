module Parents exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


-- Model and initialization


type alias Model =
    { sons : Int
    , daughters : Int
    }


initModel : Model
initModel =
    { sons = 0
    , daughters = 0
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- Msgs and Memos


type Msg
    = AddSon
    | AddDaughter
    | TestBlizzard



-- Memo that generates infinite recursion memo blizzard!


type Memo
    = MakeBlizzard



-- Update function returns a tuple with the new Model, Cmd Msg, and
-- a list of Memo's that need to be distributed.
--
-- In this case, all the incoming AddSon and AddDaughter Msgs will be
-- created by Memos sent by the Boys and Girls modules.


update : Msg -> Model -> ( Model, Cmd Msg, List Memo )
update msg model =
    case msg of
        AddSon ->
            ( { model | sons = model.sons + 1 }, Cmd.none, [] )

        AddDaughter ->
            ( { model | daughters = model.daughters + 1 }, Cmd.none, [] )

        TestBlizzard ->
            ( model, Cmd.none, [ MakeBlizzard ] )



-- view


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ "The parents admit to having "
            ++ toString model.sons
            ++ " sons and "
            ++ toString model.daughters
            ++ " daughters, for a total of "
            ++ toString (model.sons + model.daughters)
            ++ " children "
            |> text
        , button [ onClick TestBlizzard ] [ text "Create Memo Blizzard" ]
        ]



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
