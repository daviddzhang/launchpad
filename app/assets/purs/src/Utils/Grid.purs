module Utils.Grid(row, col) where

import Prelude

import Elmish (ReactElement)
import Elmish.HTML as H
import Elmish.React (class ReactChildren)

row :: forall content. ReactChildren content => content -> ReactElement
row = H.div { className: "row" }

col :: forall content. ReactChildren content => String -> content -> ReactElement
col n = H.div { className: "col col-" <> n }
