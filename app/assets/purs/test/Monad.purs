module Test.Monad
  ( Spec
  , Spec'
  , TestM
  , runSpec
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), launchAff_)
import Effect.Class.Console (log)
import Random.LCG (randomSeed)
import Test.Cleanup (CleanupT, specWithCleanup)
import Test.QuickCheck.Gen (Gen, evalGen)
import Test.Spec as S
import Test.Spec.Reporter (specReporter)
import Test.Spec.Runner (defaultConfig, runSpecT)

-- | See comments on `Spec`
type Spec' m i a = S.SpecT m i TestM a

-- | Unlike the standard `Spec` from `Test.Spec`, this type allows for
-- | generation of random values (via `MonadGen`) while constructing the test
-- | tree. This means that you can use generators right in the body of
-- | `describe`, for example:
-- |
-- |     import Test.Monad (Spec)
-- |     import Test.Enzyme.EnzymeM as EM
-- |
-- |     spec :: Spec
-- |     spec = describe "my UI" do
-- |       n <- lift $ chooseInt 5 10
-- |
-- |       let def = myComponentDef { numButtons: n }
-- |
-- |       it "shows the requested number of buttons" do
-- |         EM.testComponent def do
-- |           buttons <- EM.findAll "button"
-- |           length buttons `shouldEqual` n
-- |
-- | This makes for an experience very similar to RSpec's `let`/`let!`
-- | functions. The difference is that RSpec reruns the `let` functions afresh
-- | for every single test, while here the values are only calculated once, at
-- | the time of test tree generation, and reused for every test. I think this
-- | matches the majority of our use cases anyway, but if you need to regenerate
-- | fresh values for every test, that's still possible with good old
-- | `Test.Spec.before`.
-- |
-- | All of this makes the `spec` binding in the above example not a spec, but a
-- | _generator_ of specs, able to yield a spec when given a random seed. The
-- | `runSpec` function in this module does just that: generates a random seed,
-- | then uses it to generate a spec, then runs that spec.
type Spec a = Spec' (CleanupT Aff) Unit a

-- | The monad in which the test tree construction happens. See comments on
-- | `Spec` for more.
--
-- Note that this type is currently just a synonym for `Gen`, so that we can use
-- generators while constructing the test tree, but in the future we may make it
-- a monad stack including `Gen` and `Effect` (or `Aff`?) to allow for creation
-- of mutable cells in the same way. I'm not sure I want to do this yet though:
-- there are concerns with mutable cells, such as paralellization and reuse
-- across examples.
type TestM = Gen

runSpec :: Spec Unit -> Effect Unit
runSpec spec = do
  let (genSpec :: TestM _) =
        spec
        # specWithCleanup
        # runSpecT (defaultConfig { timeout = Just $ Milliseconds 10_000.0 }) [specReporter]
  seed <- randomSeed
  log $ "Using random seed " <> show seed
  let run = evalGen genSpec { newSeed: seed, size: 10 }
  launchAff_ run
