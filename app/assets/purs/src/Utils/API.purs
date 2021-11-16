module Utils.API
  ( Endpoint
  , class ApiFunction, numParameters
  , apiEndpoint
  , get
  , delete
  , post
  , unsafeGetEndpoint

  , ignoreResponse
  , parseResponse
  , tryParseForeign
  , tryReadForeign
  ) where

import Prelude

import Affjax (Error(..), Response)
import Affjax as Affjax
import Affjax.RequestBody (RequestBody)
import Affjax.RequestBody as Req
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as Resp
import Affjax.StatusCode (StatusCode(..))
import Data.Argonaut.Core (Json)
import Data.Either (Either(..), either)
import Data.Foldable (notElem)
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Nullable as N
import Effect (Effect)
import Effect.Aff (Aff, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Elmish.Foreign (class CanReceiveFromJavaScript, readForeign, showForeign)
import Foreign (Foreign, unsafeToForeign)
import Prim.TypeError (class Fail, Text)
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

newtype Endpoint = Endpoint (N.Nullable { path :: String, token :: String })

-- | A specialization of `apiEndpoint` to the `POST` method
post :: forall a body. ApiFunction a => String -> (({ | body } -> Aff (Either Error Foreign)) -> a) -> a
post name f = apiEndpoint POST name \call -> f (call <<< Just)

-- | A specialization of `apiEndpoint` to the `DELETE` method
delete :: forall a body. ApiFunction a => String -> (({ | body } -> Aff (Either Error Foreign)) -> a) -> a
delete name f = apiEndpoint DELETE name \call -> f (call <<< Just)

-- | A specialization of `apiEndpoint` to the `GET` method
get :: forall a. ApiFunction a => String -> (Aff (Either Error Foreign) -> a) -> a
get name f = apiEndpoint GET name \call -> f (call Nothing)


-- | Represents a function that makes a server API call. The only restriction on
-- | such functions is that the ultimate result must be `Aff`.
--
-- A secondary purpose of this class is to count the number of parameters of the
-- function in question, which is required for our test mocking mechanism. Yes,
-- this is totally test-induced damage, but I think it's worth the return.
class ApiFunction (f :: Type) where
  -- | An internal implementation detail of `Utils.API`. Do not use or implement directly.
  numParameters :: Proxy f -> Int

instance ApiFunction (Aff a) where numParameters _ = 0
else instance ApiFunction b => ApiFunction (a -> b) where numParameters _ = 1 + numParameters (Proxy :: _ b)
else instance Fail (Text "An API function must return Aff") => ApiFunction x where numParameters _ = 0


-- | Makes an XHR JSON request to the given endpoint with given body and method.
-- | The endpoint can be obtained from the `apiEndpoint` function. See comments
-- | there.
apiRequest :: forall body. Endpoint -> Method -> Maybe { | body } -> Aff (Either Error Foreign)
apiRequest (Endpoint endpoint) = case N.toMaybe endpoint of
  Just ep -> apiRequestImpl ep
  Nothing -> \_ _ -> pure $ Left $ XHROtherError $ error "Missing client-side endpoint"

-- | Obtains an endpoint path by name and runs the given continuation with it.
-- | Endpoint names are Ruby routes, e.g. `schools_search_path`. They need to be
-- | preloaded into the rendered page from the server side by calling the
-- | `client_side_endpoints` method:
-- |
-- |     class FooController < ApplicationController
-- |       def purs_powered_page
-- |         client_side_endpoints(
-- |           :foo_bar_path,
-- |           :schools_search_path
-- |         )
-- |       end
-- |     end
-- |
-- | and the PureScript side can then expose an API function like this:
-- |
-- |     module Foo.API where
-- |     import Utils.API as API
-- |
-- |     searchSchools :: String -> Aff (Array School)
-- |     searchSchools = API.post "schools_search_path" \call searchTerm ->
-- |       call { term: searchTerm }
-- |
-- | Note that `apiEndpoint` here is called at top level rather than inside the
-- | function body. This is done on purpose: this way all `apiEndpoint` calls
-- | will happen at the time of JS bundle load, and we will be able to verify
-- | presence of all endpoint paths early.
-- |
-- | If the endpoint is found missing (i.e. the server did not preload it), we
-- | will notify Sentry (in production) or display a big red error (in dev and
-- | test). This logic and its explanation is located in
-- | `views/layouts/javascript/_client_api_endpoints.haml`
-- |
-- | These endpoints are also conveniently mockable via facilities in
-- | `Test.Utils.API`.
-- |
apiEndpoint :: forall body a. ApiFunction a => Method -> String -> ((Maybe { | body } -> Aff (Either Error Foreign)) -> a) -> a
apiEndpoint mthd name f =
  apiEndpoint_
    { delegateAff: join <<< liftEffect -- See comments on `apiEndpoint_`
    , numParameters: numParameters (Proxy :: _ a)
    , name
    , continuation: \endpoint -> f $ apiRequest endpoint mthd
    }

-- | A lower-level function to be used in extreme rare circumstances where the
-- | consumer actually needs to know the path and the authentication token,
-- | rather than just make a server request. One example of this is the login
-- | buttons, which have to work via a server POST, and therefore have to be
-- | implemented as an HTML form.
-- |
-- | Normal API functions should use the `post`, `get`, and `delete` functions
-- | instead.
unsafeGetEndpoint :: String -> Maybe { path :: String, token :: String }
unsafeGetEndpoint name = let (Endpoint ep) = pathInfo_ name in N.toMaybe ep

apiRequestImpl :: forall body.
  { path :: String, token :: String }
  -> Method
  -> Maybe { | body }
  -> Aff (Either Error Foreign)
apiRequestImpl { path, token } method mBody = do
  res <- Affjax.request Affjax.defaultRequest
    { method = Left method
    , url = path
    , responseFormat = Resp.json
    , content = bodyAsJson <$> mBody
    , headers = [ RequestHeader "X-CSRF-Token" token ]
    }
  pure $ res >>= \r ->
    -- Turns out, Affjax doesn't report some error codes as errors. One example
    -- I discovered is 403. So we turn non-200 codes into errors here. 200
    -- should be enough for us for now, and we can always generalize this logic
    -- later.
    if r.status `notElem` [StatusCode 200, StatusCode 201, StatusCode 204]
      then Left $ XHROtherError $ error $ show r.status
      else Right $ responseBody r
  where
    bodyAsJson :: { | body } -> RequestBody
    bodyAsJson = Req.json <<< unsafeCoerce

    responseBody :: Response Json -> Foreign
    responseBody r = unsafeToForeign r.body

-- | Attempts to parse a given foreign value using the specified parser function
-- | and throws an Aff exception if unsuccessful. This function is meant to be
-- | used as the first parameter of `parseResponse`.
tryParseForeign :: forall a b. CanReceiveFromJavaScript a => String -> Foreign -> (a -> Maybe b) -> Aff b
tryParseForeign name f parse = case parse =<< readForeign f of
  Just p -> pure p
  Nothing -> throwError $ error $ "Unparseable " <> name <> ": " <> showForeign f

-- | Attempts to parse a given foreign value and throws an Aff exception if
-- | unsuccessful. This function is meant to be used as the first parameter of
-- | `parseResponse`.
tryReadForeign :: forall a. CanReceiveFromJavaScript a => String -> Foreign -> Aff a
tryReadForeign name f = tryParseForeign name f Just

-- | Given an Affjax response (which is an `Either` value), throws if it's an
-- | error, and attempts to parse it if it's a success using the given parsing
-- | function. The parsing function is expected to also throw an exception if
-- | unsuccessful. This way any failure along the way is turned into an
-- | exception for the consumer to catch and report to an error reporting
-- | service.
parseResponse :: forall a. (Foreign -> Aff a) -> Either Affjax.Error Foreign -> Aff a
parseResponse parse = either (throwError <<< error <<< Affjax.printError) parse

-- | Throws away a response from an Affjax request, but throws an Aff error if
-- | the request was unsuccessful.
ignoreResponse :: Either Affjax.Error Foreign -> Aff Unit
ignoreResponse = parseResponse $ const $ pure unit


foreign import pathInfo_ :: String -> Endpoint

foreign import apiEndpoint_ :: forall a.
  { delegateAff :: forall x. Effect (Aff x) -> Aff x
  -- ^ A function that can "unwrap" an Aff from an Effect. This is only
  -- necessary for testing and is used by the JS side of the API mocking
  -- mechanism to call the mock function and return its result. JS code cannot
  -- create an Aff on its own, it needs help from PS side.

  , numParameters :: Int
  -- ^ Number of parameters that the resulting function has. This is only
  -- necessary for testing and is used by the JS side of the API mocking
  -- mechanism to produce a curried function with the right number of
  -- parameters.

  , name :: String
  -- ^ Name of the API endpoint Rails route, such as `schools_lists_add_path`

  , continuation :: Endpoint -> a
  -- ^ A function that takes an endpoint info and returns another function that
  -- (possibly) takes some more parameters and ultimately produces an Aff. This
  -- function is represented here as just `a` because we don't know how many
  -- parameters it takes, so we don't know its exact type.
  }
  -> a
