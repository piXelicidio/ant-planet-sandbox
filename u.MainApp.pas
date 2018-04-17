unit u.MainApp;

interface
  uses
  sdl2,
  px.sdl,
  px.vec2d,
  u.camview,
  px.guiso,
  u.simulation,
  u.simcfg,
  u.map,
  u.ants
  ;
type
  {Main Application}
  TMainApp = class
    public
      guiso :TGuisoScreen;
      btn1 :TArea;
      appScale :TVec2d;

      procedure onMouseDown(const mMouse:TSDL_MouseButtonEvent);
      procedure onMouseMove(const mMouse:TSDL_MouseMotionEvent);
      procedure onMouseUp(const mMouse:TSDL_MouseButtonEvent);
      procedure onMouseWheel(const mMouse :TSDL_MouseWheelEvent);
      procedure onKeyUp(const key :TSDL_KeyboardEvent );

      procedure load;
      procedure update;
      procedure draw;
      procedure Start;
      procedure Finalize;
  end;

var
  mainApp :TMainApp;
implementation
{ TMainApp }


procedure TMainApp.Start;
begin
  sdl.onLoad := load;
  sdl.onUpdate := update;
  sdl.onDraw := draw;
  sdl.onFinalize := Finalize;

  sdl.cfg.window.w := cfg.windowW;
  sdl.cfg.window.h := cfg.windowH;
  sdl.cfg.window.fullScreenType := SDL_WINDOW_FULLSCREEN_DESKTOP;
  sdl.cfg.defaultFontSize := 18;
  //before this point can't call SDL api, after this point do it on Load or Update.
  sdl.Start;
end;

procedure TMainApp.load;
var
  logical :TSDL_Point;
  f :PFloat;
begin

  sim.init;
 // sdl.fullScreen := true;
  logical.x := (cfg.screenLogicalHight * sdl.window.w)  div sdl.window.h;
  logical.y := cfg.screenLogicalHight;
  sdl.LogicalSize := logical;
  SDL_RenderGetScale( sdl.rend, @appScale.x, @appScale.y);
  cam.x := 20;
  cam.y := 10;
  cam.zoom := 2;

  //ui
  guiso := TGuisoScreen.create;
  sdl.OnMouseDown := onMouseDown;
  sdl.OnMouseUp := onMouseUp;
  sdl.OnMouseMove := onMouseMove;
  sdl.OnMouseWheel := onMouseWheel;

  sdl.onKeyUp := onKeyUp;

  btn1 := TArea.create;
  btn1.setXY(10,10);
  btn1.setWH(100, 30);
  btn1.Text := 'Button';
  guiso.addChild(btn1);
end;

procedure TMainApp.update;
begin
  sim.update;
  SDL_Delay(1);
end;

procedure TMainApp.draw;
begin
  SDL_RenderSetScale( sdl.rend, appScale.x * cam.zoom, appScale.y * cam.zoom);
  sim.draw;
  SDL_RenderSetScale( sdl.rend, appScale.x, appScale.y);
  guiso.draw;
end;


procedure TMainApp.onKeyUp(const key: TSDL_KeyboardEvent);
begin
  if key._repeat=0 then
    case key.keysym.scancode of
      SDL_SCANCODE_F11 : begin sdl.fullScreen := not sdl.fullScreen; SDL_RenderGetScale(sdl.rend, @appScale.x, @appScale.y)  end;
    end;

end;

procedure TMainApp.onMouseDown(const mMouse: TSDL_MouseButtonEvent);
begin
  guiso.Consume_MouseButton(mMouse);
end;

procedure TMainApp.onMouseMove(const mMouse: TSDL_MouseMotionEvent);
begin
  guiso.Consume_MouseMove(mMouse);
end;

procedure TMainApp.onMouseUp(const mMouse: TSDL_MouseButtonEvent);
begin
  guiso.Consume_MouseButton(mMouse);
end;

procedure TMainApp.onMouseWheel(const mMouse: TSDL_MouseWheelEvent);
begin
  cam.zoomInc( mMouse.y/10 );
end;

procedure TMainApp.Finalize;
begin
  sim.finalize;
  guiso.Free;
end;





initialization
  mainApp := TMainApp.Create;
finalization
  mainApp.Free;
end.
