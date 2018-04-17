unit u.camview;

interface
uses
  px.vec2d,  px.sdl, system.generics.collections,
  u.simcfg
  ;

type

TCamView = class
  x, y :integer;
  zoom :single;
  procedure ZoomInc( value :single );
end;

var
  cam :TCamview;

implementation

{ TCamView }

procedure TCamView.ZoomInc(value: single);
begin
  zoom := zoom + value;
  if zoom < cfg.camMinZoom then zoom := cfg.camMinZoom
    else if zoom > cfg.camMaxZoom then zoom := cfg.camMaxZoom;
end;

initialization
  cam := TCamView.create;
  cam.zoom := 1;
  cam.x := 0;
  cam.y := 0;
finalization
  cam.Free;
end.
