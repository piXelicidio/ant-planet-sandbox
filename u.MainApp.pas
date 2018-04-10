unit u.MainApp;

interface
  uses
  sdl2,
  px.sdl,
  u.simulation,
  u.simcfg,
  u.map,
  u.ants
  ;
type
  {Main Application}
  TMainApp = class
    public
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
  sdl.Start;
end;

procedure TMainApp.Finalize;
begin
  sim.finalize;
end;

procedure TMainApp.load;
begin
  sdl.cfg.window.w := cfg.windowW;
  sdl.cfg.window.h := cfg.windowH;
  sim.init;
end;


procedure TMainApp.update;
begin
  sim.update;
  SDL_Delay(10);
end;

procedure TMainApp.draw;
begin
  sim.draw;
end;


initialization
  mainApp := TMainApp.Create;
finalization
  mainApp.Free;
end.
