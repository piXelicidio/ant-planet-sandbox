unit u.ants;
{our Ants, let's try Data Oriented Design here... herejía }
interface

uses
  px.vec2d,
  px.sdl,
  sdl2,
  generics.collections,
  system.Math,
  u.simcfg,
  u.utils;

type
  TListRef = (lrIgnore, lrOwner, lrGrid);

  PAnt = ^TAnt;
  TAnt = record
    private
      dir   : TVec2d;  //direction to go
      rot   : single;  //rotation equivalent to current direciton;
      PastPositions :array[0..CFG_antPositionMemorySize-1] of TVec2d;
      oldestPositionIndex :integer;
      procedure updateRot;
      procedure updateDir;
      procedure storePosition(const vec :TVec2d );
      procedure resetPositionMemory(const vec :TVec2d );
    public
      pos :TVec2d;  //position
      wishPos :TVec2d; //next position it wants to go, map has final word
      lastPos :TVec2d; //previous position;
      speed   :single;
      traveled  :single;  //distance traveled
      friction  :single;
      gridPos :TVec2di;
      isWalkingOver :TCellTypes;
      cargo :boolean;

      LastTimeSeen :array[TAntInterests] of integer;
      maxTimeSeen_MyTarget :integer;
      lookingFor :TAntInterests;
      comingFrom :TAntInterests;
      oldestPositionStored :PVec2D;

      ListRefIdx :array[TListRef] of integer;    //to store Index locations in lists or arrays, needed for fast remove
      procedure setDir( const aNormalizedVec :TVec2d );
      procedure setDirAndNormalize( const unormalizedVec :TVec2d );
      procedure setRot( rad :single );
      procedure rotate( rad :single );
      procedure headTo(const targetPos :TVec2d );
      procedure taskFound( interest :TAntInterests );
      property direction:TVec2d read dir;
  end;

  //A list of Ants, procedures and functions most time acts over all ants
  TAntList = TList<PAnt>;

  TPassLevelFunc = function( x, y: single):integer of object;

  TAntPack = class
    private
      fRadial :TRadial;
    public
      items :TAntList;
      img :TSprite;
      antOwner :boolean;
      constructor Create;
      destructor Destroy;override;
      procedure Init;
      procedure addNewAndInit( amount:integer; listRef :TListRef = lrIgnore  );  //create and init a bunch of ants, and add them to the list
      procedure draw;
      procedure update;
      procedure solveCollisions( passLevelFunc: TPassLevelFunc );
      procedure disposeAll;
  end;



implementation

{ TAntList }

constructor TAntPack.Create;
begin
  items := TAntList.Create;
  antOwner := true;
end;

destructor TAntPack.Destroy;
begin
  if antOwner then disposeAll;
  items.Free;
  inherited;
end;

procedure TAntPack.disposeAll;
var
  i:integer;
begin
  for i := 0 to items.Count-1 do
  begin
    dispose( items.list[i] );
  end;
end;

procedure TAntPack.draw;
var
  x1, y1, x2, y2 :integer;
  i :integer;
  ant :PAnt;
begin
  for i := 0 to items.Count-1 do
  begin
    ant := items.list[i];
    x1 := Floor( ant.pos.x );
    y1 := Floor( ant.pos.y );
    sdl.drawSprite(img, x1, y1, ant.rot * 180 / pi);
    if ant.cargo then
    begin
      sdl.setColor(255,255,25);
      x2 := Floor( ant.pos.x + ant.dir.x * 10 -3 );
      y2 := Floor( ant.pos.y + ant.dir.y * 10 -3 );
      sdl.drawRect( x2, y2, 5, 5 );
    end;

    {$IFDEF DEBUG}
    if i<cfg.numDebugAnts then
    begin
      x2 := Floor( ant.pos.x + ant.dir.x * 40 );
      y2 := Floor( ant.pos.y + ant.dir.y * 40 );
      sdl.setColor(255,255,255);
      // direction
      SDL_RenderDrawLine(sdl.rend, x1, y1, x2, y2);
      sdl.drawRect( ant.gridPos.x * cfg.mapCellSize,
                    ant.gridPos.y * cfg.mapCellSize,
                    cfg.mapCellSize,
                    cfg.mapCellSize );
      // oldestPosition remembered;
      sdl.setColor(25,25,255);
      x2 := Floor( ant.oldestPositionStored.x );
      y2 := Floor( ant.oldestPositionStored.y );
      sdl.drawRect(x2,y2, 2,2);
    end;
    {$ENDIF}
  end;
end;

procedure TAntPack.Init;
begin
  img := sdl.newSprite( sdl.loadTexture('images\antWalk_00.png') );
  img.center.x := img.srcRect.w div 2;
  img.center.y := (img.srcRect.h div 2)+1;
end;

{Solve ants collisions, allow or fix movement}
procedure TAntPack.solveCollisions(passLevelFunc: TPassLevelfunc);
  var
  i: Integer;
  ant :PAnt;
  found :boolean;
  radCount :integer;
  idx :integer;
  scanIdx : integer;
  vTest :TVec2d;
  currLevel :integer;
begin
  for i := 0 to items.Count-1 do
  begin
    ant := items.List[i];
    {Obstacles are determined by the passLevel integer value
     ants can walk to same or lower level and can't go to higer level}
    currLevel := passLevelFunc( ant.pos.x, ant.pos.y );
    ant.lastPos := ant.pos;
    if passLevelFunc( ant.wishPos.x, ant.wishPos.y) <= currLevel then
    begin
      ant.pos := ant.wishPos;
    end else
    begin //solve collisions
      //do a radial scan to find best free way to go
      idx := fRadial.getDirIdx(ant.rot);
      radCount := 0;
      repeat
        inc(radCount);
        scanIdx :=  idx + radCount;
        vTest := ant.pos + (fRadial.getDirByIdx( scanIdx )^) * ant.speed;
        if passLevelFunc( vTest.x, vTest.y) <= currLevel then found:=true
          else begin
            //try the other negative side
            scanIdx := idx - radCount;
            vTest := ant.pos + (fRadial.getDirByIdx( scanIdx )^) * ant.speed;
            found := passLevelFunc( vTest.x, vTest.y) <= currLevel;
          end;
      until found or (radCount > Length(fRadial.dirs));
      if found then
      begin
        ant.pos := vTest;
        ant.setRot( fRadial.IdxToAngle(scanIdx) );
      end else
      begin
        //it's a Trap!! escape..
        //now is very rare to happend since ant can walk same "passLevel"
      end;
    end;
  end;
end;

procedure TAntPack.addNewAndInit( amount: integer; listRef:TListRef = lrIgnore);
var
  ant :PAnt;
  i, p: Integer;
  interest:TAntInterests;
begin
  fRadial.Init(cfg.antRadialScanNum);
  for i := 0 to amount-1 do
  begin
    new(ant);
    ant.pos.x :=100+ random*400;
    ant.pos.y :=100+ random*300;
    {using the hiddenCell force the map to detect first overlappings without special validations}
    {ants will appear to come always form a different grid cell than the first one. }
    ant.gridPos.X := 0;
    ant.gridPos.y := 0;
    ant.speed := cfg.antMaxSpeed * 0.1;
    ant.lastPos := ant.pos;
    ant.setRot(random*pi*2);
    ant.ListRefIdx[listRef] :=  items.add(ant);
    ant.isWalkingOver := ctGround;
    ant.cargo := false;
    for p := 0 to high(ant.pastPositions) do
    begin
      ant.PastPositions[p] :=  ant.pos;
    end;
    ant.oldestPositionIndex := 0;
    ant.oldestPositionStored := @ant.PastPositions[0];
    for interest := Low(TAntInterests) to High(TantInterests) do
    begin
      ant.LastTimeSeen[interest] := -1;
    end;
    ant.lookingFor := ctFood;
    ant.comingFrom := ctCave;
  end;
end;

procedure TAntPack.update;
var
  ant :PAnt;
  i :integer;
begin
  for i:= 0 to items.count-1 do
  begin
    ant := items.list[i];
    ant.storePosition(ant.pos);
    ant.rotate( random*cfg.antErratic - cfg.antErratic / 2);
    ant.wishPos := ant.pos + ant.dir * ant.speed;
    ant.speed := ant.speed + cfg.antAccel;
    if ant.speed > cfg.antMaxSpeed then ant.speed := cfg.antMaxSpeed;
  end;
end;

{ TAnt }

procedure TAnt.headTo(const targetPos: TVec2d);
var
  delta :TVec2d;
  len :single;
begin
  delta := targetPos - pos;
  len := delta.len;
  if len>0 then
  begin
    //normalizing in place
    delta.x := delta.x / len;
    delta.y := delta.y / len;
    setDir( delta );
  end;
  //ant.lastTimeUpdatePath = frameTimer.time   ?? from lua ants
end;

procedure TAnt.resetPositionMemory(const vec: TVec2d);
var
  i: Integer;
begin
  for i := 0 to High(pastPositions) do PastPositions[i] := vec;
end;

procedure TAnt.rotate(rad: single);
begin
  dir.rotate(rad);
  rot := rot +  rad;
  //rotate then aditional child vectors bellow
end;

procedure TAnt.setDir(const aNormalizedVec: TVec2d);
begin
  dir := aNormalizedVec;
  updateRot;
end;

procedure TAnt.setDirAndNormalize(const unormalizedVec: TVec2d);
begin
  dir := unormalizedVec;
  dir.normalize;
  updateRot
end;

procedure TAnt.setRot(rad: single);
begin
  rot := rad;
  //update dirs
  updateDir;
end;

procedure TAnt.storePosition(const vec: TVec2d);
begin
  PastPositions[ oldestPositionIndex ] := pos;
  inc(oldestPositionIndex);
  if oldestPositionIndex > high(PastPositions) then oldestPositionIndex := 0;
  oldestPositionStored := @PastPositions[ oldestPositionIndex ];
end;

procedure TAnt.taskFound(interest: TAntInterests);
var
  temp :TAntInterests;
begin
    temp := lookingFor;
    lookingFor := comingFrom;
    comingFrom := temp;
    speed := 0;
    setDir( -dir);
end;

procedure TAnt.updateDir;
begin
  dir := vecDir( rot );
end;

procedure TAnt.updateRot;
begin
    if dir.x<-1 then dir.x := -1 else if dir.x>1 then dir.x:=1; //some rare cases to avoid
    if dir.y>0 then rot := arcCos( dir.x ) else rot := pi*2 - arcCos( dir.x );
end;

end.
