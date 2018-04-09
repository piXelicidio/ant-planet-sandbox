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
    cell :TCell;
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
    procedure finalize;
    procedure update;
    procedure draw;
    function canPass( x, y : single ):boolean;
    procedure RemoveCell(xg, yg: integer );
    procedure SetCell(xg, yg: integer; cellType:TCellTypes);
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
      if grid[i,j].cell=nil then
      begin
        if grid[i,j].pass then SDL_RenderCopy(sdl.rend, fGround, nil, @rect )
          else SDL_RenderCopy(sdl.rend, fBlock, nil, @rect );
      end else
      begin
        grid[i,j].cell.draw(rect.x, rect.y);
      end;
    end;
end;

procedure TMap.finalize;
var
  i: Integer;
  j: Integer;
begin
 for i := 0 to fW-1 do
    for j := 0 to fH-1 do
      with grid[i,j] do
          if cell<>nil then
          begin
            if cell.NeedDestroyWhenRemoved then cell.Free;
            cell := nil;
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
      grid[i,j].pheromInfo.seen[ctFood].frameTime := -1;
      grid[i,j].cell := nil;
    end;
  end;

  SetCell(1, 1, ctCave);
  SetCell(W-2, H-2, ctFood);
end;


procedure TMap.RemoveCell(xg, yg: integer);
begin
  if (xg>=0) and (xg<W) and (yg>=0) and (yg<H)  then
  with grid[xg,yg] do
  begin
    pass := true;
    if cell<>nil then
    begin
      if cell.NeedDestroyWhenRemoved then cell.Free;
      cell := nil;
    end;
  end;
end;

procedure TMap.SetCell(xg, yg: integer; cellType: TCellTypes);
begin
  if (xg>=0) and (xg<W) and (yg>=0) and (yg<H)  then
  begin
    RemoveCell(xg,yg);
    with grid[xg, yg] do
      case cellType of
        ctBlock: pass := false;
        ctGround:;//nothing needed;
        ctGrass: cell := cellFactory.getGrass;
        ctFood: cell := cellFactory.newFood;
        ctCave: cell := cellFactory.getCave;
      end;
  end;
end;

procedure TMap.update;
begin

end;

end.
