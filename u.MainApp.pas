unit u.MainApp;

interface
  uses
  system.SysUtils,
  sdl2,
  px.sdl,
  px.vec2d,
  u.camview,
  px.guiso,
  u.simulation,
  u.simcfg,
  u.map,
  u.ants,
  u.gui;

type
  {Main Application}
  TMainApp = class
    public
      moveBtn  :TMoveButtons;
      gui :TAppGui;

      procedure screenClick(x, y:integer; move:boolean);
      procedure ShowPheromsClick( sender:TArea;const mMouse: TSDL_MouseButtonEvent);

      procedure onMouseDown(const mMouse:TSDL_MouseButtonEvent);
      procedure onMouseMove(const mMouse:TSDL_MouseMotionEvent);
      procedure onMouseUp(const mMouse:TSDL_MouseButtonEvent);
      procedure onMouseWheel(const mMouse :TSDL_MouseWheelEvent);
      procedure onKeyUp(const key :TSDL_KeyboardEvent );
      procedure onKeyDown(const key :TSDL_KeyboardEvent );

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


procedure TMainApp.ShowPheromsClick(sender: TArea;const  mMouse: TSDL_MouseButtonEvent);
begin
  cfg.debugPheromones :=  gui.checkPheroms.Checked;
end;

procedure TMainApp.Start;
begin
  sdl.onLoad := load;
  sdl.onUpdate := update;
  sdl.onDraw := draw;
  sdl.onFinalize := Finalize;

  sdl.cfg.window.w := cfg.windowW;
  sdl.cfg.window.h := cfg.windowH;
  sdl.cfg.window.fullScreenType := SDL_WINDOW_FULLSCREEN_DESKTOP;
  sdl.cfg.RenderFlags := SDL_RENDERER_ACCELERATED; //<--- while develop
  sdl.cfg.defaultFontSize := 12;
  sdl.showDriversInfo;
  sdl.cfg.RenderDriverIndex := -1;
  //before this point can't call SDL api, after this point do it on Load or Update.
  sdl.Start;
end;

procedure TMainApp.load;
var
  logical :TSDL_Point;
  f :PFloat;
begin

  sim.init;
  sdl.fullScreen := true;
  logical.x := (cfg.screenLogicalHight * sdl.window.w)  div sdl.window.h;
  logical.y := cfg.screenLogicalHight;
  sdl.LogicalSize := logical;
  SDL_RenderGetScale( sdl.rend, @cam.appScale.x, @cam.appScale.y);
  cam.x := 20;
  cam.y := 10;
  cam.zoom := 1;

  sdl.onKeyUp := onKeyUp;
  gui := TAppGui.create;
  gui.init;
  gui.checkPheroms.OnMouseClick  := ShowPheromsClick;
//  gui.checkPheroms.OnMouseClick := Show

  sdl.OnMouseDown := onMouseDown;
  sdl.OnMouseUp := onMouseUp;
  sdl.OnMouseMove := onMouseMove;
  sdl.OnMouseWheel := onMouseWheel;
  sdl.onKeyDown := onKeyDown;
end;

procedure TMainApp.update;
var
  j:integer;
  moveStep :integer;
begin
  moveStep := round( 5 / cam.zoom / cam.appScale.x );
  if moveBtn.left then cam.x := cam.x + moveStep;
  if moveBtn.right then cam.x := cam.x - moveStep;
  if moveBtn.up then cam.y := cam.y + moveStep;
  if moveBtn.down then cam.y := cam.y - moveStep;

  sim.update;
  gui.lblFPS.Text :=  'FPS: '+ IntToStr( sdl.FPS ) ;
  gui.lblNumAnts.Text := 'Ants: '+ IntToStr( sim.ants.items.Count  );


  SDL_Delay(0);
end;

procedure TMainApp.draw;
begin
  sdl.setColor(0,0,0);
  SDL_RenderClear(sdl.rend); //TODO: can be better without cls
  SDL_RenderSetScale( sdl.rend, cam.appScale.x * cam.zoom, cam.appScale.y * cam.zoom);
  sim.draw;
  SDL_RenderSetScale( sdl.rend, 1, 1);
  // SDL_RenderSetScale(sdl.rend, appScale.x, appScale.y); //for highdef displays..
  gui.screen.draw;
end;


procedure TMainApp.onKeyDown(const key: TSDL_KeyboardEvent);
begin
  case key.keysym.scancode of
    SDL_SCANCODE_A: moveBtn.left := true;
    SDL_SCANCODE_D: moveBtn.right := true;
    SDL_SCANCODE_W: moveBtn.up := true;
    SDL_SCANCODE_S: moveBtn.down := true;
  end;
end;

procedure TMainApp.onKeyUp(const key: TSDL_KeyboardEvent);
begin
  case key.keysym.scancode of
    SDL_SCANCODE_F11 : begin sdl.fullScreen := not sdl.fullScreen; SDL_RenderGetScale(sdl.rend, @cam.appScale.x, @cam.appScale.y)  end;
    SDL_SCANCODE_ESCAPE : sdl.quit;
    SDL_SCANCODE_A: moveBtn.left := false;
    SDL_SCANCODE_D: moveBtn.right := false;
    SDL_SCANCODE_W: moveBtn.up := false;
    SDL_SCANCODE_S: moveBtn.down := false;
  end;
end;

procedure TMainApp.onMouseDown(const mMouse: TSDL_MouseButtonEvent);
begin
  if not gui.screen.Consume_MouseButton(mMouse) then
  begin
    screenClick(mMouse.x, mMouse.y, false);
  end;
end;

procedure TMainApp.onMouseMove(const mMouse: TSDL_MouseMotionEvent);
begin
  if not gui.screen.Consume_MouseMove(mMouse) then
  begin
    if (mMouse.state and SDL_BUTTON_LMASK)>0 then screenClick(mMouse.x, mMouse.y, true);
  end;
end;

procedure TMainApp.onMouseUp(const mMouse: TSDL_MouseButtonEvent);
begin
  gui.screen.Consume_MouseButton(mMouse);
end;

procedure TMainApp.onMouseWheel(const mMouse: TSDL_MouseWheelEvent);
begin
  SDL_GetMouseState(@cam.zoomOrigin.x, @cam.zoomOrigin.y);
  cam.zoomInc( mMouse.y/10 );
end;

procedure TMainApp.screenClick(x, y: integer; move:boolean);
var
  posg :TVec2di;
  posw :TVec2d;
begin
  posw := cam.ScreenToWorld(x,y);
  posg := sim.map.WorldToGrid( posw  );

  if  gui.radioTool.SelectedText='block' then  sim.map.SetCell(posg.x, posg.y, ctBlock)
  else
  if  gui.radioTool.SelectedText='food' then  sim.map.SetCell(posg.x, posg.y, ctFood)
  else
  if  (gui.radioTool.SelectedText='cave') and not move then  sim.map.SetCell(posg.x, posg.y, ctCave)
  else  
    if  gui.radioTool.SelectedText='grass' then  sim.map.SetCell(posg.x, posg.y, ctGrass)
  else
  if  gui.radioTool.SelectedText='remove' then  sim.map.RemoveCell(posg.x, posg.y);
end;

procedure TMainApp.Finalize;
begin
 gui.Free;
  sim.finalize;
  //guiso.Free;
end;





initialization
  mainApp := TMainApp.Create;
finalization
  mainApp.Free;
end.
