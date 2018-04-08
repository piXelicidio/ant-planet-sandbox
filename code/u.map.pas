unit u.map;

interface

uses
      system.math,
      px.sdl,
      px.vec2d,
      sdl2,
      u.ants,
      u.simcfg,
      u.cell;

type
  TSeen = record
    frameTime :integer;
    where :TVec2d;
  end;

  TPheromInfo = record
    seen :array[TAntInterests] of Tseen;
  end;

  TMapData = record
    pass :boolean;
    pheromInfo :TPheromInfo;

  end;

  TMap = class
  private
    fW  :integer;
    fH  :integer;
    fMaxX :integer;
    fMaxY :integer;
    fGround :PSDL_Texture;
    fBlock :PSDL_Texture;
  public
    grid  :array of array of TMapData;
    constructor Create;
    destructor Destroy;override;
    procedure init;
    procedure update;
    procedure draw;
    function canPass( x, y : single ):boolean;
    property W:integer read fW;
    property H:integer read fH;
  end;

var
  map :TMap;

implementation

{ TMap }

function TMap.canPass(x, y: single): boolean;
var
  xg, yg :integer;
begin
  xg := floor( x / cfg.mapCellSize );
  yg := floor( y / cfg.mapCellSize );
  result := false;
  if xg>=0  then if xg<W then if yg>=0 then if yg<H then result := grid[xg, yg].pass;
end;

constructor TMap.Create;
begin
end;

destructor TMap.Destroy;
begin

end;

procedure TMap.draw;
var
  i,j :integer;
  rect :TSDL_Rect;
begin
  for i := 0 to fW-1 do
    for j := 0 to fH-1 do
    begin
      //sdl.drawRect( i * cfg.mapCellSize, j * cfg.mapCellSize, cfg.mapCellSize, cfg.mapCellSize);
      rect.x := i * cfg.mapCellSize;
      rect.y := j * cfg.mapCellSize;
      rect.w := cfg.mapCellSize;
      rect.h := cfg.mapCellSize;
      if grid[i,j].pass then SDL_RenderCopy(sdl.rend, fGround, nil, @rect )
        else SDL_RenderCopy(sdl.rend, fBlock, nil, @rect );
    end;
end;

procedure TMap.init;
var
  i,j :integer;
  foo :single;
begin
  //load
  fGround := sdl.loadTexture('images\ground01.png');
  fBlock := sdl.loadTexture('images\block01.png');

  //
  fW := cfg.mapW;
  fH := cfg.mapH;
  fMaxX := fW * cfg.mapCellSize;
  fMaxY := fH * cfg.mapCellSize;
  setLength(grid, fW);
  for i := 0 to fW-1 do
  begin
    setLength(grid[i], fH);
    for j := 0 to fH-1 do
    begin
      grid[i,j].pass := random > 0.06;
      foo := random*1;
      grid[i,j].pheromInfo.seen[aiFood].frameTime := -1;
    end;
  end;
end;


procedure TMap.update;
begin

end;

end.
