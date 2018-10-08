unit u.map;

interface

uses
      system.math, system.SysUtils,
      px.sdl,
      px.vec2d,
      sdl2,
      u.ants,
      u.simcfg,
      u.camview,
      u.cell;

type
  PSeen = ^TSeen;
  TSeen = record
    frameTime :integer;
    where :TVec2d;
  end;

  PPheromInfo = ^TPheromInfo;
  TPheromInfo = record
    seen :array[TAntInterests] of Tseen;
  end;

  PMapData = ^TMapData;
  TMapData = record
    passLevel :integer;           //they can't pass to a higer level Obstacle
    pheromInfo :TPheromInfo;
    cell :TCell;
    ants :array of PAnt;         //ants passing by; array may be larger, see antsCount
    antsCount :integer;          //actual ants in ants array
    procedure antsArray_add(  ant :PAnt );
    procedure antsArray_delete( ant :PAnt );
  end;

  ///<summay> The Map. A 2D array (grid) that keeps all the TMapData and methods to deal with it.</summary>
  TMap = class
  private
    fW  :integer;
    fH  :integer;
    fMaxX :integer;
    fMaxY :integer;
    fGround :PSDL_Texture;
    fBlock :PSDL_Texture;
    currMouse :TVec2di;                          //if currMouse.x or .y is -1 then mouse is out of map;
  public
    grid  :array of array of TMapData;
    constructor Create;
    destructor Destroy;override;
    procedure init;
    procedure finalize;
    procedure update;
    procedure draw;
    function getPassLevel( x, y : single ):integer;
    procedure RemoveCell(xg, yg: integer );
    procedure SetCell(xg, yg: integer; cellType:TCellTypes);
    procedure detectAntCellEvents( ants :TAntPack );
    function WorldToGrid( vec:TVec2d ):TVec2di;inline;
    function CheckInGrid( xg, yg :integer ):boolean;inline;
    procedure MouseCursor(const posg :TVec2di  );
    property W:integer read fW;
    property H:integer read fH;
  end;

implementation

{ TMap }


function TMap.CheckInGrid(xg, yg: integer): boolean;
begin
  result := (xg >= 0)  and (xg < W) and (yg >= 0) and (yg < H)
end;

constructor TMap.Create;
begin
end;

destructor TMap.Destroy;
begin

end;

procedure TMap.detectAntCellEvents(ants: TAntPack);
var
  i :integer;
  ant :PAnt;
  newGpos :TVec2di;
  newGrid, oldGrid :PMapData;
begin
  for i := 0 to ants.items.Count-1 do
  begin
    ant := ants.items.List[i];
    newGpos := WorldToGrid( ant.pos );
    if not (newGpos = ant.gridPos) then
    begin
      //ants has jumped from one grid cell to another one, notify them;
      oldGrid := @grid[ant.gridPos.x, ant.gridPos.y];
      newGrid := @grid[newGpos.x, newGpos.y];
      if oldGrid.cell<>nil then oldGrid.cell.endOverlap(ant);
      if newGrid.cell<>nil  then
      begin
        ant.isWalkingOver := newGrid.cell.cellType;
        newGrid.cell.beginOverlap(ant);
      end else
      begin
        if newGrid.passLevel = CFG_passLevelGround then ant.isWalkingOver := ctGround else ant.isWalkingOver := ctBlock;
      end;
      //update the grid arrays of ants
      grid[ ant.gridPos.x, ant.gridPos.y ].antsArray_delete( ant );
      grid[ newGpos.x, newGPos.y ].antsArray_add( ant );
      //update ant with new gpos
      ant.gridPos := newGpos;
    end;
  end;
end;

procedure TMap.draw;
var
  i,j :integer;
  rect :TSDL_Rect;
  gdata :PMapData;
  interest :TAntInterests;
  target :TVec2di;
  gradient :integer;
begin
  for i := 0 to fW-1 do
    for j := 0 to fH-1 do
    begin
      gdata := @grid[i,j];
      //sdl.drawRect( i * cfg.mapCellSize, j * cfg.mapCellSize, cfg.mapCellSize, cfg.mapCellSize);
      rect.x := i * cfg.mapCellSize + cam.x;
      rect.y := j * cfg.mapCellSize + cam.y;
      rect.w := cfg.mapCellSize;
      rect.h := cfg.mapCellSize;

      if gdata.cell=nil then
      begin
        if gdata.passLevel = CFG_passLevelGround
                then SDL_RenderCopy(sdl.rend, fGround, nil, @rect )
                else SDL_RenderCopy(sdl.rend, fBlock, nil, @rect );
      end else
      begin
        gdata.cell.draw(rect.x, rect.y);
      end;
      //show pheromones
      if cfg.debugPheromones then
      begin
        for interest := Low(TAntInterests) to High(TAntInterests) do
          if gdata.pheromInfo.seen[interest].frameTime>0 then
          begin
            gradient := frameTimer.time - gdata.pheromInfo.seen[interest].frameTime;
            //sdl.debug( IntToStr(gdata.pheromInfo.seen[interest].frameTime));
            gradient := gradient div 5;
            if gradient > 255 then gradient := 255;
            if gradient < 200 then
            begin
              sdl.setColor(gradient,255-gradient,0);
              target := gdata.pheromInfo.seen[interest].where.floored;
              SDL_RenderDrawLine(sdl.rend, rect.x + rect.w div 2,  rect.y + rect.h div 2, cam.x+ target.x, cam.y+ target.y );
            end;
          end;
      end;

      //debug antCount / capacity
      //sdl.drawText(IntToStr(gdata.antsCount) + '/' + IntToStr(Length(gdata.ants)), rect.x, rect.y);
    end;

    //draw cursor;
    {
    if (currMouse.x <> -1) and (currMouse.y <>-1) then
    begin
      sdl.setColor(255,255,255);
      sdl.drawRectLines(cam.x + currMouse.x * cfg.mapCellSize, cam.y+currMouse.y * cfg.mapCellSize, cfg.mapCellSize, cfg.mapCellSize );
    end;     }
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

