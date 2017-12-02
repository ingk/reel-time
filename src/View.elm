module View exposing (view)

import Calculations exposing (..)
import Helpers exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, disabled, href, id, name, placeholder, selected, src, value)
import Html.Events exposing (on, onClick, onInput)
import Json.Decode as Json
import Links exposing (LinkData(..), LinkName(..), link, linkData)
import Maybe.Extra exposing (isNothing)
import Model exposing (Model)
import Translate exposing (AppString(..), Language(..), allLanguages, infoPara, translate)
import Types exposing (..)
import Update exposing (Msg(..))
import Uuid exposing (Uuid, uuidGenerator)


view : Model -> Html Msg
view model =
    div [ id "container", class "box container" ]
        [ div [ id "content" ]
            [ navbar model.page model.system model.language
            , hr [] []
            , pageContent model
            , hr [] []
            , footer model.language
            ]

        -- , responsiveWarning model.language
        ]


responsiveWarning : Language -> Html Msg
responsiveWarning language =
    div [ class "responsive-warning-container whiteout" ]
        [ div [ class "responsive-warning" ]
            [ p [ class "is-size-2" ]
                [ span [ class "icon" ]
                    [ i [ class "fa fa-exclamation-triangle" ] []
                    ]
                ]
            , p [] [ text <| translate language ResponsiveStr ]
            ]
        ]


footer : Language -> Html Msg
footer language =
    div [ class "level" ]
        [ div [ class "level-left" ] [ text <| translate language DevelopedByStr ]
        , div [ class "is-size-6 level-right" ] [ link Email, link SourceCode ]
        ]


navbar : PageView -> SystemOfMeasurement -> Language -> Html Msg
navbar page system language =
    let
        measurementControls =
            case page of
                Calculator ->
                    [ systemControls system ]

                _ ->
                    []
    in
    nav [ class "navbar", attribute "role" "navigation" ]
        [ div [ class "navbar-brand" ]
            [ div [ class "navbar-item" ]
                [ p [ class "title" ]
                    [ text "⏰ reel time"
                    ]
                ]
            ]
        , div [ class "navbar-menu" ]
            [ div [ class "navbar-start" ]
                [ div [ class "navbar-item" ]
                    [ p [] [ em [] [ text <| translate language CalculateStr ] ]
                    ]
                ]
            , div [ class "navbar-end" ]
                (measurementControls
                    ++ [ languageControls language
                       , navigationButton page
                       ]
                )
            ]
        ]


systemControls : SystemOfMeasurement -> Html Msg
systemControls system =
    let
        makeButton sys =
            button
                [ classList
                    [ ( "button is-small", True )
                    , ( "is-primary", sys == system )
                    ]
                , onClick (ChangeSystemOfMeasurement sys)
                ]
                [ text (toString sys) ]
    in
    div [ class "navbar-item" ] (List.map makeButton allSystemsOfMeasurement)


languageControls : Language -> Html Msg
languageControls language =
    let
        makeButton l =
            button
                [ classList
                    [ ( "button is-small", True )
                    , ( "is-primary", l == language )
                    ]
                , onClick (ChangeLanguage l)
                ]
                [ text (toString l) ]
    in
    div [ class "navbar-item" ] (List.map makeButton allLanguages)


navigationButton : PageView -> Html Msg
navigationButton page =
    let
        navButton iconName =
            div [ class "navbar-item" ]
                [ div [ class "button is-small", onClick (TogglePageView page) ] [ span [ class "icon" ] [ i [ class <| "fa " ++ iconName ] [] ] ]
                ]
    in
    case page of
        Calculator ->
            navButton "fa-info-circle"

        Info ->
            navButton "fa-home"


wrapSectionInLevelDiv : Html Msg -> Html Msg
wrapSectionInLevelDiv section =
    div [ class "level" ] [ section ]


pageContent : Model -> Html Msg
pageContent model =
    let
        infoPageSections =
            [ infoParagraph model.language, questionSection model.language, linksSection model.language ]
    in
    case model.page of
        Info ->
            div [ class "columns" ]
                [ div [ class "column is-one-third" ] [ img [ src "/reel-time-logo-sketch_sml.jpg" ] [] ]
                , div [ class "column is-two-thirds has-text-left" ]
                    (List.map wrapSectionInLevelDiv infoPageSections)
                ]

        Calculator ->
            div [] [ reelTable model ]


