unit u.cell;

interface
  uses
    u.simcfg, u.ants, px.sdl,  sdl2;

type


  CCell = class of TCell;
  TCell = class
    private
      fCellType :TCellTypes;
      fImg :PSprite;
      fDrawOverlay :boolean;
      fNeedDestroyWhenRemoved :boolean;
    public
      constructor create;
      procedure beginOverlap( ant :PAnt );virtual;
      procedure endOverlap( ant :PAnt );virtual;
      procedure draw( x, y:integer );virtual;
      property NeedDestroyWhenRemoved:boolean read fNeedDestroyWhenRemoved;
      property DrawOverlay:boolean read fDrawOverlay;
      property cellType :TCellTypes read fCellType;
  end;

  TGrass = class(TCell)
   private
   public
    myFriction :single;
    constructor create;
    procedure beginOverlap( ant :PAnt );override;
    procedure endOverlap( ant : PAnt );override;
  end;

  TCave = class(TCell)
    private
    public
      constructor create;
      procedure beginOverlap( ant :PAnt);override;
      procedure endOverlap( ant :PAnt);override;
  end;

  TFood = class(TCell)
    private
    public
      constructor create;
      procedure beginOverlap( ant :PAnt );override;
      procedure endOverlap( ant : PAnt );override;
  end;

  TCellFactory = class
    private
      fOneCave :TCave;
      fOneGrass :TGrass;
      fFoodImg :TSprite;
      fCaveImg :TSprite;
      fGrassImg: TSprite;
    public
      procedure init;
      procedure finalize;
      function newFood:TFood;  //you responsible to free it later
      function getCave:TCave;  //owned by this class
      function getGrass:TGrass; //owned '' '' ''
  end;

var
  cellFactory : TCellFActory;

implementation


{ TGrassCell }


{ TFood }


procedure TFood.beginOverlap(ant: PAnt);

begin
  inherited;
  if ant.lookingFor = ctFood then
  begin
    ant.cargo := true;
    ant.maxTimeSeen_MyTarget := 0;
    //swap tasks;
    ant.taskFound( ctFood );
  end;
end;

constructor TFood.create;
begin
  fCellType := ctFood;
end;

procedure TFood.endOverlap(ant: PAnt);
begin
  ant.LastTimeSeen[fCellType] := frameTimer.time;
end;

{ TCave }


procedure TCave.beginOverlap(ant: PAnt);
begin
  inherited;
  if ant.lookingFor = ctCave then
  begin
    ant.cargo := false;
    ant.maxTimeSeen_MyTarget := 0;
    //swap tasks;
    ant.taskFound( ctCave );
  end;

end;

constructor TCave.create;
begin
  fCellType := ctCave;
end;

procedure TCave.endOverlap(ant: PAnt);
begin
  //tell ant: you have seen this
  ant.LastTimeSeen[fCellType] := frameTimer.time;
end;

{ TCell }

procedure TCell.beginOverlap(ant: PAnt);
begin

end;

constructor TCell.create;
begin
  fDrawOverlay := false;
end;

procedure TCell.draw;
begin
  sdl.drawSprite(fImg^ , x,y);
end;

procedure TCell.endOverlap(ant: PAnt);
begin
end;

{ TCellFactory }

procedure TCellFactory.finalize;
begin
  fOneCave.Free;
end;

procedure TCellFactory.init;
begin
  fFoodImg := sdl.newSprite( sdl.loadTexture('images\food03.png'));
  fCaveImg := sdl.newSprite( sdl.loadTexture('images\cave.png'));
  fGrassImg := sdl.newSprite( sdl.loadTexture('images\grass01.png'));
  fOneCave := TCave.create;
  fOneCave.fNeedDestroyWhenRemoved := false;
  fOneCave.fImg := @fCaveImg;
  fOneGrass := TGrass.create;
  fOneGrass.fNeedDestroyWhenRemoved := false;
  fOneGrass.fImg := @fGrassImg;
end;

function TCellFactory.getCave: TCave;
begin
  result := fOneCave;
end;

function TCellFactory.getGrass: TGrass;
begin
  result := fOneGrass;
end;

function TCellFactory.newFood: TFood;
begin
  Result := TFood.create;
  Result.fNeedDestroyWhenRemoved := true;
  Result.fImg := @fFoodImg;
end;

{ TGrass }

procedure TGrass.beginOverlap(ant: PAnt);
begin
  ant.friction := myFriction;
end;

constructor TGrass.create;
begin
  inherited;
  fCellType :=ctGrass;
  myFriction := 0.8;
end;

procedure TGrass.endOverlap(ant: PAnt);
begin
  ant.friction := 1;
end;

initialization
  cellFactory := TCellFactory.Create;
finalization
  cellFactory.Free;
end.
