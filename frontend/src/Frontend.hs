{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE TypeApplications #-}
module Frontend (frontend) where

import Common.Route
import Data.Dependent.Sum (DSum(..))
import Frontend.Head
import Frontend.Nav
import Frontend.Footer
import Frontend.Page.Documentation
import Frontend.Page.Examples
import Frontend.Page.Faq
import Frontend.Page.Home
import Frontend.Page.Talks
import Frontend.Page.Tutorials
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Reflex.Dom.Core

frontend :: Frontend (R Route)
frontend = Frontend
  { _frontend_head = pageHead
  , _frontend_body = do
      -- The recursion here allows us to send a click event from the content area "up" into the header
      rec el "header" $ nav click
          click <- mainContainer $ do
            article $ subRoute_ $ \case
              Route_Home -> home
              Route_Talks -> talks
              Route_Tutorials -> tutorials
              Route_Examples -> examples
              Route_Documentation -> documentation
              Route_FAQ -> faq
          el "footer" footer
      return ()
  }

-- | The @<main>@ tag that will contain most of the site's content
mainContainer :: DomBuilder t m => m () -> m (Event t ())
mainContainer w = domEvent Click . fst <$> el' "main" w

-- | An @<article>@ tag that will set its title and the class of its child
-- @<section>@ based on the current route
article
  :: ( DomBuilder t m
     , Routed t (R Route) m
     , PostBuild t m
     )
  => m () -- ^ Article content widget
  -> m ()
article c = el "article" $ do
  r <- askRoute
  el "h3" $ dynText $ routeDescription <$> r
  let sectionClass = ffor r $ ("class" =:) . \(r' :=> _) -> case r' of
        Route_Home -> "home"
        Route_Talks -> "talks"
        Route_Tutorials -> "tutorials"
        Route_Examples -> "examples"
        Route_Documentation -> "documentation"
        Route_FAQ -> "faq"
  elDynAttr "section" sectionClass c
