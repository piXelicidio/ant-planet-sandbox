unit u.ants;
{our Ants, let's try Data Oriented Design here... herejía }
interface

uses
  px.vec2d,
  px.sdl,
  sdl2,
  generics.collections,
  system.Math,
  u.simcfg ;

type
  TListRef = (lrIgnore, lrOwner, lrGrid);

  PAnt = ^TAnt;
  TAnt = record
      pos :TVec2d;  //position
      lastPos :TVec2d; //previous position;
      dir :TVec2d;  //direction to go
      speed   :single;
      traveled  :single;  //distance traveled
      friction  :single;

      ListRefIdx :array[TListRef] of integer;    //to store Index locations in lists or arrays, needed for fast remove
  end;

  //A list of Ants, procedures and functions most time acts over all ants
  TAntList = TList<PAnt>;

  TAntPack = class
    public
      items :TAntList;
      antOwner :boolean;
      constructor Create;
      destructor Destroy;override;
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
begin
  for i := 0 to items.Count-1 do
  begin
    ant := items.list[i];
    x1 := Floor( ant.pos.x );
    y1 := Floor( ant.pos.y );
    x2 := Floor( ant.pos.x + ant.dir.x * 5 );
    y2 := Floor( ant.pos.y + ant.dir.y * 5 );
    SDL_RenderDrawLine(sdl.rend, x1, y1, x2, y2);
  end;
end;

procedure TAntPack.addNewAndInit( amount: integer; listRef:TListRef = lrIgnore);
var
  ant :PAnt;
  i: Integer;
begin
  for i := 0 to amount-1 do
  begin
    new(ant);
    ant.pos.x := random*700;
    ant.pos.y := random*500;
    ant.speed := cfg.antMaxSpeed * 0.1;
    ant.lastPos := ant.pos;
    ant.dir := vecDir(random*pi);
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
    ant.dir.rotate( random*cfg.antErratic - cfg.antErratic / 2);
    ant.pos := ant.pos + ant.dir * ant.speed;
    ant.speed := ant.speed + cfg.antAccel;
    if ant.speed > cfg.antMaxSpeed then ant.speed := cfg.antMaxSpeed;
  end;
end;

end.
