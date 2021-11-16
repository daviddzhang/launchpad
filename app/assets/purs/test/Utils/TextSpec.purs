module Test.Utils.TextSpec
  ( spec
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Utils.Text (enumerateWithOr, enumerateWithAnd)

spec :: Spec Unit
spec = do
  describe "Utils.Text" do
    describe "enumerateWithOr" do
      it "enumerates words with ‘or’" do
        enumerateWithOr (NEA.singleton "foo") `shouldEqual` "foo"
        enumerateWithOr (NEA.cons' "foo" ["bar"]) `shouldEqual` "foo or bar"
        enumerateWithOr (NEA.cons' "foo" ["bar", "baz"]) `shouldEqual` "foo, bar, or baz"
        enumerateWithOr (NEA.cons' "foo" ["bar", "baz", "quux"]) `shouldEqual` "foo, bar, baz, or quux"

    describe "enumerateWithAnd" do
      it "enumerates words with ‘and’" do
        enumerateWithAnd (NEA.singleton "foo") `shouldEqual` "foo"
        enumerateWithAnd (NEA.cons' "foo" ["bar"]) `shouldEqual` "foo and bar"
        enumerateWithAnd (NEA.cons' "foo" ["bar", "baz"]) `shouldEqual` "foo, bar, and baz"
        enumerateWithAnd (NEA.cons' "foo" ["bar", "baz", "quux"]) `shouldEqual` "foo, bar, baz, and quux"
