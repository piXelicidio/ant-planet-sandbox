unit u.MainApp;

interface
  uses
  sdl2,
  px.sdl,
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

      procedure onMouseDown(const mMouse:TSDL_MouseButtonEvent);
      procedure onMouseMove(const mMouse:TSDL_MouseMotionEvent);
      procedure onMouseUp(const mMouse:TSDL_MouseButtonEvent);
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



  //before this point can't call SDL, after this point do it on Load or Update.
  sdl.Start;
end;

procedure TMainApp.load;
var
  logical :TSDL_Point;
begin
  sim.init;
 // sdl.fullScreen := true;
  logical.x := (720 * sdl.window.w)  div sdl.window.h;
  logical.y := 720;
  sdl.LogicalSize := logical;
  //SDL_RenderSetScale( sdl.rend, 1, 1);

  //ui
  guiso := TGuisoScreen.create;
  sdl.OnMouseDown := onMouseDown;
  sdl.OnMouseUp := onMouseUp;
  sdl.OnMouseMove := onMouseMove;

  sdl.onKeyUp := onKeyUp;

  btn1 := TArea.create;
  btn1.setXY(10,10);
  btn1.setWH(100, 30);
  btn1.Text := 'Button';
  guiso.addChild(btn1);
end;



procedure TMainApp.onKeyUp(const key: TSDL_KeyboardEvent);
begin
  if key._repeat=0 then
    case key.keysym.scancode of
      SDL_SCANCODE_F11 : sdl.fullScreen := not sdl.fullScreen;
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

procedure TMainApp.Finalize;
begin
  sim.finalize;
  guiso.Free;
end;




procedure TMainApp.update;
begin
  sim.update;
  SDL_Delay(10);
end;

procedure TMainApp.draw;
begin
  sim.draw;
  guiso.draw;
end;


initialization
  mainApp := TMainApp.Create;
finalization
  mainApp.Free;
end.
