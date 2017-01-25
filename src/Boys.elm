module Boys exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)


-- Model and initialization


type alias Model =
    { count : Int
    , sisters : Int
    }


initModel : Model
initModel =
    { count = 0
    , sisters = 0
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- Msgs and Memos


type Msg
    = Increment
    | AddSister


type Memo
    = NewBoy



-- Update function returns a tuple with the new Model, Cmd Msg, and
-- a list of Memo's that need to be distributed


update : Msg -> Model -> ( Model, Cmd Msg, List Memo )
update msg model =
    case msg of
        -- When we add a new boy, we need to tell the parents and the sisters,
        -- so we send a NewBoy Memo
        Increment ->
            ( { model | count = model.count + 1 }, Cmd.none, [ NewBoy ] )

        -- In response to a Girls.NewGirl Memo, we'll get an Boys.AddSister Msg
        AddSister ->
            ( { model | sisters = model.sisters + 1 }, Cmd.none, [] )



-- view


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ toString model.count
            ++ " boys have "
            ++ toString model.sisters
            ++ " sisters "
            |> text
        , button [ onClick Increment ] [ text "Add Boy" ]
        ]



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
