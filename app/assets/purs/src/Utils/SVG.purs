module Utils.SVG
  ( doughnutArc
  , path_
  , text_
  ) where

import Prelude

import Data.Foldable (fold)
import Data.Int as Int
import Elmish (ReactElement)
import Elmish.HTML.Internal as I
import Math as Math

type OptProps_path r =
  ( d :: String
  , fill :: String
  , stroke :: String
  , strokeWidth :: Number
  | r
  )

path_ :: I.StyledTagNoContent_ OptProps_path
path_ = I.styledTagNoContent_ "path"

type OptProps_text r =
  ( x :: String
  , y :: String
  , dominantBaseline :: String
  , textAnchor :: String
  | r
  )

text_ :: I.StyledTag_ OptProps_text
text_ = I.styledTag_ "text"

type Point = { x :: Number, y :: Number }

-- | Produces an SVG <path> elemnent describing a section of a doughnut (i.e. an
-- | intersection area of two concentric circles)
doughnutArc ::
  { center :: Point
  , angle0 :: Number
  , angle1 :: Number
  , innerRadius :: Number
  , outerRadius :: Number
  , fill :: String
  , stroke :: { color :: String, width :: Number }
  }
  -> ReactElement
doughnutArc args = path_ ""
  { d: fold
      [ " M ", showp args.outerRadius p0

      , " A "
      , showi args.outerRadius, " ", showi args.outerRadius
      , " 0 ", isLargeArc, " 0 "
      , showp args.outerRadius p1

      , " L ", showp args.innerRadius p1

      , " A "
      , showi args.innerRadius, " ", showi args.innerRadius
      , " 0 ", isLargeArc, " 1 "
      , showp args.innerRadius p0

      , " Z"
      ]
  , fill: args.fill
  , stroke: args.stroke.color
  , strokeWidth: args.stroke.width
  }
  where
    p0 = polarPoint args.angle0
    p1 = polarPoint args.angle1
    isLargeArc = if args.angle1 - args.angle0 > Math.pi then "1" else "0"

    -- Display a point as two space-separated numbers, e.g. "5 42"
    showp scale point =
      showi (scale * point.x) <> " " <> showi (scale * point.y)

    showi = show <<< Int.round

    polarPoint angle =
      { x: args.center.x + Math.cos angle
      , y: args.center.y - Math.sin angle
      }