infoParagraph : Language -> Html Msg
infoParagraph language =
    div []
        [ h2 [ class "subtitle" ] [ text <| translate language AboutStr ]
        , p [] (infoPara language)
        , p [] [ text <| translate language ContributeStr ]
        ]


questionSection : Language -> Html Msg
questionSection language =
    div []
        [ h2 [ class "subtitle" ] [ text <| translate language QAndAStr ]
        , wrapSectionInLevelDiv
            (div []
                [ p [] [ strong [] [ text <| translate language UnknownVariablesQStr ] ]
                , p [] [ text <| translate language UnknownVariablesAStr ]
                ]
            )
        , wrapSectionInLevelDiv
            (div []
                [ p [] [ strong [] [ text <| translate language ReelDurationQStr ] ]
                , p [] [ text <| translate language ReelDurationAStr ]
                ]
            )
        ]


linksSection : Language -> Html Msg
linksSection language =
    let
        iasaTC04Link =
            case language of
                EN ->
                    [ li [] [ link IASAGuidelinesEN, text <| linkData IASAGuidelinesENData ] ]

                FR ->
                    [ li [] [ link IASAGuidelinesFR, text <| linkData IASAGuidelinesFRData ] ]

                IT ->
                    [ li [] [ link IASAGuidelinesIT, text <| linkData IASAGuidelinesITData ] ]

        iasaTC05Link =
            case language of
                EN ->
                    [ li [] [ link IASAMagLinkEN, text <| linkData IASAMagLinkENData ] ]

                FR ->
                    []

                IT ->
                    [ li [] [ link IASAMagLinkIT, text <| linkData IASAMagLinkITData ] ]
    in
    div []
        [ h2 [ class "subtitle" ] [ text <| translate language UsefulLinksStr ]
        , ul []
            (iasaTC05Link
                ++ iasaTC04Link
                ++ [ li [] [ link Estimating, text <| linkData RangerData ]
                   , li [] [ link Facet, text <| linkData CaseyData ]
                   ]
            )
        ]


lengthInfo : SystemOfMeasurement -> Language -> Footage -> Html Msg
lengthInfo system language footage =
    let
        ft =
            footageToInt footage

        metricLength =
            toFloat ft * 0.3048

        lengthText =
            case system of
                Imperial ->
                    toString ft ++ "ft"

                Metric ->
                    toString metricLength ++ "m"

        perReel =
            translate language (PerReelStr lengthText)
    in
    div [] [ text perReel ]


directionAndPassCount : Language -> Direction -> Passes -> Html Msg
directionAndPassCount language direction passes =
    let
        passText =
            if passes == 1 then
                translate language SinglePassStr
            else
                translate language (PassesStr passes)

        directionString =
            case direction of
                Unidirectional ->
                    UnidirectionalStr

                Bidirectional ->
                    BidirectionalStr

        fullDirectionString =
            translate language directionString
    in
    div [] [ text (fullDirectionString ++ ": " ++ passText) ]


durationData : Language -> DurationInMinutes -> Quantity -> Passes -> List (Html Msg)
durationData language mins quantity passes =
    let
        reelTime =
            mins * toFloat passes

        reelTimeString =
            translate language <| MinutesStr reelTime

        totalTime =
            reelTime * toFloat quantity
    in
    [ div [] [ text (translate language <| PerReelStr reelTimeString) ]
    , div [] [ text (formatTime totalTime ++ " " ++ translate language TotalStr) ]
    ]


reelTable : Model -> Html Msg
reelTable model =
    let
        total =
            if List.length model.reels > 0 then
                [ totalRow model.language model.reels ]
            else
                []

        reelRows =
            List.map (reelRow model.system model.language) model.reels
    in
    table [ class "table is-fullwidth" ]
        ([ thead [] [ headerRow model.language ]
         , tbody [] [ selectorRow model ]
         , tbody [] reelRows
         ]
            ++ total
        )


