module Test.Utils.LocationSpec
  ( spec
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Foreign.Object as FO
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Row.Homogeneous (class Homogeneous)
import Utils.Location (parseQueryString)

spec :: Spec Unit
spec = do
  describe "parseQueryString" do
    it "can parse regular query string" do
      let expected = { foo: Just "bar", baz: Nothing, x: Just "y" }
      "?foo=bar&baz&x=y" `shouldParseAs` expected
      "foo=bar&baz&x=y" `shouldParseAs` expected

    it "can parse empty query string" do
      "" `shouldParseAs` {}
      "?" `shouldParseAs` {}

  where
    shouldParseAs :: forall r. Homogeneous r _ => _ -> { | r } -> _
    shouldParseAs str rec = parseQueryString str `shouldEqual` FO.fromHomogeneous rec
