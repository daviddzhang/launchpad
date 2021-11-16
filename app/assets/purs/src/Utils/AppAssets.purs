module Utils.AppAssets
  ( assetImage_
  , assetImage
  , assetPath
  , assetsRoot
  ) where

import Prelude

import Data.Maybe (fromMaybe)
import Data.String as String
import Elmish (ReactElement)
import Elmish.HTML as H
import Elmish.HTML.Internal as I
import Elmish.HTML.Styled as S
import Foreign.Object (insert)
import Unsafe.Coerce (unsafeCoerce)

-- | An <img> tag with its `src` attribute modified to point to the assets CDN
-- | in production.
assetImage :: String -> String -> ReactElement
assetImage className src = assetImage_ className { src }

-- | An <img> tag with its `src` attribute modified to point to the assets CDN
-- | in production.
assetImage_ :: I.StyledTagNoContent_ H.OptProps_img
assetImage_ className props = S.img_ className newProps
  where
    { src } = unsafeCoerce props :: { src :: _ }

    -- This is a hacky way to update the `src` property of the props by first
    -- coercing it to Foreign.Object, inserting the value, then coercing back
    newProps =
      props # unsafeCoerce # insert "src" (assetPath src) # unsafeCoerce # sameTypeAs props

    sameTypeAs :: forall a. a -> a -> a
    sameTypeAs _ = identity

-- | Given asset's local path (relative to the `public` directory), returns the
-- | path whence this asset should be served. Isn't this just the identity
-- | function? It is for local dev environment, but not in general: in
-- | production our assets are served from a CDN.
assetPath :: String -> String
assetPath path = assetsRoot <> (path # String.stripPrefix (String.Pattern "/") # fromMaybe path)

-- | URL of where our app assets (such as images) can be found. Isn't this just
-- | the root of the current domain? No, it's not: our assets are served from a
-- | CDN, and while the current domain root also technically works, it doesn't
-- | have redundancy, geo distribution, and all the other CDN goodies.
foreign import assetsRoot :: String
