module Girls exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)


-- Model and initialization


type alias Model =
    { count : Int
    , brothers : Int
    }


initModel : Model
initModel =
    { count = 0
    , brothers = 0
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- Msgs and Memos


type Msg
    = Increment
    | Twins
    | AddBrother


type Memo
    = NewGirl
    | NewGirlTwins



-- Update function returns a tuple with the new Model, Cmd Msg, and
-- a list of Memo's that need to be distributed


update : Msg -> Model -> ( Model, Cmd Msg, List Memo )
update msg model =
    case msg of
        -- When we add a new girl, we need to tell the parents and the brothers,
        -- so we send a NewGirl Memo
        Increment ->
            ( { model | count = model.count + 1 }, Cmd.none, [ NewGirl ] )

        Twins ->
            ( { model | count = model.count + 2 }, Cmd.none, [ NewGirlTwins ] )

        -- In response to a Boys.NewBoy Memo, we'll get an Girls.AddBrother Msg
        AddBrother ->
            ( { model | brothers = model.brothers + 1 }, Cmd.none, [] )



-- view


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ toString model.count
            ++ " girls have "
            ++ toString model.brothers
            ++ " brothers "
            |> text
        , button [ onClick Increment ] [ text "Add Girl" ]
        , text " or "
        , button [ onClick Twins ] [ text "Add Twin Girls" ]
        ]



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
