module Test.Main where

import Prelude

import Effect (Effect)
import Test.Enzyme as Enzyme
import Test.Monad (runSpec)
import Test.Utils.Format as Format
import Test.Utils.JsonParseSpec as JsonParse
import Test.Utils.LocationSpec as Location
import Test.Utils.Markdown as Markdown
import Test.Utils.NaturalOrder as NaturalOrder
import Test.Utils.TextSpec as Text

main :: Effect Unit
main = do
  Enzyme.configure

-- This import is only here to cause the FFI code to run, so that jsdom can be
-- run before React.
-- See https://enzymejs.github.io/enzyme/docs/guides/jsdom.html for more info.
foreign import _configureJsDomViaFfi :: Type