function TMap.getPassLevel(x, y: single): integer;
var
  xg, yg :integer;
begin
  xg := floor( x / cfg.mapCellSize );
  yg := floor( y / cfg.mapCellSize );
  if (xg >= 0)  and (xg < W) and (yg >= 0) and (yg < H) then result := grid[xg, yg].passLevel
                                                        else result := CFG_passLevelOut;
end;

procedure TMap.init;
var
  i,j  :integer;
  interest :TCellTypes;
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
      if random > 0.02 then grid[i,j].passLevel := CFG_passLevelGround
                       else grid[i,j].passLevel := CFG_passLevelBlock  ;

      //borders obligatory
      if (i = 0) or (i = fW-1) or (j=0) or (j = fH-1) then grid[i,j].passLevel := CFG_passLevelOut;



      for interest := low(TAntInterests) to high(TAntInterests) do
      begin
        with grid[i,j] do
        begin
          pheromInfo.seen[ interest ].frameTime := -1;
          pheromInfo.seen[ interest ].where := vec(0,0);
        end;
      end;

      //grid[i,j].pheromInfo.seen[ctFood].frameTime := -1;
      grid[i,j].cell := nil;
      setlength(grid[i,j].ants, 8);
    end;
  end;

  //magic hidden Cell ......  O.o  NO LONGER NEEDED
//  setLength(grid[0], fH+1);
  {The first array will have an aditional item at the end, to avoid some validations, see TAntPack.addNewAndInit }
  {
  fHiddenCell.x := 0;
  fHiddenCell.y := fH;
  grid[0,fH] := Default( TMapData );
  }
  SetCell(1, 1, ctCave);
  SetCell(W-2, H-2, ctFood);
end;


procedure TMap.MouseCursor(const posg: TVec2di);
begin
  //if currMouse.x or .y is -1 then mouse is out of map;
  currMouse.x := -1;
  currMouse.y := -1;
  if (posg.x>=0) and (posg.x < fW) then currMouse.x :=posg.x;
  if (posg.y>=0) and (posg.y < fH) then currMouse.y :=posg.y;
end;

procedure TMap.RemoveCell(xg, yg: integer);
var
  i:integer  ;
begin
  if (xg>=1) and (xg<W-1) and (yg>=1) and (yg<H-1)  then
  with grid[xg,yg] do
  begin
    passLevel := CFG_passLevelGround;
    if cell<>nil then
    begin
      //TODO: needs end overlaps with potential ants somewhere
      //notify ants
      for i := 0 to antsCount-1 do
      begin
        cell.endOverlap( ants[i] );
      end;
      //destroy
      if cell.NeedDestroyWhenRemoved then cell.Free;
      cell := nil;
    end;
  end;
end;

procedure TMap.SetCell(xg, yg: integer; cellType: TCellTypes);
var
  i :integer;
begin
  if (xg>=1) and (xg<W-1) and (yg>=1) and (yg<H-1)  then
  begin
    RemoveCell(xg,yg);
    with grid[xg, yg] do
    begin
      case cellType of
        ctBlock: passLevel := CFG_passLevelBlock;
        ctGround:;//nothing needed;
        ctGrass: cell := cellFactory.getGrass;
        ctFood: cell := cellFactory.newFood;
        ctCave: cell := cellFactory.getCave;
      end;
      if cell<>nil then
      begin
        for i := 0 to antsCount-1 do
        begin
          cell.beginOverlap( ants[i] );
        end;
      end;
    end;
  end;
end;

procedure TMap.update;
begin

end;

function TMap.WorldToGrid(vec: TVec2d): TVec2di;
begin
  result.x := floor( vec.x / cfg.mapCellSize );
  result.y := floor( vec.y / cfg.mapCellSize );
end;


{ TMapData }

procedure TMapData.antsArray_add(ant: PAnt);
begin
  //need resize?
  if length(ants) <= antsCount then setLength(ants, length(ants)*2);
  ants[antsCount] := ant;
  ant.ListRefIdx[lrGrid] := antsCount;  //store the index
  inc(antsCount);
end;

procedure TMapData.antsArray_delete(ant: PAnt);
var
  tempAnt :PAnt;
begin
  //fastest delete; set the current ant item with the value from the last ant in the array (this could kaput if we are not careful)

  {$IFDEF DEBUG}
  //unnecesary error checking
  if antsCount<=0 then sdl.print('nothing to delete here');
  if ants[ ant.ListRefIdx[lrGrid] ] <> ant then sdl.print('deleting wrong ant');
  {$ENDIF}

  tempAnt := ants[ antsCount-1 ];
  ants[ ant.ListRefIdx[lrGrid] ] := tempAnt;
  tempAnt.ListRefIdx[lrGrid] := ant.ListRefIdx[lrGrid];
  antsCount := antsCount - 1;

  //resize down array... Only if it is less than half empty, or never if you like disable next line
  if (antsCount < (length(ants) div 2)) and (length(ants)>8) then setLength(ants, length(ants) div 2);

end;

end.
