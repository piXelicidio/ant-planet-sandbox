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
      procedure updateRot;
      procedure updateDir;
    public
      pos :TVec2d;  //position
      lastPos :TVec2d; //previous position;
      speed   :single;
      traveled  :single;  //distance traveled
      friction  :single;

      ListRefIdx :array[TListRef] of integer;    //to store Index locations in lists or arrays, needed for fast remove
      procedure setDir( const aNormalizedVec :TVec2d );
      procedure setDirAndNormalize( const unormalizedVec :TVec2d );
      procedure setRot( rad :single );
      procedure rotate( rad :single );
  end;

  //A list of Ants, procedures and functions most time acts over all ants
  TAntList = TList<PAnt>;

  TAntPack = class
    private
      fRadial :TRadial;
    public
      items :TAntList;
      antOwner :boolean;
      img :TSprite;
      constructor Create;
      destructor Destroy;override;
      procedure Init;
      procedure addNewAndInit( amount:integer; listRef :TListRef = lrIgnore );  //create and init a bunch of ants, and add them to the list
      procedure draw;
      procedure update;
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
  idx :integer;
  rdir1 :PVec2d;
  rdir2 :PVec2d;
  procedure drawScan;
  var
    iscan :integer;
    x3,y3 :integer;
  begin
    idx := fRadial.getDirIdx( ant.rot );
    for iscan := 1 to 3 do
    begin
      rdir1 := fRadial.getDirByIdx(idx+iscan);
      rdir2 := fRadial.getDirByIdx(idx-iscan);
      x3 := x1 + floor(rdir1.x * 30);
      y3 := y1 +  floor(rdir1.y * 30);
      sdl.setColor(255,255,25);
      SDL_RenderDrawLine(sdl.rend, x1, y1, x3, y3);
      x3 := x1 + floor(rdir2.x * 30);
      y3 := y1 +  floor(rdir2.y * 30);
      sdl.setColor(255,255,25);
      SDL_RenderDrawLine(sdl.rend, x1, y1, x3, y3);
    end;
  end;
begin
  for i := 0 to items.Count-1 do
  begin
    ant := items.list[i];
    x1 := Floor( ant.pos.x );
    y1 := Floor( ant.pos.y );
    x2 := Floor( ant.pos.x + ant.dir.x * 20 );
    y2 := Floor( ant.pos.y + ant.dir.y * 20 );

    //SDL_RenderCopy(sdl.rend, img.srcTex, nil, nil);
    sdl.drawSprite(img, x1, y1, ant.rot * 180 / pi);
  //  sdl.drawSprite(img, x1, y1);
   { sdl.setColor(255,255,255);
    SDL_RenderDrawPoint(sdl.rend, x1, y1);}
    sdl.setColor(255,255,255);
    SDL_RenderDrawLine(sdl.rend, x1, y1, x2, y2);
    drawScan;
  end;
end;

procedure TAntPack.Init;
begin
  img := sdl.newSprite( sdl.loadTexture('images\antWalk_00.png') );
end;

procedure TAntPack.addNewAndInit( amount: integer; listRef:TListRef = lrIgnore);
var
  ant :PAnt;
  i: Integer;
begin
  fRadial.Init(cfg.antRadialScanNum);
  for i := 0 to amount-1 do
  begin
    new(ant);
    ant.pos.x := random*700;
    ant.pos.y := random*500;
    ant.speed := cfg.antMaxSpeed * 0.1;
    ant.lastPos := ant.pos;
    ant.setRot(random*pi*2);
    ant.ListRefIdx[listRef] :=  items.add(ant);
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
    ant.lastPos :=  ant.pos;
    ant.rotate( random*cfg.antErratic - cfg.antErratic / 2);
    ant.pos := ant.pos + ant.dir * ant.speed;
    ant.speed := ant.speed + cfg.antAccel;
    if ant.speed > cfg.antMaxSpeed then ant.speed := cfg.antMaxSpeed;
  end;
end;

{ TAnt }

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

procedure TAnt.updateDir;
begin
  dir := vecDir( rot );
end;

procedure TAnt.updateRot;
begin
    if dir.y>0 then rot := arcCos( dir.y ) else rot := pi*2 - arcCos( dir.y );
end;

end.
