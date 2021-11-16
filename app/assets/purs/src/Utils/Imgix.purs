module Utils.Imgix
  ( img_
  ) where

import Prelude

import Data.Foldable (fold, intercalate)
import Data.Int (floor)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.Tuple (Tuple(..))
import Data.Undefined.NoProblem (Opt, isUndefined, toMaybe)
import Data.Undefined.NoProblem.Closed as Closed
import Data.Unfoldable (unfoldr)
import Elmish (ReactElement)
import Elmish.HTML.Styled as H

type Args =
  { src :: String
  , width :: Opt Int
  , height :: Opt Int
  , params :: Opt String
  }

-- | Generates an <img> tag with a `src` and optionally `srcset` of different
-- | crops served from imgix. `srcset` is defined for a band of different widths
-- | (see `widths` below), only when `width` is not passed in the args.
-- | Technically there needs to be symmetric logic for variable-height `srcset`
-- | for when `height` is undefined, but we don't have any use for it at this
-- | point, so 🤷.
img_ :: forall args. Closed.Coerce args Args => String -> args -> ReactElement
img_ className args' =
  H.img_ className { src, srcSet }
  where
    args = Closed.coerce args' :: Args

    src =
      args.src
      # String.stripSuffix (String.Pattern "?")
      # fromMaybe args.src
      # (_ <> "?fit=crop&crop=edges" <> height <> width <> "&q=80&auto=format" <> paramsQuery)

    height = args.height # toMaybe <#> (\h -> "&h=" <> show h) # fromMaybe ""
    width = args.width # toMaybe <#> (\w -> "&w=" <> show w) # fromMaybe ""
    paramsQuery = args.params # toMaybe <#> ("&" <>  _) # fromMaybe ""

    srcSet
      | isUndefined args.width =
          intercalate "," $ srcSetElement <$> widths
      | otherwise =
          ""

    srcSetElement w = fold
      [ src, "&w=", iw, " ", iw, "w" ]
      where
        iw = show (floor w)

-- The logic of computing the widths is copied from the Imgix-rb library.
-- The idea is, starting from the min width, keep multiplying by a factor
-- until you hit max width. Then don't forget to also include the max width
-- itself.
-- https://github.com/imgix/imgix-rb/blob/d929ad9a7ef61b195447b24c8290f1f29515facf/lib/imgix.rb#L21
widths :: Array Number
widths =
  unfoldr
    (\w ->
        if w >= maxWidth then Nothing
        else Just $ Tuple w (w * widthIncreaseFactor)
    )
    minWidth
  <>
  [maxWidth]
  where
    minWidth = 640.0
    maxWidth = 5120.0
    widthIncreaseFactor = 1.16