headerRow : Language -> Html Msg
headerRow language =
    tr []
        [ th [] [ text <| translate language TypeStr ]
        , th [] [ text <| translate language DiameterStr ]
        , th [] [ text <| translate language ThicknessStr ]
        , th [] [ text <| translate language SpeedStr ]
        , th [] [ text <| translate language QuantityStr ]
        , th [] [ text <| translate language InfoHeaderStr ]
        , th [] [ text <| translate language DurationStr ]
        , th [] []
        ]


onChange : (String -> msg) -> Html.Attribute msg
onChange makeMessage =
    on "change" (Json.map makeMessage Html.Events.targetValue)


selectorRow : Model -> Html Msg
selectorRow model =
    let
        createOption selectorMatcher displayer opt =
            option [ value (toString opt), selected (opt == selectorMatcher) ] [ text (displayer opt) ]

        sValues =
            model.selectorValues

        invalidQuantity =
            isNothing model.quantity
    in
    tr []
        [ th []
            [ div [ class "select is-small" ]
                [ select [ name "audio-config", class "select is-small", onChange ChangeAudioConfig ]
                    (List.map
                        (\config -> option [ value (toString config), selected (config == sValues.audioConfig) ] [ text <| translate model.language <| audioConfigDisplayName config ])
                        allAudioConfigs
                    )
                ]
            ]
        , th []
            [ div [ class "select is-small" ]
                [ select
                    [ name "diameter", class "select is-small", onChange ChangeDiameterInInches ]
                    (List.map
                        (createOption sValues.diameter <| diameterDisplayName model.system)
                        allDiameters
                    )
                ]
            ]
        , th []
            [ div [ class "select is-small" ]
                [ select [ name "tape-thickness", class "select is-small", onChange ChangeTapeThickness ]
                    (List.map
                        (createOption sValues.tapeThickness tapeThicknessDisplayName)
                        allThicknesses
                    )
                ]
            ]
        , th []
            [ div [ class "select is-small" ]
                [ select [ name "recording-speed", class "select is-small", onChange ChangeRecordingSpeed ]
                    (List.map
                        (createOption sValues.recordingSpeed <| speedDisplayName model.system)
                        allRecordingSpeeds
                    )
                ]
            ]
        , th []
            [ input
                [ classList [ ( "input is-small", True ), ( "is-danger", invalidQuantity ) ]
                , id "quantity"
                , placeholder "#"
                , onInput UpdateQuantity
                ]
                []
            ]
        , th [] []
        , th [] []
        , th []
            [ button
                [ class "button is-small", onClick AddReel, disabled invalidQuantity ]
                [ span [ class "icon" ]
                    [ i [ class "fa fa-plus" ] []
                    ]
                ]
            ]
        ]


reelRow : SystemOfMeasurement -> Language -> Reel -> Html Msg
reelRow system language reel =
    let
        deleteRowButton r =
            button [ class "button is-small", onClick (DeleteRow r) ]
                [ span [ class "icon" ]
                    [ i [ class "fa fa-trash" ] []
                    ]
                ]

        footage =
            reelLengthInFeet reel

        mins =
            durationInMinutes reel
    in
    tr [ id (Uuid.toString reel.id) ]
        [ td [] [ text <| translate language <| audioConfigDisplayName reel.audioConfig ]
        , td [] [ text <| diameterDisplayName system reel.diameter ]
        , td [] [ text <| tapeThicknessDisplayName reel.tapeThickness ]
        , td [] [ text <| speedDisplayName system reel.recordingSpeed ]
        , td [] [ text <| toString reel.quantity ]
        , td []
            [ directionAndPassCount language reel.directionality reel.passes
            , lengthInfo system language footage
            ]
        , td [] (durationData language mins reel.quantity reel.passes)
        , td [] [ deleteRowButton reel ]
        ]


totalRow : Language -> List Reel -> Html Msg
totalRow language reels =
    let
        totalMins =
            totalLength reels

        formattedTime =
            formatTime totalMins
    in
    tfoot []
        [ tr []
            [ td [] []
            , td [] []
            , td [] []
            , td [] []
            , td [] []
            , td [] [ text <| translate language TotalStr ]
            , td [] [ text <| translate language (DurationSummaryStr totalMins formattedTime) ]
            , td [] []
            ]
        ]