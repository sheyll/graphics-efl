import Graphics.Efl.Simple


main :: IO ()
main = do
   initWindowingSystem
   engines <- getEngines
   putStrLn (show engines)

   withDefaultWindow (Just "opengl_x11") $ \ win canvas -> do
      engineName <- getEngineName win
      putStrLn $ "Using engine " ++ engineName

      setWindowTitle "Simple Haskell-EFL Example" win

      bg <- addRectangle canvas
            |> setColor 0 0 0 255
            |> setLayer (-1)
            |> uncover

      onWindowResize win $ do
         (_,_,w,h) <- getWindowGeometry win
         resize w h bg

      let clickHandler obj ev = do
            name <- getName obj
            btn <- mouseDownButton ev
            putStrLn $ "You clicked on " ++ name ++ " with button " ++ show btn

      r <- addRectangle canvas
            |> setName "First rectangle"
            |> resize 100 40
            |> move 20 40
            |> setColor 255 0 0 255
            |> uncover
            |> onMouseDown clickHandler
            |> onMouseMove (\_ _ -> putStrLn "Move!")

      r2 <- addRectangle canvas
            |> setName "Second rectangle"
            |> resize 100 40
            |> move 100 100
            |> setColor 128 128 0 255
            |> uncover
            |> onMouseIn (\_ ev -> do
                  wxy <- mouseInWorldXY ev
                  cxy <- mouseInCanvasXY ev
                  t <- mouseInTimestamp ev
                  putStrLn (show wxy ++ ";" ++ show cxy ++ ";" ++ show t))
            |> onMouseDown clickHandler
            |> onMouseOut (\ _ _-> putStrLn "Out!")
            |> onMouseUp (\ _ _-> putStrLn "Up!")
            |> onMouseWheel (\ _ _-> putStrLn "Wheel!")

      po <- addPolygon canvas
            |> addPolygonPoints [(-5,0),(0,5),(5,0),(0,-5)]
            |> setColor 128 128 128 255
            |> move 200 200
            |> uncover

      _ <- addText canvas
            |> setText "Haskell-EFL!!"
            |> resize 200 10
            |> move 25 50
            |> setTextStyle TextStylePlain TextStyleShadowDirectionBottomRight
            |> setTextFont "DejaVu" 14
            |> setColor 0 255 0 255
            |> uncover

      _ <- addTextBlock canvas
            |> setTextBlockTextMarkup "Yo !!!!"
            |> resize 400 400
            |> move 10 150
            |> setColor 255 255 255 255
            |> uncover

      let center o = do
            (x,y,w,h) <- getGeometry o
            return (w `div` 2 + x, h `div` 2 + y)
            

      --setAnimatorFrameRate 4

      (cx,cy) <- center r

      addAnimationLinear' 1.0 Nothing $ \step -> do
         m <- createMap 4
               |> populateMapPointsFromObject r
               |> rotateMap (360.0 * step) cx cy
         setMap m r
         enableMap r

      addAnimationLinear' 4.0 Nothing $ \step -> do
         (cx',cy') <- center r2
         m <- createMap 4
               |> populateMapPointsFromObject r2
               |> rotateMap (360.0 * step) cx' cy'
         setMap m r2
         enableMap r2

      addAnimationLinear' 3.0 (Just 1) $ \step -> do
         let x' = (100+(floor $ step * 200))
         move x' 100 r2

      addAnimationBounce' 4 Nothing $ \step -> do
         let x' = (100+(floor $ step * 400))
         (_,y,_,_) <- getGeometry po
         move x' y po

      addAnimationSinusoidal' 6 8.0 Nothing $ \step -> do
         let y' = (200+(floor $ step * 100))
         (x,_,_,_) <- getGeometry po
         move x y' po


      return ()
