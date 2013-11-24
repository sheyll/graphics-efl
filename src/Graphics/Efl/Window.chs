{-# Language ForeignFunctionInterface #-}

-- | EFL windowing system
module Graphics.Efl.Window (
   Window,
   initWindowingSystem, shutdownWindowingSystem,
   isEngineSupported, getEngines, getEngineName,
   createWindow, destroyWindow, showWindow,
   setWindowTitle, getWindowTitle,
   getWindowCanvas, getWindowGeometry, setWindowGeometry,
   resizeWindow,moveWindow,
   onWindowResize, onWindowResizeEx
) where

import Foreign.Ptr
import Foreign.C.String
import Foreign.C.Types
import Foreign.Marshal.Alloc
import Data.Maybe
import Control.Applicative
import Control.Monad

import Graphics.Efl.Canvas
import Graphics.Efl.Helpers
import Graphics.Efl.Window.Types
import Graphics.Efl.Eina

#include <Ecore_Evas.h>

-- | A window
type Window = Ptr ()

-- | Initialize the windowing system
initWindowingSystem :: IO ()
initWindowingSystem = do
   err <- initWindowingSystem_
   case err of
      0 -> error "Error during initialization"
      _ -> return ()

foreign import ccall "ecore_evas_init" initWindowingSystem_ :: IO CInt

-- | Shut down the windowing system
foreign import ccall "ecore_evas_shutdown" shutdownWindowingSystem :: IO ()

-- | Indicate if an engine is supported
isEngineSupported :: EngineType -> IO Bool
isEngineSupported engine = (> 0) <$> _isEngineSupported (fromIntegral $ fromEnum engine)

foreign import ccall "ecore_evas_engine_type_supported_get" _isEngineSupported :: CInt -> IO CInt

-- | Return a list of supported engines names
getEngines :: IO [String]
getEngines = do
   xs <- _getEngines
   r <- mapM peekCString =<< toList xs
   _freeEngines xs
   return r

foreign import ccall "ecore_evas_engines_get" _getEngines :: IO (EinaList CString)
foreign import ccall "ecore_evas_engines_free" _freeEngines :: EinaList CString -> IO ()

-- | Get the name of the engine used by the window
getEngineName :: Window -> IO String
getEngineName win = peekCString =<< _getEngineName win

foreign import ccall "ecore_evas_engine_name_get" _getEngineName :: Window -> IO CString

-- | Create a new window
createWindow :: Maybe String -> CInt -> CInt -> CInt -> CInt -> Maybe String -> IO Window
createWindow engine x y w h options = do
   let wrap s = fromMaybe (return nullPtr) (newCAString <$> s)
   engine' <- wrap engine
   options' <- wrap options
   win <- createWindow_ engine' x y w h options'
   when (engine' /= nullPtr) (free engine')
   when (options' /= nullPtr) (free options')
   return win

foreign import ccall "ecore_evas_new" createWindow_ :: CString -> CInt -> CInt -> CInt -> CInt -> CString -> IO Window

-- | Destroy a window
foreign import ccall "ecore_evas_free" destroyWindow :: Window -> IO ()


-- | Set window title
setWindowTitle :: String -> Window -> IO ()
setWindowTitle title win = withCString title (_setWindowTitle win)

foreign import ccall "ecore_evas_title_set" _setWindowTitle :: Window -> CString -> IO ()

-- | Get window title
getWindowTitle :: Window -> IO String
getWindowTitle win = peekCString =<< _getWindowTitle win

foreign import ccall "ecore_evas_title_get" _getWindowTitle :: Window -> IO CString

-- | Display a window
foreign import ccall "ecore_evas_show" showWindow :: Window -> IO ()

-- | Get the rendering canvas of the window
foreign import ccall "ecore_evas_get" getWindowCanvas :: Window -> IO Canvas

-- | Retrieve the position and (rectangular) size of the given canvas object
getWindowGeometry :: Window -> IO (CInt,CInt,CInt,CInt)
getWindowGeometry win = get4_helper (_getWindowGeometry win)

foreign import ccall "ecore_evas_geometry_get" _getWindowGeometry :: Window -> Ptr CInt -> Ptr CInt -> Ptr CInt -> Ptr CInt -> IO ()

-- | Set the position and (rectangular) size of the given canvas object
setWindowGeometry :: (CInt,CInt,CInt,CInt) -> Window -> IO ()
setWindowGeometry (x,y,w,h) win = _setWindowGeometry win x y w h

foreign import ccall "ecore_evas_move_resize" _setWindowGeometry :: Window ->  CInt ->  CInt ->  CInt ->  CInt -> IO ()

-- | Resize window
resizeWindow :: (CInt,CInt) -> Window -> IO ()
resizeWindow (w,h) win = _resizeWindow win w h

foreign import ccall "ecore_evas_resize" _resizeWindow :: Window ->  CInt ->  CInt ->  IO ()

-- | Move window
moveWindow :: (CInt,CInt) -> Window -> IO ()
moveWindow (x,y) win = _moveWindow win x y

foreign import ccall "ecore_evas_move" _moveWindow :: Window ->  CInt ->  CInt ->  IO ()

-- | Associate a callback to the "resize" event
onWindowResize :: Window -> IO () -> IO ()
onWindowResize win cb = onWindowResizeEx win (const cb)

-- | Associate a callback to the "resize" event
onWindowResizeEx :: Window -> (Window -> IO ()) -> IO ()
onWindowResizeEx win cb = setWindowResizeCallback_ win =<< wrapCallback cb

foreign import ccall "ecore_evas_callback_resize_set" setWindowResizeCallback_ :: Window -> FunPtr (Window -> IO ()) -> IO ()

foreign import ccall "wrapper" wrapCallback :: (Window -> IO ()) -> IO (FunPtr (Window -> IO ()))
