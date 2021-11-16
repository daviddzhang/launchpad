module Test.Factory.Lorem
  ( paragraph
  , phrase
  , properNoun
  , sentence
  , sentences
  , title
  , word
  , words
  ) where

import Prelude

import Control.Monad.Gen (chooseInt, elements)
import Data.Array.NonEmpty as NEA
import Data.CodePoint.Unicode (toUpper)
import Data.Foldable (intercalate)
import Data.Maybe (Maybe(..))
import Data.String (fromCodePointArray, uncons)
import Test.QuickCheck.Gen (Gen, vectorOf)

paragraph :: Gen String
paragraph =
  intercalate " " <$> (sentences =<< chooseInt 2 5)

sentences :: Int -> Gen (Array String)
sentences n =
  vectorOf n sentence

sentence :: Gen String
sentence =
  (phrase =<< chooseInt 3 10)
    <#> capitalize
    <#> (_ <> ".")

title :: Gen String
title =
  intercalate " " <<< map capitalize <$> (words =<< chooseInt 1 3)

properNoun :: Gen String
properNoun =
  capitalize <$> word

phrase :: Int -> Gen String
phrase n =
  intercalate " " <$> words n

words :: Int -> Gen (Array String)
words n =
  vectorOf n word

word :: Gen String
word = elements $ NEA.cons' "lorem"
  [ "ipsum", "dolor", "sit", "amet", "consectetur"
  , "adipiscing", "elit", "curabitur", "vel", "hendrerit", "libero"
  , "eleifend", "blandit", "nunc", "ornare", "odio", "ut"
  , "orci", "gravida", "imperdiet", "nullam", "purus", "lacinia"
  , "a", "pretium", "quis", "congue", "praesent", "sagittis"
  , "laoreet", "auctor", "mauris", "non", "velit", "eros"
  , "dictum", "proin", "accumsan", "sapien", "nec", "massa"
  , "volutpat", "venenatis", "sed", "eu", "molestie", "lacus"
  , "quisque", "porttitor", "ligula", "dui", "mollis", "tempus"
  , "at", "magna", "vestibulum", "turpis", "ac", "diam"
  , "tincidunt", "id", "condimentum", "enim", "sodales", "in"
  , "hac", "habitasse", "platea", "dictumst", "aenean", "neque"
  , "fusce", "augue", "leo", "eget", "semper", "mattis"
  , "tortor", "scelerisque", "nulla", "interdum", "tellus", "malesuada"
  , "rhoncus", "porta", "sem", "aliquet", "et", "nam"
  , "suspendisse", "potenti", "vivamus", "luctus", "fringilla", "erat"
  , "donec", "justo", "vehicula", "ultricies", "varius", "ante"
  , "primis", "faucibus", "ultrices", "posuere", "cubilia", "curae"
  , "etiam", "cursus", "aliquam", "quam", "dapibus", "nisl"
  , "feugiat", "egestas", "class", "aptent", "taciti", "sociosqu"
  , "ad", "litora", "torquent", "per", "conubia", "nostra"
  , "inceptos", "himenaeos", "phasellus", "nibh", "pulvinar", "vitae"
  , "urna", "iaculis", "lobortis", "nisi", "viverra", "arcu"
  , "morbi", "pellentesque", "metus", "commodo", "ut", "facilisis"
  , "felis", "tristique", "ullamcorper", "placerat", "aenean", "convallis"
  , "sollicitudin", "integer", "rutrum", "duis", "est", "etiam"
  , "bibendum", "donec", "pharetra", "vulputate", "maecenas", "mi"
  , "fermentum", "consequat", "suscipit", "aliquam", "habitant", "senectus"
  , "netus", "fames", "quisque", "euismod", "curabitur", "lectus"
  , "elementum", "tempor", "risus", "cras"
  ]

capitalize :: String -> String
capitalize str = case uncons str of
  Nothing -> ""
  Just { head, tail } -> fromCodePointArray (toUpper head) <> tail
