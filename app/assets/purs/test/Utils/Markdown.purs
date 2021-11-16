module Test.Utils.Markdown
  ( spec
  ) where

import Prelude

import Data.Either (Either(..))
import Data.List (fromFoldable)
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Utils.Markdown (Brush(..), Content(..), Run(..), parse)

spec :: Spec Unit
spec = do
  describe "Utils.Markdown.parse" do
    it "parses basic markdown" do
      let text =
            "plain then *bold* then _italic_ then _italic " <>
            "with *nested bold* and_ then [a link](foo) and " <>
            "naked http://foo.bar/baz.html"
          result =
            [ run "plain then " []
            , run "bold" [Bold]
            , run " then " []
            , run "italic" [Italic]
            , run " then " []
            , run "italic with " [Italic]
            , run "nested bold" [Bold, Italic]
            , run " and" [Italic]
            , run " then " []
            , run' (Link { text: "a link", url: "foo" }) []
            , run " and naked " []
            , run' (Link { text: "http://foo.bar/baz.html", url: "http://foo.bar/baz.html" }) []
            ]
      parse text `shouldEqual` Right [result]

    it "tolerates unbalanced/unclosed brushes" do
      parse "foo *bar" `shouldEqual`
        Right [[run "foo " [], run "bar" [Bold]]]
      parse "*foo _bar*" `shouldEqual`
        Right [[run "foo " [Bold], run "bar" [Italic, Bold]]]

    it "parses multiple lines" do
      parse "foo\nxy*bar\nb_a_*z" `shouldEqual`
        Right
          [ [ run "foo" [] ]
          , [ run "xy" [], run "bar" [Bold] ]
          , [ run "b" [Bold], run "a" [Italic, Bold], run "z" [] ]
          ]

    describe "tolerates malformed/incomplete markdown" do
      it "malformed links" do
        parse "[foo]" `shouldEqual` Right [[ run "[foo]" [] ]]
        parse "[foo](bar" `shouldEqual` Right [[ run "[foo](bar" [] ]]
        parse "[foo]()" `shouldEqual` Right [[ run "[foo]()" [] ]]

      it "empty usernames" do
        parse "@ foobar" `shouldEqual` Right [[ run "@ foobar" [] ]]

      it "empty URLs" do
        parse "http" `shouldEqual` Right [[ run "http" [] ]]
        parse "http://" `shouldEqual` Right [[ run "http://" [] ]]
        parse "https://" `shouldEqual` Right [[ run "https://" [] ]]

    where
      run' content brushes = Run (fromFoldable brushes) content
      run = run' <<< PlainText
