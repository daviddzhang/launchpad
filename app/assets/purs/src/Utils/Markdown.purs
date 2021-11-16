-- | A (limited) Markdown parser.
-- |
-- | The parser currently supports customary "brushes" (sometimes called
-- | "styles" - e.g. bold, italic, etc.), links (both as naked URLs and as
-- | [text](http://url)), usernames (prefixed by @-sign), and newlines. There is
-- | no support for lists right now, but that should be easy to add as a
-- | separate kind of newline.
-- |
-- | This is almost a regular monadic parser, but with a twist: it runs in the
-- | `State` monad (i.e. it's a `ParserT State`), with the state being used to
-- | track the current stack of nested brushes, such that every time we
-- | encounter an asterisk, for example, we put a `Bold` brush on top of the
-- | stack, unless it's already there, in which case the asterisk is understood
-- | as the end of boldness, so the brush is taken off the stack. As multiple
-- | brushes may be nested (e.g. "plain, then *bold and _italic_*"), they are
-- | kept in a stack, and every time we parse out a piece of content (e.g. plain
-- | text, URL, etc.) we attach the current stack of brushes to it, indicating
-- | that it's "painted" with those brushes.
-- |
-- | Note that the resulting data types do not admit nesting of content - i.e.
-- | it's a plain sequence of content pieces. The possible nesting of brushes is
-- | instead attached to every piece of content separately, so that text like:
-- |
-- |     "plain, then *bold and _italic_*"
-- |
-- | would be parsed as:
-- |
-- |     [ Run [] (PlainText "plain, then")
-- |     , Run [Bold] (PlainText "bold and")
-- |     , Run [Italic, Bold] (PlainText "italic")
-- |     ]
-- |
-- | Note that the word "italic" is represented as a separate run, painted with
-- | both `Italic` and `Bold`, rather than being nested inside the "bold and"
-- | run.
-- |
-- | This was a conscious decision. Among the pros are a simpler parser
-- | structure, simpler types, simpler subsequent generation of HTML. Of the
-- | cons I only see one: double-mentioning of some brushes sometimes (e.g.
-- | `Bold` in the above example), but I think in practice even this con is not
-- | very relevant, since there is a small number of possible brushes, and in
-- | practice people rarely nest a lot of them anyway.
module Utils.Markdown
  ( Brush(..)
  , Content(..)
  , Line
  , Run(..)
  , Text
  , parse
  ) where

import Prelude

import Control.Alt ((<|>))
import Control.Alternative (guard)
import Control.Lazy (defer)
import Control.Monad.Rec.Class (class MonadRec, Step(..), tailRecM)
import Control.Monad.State (State, evalState, get, lift, modify)
import Data.Array (fromFoldable)
import Data.Either (Either)
import Data.Foldable (class Foldable)
import Data.Generic.Rep (class Generic)
import Data.List (List(..), catMaybes, reverse, someRec, (:))
import Data.List.NonEmpty as NEL
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Data.String.CodeUnits (fromCharArray)
import Text.Parsing.Parser (ParseError, ParserT, runParserT)
import Text.Parsing.Parser.Combinators (lookAhead, option, try)
import Text.Parsing.Parser.String (anyChar, eof, noneOf, oneOf, string)
import Text.Parsing.Parser.Token (alphaNum)

-- | A Markdown text - multiple lines.
type Text = Array Line

-- | A Markdown line (aka "paragraph") - multiple runs in sequence one after another.
type Line = Array Run

-- | A Markdown run - a piece of `Content`, optionally painted by one or more
-- | brushes. Note that the brushes are given as a `List`, since the content may
-- | be painted with multiple nested brushes, with the most inner brush being
-- | the head of the list.
data Run = Run (List Brush) Content

-- | Different types of elements a Markdown run may contain.
data Content
  = PlainText String
  | Link { text :: String, url :: String }
  | Username String

-- | A way to modify the appearance of a piece of content - "paint" it, so to say.
data Brush = Bold | Italic | Code

derive instance Eq Run
derive instance Generic Run _
instance Show Run where show = genericShow

derive instance Eq Brush
derive instance Generic Brush _
instance Show Brush where show = genericShow

derive instance Eq Content
derive instance Generic Content _
instance Show Content where show = genericShow

type Parser a = ParserT String (State (List Brush)) a

-- | Parses a brush, but in a pure way, in the sense that this function doesn't
-- | modify the state when it encounters the brush. This is because sometimes we
-- | need the pure function to use for `lookAhead`.
brush :: Parser Brush
brush = mk "*" Bold <|> mk "_" Italic <|> mk "`" Code
  where
    mk s b = string s $> b

-- | Doesn't actually do any parsing, but instead puts the given brush on the
-- | stack (if not there yet) or removes it from the stack (if already there).
-- | This function is separate from the pure parsing function `brush` because
-- | sometimes we need the pure function to use for `lookAhead`.
applyBrush :: forall a. Brush -> Parser (Maybe a)
applyBrush b = do
  void $ lift $ modify case _ of
    Cons top rest | top == b -> rest
    stack -> Cons b stack
  pure Nothing

-- | Naked URL
url :: Parser Content
url = do
  void $ string "http"
  s <- option "" $ string "s"
  void $ string "://"
  path <- someRec $ noneOf [' ', '\t', '\r', '\n', ',']
  let u = "http" <> s <> "://" <> str path
  pure $ Link { text: u, url: u }

-- | Link formatted as markdown - i.e. [text](http://url)
link :: Parser Content
link = do
  void $ string "["
  text <- manyTillRec anyChar (string "]") <#> str
  void $ string "("
  u <- manyTillRec anyChar (string ")") <#> str
  guard $ u /= ""
  pure $ Link { text, url: u }

username :: Parser Content
username = do
  void $ string "@"
  Username <$> str <$> someRec (alphaNum <|> oneOf ['_','-','.'])

nonPlainContent :: Parser Content
nonPlainContent = url <|> link <|> username

plainContent :: Parser Content
plainContent =
  many1TillRec anyChar (lookAhead (void nonPlainContent) <|> lookAhead (void brush) <|> endOfLine)
  <#> str >>> PlainText

run :: Parser Run
run = Run <$> lift get <*> (try nonPlainContent <|> plainContent)

line :: Parser Line
line = manyTillRec ((brush >>= applyBrush) <|> (Just <$> run)) endOfLine <#> catMaybes <#> fromFoldable

endOfLine :: Parser Unit
endOfLine = eof <|> lookAhead newline

newline :: Parser Unit
newline = void $ string "\r\n" <|> string "\r" <|> string "\n"

wholeText :: Parser Text
wholeText = line `sepEndByRec` newline <#> fromFoldable

str :: forall f. Foldable f => f Char -> String
str = fromCharArray <<< fromFoldable

parse :: String -> Either ParseError Text
parse input = evalState (runParserT input wholeText) Nil


-------------------------------------------------------------------------------
-- The following functions are stack-safe versions of some parser combinators
-- that I wrote myself. I will probably contribute them back to the parser
-- library, but until then they live here.
-------------------------------------------------------------------------------


-- | Stack-safe version of `sepEndBy` at the expense of `MonadRec` constraint
sepEndByRec :: forall m s a sep. MonadRec m => ParserT s m a -> ParserT s m sep -> ParserT s m (List a)
sepEndByRec p sep = map NEL.toList (sepEndBy1Rec p sep) <|> pure Nil

-- | Stack-safe version of `sepEndBy1` at the expense of `MonadRec` constraint
sepEndBy1Rec :: forall m s a sep. MonadRec m => ParserT s m a -> ParserT s m sep -> ParserT s m (NEL.NonEmptyList a)
sepEndBy1Rec p sep = do
  a <- p
  (NEL.cons' a <$> tailRecM go Nil) <|> pure (NEL.singleton a)
  where
    go :: List a -> ParserT s m (Step (List a) (List a))
    go acc =
      (sep *> p <#> \a -> Loop $ a : acc)
      <|> defer (\_ -> pure $ Done $ reverse acc)

-- | Stack-safe version of `manyTill` at the expense of `MonadRec` constraint
manyTillRec :: forall s a m e. MonadRec m => ParserT s m a -> ParserT s m e -> ParserT s m (List a)
manyTillRec p end = tailRecM go Nil
  where
    go :: List a -> ParserT s m (Step (List a) (List a))
    go acc =
      (end <#> \_ -> Done $ reverse acc)
      <|> (p <#> \x -> Loop $ x : acc)

-- | Stack-safe version of `many1Till` at the expense of `MonadRec` constraint
many1TillRec :: forall s a m e. MonadRec m => ParserT s m a -> ParserT s m e -> ParserT s m (NEL.NonEmptyList a)
many1TillRec p end = NEL.cons' <$> p <*> manyTillRec p end
