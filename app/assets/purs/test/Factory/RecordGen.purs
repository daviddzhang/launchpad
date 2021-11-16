module RecordGen where

import Prelude

import Data.Maybe (Maybe(..), fromJust)
import Data.Nullable (Nullable, notNull)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object, insert, lookup)
import Partial.Unsafe (unsafePartial)
import Prim.RowList (class RowToList, Cons, Nil, RowList)
import Prim.TypeError (class Fail, Beside, QuoteLabel, Text)
import Test.QuickCheck.Gen (Gen)
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

class RecordGen g r where
  -- | Turns a record of generators (from QuickCheck) into a generator of
  -- | records. It is used for generating props for UI components being tested
  -- | in automated tests.
  -- |
  -- | The parameter here is a record, where each field is either (1) a
  -- | generator `Gen a`, (2) a plain value `a`, or (3) a nested record with
  -- | same types of fields. The result is a generator `Gen r`, where `r` is a
  -- | record with all the same fields, but their types turned from generators
  -- | `Gen a` to plain values `a`.
  -- |
  -- | The types of both the input record and the resulting record have to be
  -- | known, neither of them can be inferred from the other, unfortunately:
  -- | that's a limitation of PureScript's row system. This comes into play when
  -- | using polymorphic generators as field values, such as `arbitrary` - they
  -- | need to be given an explicit type, see field `d.x` in the example below.
  -- |
  -- | Nullable fields are supported "transparently" - i.e. they don't have to
  -- | be explicitly wrapped as `Nullable` (see field `e` in the example below).
  -- | Such generators will always generate non-null values. If you need to
  -- | include null values, use the `nullable` combinator from
  -- | `Test.Factory.Combinators`.
  -- |
  -- | Example:
  -- |
  -- |     type Props =
  -- |       { a :: String
  -- |       , b :: Int
  -- |       , c :: String
  -- |       , d :: { x :: Boolean, y :: Int }
  -- |       , e :: Nullable Int
  -- |       }
  -- |
  -- |     propsGen :: Gen Props
  -- |     propsGen = genRecord
  -- |       { a: elements $ "foo" `cons'` ["bar", "baz"]
  -- |       , b: 42
  -- |       , c: "I'm a constant string"
  -- |       , d: { x: (arbitrary :: Gen Boolean), y: chooseInt 0 100 }
  -- |       , e: chooseInt 0 5
  -- |       }
  -- |
  -- |     main = do
  -- |       logShow =<< randomSampleOne propsGen
  -- |       logShow =<< randomSampleOne propsGen
  -- |
  -- | Output:
  -- |
  -- |     { a: "baz", b: 42, c: "I'm a constant string", d: { x: false, y: 88 }, e: 3 }
  -- |     { a: "foo", b: 42, c: "I'm a constant string", d: { x: false, y: 83 }, e: 2 }
  -- |
  genRecord :: { | g } -> Gen { | r }
instance rgen :: (RowToList g gl, RowToList r rl, RowListRecordGen gl rl) => RecordGen g r where
  genRecord g = unsafeCoerce <$> rlGenRecord (Proxy :: Proxy gl) (Proxy :: Proxy rl) (unsafeCoerce g)

class PropGen a b where
  genProp :: a -> Gen b
instance PropGen a a where
  genProp = pure
else instance RecordGen a b => PropGen (Record a) (Record b) where
  genProp = genRecord
else instance PropGen (Gen a) a where
  genProp = identity
else instance PropGen a b => PropGen a (Nullable b) where
  genProp = map notNull <<< genProp
else instance PropGen a b => PropGen a (Maybe b) where
  genProp = map Just <<< genProp

infixr 2 type Beside as <>

class RowListRecordGen (gl :: RowList Type) (rl :: RowList Type) where
  rlGenRecord :: Proxy gl -> Proxy rl -> Object Foreign -> Gen (Object Foreign)

instance rlgNil :: RowListRecordGen Nil Nil where
  rlGenRecord _ _ = pure

else instance rlgCons ::
  ( IsSymbol name
  , RowListRecordGen glTail rlTail
  , PropGen a b
  )
  => RowListRecordGen (Cons name a glTail) (Cons name b rlTail)
  where
    rlGenRecord _ _ g = do
      let gField :: a
          gField = unsafeCoerce $ unsafePartial $ fromJust $ lookup fieldName g
      rField :: b <- genProp gField
      g' <- rlGenRecord (Proxy :: Proxy glTail) (Proxy :: Proxy rlTail) g
      pure $ insert fieldName (unsafeToForeign rField) g'
      where
        fieldName = reflectSymbol (Proxy :: Proxy name)

else instance rlgErrorMissing ::
  Fail (Text "Generator record is missing a field: " <> QuoteLabel name)
  => RowListRecordGen Nil (Cons name a tail)
  where
    rlGenRecord _ _ = pure

else instance rlgErrorExtra ::
  Fail (Text "Generator record has an extra field: " <> QuoteLabel name)
  => RowListRecordGen (Cons name a tail) Nil
  where
    rlGenRecord _ _ = pure

else instance rlgErrorMismatch ::
  Fail (
    Text "Different fields between generator and expected type: "
      <> QuoteLabel name1
      <> Text " vs. "
      <> QuoteLabel name2
  )
  => RowListRecordGen (Cons name1 a gTail) (Cons name2 b rTail)
  where
    rlGenRecord _ _ = pure
