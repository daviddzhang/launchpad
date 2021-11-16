module Test.Utils.NaturalOrder
  ( spec
  ) where

import Prelude

import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Utils.NaturalOrder (naturalOrderCompare)

spec :: Spec Unit
spec = do
  describe "naturalOrderCompare" do
    it "compares alpha strings case-insensitively" do
      naturalOrderCompare "abc" "bbc" `shouldEqual` LT
      naturalOrderCompare "aBc" "AbC" `shouldEqual` EQ
      naturalOrderCompare "abc" "BBC" `shouldEqual` LT

    it "compares numbers as suffixes" do
      naturalOrderCompare "abc1" "abc2" `shouldEqual` LT
      naturalOrderCompare "abc01" "abc2" `shouldEqual` LT
      naturalOrderCompare "abc12" "abc5" `shouldEqual` GT

    it "compares numbers as infixes" do
      naturalOrderCompare "abc002xyz" "abc2xyz" `shouldEqual` EQ
      naturalOrderCompare "abc002xyz" "abc2yyz" `shouldEqual` LT
      naturalOrderCompare "abc003xyz" "abc2yyz" `shouldEqual` GT

    it "compares numbers without any text" do
      naturalOrderCompare "002" "2" `shouldEqual` EQ
      naturalOrderCompare "002" "02" `shouldEqual` EQ
      naturalOrderCompare "003" "2" `shouldEqual` GT
      naturalOrderCompare "13" "5" `shouldEqual` GT
