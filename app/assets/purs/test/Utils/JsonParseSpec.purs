module Test.Utils.JsonParseSpec
  ( spec
  ) where

import Prelude

import Data.Argonaut.Core as Json
import Data.Maybe (Maybe(..))
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Unsafe.Coerce (unsafeCoerce)
import Utils.Json as J

spec :: Spec Unit
spec = do
  describe "JsonParse" do

    it "can parse JSON" do
      (stringify <$> J.parse "{ \"foo\": \"bar\", \"baz\": 42 }")
        `shouldEqual` Just "{\"foo\":\"bar\",\"baz\":42}"

    it "sliently returns Nothing for invalid inputs" do
      (stringify <$> J.parse "Bogus") `shouldEqual` Nothing

  where
    stringify = unsafeCoerce >>> Json.stringify
