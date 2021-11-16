-- | This module is just a (partial) copy of `Control.Promise` from
-- | `purescript-aff-promise` with the sole change in the `coerceError`
-- | function, making it also recognize objects descended from `Error`, not only
-- | `Error` itself.
module Utils.Promise
  ( Promise
  , fromAff
  , toAff
  ) where

import Prelude

import Control.Alt ((<|>))
import Control.Monad.Except (runExcept)
import Data.Either (Either(..), either)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, runAff_)
import Effect.Exception (Error, error)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Foreign (Foreign, ForeignError(..), fail, readString, unsafeReadTagged)
import Unsafe.Coerce (unsafeCoerce)

-- | Type of JavaScript Promises (with particular return type)
foreign import data Promise :: Type -> Type

foreign import promise :: forall a b.
  ((a -> Effect Unit) -> (b -> Effect Unit) -> Effect Unit) -> Effect (Promise a)
foreign import thenImpl :: forall a b.
  Promise a -> (EffectFn1 Foreign b) -> (EffectFn1 a b) -> Effect Unit
foreign import isError :: Foreign -> Boolean
foreign import safeToString :: Foreign -> String

-- | Convert an Aff into a Promise.
fromAff :: forall a. Aff a -> Effect (Promise a)
fromAff aff = promise (\succ err -> runAff_ (either err succ) aff)

coerceError :: Foreign -> Error
coerceError e =
  either
    -- If we couldn't parse the given value as an error at all, at least we
    -- would report _sometimg_ by `.toString`-ing it.
    (\_ -> error $ "Promise failed: " <> safeToString e)
    identity
    -- To parse the error, we first try to recognize it as an object of class
    -- `Error` or a descendant of it, but if that doesn't work, we fall back to
    -- checking the value's tag or try to recognize it as a string. We have to
    -- do the first try, rather than just relying on checking the tag, because
    -- checking the tag wouldn't work for classes descendant from `Error`
    (runExcept ((readError e) <|> (unsafeReadTagged "Error" e) <|> (error <$> readString e)))
  where
    readError x
      | isError x = pure $ unsafeCoerce x
      | otherwise = fail $ ForeignError ""

-- | Convert a Promise into an Aff.
-- | When the promise rejects, we attempt to
-- | coerce the error value into an actual JavaScript Error object. We can do this
-- | with Error objects or Strings. Anything else gets a "dummy" Error object.
toAff :: forall a. Promise a -> Aff a
toAff p = makeAff
  (\cb -> mempty <$ thenImpl
    p
    (mkEffectFn1 $ cb <<< Left <<< coerceError)
    (mkEffectFn1 $ cb <<< Right))
