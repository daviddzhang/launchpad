module Test.Utils.Format
  ( spec
  ) where

import Prelude

import Data.Maybe (fromJust)
import Partial.Unsafe (unsafePartial)
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Utils.DateTime (parseAsLocalTime)
import Utils.Format (durationString, timeDiff, timeDiffLongFormat, timeDiffShortFormat)

spec :: Spec Unit
spec = do
  describe "Utils.Format.timeDiff" do
    describe "log format" do
      run longFormat "2021-01-01 12:00" "just now"
      run longFormat "2021-01-01 12:00:29" "just now"
      run longFormat "2021-01-01 12:01" "a minute ago"
      run longFormat "2021-01-01 12:07" "7 minutes ago"
      run longFormat "2021-01-01 12:45" "45 minutes ago"
      run longFormat "2021-01-01 12:57" "an hour ago"
      run longFormat "2021-01-01 13:28" "an hour ago"
      run longFormat "2021-01-01 13:31" "2 hours ago"
      run longFormat "2021-01-02 05:31" "18 hours ago"
      run longFormat "2021-01-02 11:31" "a day ago"
      run longFormat "2021-01-03 00:01" "2 days ago"
      run longFormat "2021-01-04 12:00" "3 days ago"
      run longFormat "2021-01-21 12:00" "20 days ago"
      run longFormat "2021-02-05 12:00" "a month ago"
      run longFormat "2021-03-20 12:00" "2 months ago"
      run longFormat "2021-05-07 12:00" "4 months ago"
      run longFormat "2021-09-03 12:00" "8 months ago"
      run longFormat "2021-12-20 12:00" "11 months ago"
      run longFormat "2022-01-01 05:00" "a year ago"
      run longFormat "2022-05-21 12:00" "a year ago"
      run longFormat "2022-07-21 12:00" "2 years ago"
      run longFormat "2024-09-11 12:00" "4 years ago"

    describe "short format" do
      run shortFormat "2021-01-01 12:00" "now"
      run shortFormat "2021-01-01 12:00:29" "now"
      run shortFormat "2021-01-01 12:01" "1m"
      run shortFormat "2021-01-01 12:07" "7m"
      run shortFormat "2021-01-01 12:45" "45m"
      run shortFormat "2021-01-01 12:57" "1h"
      run shortFormat "2021-01-01 13:28" "1h"
      run shortFormat "2021-01-01 13:31" "2h"
      run shortFormat "2021-01-02 05:31" "18h"
      run shortFormat "2021-01-02 11:31" "1d"
      run shortFormat "2021-01-03 00:01" "2d"
      run shortFormat "2021-01-04 12:00" "3d"
      run shortFormat "2021-01-21 12:00" "20d"
      run shortFormat "2021-02-05 12:00" "35d"
      run shortFormat "2021-09-03 12:00" "245d"
      run shortFormat "2021-12-07 12:00" "340d"
      run shortFormat "2021-12-08 12:00" "1y"
      run shortFormat "2022-01-19 05:00" "1y"
      run shortFormat "2022-05-21 12:00" "1y"
      run shortFormat "2022-07-21 12:00" "2y"
      run shortFormat "2024-09-11 12:00" "4y"

  describe "Utils.Format.durationString" do
    it "creates correct duration string" do
      durationString 85 `shouldEqual` "1:25"
      durationString 10 `shouldEqual` "0:10"
      durationString 120 `shouldEqual` "2:00"
      durationString 0 `shouldEqual` "0:00"

  where
    startTime = unsafePartial $ fromJust $ parseAsLocalTime "2021-01-01 12:00:00"

    run format to expected = unsafePartial $
      it (to <> " --> " <> expected) $
        timeDiff { from: startTime, to: fromJust $ parseAsLocalTime to, format }
          `shouldEqual` expected

    longFormat = timeDiffLongFormat "ago"
    shortFormat = timeDiffShortFormat
