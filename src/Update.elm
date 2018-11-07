module Update exposing (update)

import AppSettings exposing (PageView(..), SystemOfMeasurement(..))
import Audio.Reel.Model exposing (Reel, newReel)
import CsvOutput exposing (dataForCSV)
import Messages exposing (Msg(..))
import Model exposing (Model)
import Ports
import Random exposing (step)
import Uuid exposing (Uuid, uuidGenerator)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddReel ->
            case model.selectorValues.quantity of
                Just q ->
                    let
                        ( uuid, newSeed ) =
                            step uuidGenerator model.currentSeed

                        newReels =
                            newReel uuid model.selectorValues q
                                :: model.reels

                        newModel =
                            { model | currentSeed = newSeed, reels = newReels }
                    in
                    ( newModel, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        DeleteReel reelID ->
            let
                newModel =
                    { model | reels = removeReel reelID model.reels }
            in
            ( newModel, Cmd.none )

        ChangeFileType ft ->
            ( { model | fileType = ft }, Cmd.none )

        ChangeAudioConfig config ->
            let
                updateSValues sValues newConfig =
                    { sValues | audioConfig = newConfig }

                newSelectorValues =
                    updateSValues model.selectorValues config

                newModel =
                    { model | selectorValues = newSelectorValues }
            in
            ( newModel, Cmd.none )

        ChangeDiameterInInches diameter ->
            let
                updateSValues sValues newDiameterInInches =
                    { sValues | diameter = newDiameterInInches }

                newSelectorValues =
                    updateSValues model.selectorValues diameter

                newModel =
                    { model | selectorValues = newSelectorValues }
            in
            ( newModel, Cmd.none )

        ChangeTapeThickness thickness ->
            let
                updateSValues sValues newThickness =
                    { sValues | tapeThickness = newThickness }

                newSelectorValues =
                    updateSValues model.selectorValues thickness

                newModel =
                    { model | selectorValues = newSelectorValues }
            in
            ( newModel, Cmd.none )

        ChangeRecordingSpeed speed ->
            let
                updateSValues sValues newSpeed =
                    { sValues | recordingSpeed = newSpeed }

                newSelectorValues =
                    updateSValues model.selectorValues speed

                newModel =
                    { model | selectorValues = newSelectorValues }
            in
            ( newModel, Cmd.none )

        UpdateQuantity quantity ->
            let
                updateSValues sValues newSpeed =
                    { sValues | quantity = newSpeed }
            in
            case String.toInt quantity of
                Just q ->
                    let
                        newSelectorValues =
                            updateSValues model.selectorValues <| Just q

                        newModel =
                            { model | selectorValues = newSelectorValues }
                    in
                    ( newModel, Cmd.none )

                Nothing ->
                    let
                        newSelectorValues =
                            updateSValues model.selectorValues Nothing

                        newModel =
                            { model | selectorValues = newSelectorValues }
                    in
                    ( newModel, Cmd.none )

        ChangeSystemOfMeasurement system ->
            case system of
                Metric ->
                    ( { model | system = Metric }, Cmd.none )

                Imperial ->
                    ( { model | system = Imperial }, Cmd.none )

        ChangeLanguage l ->
            ( { model | language = l }, Cmd.none )

        TogglePageView page ->
            case page of
                Calculator ->
                    ( { model | page = Info }, Cmd.none )

                Info ->
                    ( { model | page = Calculator }, Cmd.none )

        StartExport ->
            let
                csvData =
                    dataForCSV model.language model.fileType model.reels
            in
            ( model, Ports.exportData csvData )

        NoOp ->
            ( model, Cmd.none )


removeReel : Uuid -> List Reel -> List Reel
removeReel reelID allReels =
    List.filter (\r -> r.id /= reelID) allReels
