-- | This module is a general-purpose (but with intent to use in tests) support
-- | for running various effectful stuff, some of which may want to cleanup
-- | after itself after the whole running is done. The motivating example is
-- | mocking APIs in our tests: the mocking function does some effectful
-- | monkey-patching, and it has to be undone after the test has finished
-- | running.
-- |
-- | To achieve this, the computation runs under a special monad transformer
-- | `CleanupT`, which is nothing more than a `WriterT` collecting a list of
-- | "cleanup actions". While the computation is running, it may add to the list
-- | by calling the `cleanupAction` function, and after the computation is
-- | complete, all cleanup actions are run in reverse.
module Test.Cleanup
  ( CleanupT
  , class MonadCleanup, cleanupAction
  , runWithCleanup
  , specWithCleanup
  ) where

import Prelude

import Control.Monad.Writer (WriterT, runWriterT, tell)
import Data.Array (reverse)
import Data.Foldable (for_)
import Data.Tuple (Tuple(..))
import Effect.Aff (Milliseconds(..), delay)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect)
import Test.Spec (SpecT, hoistSpec)

-- | Monad for computations that may require transparent accumulation of cleanup
-- | actions to be run after the computation is finished.
type CleanupT m = WriterT (Array (m Unit)) m

-- | Monad for computations that may require transparent accumulation of cleanup
-- | actions to be run after the computation is finished.
class Monad m <= MonadCleanup m where
  -- | Adds a cleanup action to the list of cleanup actions accumulated for the
  -- | current computation.
  cleanupAction :: m Unit -> CleanupT m Unit

instance MonadEffect m => MonadCleanup m where
  cleanupAction f = tell [f]

-- | Transforms a test tree where each test potentially requires cleanup (i.e.
-- | runs inside `CleanupT`) into a "regular" computation, by wrapping each test
-- | in `runWithCleanup`.
specWithCleanup :: forall m g i a. MonadAff g => Monad m => SpecT (CleanupT g) i m a -> SpecT g i m a
specWithCleanup = hoistSpec identity (\_ -> runWithCleanup)

runWithCleanup :: forall m a. MonadAff m => CleanupT m a -> m a
runWithCleanup f = do
  Tuple res cleanupActions <- runWriterT f
  liftAff $ delay $ Milliseconds 0.0  -- allow async stuff to finish running
  for_ (reverse cleanupActions) \a -> a
  pure res
