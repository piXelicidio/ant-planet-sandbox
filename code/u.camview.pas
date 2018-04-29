unit u.camview;

interface
uses
  px.vec2d,  px.sdl, system.generics.collections,
  u.simcfg, system.Math
    ;

type

TCamView = class
  x, y :integer;
  zoom :single;
  zoomOrigin :TVec2di;
  appScale :TVec2d;
  procedure ZoomInc( value :single );
  function ScreenToWorld( ax, ay :integer):TVec2d;
end;

var
  cam :TCamview;

implementation

{ TCamView }

function TCamView.ScreenToWorld(ax, ay: integer): TVec2d;
begin
  result.x :=floor( ax / zoom / appScale.x - x);
  result.y :=floor( ay / zoom / appScale.y - y);
end;

{doing a zoom, you must update zoomOrigin before to
 set the origin point in screen of the zoom}
procedure TCamView.ZoomInc(value: single);
var
  oldzoom :single;
  Dt :TVec2d; //delta correction;
  trans :TVec2d;
  appZ :single;
  origin :TVec2d;
begin
  //doing the zoom
  oldzoom := zoom ;
  zoom := zoom + value;
  if zoom < cfg.camMinZoom then zoom := cfg.camMinZoom
    else if zoom > cfg.camMaxZoom then zoom := cfg.camMaxZoom;

  //"pinning" the zoom to occur using the mouse origin
  trans.x := x;
  trans.y := y;
  appZ := appScale.x;
  //converting the mouse position to world position
  origin.x := zoomOrigin.x / oldzoom / appZ - x;
  origin.y := zoomOrigin.y / oldZoom / appZ - y;
  { using the formula that I got on my sketch pad  after a few head aches,
    but actually modified after a few trial and errors... don't ask how it works
  }
  dt :=  ( ( - origin - trans ) * appZ * (zoom - oldzoom) ) *( 1 / zoom);
  //correcting translation;
  x := round( x + dt.x );
  y := round( y + dt.y );
end;

initialization
  cam := TCamView.create;
  cam.zoom := 1;
  cam.x := 0;
  cam.y := 0;
finalization
  cam.Free;
end.
