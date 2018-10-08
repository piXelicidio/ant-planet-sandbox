unit u.ants;
{Our Ants, let's try Data Oriented Design here... herejía }

interface

uses
  px.vec2d,
  px.sdl,
  sdl2,
  generics.collections,
  system.Math,
  u.simcfg,
  u.utils,
  u.camview;

type
  TListRef = (lrIgnore, lrOwner, lrGrid);

  TAntPack = class;

  PAnt = ^TAnt;
  ///<summary>Our Ant-Data, a record with basic methods. Most important processings are done in TAntPack</summary>
  TAnt = record
    private
      dir     : TVec2d;  //actual direction its going to, affected by environment
      rot   : single;  //rotation equivalent to current direciton;
      PastPositions :array[0..CFG_antPositionMemorySize-1] of TVec2d;
      oldestPositionIndex :integer;
      procedure updateRot;
      procedure updateDir;
      procedure storePosition(const vec :TVec2d );
      procedure resetPositionMemory(const vec :TVec2d );
    public
      owner :TAntPack;
      dirWish : TVec2d;  //direction ant want to go
      dirWishDuration :integer; //wish will expire after many frames.
      pos :TVec2d;  //position
      wishPos :TVec2d; //next position it wants to go, map has final word
      lastPos :TVec2d; //previous position;
      speed   :single;
      traveled  :single;  //distance traveled
      friction  :single;
      gridPos :TVec2di;
      isWalkingOver :TCellTypes;
      cargo :boolean;

      LastTimeSeen :array[TAntInterests] of integer;   //Last time seen each ant interests
      maxTimeSeen_MyTarget :integer;
      lookingFor :TAntInterests;
      comingFrom :TAntInterests;
      oldestPositionStored :PVec2D;

      ListRefIdx :array[TListRef] of integer;    //to store Index locations in lists or arrays, needed for fast remove, little weird, dunno how make it better
      procedure setDir( const aNormalizedVec :TVec2d );
      procedure setDirAndNormalize( const unormalizedVec :TVec2d );
      procedure setRot( rad :single );
      procedure rotate( rad :single );
      procedure headTo(const targetPos :TVec2d );
      procedure dirWishTo(const targetPos :TVec2d);
      procedure taskFound( interest :TAntInterests );
      property direction:TVec2d read dir;
  end;

  TAntList = TList<PAnt>;

  TPassLevelFunc = function( x, y: single):integer of object;

  ///<summary> A data-oriented class that deal with pack of ants, doing updates, draws and other processing for many ants in loops. </summary>
  ///<remarks> Can work also with subset of ants from other lists, setting antOwner to false and setting the items:TAntLists with PAnt references  </remarks>
  TAntPack = class
    private
      fRadial :TRadial;
    public
      items :TAntList;
      antImg :TSprite;
      fFoodCargoImg :TSprite;
      antOwner :boolean;
      constructor Create;
      destructor Destroy;override;
      procedure Init;
      ///<summary>create and init a bunch of ants, and add them to the list.
      /// return in addedAnts a list of the just added ants
      ///</summary>
      procedure addNewAndInit( amount:integer; listRef :TListRef = lrIgnore; const addedAnts :TAntList = nil  );
      procedure removeAnt(ant:PAnt; listRef :TListRef);
      procedure draw;
      procedure update;
      ///<summary>Solve ants collisions, avoid obstacles, allow or fix movement</summary>
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
    x1 := Floor( ant.pos.x ) + cam.x;
    y1 := Floor( ant.pos.y ) + cam.y;
    sdl.drawSprite(antImg, x1, y1, ant.rot * 180 / pi);
    //sdl.drawSprite(antImg, x1, y1);
    if ant.cargo  then
    begin
      sdl.setColor(255,255,25);
      x2 := Floor( ant.pos.x + ant.dir.x * 10 ) + cam.x;
      y2 := Floor( ant.pos.y + ant.dir.y * 10 ) + cam.y;
      //sdl.drawRect( x2, y2, 5, 5 );
      sdl.drawSprite(fFoodCargoImg, x2, y2);
      //SDL_RenderDrawRect()
    end;

    {$IFDEF DEBUG}
    if i<cfg.numDebugAnts then
    begin
      x2 := Floor( ant.pos.x + ant.dir.x * 40 ) + cam.x;
      y2 := Floor( ant.pos.y + ant.dir.y * 40 ) + cam.y;
      sdl.setColor(255,255,255);
      // direction
      SDL_RenderDrawLine(sdl.rend, x1, y1, x2, y2);
      sdl.drawRect( ant.gridPos.x * cfg.mapCellSize + cam.x,
                    ant.gridPos.y * cfg.mapCellSize + cam.y,
                    cfg.mapCellSize,
                    cfg.mapCellSize );
      // oldestPosition remembered;
      sdl.setColor(25,25,255);
      x2 := Floor( ant.oldestPositionStored.x ) + cam.x;
      y2 := Floor( ant.oldestPositionStored.y ) + cam.y;
      sdl.drawRect(x2,y2, 2,2);
      sdl.drawText('Soy bonita!', x2,y2);
    end;
    {$ENDIF}
  end;
end;

procedure TAntPack.Init;
begin
  antImg := sdl.newSprite( sdl.loadTexture('images\antWalk_00.png') );
  sdl.setCenterToMiddle(antImg);
  fFoodCargoImg := sdl.newSprite(sdl.loadTexture('images\foodCargo.png'));
  sdl.setCenterToMiddle(fFoodCargoImg);
end;

procedure TAntPack.removeAnt(ant: PAnt; listRef :TListRef);
var
  lastIdx, idx :integer;
  tempAnt :PAnt;
begin
  idx := ant.ListRefIdx[listRef];
  {$IFDEF DEBUG}
  //unnecesary error checking
  if idx>= items.count then sdl.print('Out of list  range, deleting ant.');
    if items.list[idx ] <> ant then sdl.print('deleting wrong ant');
  {$ENDIF}
  lastIdx := items.count -1;
  tempAnt := items.list[ lastIdx ];
  items.List[ idx ] := tempAnt;
  tempAnt.ListRefIdx[listRef] := idx;
  //delete last and free
  items.Delete(lastIdx);
  dispose(ant);
end;

procedure TAntPack.solveCollisions(passLevelFunc: TPassLevelfunc);
  var
  i: Integer;
  ant :PAnt;
  found :boolean;
  radCount :integer;
  idx :integer;
  scanIdx : integer;
  vTest :TVec2d;
  vTest2 :TVec2d;
  currLevel :integer;
begin
  for i := 0 to items.Count-1 do
  begin
    ant := items.List[i];
    {Obstacles are determined by the passLevel integer value
     ants can walk to same or lower level and can't go to higer level}
    currLevel := passLevelFunc( ant.pos.x, ant.pos.y );
    ant.lastPos := ant.pos;
    idx := fRadial.getDirIdx(ant.rot);
    if passLevelFunc( ant.wishPos.x, ant.wishPos.y) <= currLevel then
    begin
      //can walk, but lets try object avoidance first:
      vTest := ant.pos + ( fRadial.getDirByIdx(idx)^ ) * (cfg.mapCellSize*0.9) ;
      if passLevelFunc(vTest.x, vTest.y) > currLevel then
      begin
        //something ahead, try to avoid, left or right?
        vTest := ant.pos + ( fRadial.getDirByIdx(idx+1)^ ) * (cfg.mapCellSize*0.9) ;
        if passLevelFunc(vTest.x, vTest.y) <= currLevel then
        begin
          //free direction, turn that way;
          ant.setRot(fRadial.IdxToAngle(idx+1));
          //or randomly-maybe the other way if free too.
          if random(2)=1 then
          begin
            vTest := ant.pos + ( fRadial.getDirByIdx(idx-1)^ ) * (cfg.mapCellSize*0.9);
            if passLevelFunc(vTest.x, vTest.y) <= currLevel then ant.setRot(fRadial.IdxToAngle(idx-2));
          end;
        end else
        begin
          vTest := ant.pos + ( fRadial.getDirByIdx(idx-1)^ ) * (cfg.mapCellSize*0.9);
          if passLevelFunc(vTest.x, vTest.y) <= currLevel then ant.setRot(fRadial.IdxToAngle(idx-2));
        end;
      end;
      ant.pos := ant.wishPos;
    end else
    begin //solve collisions
      //do a radial scan to find best free way to go
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
      end
    end;
  end;
end;

procedure TAntPack.addNewAndInit( amount: integer; listRef:TListRef = lrIgnore;const addedAnts :TAntList = nil);
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
    //all ants start at non-accessible grid Pos 0,0;
    //so on the first step they will fall in a NEW grid position.
    ant.gridPos.X := 0;
    ant.gridPos.y := 0;
    ant.speed := cfg.antMaxSpeed * 0.1;
    ant.friction := 1;
    ant.lastPos := ant.pos;
    ant.setRot(random*pi*2);
    ant.dirWish := ant.dir;   //TODO: This line is creating the wall magnetism issue!! grr
    ant.dirWishDuration := 10; //initializing with something
    //ant.setRot(0.5);
    ant.ListRefIdx[listRef] :=  items.add(ant);
    if listRef = lrOwner then ant.owner := self;
    
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
    if addedAnts <> nil  then addedAnts.Add(ant);
    
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
    if ant.dirWishDuration>0 then
    begin
      dec(ant.dirWishDuration);
      if (ant.dirWishDuration mod 3) = 0 then ant.setDirAndNormalize( ant.dir * 2 + ant.dirWish);
    end;
    ant.speed := ant.speed * ant.friction;
    ant.wishPos := ant.pos + ant.dir * ant.speed ;
    ant.speed := ant.speed + cfg.antAccel;
    if ant.speed > cfg.antMaxSpeed then ant.speed := cfg.antMaxSpeed;
  end;
end;

{ TAnt }

procedure TAnt.dirWishTo(const targetPos: TVec2d);
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
    dirWish := delta
  end;
  //ant.lastTimeUpdatePath = frameTimer.time   ?? from lua ants
end;

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
